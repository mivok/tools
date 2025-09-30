#!/usr/bin/env bash
# Checks kustomization.yaml files for any images with updates available,
# printing out any differences.
#
# Requires: skopeo, yq, jq and GNU coreutils (for sort -V).

VERBOSE=0
INCLUDE_RE=''
EXCLUDE_RE='-(alpha|beta|rc|dev|snapshot)[0-9.-]*$'

DEBUG() { (( VERBOSE > 1 )) && echo "[debug] $*"; }
WARN()  { echo "WARN: $*" >&2; }
ERR()   { echo "ERROR: $*" >&2; }

usage() {
  echo 'Usage:'
  echo "  $0 [OPTIONS] [DIR ...]"
  echo
  echo 'Options:'
  echo '  -v            verbose (print all images current/latest)'
  echo '  -vv           very verbose (debug: show registry queries)'
  echo '  -i REGEX      include tags matching REGEX (applied before exclude)'
  echo '  -x REGEX      exclude tags matching REGEX'
  echo "                (default: '$EXCLUDE_RE')"
  echo '  -h            help'
  echo
  echo 'Notes:'
  echo '  * If no DIRs are given, scans */kustomization.yaml'
  echo '  * "Latest" is computed as the highest semver-ish tag'
  echo '    (v-prefixed allowed). Use -i/-x to modify this (e.g.'
  echo '    -x '\''(-dev|-rc)$'\''). Attempts are made to match the'
  echo '    style of the current tag (e.g. if current is "1.2.3-alpine",'
  echo '    the latest will also have "-alpine" at the end).'
}

# Choose the latest tag from stdin according to the given rules.
pick_latest_tag() {
  local include_re="$1" exclude_re="$2" current="$3"

  local stream
  stream=$(cat)

  # Apply include/exclude first
  if [[ -n "$include_re" ]]; then
    stream=$(grep -E -- "$include_re" <<<"$stream")
  fi
  if [[ -n "$exclude_re" ]]; then
    stream=$(grep -Ev -- "$exclude_re" <<<"$stream")
  fi

  # If current tag "looks semver-ish" (contains a dot), filter only to tags that
  # also look semver-ish.  This helps avoid picking bare numeric tags when
  # current is a semver like "1.2.3" or "v1.2.3".
  if [[ "$current" == *.* ]]; then
    # Match current version style, with or without leading 'v'
    if [[ "$current" == v* || "$current" == V* ]]; then
      stream=$(grep -E '^[vV][0-9]+\.' <<<"$stream")
    else
      stream=$(grep -E '^[0-9]+\.' <<<"$stream")
    fi
  fi

  # If the current version ends with a suffix (e.g. -alpine) filter to tags that
  # also end with that suffix.  This helps avoid picking "1.2.3" when current is
  # "1.2.3-alpine". Similarly, if the current tag has no suffix, filter out tags
  # that do have a suffix.
  if [[ "$current" =~ -[A-Za-z]+$ ]]; then
    local suffix="${current##*-}"
    stream=$(grep -E -- "-${suffix}$" <<<"$stream")
  else
    stream=$(grep -Ev -- '-[a-zA-Z0-9]+$' <<<"$stream")
  fi

  # Always exclude latest
  stream=$(grep -Ev '^(latest|stable|current)$' <<<"$stream")

  sort -V <<<"$stream" | tail -n1
}

#
# Main script
#

while getopts ':vi:x:h' opt; do
  case "$opt" in
    v) ((VERBOSE++)) ;;
    i) INCLUDE_RE="$OPTARG" ;;
    x) EXCLUDE_RE="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) ERR "Option -$OPTARG requires an argument"; usage; exit 2 ;;
    \?) ERR "Unknown option -$OPTARG"; usage; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

shopt -s nullglob
if (( $# )); then
    DIRS=("$@")
else
  DIRS=(*/)
fi

# Collect lines: "imagename","currenttag"
for dir in "${DIRS[@]}"; do
  kf="${dir%/}/kustomization.yaml"
  [[ -f "$kf" ]] || { DEBUG "No kustomization.yaml in $dir"; continue; }
  DEBUG "Parsing images from: $kf"

  yq -r '.images // [] | .[] | [.newName // .name, .newTag] | @tsv' "$kf" | \
  while IFS=$'\t' read -r img cur; do

    if [[ -z "$img" ]]; then
      DEBUG "Skipping empty image"
      continue
    fi

    DEBUG "Checking image: $img (current tag: ${cur:-<none>})"

    # Ask registry for all tags for this repo name.
    TAGS=$(skopeo list-tags "docker://${img}" 2>/dev/null | jq -r '.Tags[]')
    if [[ -z "$TAGS" ]]; then
      WARN "No tags found or unable to list for ${img}"
      continue
    fi

    latest=$(printf '%s\n' "$TAGS" |
      pick_latest_tag "$INCLUDE_RE" "$EXCLUDE_RE" "$cur")
    if [[ -z "$latest" ]]; then
      WARN "No matching tags (after filters) for ${img}"
      continue
    fi

    DEBUG "---"
    DEBUG "file:         $kf"
    DEBUG "image:        $img"
    DEBUG "current tag:  ${cur:-<none>}"
    DEBUG "latest tag:   $latest"
    DEBUG "include re:   ${INCLUDE_RE:-<none>}"
    DEBUG "exclude re:   ${EXCLUDE_RE:-<default>}"

    if [[ -z "$cur" || "$cur" != "$latest" ]]; then
      echo "$kf: ${img} -> current=${cur:-<none>} latest=${latest}"
    else
      (( VERBOSE > 0 )) && echo "$kf: ${img} up-to-date (tag ${cur})"
    fi
  done
done
