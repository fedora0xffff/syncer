#!/bin/bash

# PROJECT: <name> used for display
export PROJECT_NAME=""
# the builder creds
export BUILDER_REMOTE_USER="user" #builder
#remote host ip
export BUILDER_REMOTE_HOST=""
#path to the pass file used by the sshpass
export BUILDER_PASS_FILE=""

# the sandbox creds
export SANDBOX_REMOTE_USER""
export SANDBOX_REMOTE_HOST=""
export SANDBOX_PASS_FILE=""

# branches 
export CURR_BRANCH="master"
export MASTER_BRANCH="master"

# path to the project on the builder 
export BUILDER_PROJECT_DIR="" 
# path to the project locally
export LOCAL_PROJECT_DIR=""
# path to the project on the sandbox
export SANDBOX_PROJECT_DIR=""
# the directory name, where the binary tree appears
export BINARY_TREE="" 
# paths not to sync, ever 
# TODO: use filters
export EXCLUDE_PATH="" 


reset_remote_and_sync() {
    ./update.sh upd-curr-no-stash
    ./sync.sh sync
}

update_from_local() {
    ./syncer_engine/sync.sh sync
}

update_sandbox() {
    ./syncer_engine/sync.sh 
}

load_from_remote() {
    ./syncer_engine/sync.sh sync 1
}

update_remote_and_sync() {
    ./syncer_engine/update.sh upd-curr
    ./syncer_engine/sync.sh sync
}

# !!! make sure to have set the correct @CURR_BRANCH above
sync_remote_branch() {
    ./syncer_engine/update.sh checkout-current
}

diff() {
    ./syncer_engine/sync.sh diff
}

do_build_test_iteration() {
    update_from_local
    ./syncer_engine/build.sh debug
    load_from_remote
    ./syncer_engine/sync.sh get-index-and-sync
    ./syncer_engine/deploy.sh 
}

# 1 - set managing scripts to remotes
# 2 - make sure the local and the builder are both on the same page (TODO: src branch sync)
# 3 - make changes locally
# 4 - sync changes to the builder && build
# 5 - dowloand the binaries
# 6 - upload the binaries to the sandbox && deploy

# or for 4,5,6 use a single command - iterate 

case $1 in #TODO: separate bldr and sb -- snapshots
set-scripts-builder)
    ./syncer_engine/sync.sh send-files-builder "$(realpath scripts_for_infrastructure/ztn-builder_do.sh)"
    ;;
set-scripts-sbx)
    ./syncer_engine/sync.sh send-files-sandbox "$(realpath scripts_for_infrastructure/ztn-sandbox_deploy.sh)"
    ;;
set-all)
    ./syncer_engine/sync.sh send-files-sandbox "$(realpath scripts_for_infrastructure/ztn-sandbox_deploy.sh)"
    ./syncer_engine/sync.sh send-files-builder "$(realpath scripts_for_infrastructure/ztn-builder_do.sh)"
    ;;
# TODO: combine the commands into batches, e.g., sync-build - upload local changes && build
set-branch)
    # scenario: after creating a new branch locally, update the builder and check it out to the same branch
    # this must take the new branch's name
    actions/update.sh 
    ;;
download)
    load_from_remote
    ;;
upload)
    update_from_local
    ;;
diff)
    diff
    ;;
build)
    update_from_local
    ./syncer_engine/build.sh debug
    load_from_remote
    ;;
update-sandbox)
    ./syncer_engine/sync.sh get-index-and-sync
    #./syncer_engine/deploy.sh 
    ;;
iterate)
    do_build_test_iteration
    ;;
send-package)
    ./syncer_engine/sync.sh send-files-sandbox "$PROJECT_DIR_LOCAL/build/build/deb/*.deb"
    ;;
*) 
echo '
    Options:
    set-remote-scripts      install remote scripts to sb and bldr 
    download                just load remote changes
    upload                  just upload local changes
    diff                    show diffs
    build                   build the debug version and download
    update-sandbox          sync buns to sandbox and deploy
'
    ;;
esac

