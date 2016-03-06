#!/usr/bin/env zsh
#
# SYNOPSIS
#   gitio <[https://github.com/]username/repo> [vanity code]
#
# DESCRIPTION
#   Generate a GitHub short URL.
#
# LINKS
#   github.com/blog/985-git-io-github-url-shortener


function gitio() {

  function gitio-help() {
    printf "USAGE: gitio <[%s]%s/%s> [%s] \n" \
      "https://github.com/" \
      "${fg[cyan]}username${reset_color}" \
      "${fg[magenta]}repo${reset_color}" \
      "${fg[green]}vanity code${reset_color}" \
  }

  if [[ $1 == "-h" || $1 == "--help" ]]; then
    gitio-help
    return 0
  fi

  if test "${1#*http}" == $1; then
    local URL="https://github.com/$1"
  else
    local URL="$1"
  fi

  if [[ -n "$2" ]]; then
    local CODE="$(echo "$2" | tr "[:upper:]" "[:lower:]")"

    if [[ ! "$CODE" =~ ^[0-9a-z]+$ ]]; then
      printf "Error: %s code is invalid." "${fg_bold[red]}$2${reset_color}"
      return 1
    fi
  fi

  if [[ -n "$URL" && -n "$CODE" ]]; then
    local GITIO_URL=$(
      curl --include --silent https://git.io/ \
           --form url="$URL" \
           --form code="$CODE" \
    )
  elif [[ -n "$URL" ]]; then
    local GITIO_URL=$(
      curl --include --silent https://git.io/ \
           --form url="$URL" \
    )
  else
    gitio-help
    return 1
  fi

  GITIO_URL=$(
    echo "$GITIO_URL" \
    | grep "Location: http" \
    | cut -c11- \
    | awk '{print substr($0, 1, length($0) - 1)}' \
  )

  case $(uname) in
    ("Darwin") echo "$GITIO_URL" | pbcopy ;;
    ("Linux")  echo "$GITIO_URL" | xclip -selection c ;;
  esac

  echo "${fg[cyan]}$GITIO_URL${reset_color}"

  open "$GITIO_URL"
}
