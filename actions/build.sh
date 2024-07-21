#!/bin/bash

#
# run a command on the remote @REMOTE_HOST as @REMOTE_USER
run_remote() {
    local command=$1
    echo Remote command is: $command
    [[ (( ! -f /usr/bin/sshpass) || ( -z $PATH_TO_PASS )) ]] && print_message "sshpass is missing or PATH_TO_PASS is not set" e && exit 1
    sshpass -f $PATH_TO_PASS ssh -t $REMOTE_USER@$REMOTE_HOST "${command}"
}

# build_release() {
#     run_remote "./ztn-builder_do.sh rel"
# }

build_debug() {
    run_remote "./ztn-builder_do.sh"
}

case "$1" in
debug)
    build_debug
    ;;
release)
    build_release
    ;;
*)
    echo Unknown config type
    ;;
esac