# adb-copy

Transfers files and directorries from macOs to Android via adb over USB.

## Usage
`adb-copy.sh <src1> [<src2> ...] [<s/n>|<name>|<maker>:]<dest dir>`

## Requirements
Requres Android SDK Platform Tools. The adb executable must be on the $PATH.

https://developer.android.com/studio/releases/platform-tools#downloads

https://www.xda-developers.com/install-adb-windows-macos-linux/

## Examples
`adb-copy.sh ~/Desktop/document.pdf /scdard/Download`

Copies the PDF file from compute\'s desktop to phone\'s downloads 
directory. This command will fail if more then one Android device is 
connected.

`adb-copy.sh /Volumes/ThumbDrive/Video/*.mkv Xiaomi:/sdcard/Movies`

Transfers all matroska files from Video dir on a thumb drive to the Movies
dir on a Xiaomi phone.

`adb-copy.sh Pictures/family.jpg Movies/pets.mp4 Redmi:/sdcard/temp`

Copies 2 files from computer to a custom dir on the phone named "Redmi".
The custom dir will NOT be created so must already exist. The device name
is set in Settings -> About phone -> Device name

`adb-copy.sh /tmp/vivaldi-searches-backup-readable.json abcdabcd:/sdcard/temp`

Copies a file to a custom dir on the phone with serial number "abcdabcd".
To check the device s/n run:
`adb devices -l`
