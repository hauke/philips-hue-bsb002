#############################################################################
# CMake top level project file
cmake_minimum_required(VERSION 2.8.7)

project(tommath)

#############################################################################
# Definitions and Options
#############################################################################
set(PROJECT_VERSION_MAJOR 0)
set(PROJECT_VERSION_MINOR 42)
set(PROJECT_VERSION_PATCH 0)
set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")

#############################################################################
# Project Libraries
#############################################################################
# Add external project for host only build
include(ExternalProject)

ExternalProject_Add(prj_tommath
  PREFIX ${PROJECT_BINARY_DIR}
  GIT_REPOSITORY "https://github.com/libtom/libtommath"
  GIT_TAG 6f5bf561220a04962fbcd56db940085de4b53327
  PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/patches patches
  CONFIGURE_COMMAND quilt push -a
  BUILD_COMMAND make
  INSTALL_COMMAND make install DESTDIR=${CMAKE_BINARY_DIR}/install
  BUILD_IN_SOURCE 1)

# Define the libraries provided in CMake import terms
if(BUILD_SHARED_LIBS)
  add_library(tommath SHARED IMPORTED)
else()
  add_library(tommath STATIC IMPORTED)
endif()
set_target_properties(tommath PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib)

# Add external project as dependency for imported libraries
add_dependencies(tommath prj_tommath)


#############################################################################
# Install external project files (e.g. headers, libs, License, etc)
#############################################################################
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/tommath_class.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/tommath.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/tommath_superclass.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/libtommath.a
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/libtommath.so
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/libtommath.so.0
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tommath/libtommath.so.0.42.0
	DESTINATION lib)


#############################################################################
# EOF
