#!/bin/bash
meson build --prefix=/usr
cd build
ninja
sudo ninja install
