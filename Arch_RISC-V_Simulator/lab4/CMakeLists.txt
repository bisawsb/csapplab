cmake_minimum_required(VERSION 3.16)
project(lab4_new)

set(CMAKE_CXX_STANDARD 17)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")

set(X86_FILES Yuv420pFrame_x86.cpp)
set(MMX_FILES Yuv420pFrame_mmx.cpp)
set(SSE_FILES Yuv420pFrame_sse.cpp)
set(AVX_FILES Yuv420pFrame_avx.cpp Rgb888.cpp)

#set_source_files_properties(${X86_FILES} PROPERTIES COMPILE_FLAGS "-mno-mmx -mno-sse -mno-avx")
#set_source_files_properties(${MMX_FILES} PROPERTIES COMPILE_FLAGS "-mmmx -mno-sse -mno-avx")
#set_source_files_properties(${SSE_FILES} PROPERTIES COMPILE_FLAGS "-mmmx -msse4.2 -mno-avx")
#set_source_files_properties(${AVX_FILES} PROPERTIES COMPILE_FLAGS "-march=native")

add_executable(lab4_new main.cpp Yuv420pFrame.cpp Yuv420pFrame.h Rgb888.cpp Rgb888.h ExecutePolicy.h Yuv420pVideo.cpp Yuv420pVideo.h utils.h MapMacro.h debug.h Yuv420pFrame_x86.cpp Yuv420pFrame_mmx.cpp Yuv420pFrame_sse.cpp Yuv420pFrame_avx.cpp Rgb888_avx.cpp Rgb888_mmx.cpp Rgb888_sse.cpp Rgb888_x86.cpp)
