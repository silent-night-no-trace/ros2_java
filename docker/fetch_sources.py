#!/usr/bin/env python3
"""Fetch ros2 .repos sources as tarballs from codeload.github.com.

Replaces `vcs import` on hosts where git smart-http to github.com is throttled
(common in CN networks). codeload tarball fetch is plain HTTPS GET and works.

Tries refs/heads/<version> first, falls back to refs/tags/<version>.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path


def parse_repos(f: Path):
    repos = []
    name = url = ver = None
    for line in f.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\s{2}([^\s].*?):\s*$", line)
        if m:
            if name and url and ver:
                repos.append((name, url, ver))
            name, url, ver = m.group(1), None, None
            continue
        u = re.match(r"^\s{4}url:\s*(\S+)", line)
        if u:
            url = u.group(1)
            continue
        v = re.match(r"^\s{4}version:\s*(\S+)", line)
        if v:
            ver = v.group(1)
            continue
    if name and url and ver:
        repos.append((name, url, ver))
    return repos


def github_repo(url: str) -> str:
    r = url
    for pre in ("https://github.com/", "http://github.com/"):
        if r.startswith(pre):
            r = r[len(pre):]
            break
    if r.endswith(".git"):
        r = r[:-4]
    return r.rstrip("/")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repos", required=True)
    ap.add_argument("--src", required=True)
    a = ap.parse_args()
    src = Path(a.src)
    src.mkdir(parents=True, exist_ok=True)
    tgz = Path("/tmp/fetch_sources.tgz")
    for path, url, ver in parse_repos(Path(a.repos)):
        repo = github_repo(url)
        dest = src / path
        if dest.exists() and any(dest.iterdir()):
            print(f"[skip] {path} (already present)")
            continue
        dest.mkdir(parents=True, exist_ok=True)
        ok = False
        for ref in (f"refs/heads/{ver}", f"refs/tags/{ver}"):
            u = f"https://codeload.github.com/{repo}/tar.gz/{ref}"
            print(f"[get ] {path} @ {ver} <- {ref}", flush=True)
            rc = subprocess.call(
                ["curl", "-fsL", "--retry", "3", "--retry-delay", "2",
                 "--connect-timeout", "20", "-o", str(tgz), u])
            if rc == 0 and tgz.exists() and tgz.stat().st_size > 0:
                ok = True
                break
        if not ok:
            print(f"[ERR ] {path} @ {ver}: codeload fetch failed", file=sys.stderr)
            sys.exit(1)
        rc = subprocess.call(["tar", "-xzf", str(tgz), "-C", str(dest),
                              "--strip-components=1"])
        if rc != 0:
            print(f"[ERR ] {path}: extract failed", file=sys.stderr)
            sys.exit(1)
        print(f"[ok  ] {path} @ {ver}", flush=True)
    print("[done] all sources fetched")


if __name__ == "__main__":
    main()
