#!/usr/bin/env bash

# The original file can be found here : https://github.com/mozilla/janus-plugin-sfu/blob/master/scripts/setup-and-run-janus.sh
banner () {
    msg=$1
    echo ''
    echo '####################################################'
    echo "    $msg"
    echo '####################################################'
    echo ''
}

script_directory=$(dirname "$0")
script_directory=$(realpath "$script_directory")
working_directory=$(realpath "$working_directory")

banner 'starting janus and web servers'
/opt/janus/bin/janus &
pushd "$script_directory/../client"
if [[ ! -e server.pem ]]; then
    banner 'generating ssl cert'
    openssl req -nodes -x509 -newkey rsa:2048 -keyout server.key -out server.pem -days 365 \
        -subj "/C=US/ST=CA/L=MTV/O=foo/OU=foo/CN=foo"
fi
twistd -no web --path . -c server.pem -k server.key --https=443 &
popd

trap "kill %1; kill %2; wait" SIGINT
sleep 1
banner 'press Ctrl+C to kill'
wait
