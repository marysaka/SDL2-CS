#!/bin/bash

set -e

if [ "$#" -le 2 ]; then
    echo "usage: <sdl_dir> <output_path> <build_arch>"
    exit 1
fi

uname_system="$(uname -s)"

case "${uname_system}" in
    Linux*)     system_name=linux;;
    Darwin*)    system_name=macos;;
    CYGWIN*)    system_name=win;;
    MINGW*)     system_name=win;;
    *)          system_name="Unknown OS: ${uname_system}"
esac

sdl_dir=$1
output_path=$2
build_arch=$3

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

mkdir -p $output_path

if [ $system_name == "linux" ] && [ $build_arch == "arm64" ]; then
    if command -v podman &> /dev/null; then
        DOCKER=podman
    elif command -v docker &> /dev/null; then
        DOCKER=docker
    else
        echo "ERROR - Missing docker/podman env, cannot crossbuild"
        exit 1
    fi

    $DOCKER run --rm -v $SCRIPT_DIR:/scripts -v $output_path:/output -v $sdl_dir:/source -t arm64v8/ubuntu:focal bash /scripts/compile.sh /source /output $build_arch
else
    $SCRIPT_DIR/compile.sh "$sdl_dir" "$output_path" "$build_arch"
fi