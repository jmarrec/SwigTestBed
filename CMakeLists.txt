cmake_minimum_required(VERSION 3.17.5)

add_library(cpp_warning_options INTERFACE)
add_library(cpp_compile_options INTERFACE)

target_compile_features(cpp_compile_options INTERFACE cxx_std_20)

if(MSVC)
  target_compile_options(cpp_warning_options INTERFACE /W4 /Werror)
else()
  target_compile_options(cpp_compile_options INTERFACE -fPIC)

  target_compile_options(
    cpp_warning_options INTERFACE -Wall -Wextra -Wconversion -Werror -Wno-unused-variable -Wno-unused-parameter)
#  target_compile_options(cpp_compile_options
#                         INTERFACE -fsanitize=undefined,address)
#  target_link_options(cpp_compile_options INTERFACE
#                      -fsanitize=undefined,address)
endif()

# Do not enable compiler specific extensions, for eg on GCC use -std=c++1z
# (=c++17) and not -std=gnu++17
set(CMAKE_CXX_EXTENSIONS OFF)

# Use ccache is available, has to be before "project()"
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  # Support Unix Makefiles and Ninja
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

project(test_swig VERSION 0.0.1)

# Set a default build type if none was specified
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      Release
      CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
                                               "MinSizeRel" "RelWithDebInfo")
endif()

option(BUILD_RUBY_BINDINGS "Build Ruby bindings" ON)

# Build CSharp bindings
option(BUILD_CSHARP_BINDINGS "Build CSharp bindings" OFF)

# Build Python bindings Requires: SWIG Python
option(BUILD_PYTHON_BINDINGS "Build Python bindings" ON)

###############################################################################
#                          C M A K E    C O N T R O L                         #
###############################################################################

# High level project configuration Do we actually want everything to go to
# CMAKE_BINARY_DIR/Products, so that when you build OpenStudioApplication you
# get both OpenStudio (core) and Application in the same place?
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Products")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Products")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Products")

set(LIBRARY_SEARCH_DIRECTORY
    "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
    "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/Release"
    "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/Debug")

# Search first in the binary dir, where conan will install finders, then search
# for modules in the root dir to override cmake ones
list(APPEND CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR}"
     "${PROJECT_SOURCE_DIR}/CMake")

# Add to include path

# Project source directory
include_directories("${PROJECT_SOURCE_DIR}")

# Search first in the binary dir, where conan will install finders, then
# search for modules in the root dir to override cmake ones
# Start with ROOT, then PROJECT_BINARY_DIR
list(APPEND CMAKE_MODULE_PATH "${PROJECT_BINARY_DIR}" "${PROJECT_SOURCE_DIR}/CMake")
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

###############################################################################
#                   R E G U L A R    O U P U T    A N D    L I B S            #
###############################################################################

find_package(jsoncpp REQUIRED)

set(target_name mylib)

set(${target_name}_src Model.hpp Model.cpp)

add_library(${target_name} STATIC ${${target_name}_src})
target_link_libraries(${target_name} PRIVATE
  jsoncpp::jsoncpp
  cpp_warning_options
  cpp_compile_options
)

###############################################################################
#                                S W I G                                      #
###############################################################################

find_package(SWIG CONFIG REQUIRED COMPONENTS python ruby csharp)
message("${SWIG_USE_FILE}")
# include("${SWIG_USE_FILE}")
include(UseSWIG)
message("SWIG_EXECUTABLE=${SWIG_EXECUTABLE}")
message("swig_PACKAGE_FOLDER_DEBUG=${swig_PACKAGE_FOLDER_DEBUG}")

message("swig_INCLUDE_DIR=${swig_INCLUDE_DIR}")

set(SWIG_EXECUTABLE "${swig_PACKAGE_FOLDER_DEBUG}/bin/swig")
set(SWIG_DIR "${swig_PACKAGE_FOLDER_DEBUG}/bin/swiglib")

set(${target_name}_swig_src Model.i)

foreach(SWIG_FILE ${${target_name}_swig_src})
  message("SWIG_FILE=${SWIG_FILE}")
  set_source_files_properties(${SWIG_FILE} PROPERTIES CPLUSPLUS ON)
endforeach()






