#!/bin/bash

# path to the project locally
PROJECT_DIR_LOCAL="/home/user/repos/ztn-linux" 


build_bins() {
    make all
    make install #уточнить
}

build_package() {
    ./build.sh --directory=build --devel
}


cd $PROJECT_DIR_LOCAL

case "$1" in
bins)
    build_bins
    ;;
package)
    build_package
    ;;
*)
    echo "Unknown command"
    ;;
esac