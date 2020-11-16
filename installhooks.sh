#!/usr/bin/env bash
set -e

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

installVivaldiHooks() {
  typeset -g targetResourcesDir="${targetDir}/resources/vivaldi"
  if [ ! -e "${targetResourcesDir}/jdhooks.js" ] ||
    ! cmp -s vivaldi/jdhooks.js "${targetResourcesDir}/jdhooks.js"; then
    # Install VivaldiHooks files
    echo "Copying VivaldiHooks files from $(pwd)/vivaldi to ${targetDir}"
    [ -d "${targetResourcesDir}/hooks" ] && rm -rf "${targetResourcesDir}"/hooks
    install -Dt "${targetResourcesDir}" ./vivaldi/jdhooks.js
    install -Dt "${targetResourcesDir}"/hooks ./vivaldi/hooks/*

    # Patch browser.html, if needed
    if ! grep -q "jdhooks.js" "${targetResourcesDir}/browser.html"; then
      echo "Patching browser.html"
      sed -i -e '/src="bundle.js"/i \ \ \ \ <script src="jdhooks.js"></script>' \
        "${targetResourcesDir}/browser.html"
    fi

    echo -e '\nVivaldiHooks installed successfully!'
  else
    echo -e '\nThis Vivaldi installation already has the latest VivaldiHooks.'
  fi
}

checkDependencies
checkRoot
checkVivaldiInstalled
selectVivaldiInstallation
installVivaldiHooks
