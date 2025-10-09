#!/usr/bin/env bash
# neovim
git clone --depth 1 --branch stable https://github.com/neovim/neovim.git
cd neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
cpack -G DEB
sudo dpkg -i nvim-linux64.deb
