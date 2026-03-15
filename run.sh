#!/bin/bash

export CC=clang; cmake -B .build
cmake --build .build --target tetris

./tetris
