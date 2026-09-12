#!/bin/sh

export LANG="${LANG:-C.UTF-8}"

# Keep the window manager as the X client.  Calamares is started by Openbox
# and may be closed/restarted without terminating the graphical session.
exec openbox-session
