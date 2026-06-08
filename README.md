# TETRISSEMBLY
terminal based tetris in assembly, using Ncurses

[![DEMO video](https://youtu.be/fO8L9FKxaGk/0.jpg)](https://youtu.be/fO8L9FKxaGk)



## REQUIREMENTS:
- some sort of linux terminal (the simpler the better, i only tested on wsl and standard linux mint)
- clang
    sudo apt install clang
- Ncurses 
    sudo apt-get install libncurses5-dev


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



