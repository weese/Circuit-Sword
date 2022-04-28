# Cross-build a new SD image in 6min

## Circuit-Sword

You can build your own SD image of Retropie for the Circuit Sword on your local machine (tested on Mac OS) using [Docker Desktop](https://www.docker.com/get-started/).
After installing Docker, you should tune it a bit to speed up the build process:

 - increase resources to e.g. 8 CPUs
 - enable Experimental Features -> Enable VirtuoFS accelerated directory sharing

Then create the requried docker images with:

```
cd cross-build
make docker-build
```

and after that build the images with

```
make all
```

The final image will be written into the folder `cross-build/images` and is has a filename that includes a recent UTC date
`retropie-buster-4.8-rpi2_3_zero2w_stable_CSO_CM3_2022xxxx-xxxxxx.img`. Simply burn that image to a microSD card using [balenaEtcher](https://www.balena.io/etcher/) and boot.

## Super-AIO

To build for the Kiteretro Super-AIO board, add `BOARD=saio` to all your make commands:

```
cd cross-build
make BOARD=saio docker-build all
```
