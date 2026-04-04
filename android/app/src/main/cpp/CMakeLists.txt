cmake_minimum_required(VERSION 3.18)
project(citecoach_llm)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Check if llama.cpp source exists
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/CMakeLists.txt")
    message(STATUS "llama.cpp found, building with LLM support")

    # llama.cpp build options for Android
    set(LLAMA_NATIVE OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
    set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
    set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)

    # Enable NEON for ARM64, disable FP16 for 32-bit ARM
    if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
        set(GGML_NEON ON CACHE BOOL "" FORCE)
    else()
        set(GGML_NEON OFF CACHE BOOL "" FORCE)
        set(GGML_FP16 OFF CACHE BOOL "" FORCE)
    endif()

    add_subdirectory(llama.cpp)

    add_library(citecoach_llm SHARED llm_bridge.cpp)

    target_include_directories(citecoach_llm PRIVATE
        llama.cpp/include
        llama.cpp/ggml/include
        llama.cpp/ggml/src
    )

    # Link against llama (ggml is bundled inside llama in latest versions)
    target_link_libraries(citecoach_llm
        llama
        log
    )

    target_compile_definitions(citecoach_llm PRIVATE LLAMA_AVAILABLE=1)

else()
    message(WARNING "llama.cpp NOT found, building stub library")

    # Build a stub that just returns errors
    add_library(citecoach_llm SHARED llm_stub.cpp)
    target_link_libraries(citecoach_llm log)
endif()
