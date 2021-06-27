# Window capture for macOS

Resize a window and take a screen capture of it.

## Synopsis

```sh
windowcapture [options] [size]
```

## Description

The front window of an application is raised and screen captured into
a PNG image file or to the clipboard.

The window can be resized before the capture. Either:

- the width is set, and the height left unchanged;
- the height is set, and the width is left unchanged;
- both the width and height are set; or
- the dimensions of the window are left unchanged.

### Options

`-a | --application`
: the name of the application whose window will be captured.
Defaults to Safari. The application name is not case sensitive.

`-d | --delay SECONDS`
: number of seconds delay between raising and resizeing the window and
when the capture is taken. Useful for interacting with pop-up menus
and other on-screen items so they are included in the capture.

`-s | --shadow`
: include the shadow behind the window in the capture. The image
in the PNG file will be larger than the dimensions of the window.
By default, the shadow is not included and only the window is captured.

`-c | --center`
: move the window to the center of the screen. This has no effect
on the capture, but can make it more obvious which window is being
captured.

`-o | --output FILENAME`
: the name of the file the capture will be written to. Specify "-"
as the filename to capture to the clipboard instead of to a file.

`-f | --force`
: overwrite the output file, if it already exists. Normally, the
capture will not proceed if the output file already exists.

`-v | --verbose`
: output extra information when running.

`--version`
: display version information and exits.

`-h | --help`
: display a short help message and exits.

### Arguments

`size`
: resize the window to the specified size. This can be specified as:
the width only (e.g. 960x) to leave the height unchanged; the height
only (e.g. x500) to leave the width unchanged; both width and height
(e.g. 1920x1080); or omitted to not change the size of the window at
all.

## Examples

Capture the front-most Safari window, without changing its size.
The capture is saved as a PNG file in the _Desktop_ folder.

```sh
./windowcapture.sh
```

Capture the front-most Safari window, without changing its size.
The capture is saved to the clipboard.

```sh
./windowcapture.sh -o -
```

Resize the front-most Safari window to a width of 960 pixels (leaving
its height unchanged) and then capture it.

```sh
./windowcapture.sh 960x
```

Resize the front-most FireFox window to 800x600 pixels and then
capture it to a file called "foobar.png" in the current directory.

```sh
./windowcapture.sh --application firefox  --output foobar.png 800x600
```

Tip: if the the application name is not known, it can be obtained by
using the _Activity Monitor_ application.

## Requirements

This is a command line program that only works on an Apple Macintosh,
since it is a wrapper for the macOS _screencapture_ program and uses
AppleScript to resize the window.

This program has been tested on macOS 11.4 (Big Sur).

## Known issues

### Does not work with Google Chrome

Workaround: use the utility to resize the window, and then manually
capture the window: using ⌘-Shift-4, then press the space key and
select the window.

### Combining command line options does not work

Command line options cannot be combined together. For example, "-sf"
does not work and must be specified as "-s -f".

## Files

By default, the window captures are saved into the user's _Desktop_
folder with a name that starts with `windowcapture_` followed by the
date and time in ISO 8601 format. But the file name can be set
using the _output_ command line option.

## See also

- The man page for the _screencapture_ program on macOS.