cmake_minimum_required(VERSION 3.22.1)
project(citecoach_llm)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================
# llama.cpp Configuration
# ============================================================
#
# SETUP: Clone llama.cpp into this directory:
#   cd android/app/src/main/cpp
#   git clone https://github.com/ggerganov/llama.cpp.git
#
# Or download a specific release tag for stability:
#   git clone --branch b4000 --depth 1 https://github.com/ggerganov/llama.cpp.git
#
# ============================================================

# llama.cpp build options for Android
set(LLAMA_NATIVE OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)

# Enable NEON for ARM (most Android devices)
if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
    set(GGML_NEON ON CACHE BOOL "" FORCE)
endif()

# Add llama.cpp as a subdirectory
add_subdirectory(llama.cpp)

# ============================================================
# JNI Bridge Library
# ============================================================

add_library(citecoach_llm SHARED
    llm_bridge.cpp
)

target_include_directories(citecoach_llm PRIVATE
    llama.cpp/include
    llama.cpp/ggml/include
    llama.cpp/common
)

target_link_libraries(citecoach_llm
    llama
    common
    log
)
