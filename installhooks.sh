#!/usr/bin/env bash
# Shell script to install VivaldiHooks on *nix systems <https://git.io/JLmXn>
#
# SPDX-FileCopyrightText: 🄯 2020 Peter J. Mello <admin@petermello.net>
#
# SPDX-License-Identifier: MPL-2.0
set -e

typeset -g hooksRootDir="$(dirname "$(test -L "${BASH_SOURCE[0]}" &&
  realpath -Leq "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")"

checkDependencies() {
  typeset -A neededBinaries=(
    "sudo" "sudo" "find" "findutils" "xargs" "findutils" "realpath" "coreutils"
    "cmp" "diffutils" "base64" "coreutils" "gunzip" "gzip"
  )
  for tool in "${!neededBinaries[@]}"; do
    if ! command -v "${tool}" &>/dev/null; then
      echo "ERROR: Cannot find the ${tool} command on your system."
      echo -n "Please install the ${neededBinaries[$tool]} package and re-run "
      echo "this script."
      exit 1
    fi
  done
}

checkRoot() {
  if [ "${UID}" -ne 0 ]; then
    echo -n "This script must be run with elevated privileges. "
    echo "Please authenticate to grant them."
    # Runs itself as root
    sudo "${0}"
    exit 0
  fi
}

checkVivaldiInstalled() {
  echo "Finding all Vivaldi installations"
  typeset -ga vivaldiInstallations=(
    "$(find -O3 /opt -nowarn -executable -type f -name 'vivaldi-bin' \
      -printf '%h\0' 2>/dev/null | xargs -0 -I '{}' realpath -Leq '{}')"
  )
  typeset -gi vivaldiInstallCount="${#vivaldiInstallations[*]}"
  if [ "${vivaldiInstallCount}" -eq 0 ]; then
    echo "ERROR: Could not find any Vivaldi installation."
    exit 1
  fi
  echo -e 'Installations found.\n--------------------'
}

selectVivaldiInstallation() {
  if [ "${vivaldiInstallCount}" -gt 1 ]; then
    typeset -i option=0
    while [ "${option}" -le 0 ] ||
      [ "${option}" -gt "${vivaldiInstallCount}" ]; do
      echo "Select a Vivaldi installation to patch:"
      typeset -i i=1
      for vivaldiInstallFolder in "${vivaldiInstallations[@]}"; do
        echo "$((i++)). ${vivaldiInstallFolder}"
      done
      echo "${i}. Cancel"
      read -r option
      # This block transforms input into an invalid option to avoid breaking
      # the script if we enter a letter or a symbol.
      if [[ "$(echo "${option}" | grep -E '\b[0-9]{1,2}\b')" == '' ]]; then
        option=0
      fi
      # If we choose to cancel we get out here
      if [ "${option}" -eq "${i}" ]; then
        exit 0
      fi
    done
    # the '--' is an arithmetic operator for prefix subtraction to return the
    # option to a zero-indexed value.
    typeset -g targetDir="${vivaldiInstallations[--option]}"
  else
    typeset -g targetDir="${vivaldiInstallations[0]}"
  fi
}

installVivaldiHooks() {
  typeset -g targetResourcesDir="${targetDir}/resources/vivaldi"
  if [ ! -e "${targetResourcesDir}/jdhooks.js" ] ||
    ! cmp -s vivaldi/jdhooks.js "${targetResourcesDir}/jdhooks.js"; then
    # Install VivaldiHooks files
    echo "Copying hook files from ${hooksRootDir}/vivaldi to ${targetDir}..."
    [ -d "${targetResourcesDir}/hooks" ] && rm -rf "${targetResourcesDir}"/hooks
    install -Dm0644 -t "${targetResourcesDir}" \
      "${hooksRootDir}/vivaldi/jdhooks.js"
    install -Dm0644 -t "${targetResourcesDir}/hooks" \
      "${hooksRootDir}"/vivaldi/hooks/*
    # Patch browser.html, if needed
    if ! grep -q "jdhooks.js" "${targetResourcesDir}/browser.html"; then
      echo "Patching browser.html..."
      sed -i.preHooks -e \
        '/src="bundle.js"/i \ \ \ \ <script src="jdhooks.js"></script>' \
        "${targetResourcesDir}/browser.html"
    fi
    echo -e '\nVivaldiHooks installed successfully!'
  else
    echo -e '\nThis Vivaldi installation already has the latest VivaldiHooks.'
  fi
}

checkDependencies
checkRoot

# ASCII Art
base64 -d <<<"H4sIAAAAAAAAA5WPMQ7DIBRDd67A4vFHArlR1Km9SQafAOUCPXz8k1RKx1ofDO8bE\
HWdX8syoAZAuOva6ZdaJfABuN0ZmdMWsPPLzjScZjvua1I+5LCUiL3nMotvIM40EeJloaDsOZy3TS53\
jSbV9TFKzS88R/9Lx8myA5fh2Yv+AAAA" | gunzip || :

checkVivaldiInstalled
selectVivaldiInstallation
installVivaldiHooks
