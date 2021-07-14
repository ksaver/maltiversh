#!/bin/bash
#
#  This script checks an IP address or hostname in
#  maltiverse.com database.
#  requires: bash shell, curl and jq
#  ksaver, 2021.07.14
#

SCRIPTNAME="maltiversh"
VERSION="0.2"
# API key required, register your own at maltiverse.com
API_KEY=""

function check_requirements() {
  # check all requirements are met before continue
  REQUIREMENTS=(bash curl jq)
    for REQ in ${REQUIREMENTS[@]}; do
      type $REQ &>/dev/null || \
        (echo -e "Error: ${REQ} is not installed.\n\
        \rPlease install it before continue." && return 1)
    done
}

function show_help() {
  echo -e "${SCRIPTNAME} v${VERSION}"
  echo -e "Example:"
  echo -e "\t${0} -h"
  echo -e "\t${0} help"
  echo -e "\t${0} 123.123.123.123"
  echo -e "\t${0} domain.com"
  echo -e "\t${0} file.txt"
}

function missing_arg() {
  echo "Missing argument!"
  echo "Run: ${SCRIPTNAME} help"
}

function validate_ip() {
  # input: string containg ip address to validate
  # output: none
  # returns:
  #   0: valid IP address
  #   1: not valid IP address
  rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
  [[ "$1" =~ ^$rx\.$rx\.$rx\.$rx$ ]] && return 0 || return 1
}

function get_url() {
  # input: IP address or hostname
  # output: maltiverse URL
  # call this function:
  #  get_url 12.12.12.12
  #  get_url example.com
  TYPE=""
  TARGET="$1"
  
  if validate_ip "$TARGET"; then
    TYPE="ip"
  else
    TYPE="hostname"
  fi

  API_URL="https://api.maltiverse.com/${TYPE}/${TARGET}"
  echo "${API_URL}"
}

function maltiverse_req() {
  # input: maltiverse api URL ($1)
  # output: json with maltiverse response
  API_URL="$1"
  curl -s -H "Authorization: Bearer ${API_KEY}" "$API_URL"
}

function print_results() {
  # input:
  #   $1: File line or argument (target)
  # output:
  #   target, response_type, url
  TARGET="$1"
  API_URL=$(get_url "$TARGET")
  RESPONSE=$(maltiverse_req "$API_URL" | jq -r .classification)
  WWW_URL=$(echo $API_URL | sed 's/api/www/')
  echo "$TARGET, $RESPONSE, $WWW_URL"
}

function main() {
  # input is a file
  if [ -f "$1" ]; then
    FILENAME="$1"
    while read TARGET; do
      [ -z $TARGET ] && continue # skips blank line
      print_results "$TARGET"
    done < ${FILENAME}
  else
    # input is one or more arguments
    for TARGET in "${@}"; do
      print_results "$TARGET"
    done
  fi
}


check_requirements || exit
[[ "$API_KEY" == "" ]] && echo "Missing API KEY. Please register at maltiverse.com" && exit

case "$@" in
    "")
        missing_arg
        exit
        ;;
    "help" | "-h")
        show_help
        exit
        ;;
    *)
        main "${@}"
        exit
        ;;
esac
