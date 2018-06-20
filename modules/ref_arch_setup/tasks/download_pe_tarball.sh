#!/usr/bin/env bash

# Download PE Tarball:
# This is a script-based task as the target node may not have Ruby installed.
# Provide the URL and optionally an existing destination directory (the default is /tmp/ref_arch_setup).
# Run the task as per the following examples:
#
# Localhost with default destination -
# bolt task run ref_arch_setup::download_pe_tarball url=http://test.net/test.gz --modulepath ./modules --nodes localhost
#
# Remote node as root user with specified destination -
# bolt task run ref_arch_setup::download_pe_tarball url=http://test.net/test.gz destination=/tmp/ras --modulepath ./modules --nodes tjsss144r6ouvhc --user root

URL=$PT_url
DESTINATION=${PT_destination:-/tmp/ref_arch_setup}
FILENAME=$(basename $PT_url)
DESTINATION_PATH=$DESTINATION/$FILENAME

echo URL: $URL
echo Destination: $DESTINATION
echo Filename: $FILENAME
echo

if [[ $URL =~ https?://.*gz ]] ; then
  echo "URL is valid; proceeding"
else
  echo "Invalid URL (must be http or https with a .gz extension); exiting"
  exit 1
fi

if [ -d "$DESTINATION" ]; then
  echo "Destination exists; proceeding"
  echo Downloading $URL to $DESTINATION_PATH

  if curl -f -L -o $DESTINATION_PATH $URL ; then
    echo "Download complete"
    exit 0
  else
    echo "Download failed; exiting"
    exit 1
  fi

else
  echo "Destination directory does not exist; exiting"
  exit 1

fi

