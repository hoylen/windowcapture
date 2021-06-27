#!/bin/sh
#
# Resize a window and take a screen capture of it.
#
# Uses the "screencapture" program to take a screen capture of the
# front window of a running application. Uses AppleScript to
# optionally resize the window before capturing it.
#
# Run with --help to see available options.
#
# Copyright (C) 2021, Hoylen Sue.
#================================================================

PROGRAM='windowcapture'
VERSION='1.0.0'

EXE=$(basename "$0" .sh)
EXE_EXT=$(basename "$0")

#----------------------------------------------------------------
# Constants

# Default window size
#
# DEFAULT_SIZE=x # no resize
# DEFAULT_SIZE=960x # resize width, keep height unchanged
# DEFAULT_SIZE=x500 # keep width unchanged, resize height
# DEFAULT_SIZE=1920x1080 # resize both width and height

DEFAULT_SIZE=x

# Default application
#
# Names can be found by looking at the "Activity Monitor" application.

DEFAULT_APP='Safari'

# Default output file

# Note: the extended form of the ISO 8601 time is not used, because
# colons do not work well in file names on macOS.

DEFAULT_OUTPUT="$HOME/Desktop/windowcapture_$(date +%FT%H%M%S).png"

# Seconds to delay (after activating the application and before the capture)

DEFAULT_DELAY=1

#----------------------------------------------------------------
# Error handling

# Exit immediately if a simple command exits with a non-zero status.
# Better to abort than to continue running when something went wrong.
set -e

#----------------------------------------------------------------
# Command line arguments
# Note: parsing combined single letter options (e.g. "-vh") not supported

SIZE=
APPLICATION="$DEFAULT_APP"
DELAY=$DEFAULT_DELAY
INCLUDE_SHADOW=
CENTER_WINDOW=
OUTPUT=$DEFAULT_OUTPUT
FORCE=
QUIET=
VERBOSE=
SHOW_VERSION=
SHOW_HELP=

while [ $# -gt 0 ]
do
  case "$1" in
    -o|--output)
      if [ $# -lt 2 ]; then
        echo "$EXE: usage error: $1 missing value" >&2
        exit 2
      fi
      OUTPUT="$2"
      shift; shift
      ;;
    -a|--app|--application)
      if [ $# -lt 2 ]; then
        echo "$EXE: usage error: $1 missing value" >&2
        exit 2
      fi
      APPLICATION="$2"
      shift; shift
      ;;
    -d|--delay)
      if [ $# -lt 2 ]; then
        echo "$EXE: usage error: $1 missing value" >&2
        exit 2
      fi
      DELAY="$2"
      shift; shift
      ;;
    -s|--shadow)
      INCLUDE_SHADOW=yes
      shift
      ;;
    -c|--center|--center-window)
      CENTER_WINDOW=yes
      shift
      ;;
    -f|--force)
      FORCE=yes
      shift
      ;;
    -q|--quiet)
      QUIET=yes
      shift
      ;;
    -v|--verbose)
      VERBOSE=yes
      shift
      ;;
    --version)
      SHOW_VERSION=yes
      shift
      ;;
    -h|--help)
      SHOW_HELP=yes
      shift
      ;;
    -*)
      echo "$EXE: usage error: unknown option: $1" >&2
      exit 2
      ;;
    *)
      # Argument
      if [ -n "$SIZE" ]; then
        echo "$EXE: usage error: too many arguments" >&2
        exit 2
      fi
      SIZE="$1"
      shift
      ;;
  esac
done

if [ -n "$SHOW_HELP" ]; then
  if [ "$DEFAULT_SIZE" = 'x' ]; then
    DEF_STR='no resize'
  else
    DEF_STR=$DEFAULT_SIZE
  fi
  
  cat <<EOF
Usage: $EXE_EXT [options] [size]
Options:
  -a | --app NAME     application for window (default: $DEFAULT_APP)
  -d | --delay SEC    seconds before capturing window (default: $DEFAULT_DELAY)
  -s | --shadow       include shadow around the window (default: not included)
  -c | --center       move the window to the center of the screen
  -o | --output FILE  file to save the PNG image to ("-" for clipboard)
  -f | --force        overwrite the output file if it exists
  -v | --verbose      output extra information when running
       --version      display version information and exit
  -h | --help         display this help and exit
