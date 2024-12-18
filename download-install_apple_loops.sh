#!/bin/sh

###################
# download-install_apple_loops.sh - script to download and install all available Apple loops for the specified plist
# Shannon Pasto https://github.com/shannonpasto/AppleLoops
#
# v1.1 (18/12/2024)
###################

## uncomment the next line to output debugging to stdout
#set -x

###############################################################################
## variable declarations
# shellcheck disable=SC2034
ME=$(basename "$0")
# shellcheck disable=SC2034
BINPATH=$(dirname "$0")
appPlist=""  # garageband1047 logicpro1110 mainstage362
jqBin=$(whereis -qb jq)

###############################################################################
## function declarations

exit_trap() {

  # clean up
  /bin/rm -rf "${tmpDir}"
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
elif [ "${4}" = "" ] && [ "${appPlist}" = "" ]; then
  /bin/echo "Required parameter 4 not set. Exiting"
  exit 1
fi

tmpDir="/tmp/${appPlist}"
/bin/mkdir "${tmpDir}"

# see if we have a caching server on the network. pick the first one
cacheSrvrURL=$(/usr/bin/AssetCacheLocatorUtil -j 2>/dev/null | "${jqBin}" -r '.results.reachability[]' | /usr/bin/head -n 1)
if [ "${cacheSrvrURL}" ]; then
  /bin/echo "Cache server located. Testing"
  /usr/bin/curl --telnet-option 'BOGUS=1' --connect-timeout 2 -s telnet://"${cacheSrvrURL}"
  if [ $? = 48 ]; then
    /bin/echo "Cache server reachable"
    baseURL="http://${cacheSrvrURL}/lp10_ms3_content_2016"
    baseURLOpt="?source=audiocontentdownload.apple.com&sourceScheme=https"
  fi
else
  /bin/echo "Cache Server not found or not reachable"
  baseURL="https://audiocontentdownload.apple.com/lp10_ms3_content_2016"
fi

/bin/echo "Base URL is ${baseURL}"

# take a double shot espresso
/usr/bin/caffeinate -ims &
cafPID=$(pgrep caffeinate)

# get the plist file
/bin/echo "getting the main plist for ${appPlist}"
/usr/bin/curl -s "${baseURL}/${appPlist}.plist${baseURLOpt}" -o "${tmpDir}/${appPlist}".plist

if ! /usr/bin/plutil "${tmpDir}/${appPlist}".plist >/dev/null 2>&1; then
  /bin/echo "Invalid plist file. Exiting"
  exit 1
fi

# loop through all the pkg files and download/install
for thePKG in $(/usr/bin/defaults read "${tmpDir}/${appPlist}".plist Packages | /usr/bin/grep DownloadName | /usr/bin/awk -F \" '{print $2}'); do
  thePKGFile=$(/bin/echo "${thePKG}" | /usr/bin/sed 's/..\/lp10_ms3_content_2013\///')
  if ! /usr/sbin/pkgutil --pkgs | /usr/bin/grep "$(basename "${thePKGFile}" .pkg)"; then
    /bin/echo "Installing ${thePKGFile}"
    /usr/bin/curl -s "${baseURL}/${thePKG}${baseURLOpt}" -o "${tmpDir}/${thePKGFile}"
    /usr/sbin/installer -pkg "${tmpDir}/${thePKGFile}" -target /
  else
    /bin/echo "${thePKGFile} already installed"
  fi
done

exit 0
