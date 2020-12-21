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
  typeset -a neededBinaries=("sudo" "find" "xargs" "realpath" "cmp")
  for tool in "${neededBinaries[@]}"; do
    if ! command -v "${tool}" &>/dev/null; then
      echo "Cannot find the ${tool} command on your system."
      echo "Please install it using your package manager and re-run this script."
      exit 1
    fi
  done
}

checkRoot() {
  if [ "${UID}" -ne 0 ]; then
    echo -n "This script must be run with elevated privileges. "
    echo "Please authenticate to grant them."
    # Runs itself as root
    sudo "$0"
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
    echo "Could not find any Vivaldi installation"
    exit 1
  fi
  echo -e 'Installations found.\n--------------------'
}

selectVivaldiInstallation() {
  if [ "${vivaldiInstallCount}" -gt 1 ]; then
    typeset -i option=0
    while [ "${option}" -le 0 ] ||
      [ "${option}" -gt "${vivaldiInstallCount}" ]; do
      echo "Pick Vivaldi installation to patch"
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

uninstallVivaldiHooks() {
  typeset -g targetResourcesDir="${targetDir}/resources/vivaldi"
  if [ -e "${targetResourcesDir}/jdhooks.js" ] &&
    cmp -s "${targetResourcesDir}/jdhooks.js" \
      "${hooksRootDir}/vivaldi/jdhooks.js"; then
    # Install VivaldiHooks files
    echo "Deleting hook files from ${targetResourcesDir}"
    [ -d "${targetResourcesDir}/hooks" ] &&
      rm -Rvf "${targetResourcesDir}"/hooks
    rm -vf "${targetResourcesDir}/jdhooks.js"

    # Clean browser.html, if needed
    if [ -e "${targetResourcesDir}/browser.html.preHooks" ]; then
      echo "Restoring backup of unpatched browser.html..."
      cp -vf "${targetResourcesDir}/browser.html.preHooks" \
        "${targetResourcesDir}/browser.html"
    elif grep -q "jdhooks.js" "${targetResourcesDir}/browser.html"; then
      echo "Removing patch from browser.html..."
      sed -E -i -e '/^\s+<script src="jdhooks.js"><\/script>.+/d' \
        "${targetResourcesDir}/browser.html"
    fi
    echo -e '\nVivaldiHooks uninstalled successfully!'
  else
    echo -e '\nThis Vivaldi installation did not have VivaldiHooks installed.'
  fi
}

checkDependencies
checkRoot

base64 -d <<<"H4sIAAAAAAAAA5WPMQ7DIBRDd67A4vFHArlR1Km9SQafAOUCPXz8k1RKx1ofDO8bE\
HWdX8syoAZAuOva6ZdaJfABuN0ZmdMWsPPLzjScZjvua1I+5LCUiL3nMotvIM40EeJloaDsOZy3TS53\
jSbV9TFKzS88R/9Lx8myA5fh2Yv+AAAA" | gunzip

checkVivaldiInstalled
selectVivaldiInstallation
uninstallVivaldiHooks
