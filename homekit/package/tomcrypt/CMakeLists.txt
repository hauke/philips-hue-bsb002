#############################################################################
# CMake top level project file
cmake_minimum_required(VERSION 2.8.7)

project(tomcrypt)

#############################################################################
# Definitions and Options
#############################################################################
set(PROJECT_VERSION_MAJOR 1)
set(PROJECT_VERSION_MINOR 17)
set(PROJECT_VERSION_PATCH 0)
set(PROJECT_VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")

#############################################################################
# Find and include required external libraries
#############################################################################
if(NOT TARGET prj_tommath)
add_subdirectory(../tommath ${CMAKE_BINARY_DIR}/tommath)
set(EXT_CFLAGS "-DLTM_DESC -DUSE_LTM -I${CMAKE_BINARY_DIR}/install/usr/include")
set(EXT_LDFLAGS "-L${CMAKE_BINARY_DIR}/install/usr/lib -ltommath")
endif()

#############################################################################
# Project Libraries
#############################################################################
# Add external project CMake support
include(ExternalProject)

# Create external project for host only build
ExternalProject_Add(prj_tomcrypt
  DEPENDS prj_tommath
  PREFIX ${PROJECT_BINARY_DIR}
  GIT_REPOSITORY "https://github.com/libtom/libtomcrypt"
  GIT_TAG bbc52b9e1bf4b22ac4616e667b06d217c6ab004e
  PATCH_COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/patches patches
  CONFIGURE_COMMAND quilt push -a
  BUILD_COMMAND env CFLAGS=${EXT_CFLAGS} LDFLAGS=${EXT_LDFLAGS} make
  INSTALL_COMMAND make install DESTDIR=${CMAKE_BINARY_DIR}/install
  BUILD_IN_SOURCE 1)

# Define the libraries provided in CMake import terms
if(BUILD_SHARED_LIBS)
  add_library(tomcrypt SHARED IMPORTED)
else()
  add_library(tomcrypt STATIC IMPORTED)
endif()
set_target_properties(tomcrypt PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/install/usr/lib)

# Add external project as dependency for imported libraries
add_dependencies(tomcrypt prj_tomcrypt)


#############################################################################
# Install external project files (e.g. headers, libs, License, etc)
#############################################################################
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_argchk.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_cfg.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_cipher.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_custom.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_hash.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_mac.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_macros.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_math.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_misc.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_pkcs.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_pk.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/src/headers/tomcrypt_prng.h
	DESTINATION include)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/libtomcrypt.a
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/libtomcrypt.so
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/libtomcrypt.so.1
	DESTINATION lib)
install(FILES ${PROJECT_BINARY_DIR}/src/prj_tomcrypt/libtomcrypt.so.1.17
	DESTINATION lib)


#############################################################################
# EOF
