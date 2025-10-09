#!/usr/bin/env bash
# neovim
sudo apt-get install ninja-build gettext cmake curl build-essential git
git clone https://github.com/neovim/neovim
cd neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo build
cd build
cpack -G DEB
sudo dpkg -i nvim-linux64.deb
