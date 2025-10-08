#!/usr/bin/env bash
# ananicy-cpp
git clone https://gitlab.com/ananicy-cpp/ananicy-cpp.git
cd ananicy-cpp || exit
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target ananicy-cpp
cmake --install build --component Runtime

systemctl enable ananicy-cpp
