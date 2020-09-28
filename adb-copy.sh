#!/usr/bin/env bash

# Author: Ish West https://github.com/optimistiCli
# License: MIT

usage () {
cat <<EOU
Usage:
  ${0##*/} <src1> [<src2> ...] [<s/n>|<name>|<maker>:]<dest dir>

  Transfers files and directorries from macOs to Android via adb over USB.

  Requres Android SDK Platform Tools. The adb executable must be on the \$PATH.
  https://developer.android.com/studio/releases/platform-tools#downloads
  https://www.xda-developers.com/install-adb-windows-macos-linux/

Examples:
  ${0##*/} ~/Desktop/document.pdf /scdard/Download
    Copies the PDF file from compute\'s desktop to phone\'s downloads 
    directory. This command will fail if more then one Android device is 
    connected.

  ${0##*/} /Volumes/ThumbDrive/Video/*.mkv Xiaomi:/sdcard/Movies
    Transfers all matroska files from Video dir on a thumb drive to the Movies
    dir on a Xiaomi phone.

  ${0##*/} Pictures/family.jpg Movies/pets.mp4 Redmi:/sdcard/temp
    Copies 2 files from computer to a custom dir on the phone named "Redmi".
    The custom dir will NOT be created so must already exist. The device name
    is set in Settings -> About phone -> Device name

  ${0##*/} /tmp/vivaldi-searches-backup-readable.json abcdabcd:/sdcard/temp
    Copies a file to a custom dir on the phone with serial number "abcdabcd".
    To check the device s/n run:
      adb devices -l
EOU
} 

brag_and_exit () {
	if [ -n "$1" ] ; then
		ERR_MESSAGE="$1"
	else
		ERR_MESSAGE='Something went terribly wrong'
	fi

	echo "Error: $ERR_MESSAGE"$'\n' >&2
    usage >&2

	exit 1
}

if ! which adb >/dev/null 2>/dev/null ; then
    brag_and_exit 'adb is not on the $PATH'
fi

if [ "$#" -lt 2 ] ; then
    brag_and_exit 'no source and/or destination provided'
fi

D="${@:$#}"
if [ "${D%:*}" == "$D" ] ; then
    DEST_DEV=''
    DEST_PATH="$D"
else
    DEST_DEV="${D%:*}"
    DEST_PATH="${D##*:}"
fi

FOUND_SERIAL=''
FOUND_NAME=''
MULTIPLE_FINDS=''
for SERIAL in "$(adb devices | grep '\t' | sed $'s/\t.*//')" ; do
    DEV_NAME="$(adb -s "$SERIAL" shell 'getprop persist.sys.device_name')"
    DEV_MAKE="$(adb -s "$SERIAL" shell 'getprop ro.product.brand')"

    echo -n "$DEV_MAKE device named $DEV_NAME s/n $SERIAL" >&2

    if [ -z "$DEST_DEV" -o "$DEST_DEV" == "$SERIAL" -o "$DEST_DEV" == "$DEV_NAME" -o "$DEST_DEV" == "$DEV_MAKE" ] ; then
        if [ -n "$FOUND_SERIAL" ] ; then
            MULTIPLE_FINDS='YES'
        fi
        FOUND_SERIAL="$SERIAL"
        FOUND_NAME="$DEV_NAME"
        echo ' fits the bill' >&2
    else
        echo ' -' >&2
    fi
done

if [ -z "$FOUND_SERIAL" ] ; then
    brag_and_exit 'no fitting devices found'
fi

if [ -n "$MULTIPLE_FINDS" ] ; then
    brag_and_exit 'multiple fitting devices found'
fi

DISPLAY_DEV="${DEST_DEV:-$FOUND_NAME}"

if adb -s "$FOUND_SERIAL" shell -x 'ls' >/dev/null 2>/dev/null ; then
    echo "The $DISPLAY_DEV device is connected" >&2

    T="$(adb shell "
        if [ -d '$DEST_PATH' -a -w '$DEST_PATH' ] ; then 
            echo YES
        else
            echo NO
        fi
    ")"
    if [ "$T" == 'YES' ] ; then
        echo "Destintation path $DEST_PATH is Ok" >&2
    else
        brag_and_exit 'destination is not a writable directory'
    fi

    NUM=1
    export COPYFILE_DISABLE=1
    while [ $NUM -lt $# ] ; do
        SRC="${!NUM}"
        if ! [ -e "$SRC" -a -r "$SRC" ] ; then
            brag_and_exit "source \"$SRC\" is inaccessible"
        fi
        echo "• $SRC" >&2
        SRC_DIR="$(dirname "$SRC")"
        SRC_NAME="$(basename "$SRC")"
        tar czf - -C "$SRC_DIR" "$SRC_NAME" | adb shell "tar xzf - -C '$DEST_PATH/'"
        NUM=$(( $NUM + 1 ))
    done
else
    brag_and_exit "the $DISPLAY_DEV device is offline"
fi