if(BUILD_PYTHON_BINDINGS)

  add_compile_definitions(WITHPYTHON)

  set(swig_target_name ${target_name}_python)

  # **Only** find static libs
  #set(Python_USE_STATIC_LIBS TRUE)

  find_package(
    Python
    COMPONENTS Interpreter Development
    REQUIRED)

  swig_add_library(
    ${swig_target_name}
    #TYPE STATIC
    LANGUAGE python OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/Products/python"
                    OUTFILE_DIR "${CMAKE_CURRENT_BINARY_DIR}/python_wrapper"
    SOURCES ${${target_name}_swig_src})

  set_target_properties(${swig_target_name} PROPERTIES OUTPUT_NAME
                                                       ${target_name})

  set_target_properties(
    ${swig_target_name} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY
                                   "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/python/")
  set_target_properties(
    ${swig_target_name} PROPERTIES LIBRARY_OUTPUT_DIRECTORY
                                   "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/python/")
  set_target_properties(
    ${swig_target_name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                   "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/python/")

#  target_include_directories(${swig_target_name} PRIVATE SYSTEM
#                                                         ${Python_INCLUDE_DIRS})

  swig_link_libraries(${swig_target_name}
    PUBLIC ${target_name}
    PRIVATE cpp_compile_options
    jsoncpp::jsoncpp)

  target_include_directories(${swig_target_name} PRIVATE ${Python_INCLUDE_DIRS})
#  if(MSVC)
#    swig_link_libraries(${swig_target_name} PRIVATE Python::Module)
#  endif()

  add_test(
    NAME test_python_only
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/python
    COMMAND ${Python_EXECUTABLE} test_python.py)

  # Must call CMake itself in order to set the SWIG_LIB env var for
  # add_custom_command
  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/python_wrapper/SWIGPythonRuntime.hxx"
    COMMAND
      ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_DIR}" "${SWIG_EXECUTABLE}" "-v"
      "-python" -external-runtime
      "${CMAKE_CURRENT_BINARY_DIR}/python_wrapper/SWIGPythonRuntime.hxx")

endif()

if(BUILD_RUBY_BINDINGS)

  add_compile_definitions(WITHRUBY)
  add_compile_definitions(RUBY_EMBEDDED)

  set(CMAKE_SWIG_FLAGS ${CMAKE_SWIG_FLAGS} -fvirtual)

  find_package(
    Ruby
    REQUIRED)

  set(swig_target_name ${target_name}_ruby)

  swig_add_library(
    ${swig_target_name}
    #TYPE OBJECT
    LANGUAGE ruby OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/Products/ruby"
                  OUTFILE_DIR "${CMAKE_CURRENT_BINARY_DIR}/ruby_wrapper"
    SOURCES ${${target_name}_swig_src})

  set_target_properties(${swig_target_name} PROPERTIES OUTPUT_NAME
                                                       ${target_name})
  set_target_properties(${swig_target_name} PROPERTIES SWIG_INCLUDE_DIRECTORIES ${CMAKE_SOURCE_DIR}/ruby/)
  set_target_properties(
    ${swig_target_name} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY
                                   "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/ruby/")
  set_target_properties(
    ${swig_target_name} PROPERTIES LIBRARY_OUTPUT_DIRECTORY
                                   "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/ruby/")
  set_target_properties(
    ${swig_target_name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                   "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ruby/")

  target_include_directories(
    ${swig_target_name} PRIVATE SYSTEM ${RUBY_INCLUDE_DIRS} )

  swig_link_libraries(${swig_target_name}
    PUBLIC ${target_name}
    PRIVATE ${RUBY_LIBRARIES} 
    jsoncpp::jsoncpp
    cpp_compile_options)

  message("RUBY_EXECUTABLE=${RUBY_EXECUTABLE}")
  add_test(
    NAME test_ruby_rb
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/ruby
    COMMAND ${RUBY_EXECUTABLE} test_ruby.rb)


  # Must call CMake itself in order to set the SWIG_LIB env var for
  # add_custom_command
  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/ruby_wrapper/SWIGRubyRuntime.hxx"
    COMMAND
      ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_DIR}" "${SWIG_EXECUTABLE}" "-v"
      "-ruby" -external-runtime
      "${CMAKE_CURRENT_BINARY_DIR}/ruby_wrapper/SWIGRubyRuntime.hxx")

  set_source_files_properties("${CMAKE_CURRENT_BINARY_DIR}/ruby_wrapper/SWIGRubyRuntime.hxx" PROPERTIES COMPILE_FLAGS "-DRUBY_EMBEDDED -Wno-unused-variable" )
  # -Wno-deprecated-declaration, /wd4996: suppresses deprecated warning
  # -Wno-register, /wd5033: ISO C++1z does not allow *register* storage class specifier

endif()

enable_testing()
include(CTest)
