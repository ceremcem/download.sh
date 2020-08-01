#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

# show help
# -----------------------------------------------
show_help(){
    cat <<HELP
    $(basename $0) [options] http://your-url/file
    Options:
        --filename       : Use this filename instead of basename of url
        --refresh        : Re-download the file.
HELP
    exit
}
die(){
    echo 
    echo "$@"
    echo
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
filename=
url=
refresh=
# ---------------------------
args=("$@")
_count=1
while :; do
    key="${1:-}"
    case $key in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        --filename) shift
            filename="$1"
            ;;
        --refresh) shift
            refresh="yes"
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            echo
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)  # Generate the positional arguments: $_arg1, $_arg2, ...
            [[ ! -z ${1:-} ]] && declare _arg$((_count++))="$1" && shift
    esac
    [[ -z ${1:-} ]] && break
done; set -- "${args[@]}"
# use $_arg1 in place of $1, $_arg2 in place of $2 and so on, "$@" is intact

url="${_arg1:-}"
[[ -z $url ]] && die "Url is required."
[[ -z $filename ]] && filename=$(basename $url)
tmp="${filename}.part"

if [ ! -f "${filename}" ] || [[ ! -z $refresh ]]; then
  echo "Downloading ${filename}"
  wget --continue -O "${tmp}" "${url}" --progress=bar:force 2>&1 | tail -f -n +6
  # rename the partial file if download is succeeded
  mv "${tmp}" "${filename}"
else
  echo "$filename is already downloaded. Use --refresh to re-download."
fi

