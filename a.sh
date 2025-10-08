# ananicy-cpp
git clone https://gitlab.com/ananicy-cpp/ananicy-cpp.git
cd ananicy-cpp
cmake -S . -B -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build --component Runtime
