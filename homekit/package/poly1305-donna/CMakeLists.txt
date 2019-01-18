#############################################################################
# CMake top level project file
cmake_minimum_required(VERSION 2.8.7)

project(poly1305-donna)

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

ExternalProject_Add(prj_poly1305-donna
  PREFIX ${PROJECT_BINARY_DIR}
  GIT_REPOSITORY "https://github.com/floodyberry/poly1305-donna"
  GIT_TAG dabffc6608eaca87d48c4ce9fc33a1e74a47e3f9 
  PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/patches patches
  CONFIGURE_COMMAND quilt push -a
  BUILD_COMMAND make
  INSTALL_COMMAND make install DESTDIR=${CMAKE_BINARY_DIR}/install
  BUILD_IN_SOURCE 1)

# Define the libraries provided in CMake import terms
if(BUILD_SHARED_LIBS)
  add_library(poly1305-donna SHARED IMPORTED)
else()
  add_library(poly1305-donna STATIC IMPORTED)
endif()
set_target_properties(poly1305-donna PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib)

# Add external project as dependency for imported libraries
add_dependencies(poly1305-donna prj_poly1305-donna)


#############################################################################
# Install external project files (e.g. headers, libs, License, etc)
#############################################################################
install(FILES ${PROJECT_BINARY_DIR}/src/prj_poly1305-donna/poly1305-donna.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_poly1305-donna/libpoly1305-donna.a
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_poly1305-donna/libpoly1305-donna.so
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_poly1305-donna/libpoly1305-donna.so.1
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_poly1305-donna/libpoly1305-donna.so.1.0
	DESTINATION lib)


#############################################################################
# EOF
