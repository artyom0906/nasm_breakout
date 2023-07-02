cmake_minimum_required(VERSION 3.16)
project(nasm_project C)
enable_language(ASM_NASM)
set(CMAKE_VERBOSE_MAKEFILE on)

# Find X11 library
find_package(X11 REQUIRED)

# Set include directories
include_directories(${X11_INCLUDE_DIR})

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
set(CMAKE_LINKER /usr/bin/ld)
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "<CMAKE_LINKER> <FLAGS> <OBJECTS> -o <TARGET> -lc -dynamic-linker /usr/lib64/ld-linux-x86-64.so.2")
set(CMAKE_ASM_NASM_LINK_FLAGS "<LINKER_FLAGS> ")
set(CMAKE_C_FLAGS -march=native)

add_executable(nasm_project src/main.asm)
target_link_libraries(nasm_project  ${X11_LIBRARIES})

add_executable(nasm_project1 src/main.c src/main.asm src/asm/x11.asm src/asm/graphics.asm src/asm/utils.asm src/asm/logic.asm src/asm/test.asm)
target_link_libraries(nasm_project1 ${X11_LIBRARIES})