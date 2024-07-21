#!/bin/bash

# PROJECT: <name>
# the builder creds
export REMOTE_USER="user" #builder
export REMOTE_HOST=""
export PATH_TO_PASS=""

# the sandbox creds
export REMOTE_USER_SANDBOX="anast"
export REMOTE_SANDBOX=""
export PATH_TO_PASS_SANDBOX=""

# branches (not used currently) #TODO fix
export CURR_BRANCH="master"
export MASTER_BRANCH="master"

# path to the project on the builder 
export PROJECT_DIR_REMOTE="" 
# path to the project locally
export PROJECT_DIR_LOCAL=""
# path to the project on the sandbox
export PROJECT_DIR_SANDBOX=""
# the directory name, where the binary three appears
export BINARY_TREE="" 
# paths not to sync, ever
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

