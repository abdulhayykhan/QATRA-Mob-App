#!/usr/bin/env python3
"""
calculate_next_tag.py
Determines the next unique semver release tag for QATRA releases.
Progression:
  v0.0.1 -> v0.0.9 -> v0.1.0 -> v0.1.9 -> v0.2.0 ... -> v0.9.9 -> v1.0.0
"""
import re
import subprocess
import sys

def get_remote_tags():
    try:
        output = subprocess.check_output(
            ["git", "ls-remote", "--tags", "origin"],
            stderr=subprocess.DEVNULL,
            text=True
        )
        tags = set()
        for line in output.strip().splitlines():
            if not line:
                continue
            parts = line.split()
            if len(parts) >= 2 and parts[1].startswith("refs/tags/"):
                ref = parts[1][len("refs/tags/"):]
                if ref.endswith("^{}"):
                    ref = ref[:-3]
                tags.add(ref)
        return tags
    except Exception as e:
        sys.stderr.write(f"Notice: git ls-remote encountered {e}, falling back to local tags\n")
        try:
            local = subprocess.check_output(["git", "tag", "-l"], text=True)
            return set(line.strip() for line in local.splitlines() if line.strip())
        except Exception:
            return set()

def increment_tag(major: int, minor: int, patch: int):
    # Enforce custom specification:
    # v0.0.1 -> v0.0.9 -> v0.1.0 -> v0.1.9 -> v0.2.0 ... -> v0.9.9 -> v1.0.0
    if patch < 9:
        return major, minor, patch + 1
    else:
        patch = 0
        if minor < 9:
            return major, minor + 1, patch
        else:
            return major + 1, 0, 0

def resolve_tag(custom_tag=None):
    remote_tags = get_remote_tags()
    sys.stderr.write(f"Found existing tags: {sorted(remote_tags)}\n")

    if custom_tag and custom_tag.strip():
        tag = custom_tag.strip()
        if not tag.startswith("v"):
            tag = "v" + tag
        return tag

    pattern = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")
    parsed_tags = []
    for tag in remote_tags:
        match = pattern.match(tag)
        if match:
            maj, min_, pat = int(match.group(1)), int(match.group(2)), int(match.group(3))
            parsed_tags.append((maj, min_, pat))

    if not parsed_tags:
        next_maj, next_min, next_pat = 0, 0, 1
    else:
        parsed_tags.sort()
        latest = parsed_tags[-1]
        sys.stderr.write(f"Latest tag: v{latest[0]}.{latest[1]}.{latest[2]}\n")
        next_maj, next_min, next_pat = increment_tag(latest[0], latest[1], latest[2])

    # Advance until an unused tag is found (guarantees no tag collision)
    while f"v{next_maj}.{next_min}.{next_pat}" in remote_tags:
        sys.stderr.write(f"Tag v{next_maj}.{next_min}.{next_pat} already exists, incrementing...\n")
        next_maj, next_min, next_pat = increment_tag(next_maj, next_min, next_pat)

    candidate = f"v{next_maj}.{next_min}.{next_pat}"
    sys.stderr.write(f"Calculated next unique tag: {candidate}\n")
    return candidate

if __name__ == "__main__":
    custom = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].strip() else None
    print(resolve_tag(custom))
