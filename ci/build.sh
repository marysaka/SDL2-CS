#!/bin/bash

set -e

if [ "$#" -le 1 ]; then
    echo "usage: <sdl_dir> <output_path> [build_arch]"
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

export DEBIAN_FRONTEND=noninteractive

sdl_dir=$1
output_path=$2
build_arch=$3

mkdir -p $output_path

if [ -z "$3" ]; then
    if [ $system_name == "linux" ]; then
        build_arch=$(dpkg --print-architecture)
    else
        echo "ERROR - build_arch parameter needed on macOS and Windows"
        exit 1
    fi
fi

if command -v sudo &> /dev/null
then
    SUDO=sudo
fi

if [[ $system_name == "linux" ]]; then
    if [[ $build_arch == "i386" ]]; then
        sudo dpkg --add-architecture i386

        export CFLAGS=-m32
        export CXXFLAGS=-m32
    fi

    $SUDO apt-get update -y
    $SUDO apt-get install -y \
            build-essential \
            cmake \
            ninja-build \
            wayland-scanner++ \
            wayland-protocols \
            pkg-config:$build_arch \
            libasound2-dev:$build_arch \
            libdbus-1-dev:$build_arch \
            libegl1-mesa-dev:$build_arch \
            libgl1-mesa-dev:$build_arch \
            libgles2-mesa-dev:$build_arch \
            libglu1-mesa-dev:$build_arch \
            libibus-1.0-dev:$build_arch \
            libpulse-dev:$build_arch \
            libsdl2-2.0-0:$build_arch \
            libsndio-dev:$build_arch \
            libudev-dev:$build_arch \
            libwayland-dev:$build_arch \
            libx11-dev:$build_arch \
            libxcursor-dev:$build_arch \
            libxext-dev:$build_arch \
            libxi-dev:$build_arch \
            libxinerama-dev:$build_arch \
            libxkbcommon-dev:$build_arch \
            libxrandr-dev:$build_arch \
            libxss-dev:$build_arch \
            libxt-dev:$build_arch \
            libxv-dev:$build_arch \
            libxxf86vm-dev:$build_arch \
            libdrm-dev:$build_arch \
            libgbm-dev:$build_arch \
            libpulse-dev:$build_arch \
            libhidapi-dev:$build_arch \
            libwayland-client++0:$build_arch \
            libwayland-cursor++0:$build_arch

    extra_cmake_flags="-GNinja"
elif [[ $system_name == "macos" ]]; then
    extra_cmake_flags="-DCMAKE_OSX_ARCHITECTURES=\"$build_arch\" -DCMAKE_OSX_DEPLOYMENT_TARGET=\"11.0\""
elif [[ $system_name == "win" ]]; then
    extra_cmake_flags="-A $build_arch"
fi

pushd $sdl_dir
cmake -B build -DCMAKE_BUILD_TYPE=Release -DSDL_SHARED_ENABLED_BY_DEFAULT=ON -DSDL_STATIC_ENABLED_BY_DEFAULT=ON $extra_cmake_flags
cmake --build build/ --config Release
$SUDO cmake --install build/ --prefix install_output --config Release

if [[ $system_name == "linux" ]]; then
    cp install_output/lib/libSDL2-2.0.so.0 $output_path/libSDL2.so
elif [[ $system_name == "macos" ]]; then
    cp install_output/lib/libSDL2-2.0.dylib $output_path/libSDL2.dylib
elif [[ $system_name == "win" ]]; then
    cp install_output/bin/SDL2.dll $output_path/SDL2.dll
fi
popd
