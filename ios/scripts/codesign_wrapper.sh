#!/bin/sh
# Wrapper for codesign that adds --no-strict to bypass the
# "resource fork, Finder information, or similar detritus not allowed" error.

echo "[codesign_wrapper] Called with args: $@" >> /tmp/codesign_wrapper.log
echo "[codesign_wrapper] PATH=$PATH" >> /tmp/codesign_wrapper.log

# Call the real codesign with --no-strict injected
exec /usr/bin/codesign --no-strict "$@"
