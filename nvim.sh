#!/usr/bin/env bash
# neovim
git clone --depth 1 --branch stable https://github.com/neovim/neovim.git
cd neovim
make CMAKE_BUILD_TYPE=RelWithDebInfo
cd build
cpack -G DEB
sudo dpkg -i nvim-linux64.deb
