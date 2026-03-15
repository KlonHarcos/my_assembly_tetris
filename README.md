# TETRISSEMBLY

this project was developed for linux terminal therefore a WSL or linux is required (probably no MACOS)

## CONTROLS:
- left arrow: move tile to the left
- right arrow: move tile to the right
- up_arrow: rotate tiles
- down_arrow: speed up fall
- C: store tile /& swap

## FEATURES:
- constantly increasing speed
- multiplied scoring 
- high score system (non savable)
- coyote timer

## INSTALL AND RUN:
run the ./run.sh command


if that doesnt work try the following:

run these commands in order:
    1. export CC=clang; cmake -B .build
    2. cmake --build .build --target tetris

you can then run the program by running:
    ./tetris



