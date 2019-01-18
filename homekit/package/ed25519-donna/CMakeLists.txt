#############################################################################
# CMake top level project file
cmake_minimum_required(VERSION 2.8.7)

project(ed25519-donna)

#############################################################################
# Definitions and Options
#############################################################################
set(PROJECT_VERSION_MAJOR 1)
set(PROJECT_VERSION_MINOR 0)
set(PROJECT_VERSION_PATCH 0)
set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")

#############################################################################
# Find and include required external libraries
#############################################################################
# If not cross compiling, then we need to handle our own external library
# needs (which for now is to include the other sibling cmake projects)
if(NOT CMAKE_CROSSCOMPILING)

if(NOT TARGET prj_tomcrypt)
add_subdirectory(../tomcrypt ${CMAKE_BINARY_DIR}/tomcrypt)
endif()
set(EXT_CFLAGS "-DSHA1 -I${CMAKE_BINARY_DIR}/install/usr/include")
set(EXT_LDFLAGS "-L${CMAKE_BINARY_DIR}/install/usr/lib -ltommath")
set(EXT_CONFIGURE --prefix=/usr --with-tomcrypt=${CMAKE_BINARY_DIR}/tomcrypt/src/tomcrypt)

# Add external library dependency directories created from above
include_directories(${CMAKE_BINARY_DIR}/install/usr/include)
link_directories(${CMAKE_BINARY_DIR}/install/usr/lib)
endif()


#############################################################################
# Project Libraries
#############################################################################
# Add external project CMake support
include(ExternalProject)

# Create external project for host only build
ExternalProject_Add(prj_ed25519-donna
  DEPENDS prj_tomcrypt
  PREFIX ${PROJECT_BINARY_DIR}
  GIT_REPOSITORY "https://github.com/floodyberry/ed25519-donna"
  GIT_TAG 8757bd4cd209cb032853ece0ce413f122eef212c
  PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/patches patches
  CONFIGURE_COMMAND quilt push -a
  BUILD_COMMAND env CFLAGS=${EXT_CFLAGS} LDFLAGS=${EXT_LDFLAGS} make
  INSTALL_COMMAND make install DESTDIR=${CMAKE_BINARY_DIR}/install
  BUILD_IN_SOURCE 1)

# Define the libraries provided in CMake import terms
if(BUILD_SHARED_LIBS)
  add_library(ed25519-donna SHARED IMPORTED)
else()
  add_library(ed25519-donna STATIC IMPORTED)
endif()
set_target_properties(ed25519-donna PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib)

# Add external project as dependency for imported libraries
add_dependencies(ed25519-donna prj_tomcrypt prj_ed25519-donna)


#############################################################################
# Install external project files (e.g. headers, libs, License, etc)
#############################################################################
install(FILES ${PROJECT_BINARY_DIR}/src/prj_ed25519-donna/ed25519.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_ed25519-donna/libed25519-donna.a
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_ed25519-donna/libed25519-donna.so
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_ed25519-donna/libed25519-donna.so.1
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_ed25519-donna/libed25519-donna.so.1.0
	DESTINATION lib)


#############################################################################
# EOF
