#!/bin/bash
set -eu
IFS=$'\n'

opt_verbose=true
opt_abspath=false
opt_finddir=.
opt_maxdepth=1

log() {
    $opt_verbose && echo "$@" >&2
    return 0
}

error() {
    echo "Error: $*" >&2
    exit 1
}

reponame() {
    $opt_abspath && realpath -s "$1" || echo "$1"
}

usage() {
    cat <<DOC
Usage: $(basename $0) [OPTION...] [command [args]]

Run commands with optional args in each git repository for each git repository
found. Without command, found git repositories are printed to stdout.

  -a, --abspath             Print absolute path to repositories
      --dir DIR             Find repositories in DIR (default: $opt_finddir)
      --maxdepth N          See FIND(1) -maxdepth option (default: $opt_maxdepth)
  -q, --quiet               Don't log messages to stderr
  -h, --help                Give this help

DOC
}

while [ -n "${1:-}" ]; do
    case "$1" in
        -a|--abspath)   opt_abspath=true; shift ;;
        --dir)
            if [ -n "${2:-}" ] && [ -d "$2" ]; then
                opt_finddir="$2"
                shift 2
            else
                error "Missing or invalid argument value for $1"
            fi
            ;;
        --maxdepth)
            if [[ "${2:-}" =~ ^[[:digit:]]$ ]]; then
                opt_maxdepth="$2"
                shift 2
            else
                error "Missing or invalid argument value for $1"
            fi
            ;;
        -h|--help)      usage; exit 0 ;;
        -q|--quiet)     opt_verbose=false; shift ;;
        *)  break ;;
    esac
done

mapfile -t repos < <(find "$opt_finddir" -maxdepth "$opt_maxdepth" -type d -exec test -d "{}/.git" \; -print)

set +e
for repo in "${repos[@]}"; do
    if [ -z "${1:-}" ]; then
        reponame "$repo"
        continue
    fi
    log "=== `reponame $repo`"
    git -C "$repo" "$@"
    log "git exit status: $?"
done
