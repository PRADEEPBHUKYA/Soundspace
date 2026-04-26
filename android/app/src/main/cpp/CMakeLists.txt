cmake_minimum_required(VERSION 3.22.1)
project("soundspace" VERSION 1.0.0)
set(CMAKE_CXX_STANDARD 17)

find_package(oboe REQUIRED CONFIG)

add_library(soundspace SHARED SpatialDspEngine.cpp)
target_compile_options(soundspace PRIVATE -O3 -ffast-math)
target_link_libraries(soundspace oboe::oboe log android)
