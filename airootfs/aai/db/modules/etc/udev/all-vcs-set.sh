#!/bin/sh
# We must load locale for ${VCS} util
source /etc/locale.conf
export LANG
VCS=/usr/lib/systemd/systemd-vconsole-setup

# Setup the "real" (current) console first
${VCS}

# Setup all other active consoles
for VC in /dev/vcs[0-9]*
do
  ${VCS} /dev/tty${VC#/dev/vcs}
done