size = resize to WIDTHxHEIGHT, e.g. 960x, x500, 1920x1080 (default: $DEF_STR)
EOF
  exit 0
fi

# Quiet has not effect yet
# -q | --quiet        no output unless there is an error

if [ -n "$SHOW_VERSION" ]; then
  echo "$PROGRAM $VERSION"
  exit 0
fi

#----------------

if [ -z "$SIZE" ]; then
  SIZE=$DEFAULT_SIZE
fi

if ! echo "$SIZE" | grep -qE '^[0-9]*x[0-9]*$' ;then
  echo "$EXE: usage error: bad size (expecting width x height): $SIZE" >&2
  exit 2
fi
WIDTH=$(echo $SIZE | sed -E s/x[0-9]*$//)
HEIGHT=$(echo $SIZE | sed -E s/^[0-9]*x//)

if [ -z "$WIDTH" ]; then
   WIDTH=0 # keep existing width
elif [ "$WIDTH" -lt 10 ]; then
  echo "$EXE: usage error: width is too small: $WIDTH" >&2
  exit 2
fi

if [ -z "$HEIGHT" ]; then
  HEIGHT=0 # keep existing height
elif [ "$HEIGHT" -lt 10 ]; then
  echo "$EXE: usage error: height is too small: $HEIGHT" >&2
  exit 2
fi

if ! echo "$DELAY" | grep -qE '^[0-9]+$' ;then
  echo "$EXE: usage error: bad delay (expecting +ve integer): $DELAY" >&2
  exit 2
fi

#----------------------------------------------------------------

if [ -e "$OUTPUT" ] && [ -z "$FORCE" ]; then
  echo "$EXE: error: file already exists (--force to overwrite): $OUTPUT" >&2
  exit 1
fi

#----------------------------------------------------------------

CENTER=false
if [ -n "$CENTER_WINDOW" ]; then
  CENTER=true
fi

# Build up command line options for the "screencapture" program

if [ "$OUTPUT" = '-' ]; then
  # Capture to the clipboard instead of to a file
  SC_OPTS='-c'
  OUT_MSG='<clipboard>'
else
  # Capture to a file
  SC_OPTS=
  OUT_MSG="$OUTPUT"
fi

SC_OPTS="$SC_OPTS -T $DELAY"

if [ -z "$INCLUDE_SHADOW" ]; then
  SC_OPTS="$SC_OPTS -o" # do not capture the shadow
fi

#----------------
# Run the "screencapture" program inside an AppleScript script

#cat <<EOF
osascript -l AppleScript <<EOF
(* Window capture *)

set _w to $WIDTH
set _h to $HEIGHT
set _center to $CENTER

(* Get screen dimensions *)

tell application "Finder"
    set screenRes to bounds of window of desktop
end tell

set _screenWidth to item 3 of screenRes
set _screenheight to item 4 of screenRes

(* Position window *)

tell application "$APPLICATION"
    activate

    (* Keep existing width or height of the window if their value is zero *)

    set _dim to bounds of the front window
    if _w = 0 then
      set _w to ((item 3 of _dim) - (item 1 of _dim))
    end if
    if _h = 0 then
      set _h to ((item 4 of _dim) - (item 2 of _dim))
    end if

    (* Keep existing top-left position or center the window on the screen *)

    if _center then
        set _top to (_screenHeight - _h) / 2 as integer
        set _left to (_screenWidth - _w) / 2 as integer
    else
        set _top to item 2 of _dim
        set _left to item 1 of _dim
    end if

    (* Position and resize the window *)

    set the bounds of the front window to {_left, _top, _left + _w, _top + _h}

    set _winId to id of front window
end tell

(* Capture the window with the "screencapture" program *)

do shell script "screencapture $SC_OPTS -l " & _winId & " \"$OUTPUT\""

return "$EXE: $OUT_MSG\n$EXE: window size: " & _w & "x" & _h & ""

EOF

#----------------

if [ -n "$VERBOSE" ]; then
  if [ -n "$INCLUDE_SHADOW" ]; then
    echo "$EXE: shadow included"
  fi
  echo "$EXE: application: $APPLICATION"
fi

#EOF
