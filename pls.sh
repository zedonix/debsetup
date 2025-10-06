#!/usr/bin/env bash
set -euo pipefail

pkgfile="${1:-pkglist.txt}"

if [ ! -f "$pkgfile" ]; then
  echo "Error: package list file '$pkgfile' not found." >&2
  exit 2
fi

# Pre-cache manual packages
manual_list=$(apt-mark showmanual 2>/dev/null || true)

# Helper: trim
trim() { printf '%s' "$1" | awk '{$1=$1;print}'; }

while IFS= read -r line || [ -n "$line" ]; do
  # strip comments and whitespace
  pkg=$(printf '%s' "$line" | sed 's/#.*//' | tr -d '\r' | awk '{$1=$1;print}')
  [ -z "$pkg" ] && continue

  # must be installed
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    continue
  fi

  # Check Essential and Priority
  essential=$(apt-cache show "$pkg" 2>/dev/null | awk '/^Essential:/{print tolower($2);exit}' || true)
  priority=$(apt-cache show "$pkg" 2>/dev/null | awk '/^Priority:/{print tolower($2);exit}' || true)

  if [ "${essential:-}" = "yes" ]; then
    # essential package -> skip
    continue
  fi
  if [ "${priority:-}" = "required" ] || [ "${priority:-}" = "important" ]; then
    # high-priority package -> skip
    continue
  fi

  # Skip if user marked it manual
  if printf '%s\n' "$manual_list" | grep -qx "$pkg"; then
    continue
  fi

  # Check installed reverse-dependencies (installed packages that depend on $pkg)
  rdeps=$(apt-cache rdepends "$pkg" 2>/dev/null | sed '1,2d' | sed 's/^[[:space:]]*//' | sed '/^$/d' || true)
  has_installed_rdep=0
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    # ignore virtual pkg lines or headers
    if dpkg -s "$r" >/dev/null 2>&1 && [ "$r" != "$pkg" ]; then
      has_installed_rdep=1
      break
    fi
  done <<<"$rdeps"

  if [ $has_installed_rdep -eq 1 ]; then
    continue
  fi

  # Simulate removal and capture the package list apt would remove
  removed_list=$(apt-get -s remove --purge "$pkg" 2>/dev/null | awk '
    /^The following packages will be REMOVED:/{flag=1; next}
    flag && NF==0 {exit}
    flag {gsub(/^[[:space:]]+/, ""); gsub(/,$/,""); print}
  ' || true)

  # If apt-get didn't emit the "The following packages will be REMOVED:" block,
  # fall back to trying to extract "Remv " lines (older apt output formats)
  if [ -z "$removed_list" ]; then
    removed_list=$(apt-get -s remove --purge "$pkg" 2>/dev/null | sed -n '1,200p' | awk '/^Remv /{print $2}' || true)
  fi

  # Normalize removed_list to whitespace-separated tokens and check if anything else would be removed
  other_to_remove=$(printf '%s\n' "$removed_list" | tr -s ' \n' '\n' | grep -vx -- "$pkg" || true)

  if [ -n "$other_to_remove" ]; then
    # removing this will remove other installed packages -> treat as necessary
    continue
  fi

  # passed all checks => consider unnecessary (conservative)
  printf '%s\n' "$pkg"

done < "$pkgfile"
