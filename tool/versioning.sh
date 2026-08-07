#!/bin/sh
set -eu

find_pubspec() {
  repo_dir="$1"

  for candidate in \
    "$repo_dir/pubspec.yaml" \
    "$repo_dir/frontend_projeto_semestre/pubspec.yaml" \
    "$repo_dir/FrontEnd/frontend_projeto_semestre/pubspec.yaml"
  do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  found="$(find "$repo_dir" -maxdepth 3 -type f -name pubspec.yaml -not -path '*/build/*' | head -n 1 || true)"
  if [ -n "$found" ]; then
    printf '%s\n' "$found"
    return 0
  fi

  return 1
}

read_flutter_version() {
  pubspec="$1"
  line="$(grep -E '^version:[[:space:]]*' "$pubspec" | head -n 1 || true)"
  [ -n "$line" ] || return 1

  value="${line#version:}"
  value="$(printf '%s' "$value" | tr -d '[:space:]' | tr -d '"' | tr -d "'")"
  printf '%s\n' "$value"
}

next_version() {
  current="$1"
  change_type="$2"

  base="${current%%+*}"
  if [ "$base" = "$current" ]; then
    build=0
  else
    build="${current#*+}"
  fi

  old_ifs="$IFS"
  IFS=.
  set -- $base
  IFS="$old_ifs"

  major="${1:-0}"
  minor="${2:-0}"
  patch="${3:-0}"

  case "$major:$minor:$patch:$build" in
    *[!0-9:]*|'') return 1 ;;
  esac

  case "$change_type" in
    FEAT)
      minor=$((minor + 1))
      patch=0
      ;;
    FIX|CHORE)
      patch=$((patch + 1))
      ;;
    *)
      return 1
      ;;
  esac

  build=$((build + 1))
  printf '%s.%s.%s+%s\n' "$major" "$minor" "$patch" "$build"
}

write_flutter_version() {
  pubspec="$1"
  next="$2"
  tmp="${pubspec}.version-hook.tmp"

  awk -v replacement="version: $next" '
    BEGIN { changed = 0 }
    /^version:[[:space:]]*/ && changed == 0 {
      print replacement
      changed = 1
      next
    }
    { print }
    END {
      if (changed == 0) exit 7
    }
  ' "$pubspec" > "$tmp" || {
    rm -f "$tmp"
    return 1
  }

  mv "$tmp" "$pubspec"
}
