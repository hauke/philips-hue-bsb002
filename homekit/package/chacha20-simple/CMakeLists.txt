#############################################################################
# CMake top level project file
cmake_minimum_required(VERSION 2.8.7)

project(chacha20-simple)

#############################################################################
# Definitions and Options
#############################################################################
set(PROJECT_VERSION_MAJOR 1)
set(PROJECT_VERSION_MINOR 0)
set(PROJECT_VERSION_PATCH 0)
set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")

#############################################################################
# Project Libraries
#############################################################################
# Add external project for host only build
include(ExternalProject)

ExternalProject_Add(prj_chacha20-simple
  PREFIX ${PROJECT_BINARY_DIR}
  URL "http://chacha20.insanecoding.org/chacha20-simple-1.0.tar.bz2"
  URL_MD5 e6d7b631225dcaf00ea4ba489fb36e67
  PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/patches patches
  CONFIGURE_COMMAND quilt push -a
  BUILD_COMMAND make
  INSTALL_COMMAND make install DESTDIR=${CMAKE_BINARY_DIR}/install
  BUILD_IN_SOURCE 1)

# Define the libraries provided in CMake import terms
if(BUILD_SHARED_LIBS)
  add_library(chacha20-simple SHARED IMPORTED)
  set_target_properties(chacha20-simple PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib/libchacha20-simple.so.1)
else()
  add_library(chacha20-simple STATIC IMPORTED)
  set_target_properties(chacha20-simple PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib/libchacha20-simple.a)
endif()

# Add external project as dependency for imported libraries
add_dependencies(chacha20-simple prj_chacha20)


#############################################################################
# Install external project files (e.g. headers, libs, License, etc)
#############################################################################
install(FILES ${PROJECT_BINARY_DIR}/src/prj_chacha20-simple/chacha20_simple.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_chacha20-simple/libchacha20-simple.a
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_chacha20-simple/libchacha20-simple.so
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_chacha20-simple/libchacha20-simple.so.1
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_chacha20-simple/libchacha20-simple.so.1.0
	DESTINATION lib)


#############################################################################
# EOF
