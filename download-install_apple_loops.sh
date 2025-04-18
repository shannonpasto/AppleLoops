#!/bin/sh

###################
# download-install_apple_loops.sh - script to download and install all available Apple loops for the specified plist
# Shannon Pasto https://github.com/shannonpasto/AppleLoops
#
# v1.3.1 (18/04/2025)
###################

## uncomment the next line to output debugging to stdout
#set -x

###############################################################################
## variable declarations
# shellcheck disable=SC2034
ME=$(basename "$0")
# shellcheck disable=SC2034
BINPATH=$(dirname "$0")
appPlist=""  # garageband1047 logicpro1110 mainstage362. multiple plists can be specified, separate with a space

###############################################################################
## function declarations

exit_trap() {

  # clean up
  /bin/rm -rf "${tmpDir}" >/dev/null 2>&1
  /bin/kill "${cafPID}" >/dev/null 2>&1

}

###############################################################################
## start the script here
trap exit_trap EXIT

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO "appPlist"
if [ "${4}" != "" ] && [ "${appPlist}" = "" ]; then
  /bin/echo "Parameter 4 configured"
  appPlist="${4}"
elif [ "${4}" != "" ] || [ "${appPlist}" != "" ]; then
  /bin/echo "Parameter 4 overwritten by script variable"
fi

tmpDir=$(mkdir -d)

# see if we have a caching server on the network. pick the first one
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  /bin/echo "macOS Sequoia or later installed. Using jq to extract the data"
  cacheSrvrCount=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | /usr/bin/jq '.results.reachability | length')
  case "${cacheSrvrCount}" in
    ''|0)
      /bin/echo "No cache server(s) found"
      ;;

    1)
      /bin/echo "${cacheSrvrCount} server(s) found"
      cacheSrvrURL=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | /usr/bin/jq -r ".results.reachability[0]")
      ;;

    *)
      /bin/echo "${cacheSrvrCount} server found"
      cacheSrvrCount=$((cacheSrvrCount-1))
      cacheSrvrSelect=$(jot -r 1 0 "${cacheSrvrCount}")
      cacheSrvrURL=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | /usr/bin/jq -r ".results.reachability[${cacheSrvrSelect}]")
      ;;
  esac
else
  /bin/echo "macOS Sonoma or older installed. Using plutil to extract the data"
  cacheSrvrCount=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | /usr/bin/plutil -extract results.reachability raw -o - -)
  case "${cacheSrvrCount}" in
    ''|0)
      /bin/echo "No cache server(s) found"
      ;;

    1)
      /bin/echo "${cacheSrvrCount} server(s) found"
      cacheSrvrURL=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | /usr/bin/plutil -extract results.reachability.0 raw -o - -)
      ;;

    *)
      /bin/echo "${cacheSrvrCount} server(s) found"
      cacheSrvrCount=$((cacheSrvrCount-1))
      cacheSrvrSelect=$(jot -r 1 0 "${cacheSrvrCount}")
      cacheSrvrURL=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | /usr/bin/plutil -extract results.reachability."${cacheSrvrSelect}" raw -o - -)
      ;;
  esac
fi
if [ "${cacheSrvrURL}" ]; then
  /bin/echo "Cache server located. Testing"
  /usr/bin/curl --telnet-option 'BOGUS=1' --connect-timeout 2 -s telnet://"${cacheSrvrURL}"
  if [ $? = 48 ]; then
    /bin/echo "Cache server reachable"
    downloadURL="http://${cacheSrvrURL}/lp10_ms3_content_2016"
    baseURLOpt="?source=audiocontentdownload.apple.com&sourceScheme=https"
  fi
else
  /bin/echo "Cache Server not found or not reachable"
  downloadURL="https://audiocontentdownload.apple.com/lp10_ms3_content_2016"
fi

/bin/echo "Download URL is ${downloadURL}"

# take a double shot espresso
/usr/bin/caffeinate -ims &
cafPID=$(pgrep caffeinate)

if [ "${appPlist}" = "" ]; then
  /bin/echo "No plist configured as a parameter. Searching /Applications for any/all apps"
  plistNames="garageband logicpro mainstage"
  for X in $plistNames; do
    /usr/bin/find /Applications -name "${X}*.plist" -maxdepth 4 | /usr/bin/rev | /usr/bin/cut -d "/" -f 1 - | /usr/bin/rev | /usr/bin/cut -d "." -f 1 - >> "${tmpDir}/thelist.txt"
  done

  if [ ! -s "${tmpDir}/thelist.txt" ]; then
    /bin/echo "No valid application found. Exiting"
    exit 1
  else
    appPlist=$(/bin/cat "${tmpDir}/thelist.txt")
  fi
fi

for X in $appPlist; do
  # get the plist file
  /bin/echo "Fetching the Apple plist for ${X}"
  /usr/bin/curl -s "${downloadURL}/${X}.plist${baseURLOpt}" -o "${tmpDir}/${X}".plist

  if ! /usr/bin/plutil "${tmpDir}/${X}".plist >/dev/null 2>&1; then
    /bin/echo "Invalid plist file. Exiting"
    exit 1
  fi

  # loop through all the pkg files and download/install
  for thePKG in $(/usr/bin/defaults read "${tmpDir}/${X}".plist Packages | /usr/bin/grep DownloadName | /usr/bin/awk -F \" '{print $2}'); do
    thePKGFile=$(/bin/echo "${thePKG}" | /usr/bin/sed 's/..\/lp10_ms3_content_2013\///')
    if ! /usr/sbin/pkgutil --pkgs | /usr/bin/grep "$(basename "${thePKGFile}" .pkg)"; then
      /bin/echo "Installing ${thePKGFile}"
      /usr/bin/curl -s "${downloadURL}/${thePKG}${baseURLOpt}" -o "${tmpDir}/${thePKGFile}"
      /usr/sbin/installer -pkg "${tmpDir}/${thePKGFile}" -target /
    else
      /bin/echo "${thePKGFile} already installed"
    fi
  done
done

exit 0
