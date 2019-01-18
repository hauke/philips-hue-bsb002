#############################################################################
# CMake top level project file
cmake_minimum_required(VERSION 2.8.7)

project(srp)

#############################################################################
# Definitions and Options
#############################################################################
set(PROJECT_VERSION_MAJOR 2)
set(PROJECT_VERSION_MINOR 1)
set(PROJECT_VERSION_PATCH 2)
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
set(EXT_LIBS "-L${CMAKE_BINARY_DIR}/install/usr/lib -ltommath")
set(EXT_CONFIGURE --prefix=/usr --with-tomcrypt=${CMAKE_BINARY_DIR}/tomcrypt/src/tomcrypt)

# Add external library dependency directory created from above
include_directories(${CMAKE_BINARY_DIR}/install/usr/include)
endif()


#############################################################################
# Project Libraries
#############################################################################
# Add external project CMake support
include(ExternalProject)

# Create external project for host only build
ExternalProject_Add(prj_srp
  DEPENDS prj_tomcrypt
  PREFIX ${PROJECT_BINARY_DIR}
  URL "http://srp.stanford.edu/source/${PROJECT_NAME}-${PROJECT_VERSION}.tar.gz"
  URL_MD5 39d150d2fcfcea1646c405172b748119
  PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/patches patches
  UPDATE_COMMAND quilt push -a
  CONFIGURE_COMMAND cd libsrp && env CFLAGS=${EXT_CFLAGS} LIBS=${EXT_LIBS} ./configure ${EXT_CONFIGURE}
  BUILD_COMMAND cd libsrp && make
  INSTALL_COMMAND cd libsrp && make install DESTDIR=${CMAKE_BINARY_DIR}/install
  BUILD_IN_SOURCE 1)

# Define the libraries provided in CMake import terms
if(BUILD_SHARED_LIBS)
  add_library(srp SHARED IMPORTED)
else()
  add_library(srp STATIC IMPORTED)
endif()
set_target_properties(srp PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib)

# Add external project as dependency for imported libraries
add_dependencies(srp prj_srp)


#############################################################################
# Install external project files (e.g. headers, libs, License, etc)
#############################################################################
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/cstr.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/srp_aux.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/srp.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/t_client.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/t_pwd.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/t_server.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/t_sha.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/libsrp.a
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/libsrp.so
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/libsrp.so.2
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_srp/libsrp/libsrp.so.2.0.0
	DESTINATION lib)


#############################################################################
# EOF
