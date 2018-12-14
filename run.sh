#!/bin/bash
set -e
set -x
export DEVPISERVER_SERVERDIR=/mnt
export DEVPI_CLIENTDIR=/tmp/devpi-client
[[ -f $DEVPISERVER_SERVERDIR/.serverversion ]] || initialize=yes

kill_devpi() {
    test -n "$DEVPI_PID" && kill $DEVPI_PID
}
trap kill_devpi EXIT

# For some reason, killing tail during EXIT trap function triggers an
# "uninitialized stack frame" bug in glibc, so kill tail when handling INT or
# TERM signal.
kill_tail() {
    test -n "$TAIL_PID" && kill $TAIL_PID
}
trap kill_tail INT
trap kill_tail TERM

# NOTE: The --init flag is required so that the first time the server
# runs with a given serverdir, necessary groundwork can be put in place.
# It is smart enough to do nothing if the serverdir is not empty.
devpi-server --start --init --host 0.0.0.0 --port 3141 || \
    { [ -f "$LOG_FILE" ] && cat "$LOG_FILE"; exit 1; }
DEVPI_PID="$(cat $DEVPISERVER_SERVERDIR/.xproc/devpi-server/xprocess.PID)"

if [[ $initialize = yes ]]; then
  devpi use http://localhost:3141
  devpi login root --password=''
  devpi user -m root password="${DEVPI_PASSWORD}"
  devpi index -y -c public pypi_whitelist='*'
fi
# We cannot simply execute tail, because otherwise bash won't propagate
# incoming TERM signals to tail and will hang indefinitely.  Instead, we wait
# on tail PID and then "wait" command will interrupt on TERM (or any other)
# signal and the script will proceed to kill_* functions which will gracefully
# terminate child processes.
tail -f /etc/fstab & #"$LOG_FILE" &
TAIL_PID=$!
wait $TAIL_PID
