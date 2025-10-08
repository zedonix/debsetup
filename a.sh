#!/usr/bin/env bash
# ananicy-cpp
apt update
apt install -y build-essential clang cmake ninja-build git pkg-config \
  libbpf-dev libelf-dev libfmt-dev libspdlog-dev nlohmann-json3-dev \
  libsystemd-dev zlib1g-dev
git clone https://gitlab.com/ananicy-cpp/ananicy-cpp.git
cd ananicy-cpp || exit
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target ananicy-cpp
cmake --install build --component Runtime
systemctl enable ananicy-cpp
