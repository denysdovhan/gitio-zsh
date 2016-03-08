#!/usr/bin/env zsh


# SYNOPSIS
#   gitio [[https://github.com/]username/repo] [vanity code]
#
# DESCRIPTION
#   A zsh plugin for generating a GitHub short URL.
#
# LINKS
#   github.com/blog/985-git-io-github-url-shortener
#   github.com/fishery/tiny
function gitio() {

  # Show help message with colors
  function gitio-help() {
    printf "USAGE: gitio [[%s]%s/%s] [%s] \n" \
      "https://github.com/" \
      "${fg[cyan]}username${reset_color}" \
      "${fg[magenta]}repo${reset_color}" \
      "${fg[green]}vanity code${reset_color}" \
  }

  # Get URL from git config
  if [[ "$#" -eq 0 && -s ".git/config" ]]; then
    local CONFIG_URL="$(
      awk '/url =/ {
        sub(/^.+github\.com[\/:]/, "", $3)
        sub(/\.git$/, "", $3)
        print $3
        exit
      }' .git/config
    )"
  fi

  # Show help message for -h and --help flags
  if [[ "$#" -eq 0 && -z "$CONFIG_URL" || "$1" == "-h" || "$1" == "--help" ]]; then
    gitio-help
    return 0
  fi

  # Check if URL contains http(s)
  if [[ -n "$CONFIG_URL" ]]; then
    local URL="https://github.com/$CONFIG_URL"
  elif [[ ! "$1" =~ ^(http|https)://github.com/ ]]; then
    local URL="https://github.com/$1"
  else
    local URL="$1"
  fi

  # Check if code is valid
  if [[ -n "$2" ]]; then
    local CODE="$(echo "$2" | tr "[:upper:]" "[:lower:]")"

    if [[ ! "$CODE" =~ ^[0-9a-z\-]+$ ]]; then
      printf "Error: %s code is invalid." "${fg_bold[red]}$2${reset_color}"
      return 1
    fi
  fi

  # Make request to git.io
  if [[ -n "$URL" && -n "$CODE" ]]; then
    local GITIO_URL="$(
      curl --include --silent https://git.io/ \
           --form url="$URL" \
           --form code="$CODE" \
    )"
  elif [[ -n "$URL" ]]; then
    local GITIO_URL="$(
      curl --include --silent https://git.io/ \
           --form url="$URL" \
    )"
  else
    gitio-help
    return 1
  fi

  # Get shorten URL from response
  GITIO_URL="$(
    echo "$GITIO_URL" \
    | grep "Location: http" \
    | cut -c11- \
    | awk '{print substr($0, 1, length($0) - 1)}' \
  )"

  # Copy to clipboard if possible
  case "$(uname)" in
    ("Darwin") echo "$GITIO_URL" | pbcopy ;;
    ("Linux")  echo "$GITIO_URL" | xclip -selection c ;;
  esac

  # Print shorten URL to terminal
  echo "${fg[cyan]}$GITIO_URL${reset_color}"

  # Open in browser if possible
  open "$GITIO_URL"
}
