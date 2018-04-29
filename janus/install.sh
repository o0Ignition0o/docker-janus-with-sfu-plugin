#!/usr/bin/env bash

# Helper script for the lazy and not picky. Compiles, installs, and runs Janus, its dependencies,
# and the latest version of this plugin. Should be compatible with Ubuntu >= 16.04.
#
# Janus will be installed into /opt/janus.

set -e

banner () {
    msg=$1
    echo ''
    echo '####################################################'
    echo "    $msg"
    echo '####################################################'
    echo ''
}

banner 'installing script dependencies'
if [[ ! -e $(which python) || ! -e $(which curl) ]]; then
     apt update
     apt -y install python curl || true
fi

if [[ ! -e $(which pip) ]]; then
    curl https://bootstrap.pypa.io/get-pip.py -sSf > get-pip.py
     python get-pip.py
    rm get-pip.py
fi

if [[ ! -e $(which docopts) ]]; then
     pip install docopts
fi

if [[ ! -e $(which twistd) ]]; then
     apt install -y python-dev build-essential
     pip install pyopenssl twisted
fi

eval "$(
docopts -h - : "$@" <<EOF
Usage: ./setup-and-run-social-mr-janus-server.sh [--force-rebuild] [--working-directory <dir>]

    -f --force-rebuild               Forcefully rebuild dependencies
    -d --working-directory <dir>     Directory to work under [default: ./build]
EOF
)"

force_rebuild=$([[ $force_rebuild == "true" ]] && echo "true") || true

script_directory=$(dirname "$0")
script_directory=$(realpath "$script_directory")
working_directory=$(realpath "$working_directory")
mkdir -p "$working_directory"
cd "$working_directory"

git-get () {
    repo=$1
    version=$2
    if [ ! -e $repo ]; then
        git clone https://github.com/$repo $repo
    fi
    pushd $repo
    git fetch
    git checkout $version
    git reset --hard $version
    git clean -ffdx
    popd
}

if [[ $force_rebuild || ! -e /opt/janus/bin/janus ]]; then
    banner 'getting janus source'
    git-get meetecho/janus-gateway master

     apt update

    banner 'installing janus compilation dependencies'
     apt -y install dh-autoreconf pkg-config cmake

    banner 'installing janus dependencies'
     apt -y install libglib2.0-dev libjansson-dev libnice-dev libssl-dev gengetopt libmicrohttpd-dev

    if [[ $force_rebuild || ! -e /usr/lib/libsrtp.so ]]; then
        git-get cisco/libsrtp v2.1.0
        pushd cisco/libsrtp
        ./configure --prefix=/usr --enable-openssl
        make shared_library &&  make install
        popd
    fi

    if [[ $force_rebuild || ! -e /usr/lib/libusrsctp.so ]]; then
        git-get sctplab/usrsctp 2d26613
        pushd sctplab/usrsctp
        ./bootstrap
        ./configure --prefix=/usr && make &&  make install
        popd
    fi

    if [[ $force_rebuild || ! -e /usr/lib/libwebsockets.so ]]; then
        git-get warmcat/libwebsockets v2.4.2
        pushd warmcat/libwebsockets
        mkdir build
        pushd build
        # see https://github.com/meetecho/janus-gateway/issues/732 re: LWS_MAX_SMP
        cmake -DLWS_MAX_SMP=1 -DLWS_WITHOUT_TESTAPPS=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" ..
        make &&  make install
        popd
        popd
    fi

    banner 'building and installing janus'
    pushd meetecho/janus-gateway
    sh autogen.sh
    ./configure --prefix=/opt/janus --disable-all-plugins --disable-all-handlers
    make
     make install
     make configs
    popd
fi

if [[ $force_rebuild || ! -e /opt/janus/lib/janus/plugins/libjanus_plugin_sfu.so ]]; then
    banner 'installing latest rust'
    curl https://sh.rustup.rs -sSf > rustup.sh
    sh rustup.sh -y
    . ~/.cargo/env
    rm rustup.sh

    banner 'getting, building and installing janus-plugin-sfu'
    git-get mquander/janus-plugin-sfu master
    pushd mquander/janus-plugin-sfu
    cargo build --release
     mkdir -p /opt/janus/lib/janus/plugins
     cp target/release/libjanus_plugin_sfu.so /opt/janus/lib/janus/plugins/
    popd
fi

if [ "$(awk '/\[nat\]/,/^stun/' /opt/janus/etc/janus/janus.cfg | wc -l)" -gt "2" ]; then
     sed 's/\[nat\]/\0\nstun_server = stun2.l.google.com\nstun_port = 19302/' -i /opt/janus/etc/janus/janus.cfg
fi

if [ "$(awk '/\[plugins\]/,/^disable/' /opt/janus/etc/janus/janus.cfg | wc -l)" -gt "2" ]; then
     sed 's/\[plugins\]/\0\ndisable = '\
'libjanus_voicemail.so,libjanus_echotest.so,libjanus_recordplay.so,libjanus_streaming.so,'\
'libjanus_textroom.so,libjanus_videocall.so,libjanus_videoroom.so/' -i /opt/janus/etc/janus/janus.cfg
fi

 sed 's/wss = no/wss = yes/' -i /opt/janus/etc/janus/janus.transport.websockets.cfg
 sed 's/;wss_port/wss_port/' -i /opt/janus/etc/janus/janus.transport.websockets.cfg
