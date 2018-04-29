## Docker janus with SFU plugin

This a dockerized version of Janus + the Janus SFU Plugin, which allowed me to use a local janus server for [Mozilla Hubs](https://github.com/mozilla/hubs)

# License
<p>
  <a href="LICENSE.md">
    <img
    src="https://img.shields.io/badge/license-MPL-green.svg" alt="MPL 2.0 License">
  </a>
</p>

This is basically a copy/paste/split of the amazing https://github.com/mozilla/janus-plugin-sfu/blob/master/scripts/setup-and-run-janus.sh written by @mquander

More information on the plugin can be found here : https://github.com/mozilla/janus-plugin-sfu

# Run with docker-compose : 
```
$ docker-compose up --build
// You can now reach the server on 
// ws://localhost:8188 or 
// wss://localhost:8989
```


# Run as a daemon with docker-compose :
```
$ docker-compose up -d
```


# Build and Run with docker : 
```
$ docker build janus/ -t janus-sfu-plugin
$ docker run janus-sfu-plugin -p 8989:8989 -p 8188:8188
```

# Dependencies :

In order to build and Run the container you need at least the CE edition of
[docker](https://docs.docker.com/install/)

In order to run the docker-compose script you need to install 
[docker-compose](https://docs.docker.com/compose/install/)

