macro(libtool_create_control_file _target)
  # Get target properties to fill into control file
  get_target_property(_target_location ${_target} LOCATION)
  get_target_property(_target_type ${_target} TYPE)

  message("-- Creating static libtool control file for target ${_target}")
  # No support for shared libraries as tigervnc only needs libtool config files
  # for static libraries
  if("${_target_type}" MATCHES "^[^STATIC_LIBRARY]$")
    message(ERROR " -  trying to use libtool_create_control_file on non static library target.")
  endif()

  #
  # Parse the target_LIB_DEPENDS of libraries to put into libtool control file
  # as library dependencies and handle a few corners...
  #
  foreach(library ${${_target}_LIB_DEPENDS})
    # Assume all entries as shared if not platform specific static library
    # extension is matched
    if("${library}" MATCHES "[^.+\\${CMAKE_STATIC_LIBRARY_SUFFIX}]$")
      # Check if we have shared extenstion or not
      if("${library}" MATCHES ".+\\${CMAKE_SHARED_LIBRARY_SUFFIX}$")
        # We got an shared library lets cut it down to path and library name then
	# add to libtool dependency libs, we always assume this is a absoult path
	# because this is how cmake does..
	get_filename_component(_shared_lib ${library} NAME_WE)
	get_filename_component(_shared_lib_path ${library} PATH)
	string(REPLACE "lib" "" _shared_lib ${_shared_lib})
        set(_target_dependency_libs "${_target_dependency_libs} -L${_shared_lib_path} -l${_shared_lib}")
      else()
	# No shared library suffix found, might also be a cmake target.
	# Dont continue if we have a target name as lib	due to we
	# assume static linkage against out targets
	get_target_property(_ltp ${library} TYPE)
	if(${_ltp})
	  # No cmake target soo let's use find_library to see if we found any useful to use
  	  find_library(FL ${library})
	  if(FL)
	    # Found library, lets cut it down to make libtool happy
    	    get_filename_component(_shared_lib ${FL} NAME_WE)
	    get_filename_component(_shared_lib_path ${FL} PATH)
	    string(REPLACE "lib" "" _shared_lib ${_shared_lib})
            set(_target_dependency_libs "${_target_dependency_libs} -L${_share_lib_path} -l${_shared_lib}")
	  else()
	    # Nothing found, lets ignore it
	  endif()
	else()
	  # taget detected lets ignore it
	endif()
      endif()
    else()
      # Detected a static library, we want the absolute path so lets check if we have that
      # if not try use find_library to get one
      get_filename_component(_name ${library} NAME)
      string(REPLACE "${_name}" "" _path ${library})
      if(NOT "${_path}" MATCHES "")
      	# We got a full path to static library lets add as is to libtool library dependencies
        set(_target_dependency_libs "${_target_dependency_libs} ${library}")
      else()
        # there no path for the static library lets use find_library to find one
	find_library(FL ${library})
	if(FL)
	  # got the library lets add it..
	  set(_target_dependency_libs "${_target_dependency_libs} ${FL}")
	else()
	  # Nothing found, let's ignore it
	endif()
      endif()
    endif()
  endforeach()

  # Write the libtool control file for static library
  get_filename_component(_lname ${_target_location} NAME_WE)
  set(_laname ${CMAKE_CURRENT_BINARY_DIR}/${_lname}.la)
 
  file(WRITE ${_laname} "# ${_lname}.la - a libtool library file\n# Generated by ltmain.sh (GNU libtool) 2.2.6b\n")
  file(APPEND ${_laname} "dlname=''\n\n")
  file(APPEND ${_laname} "library_names=''\n\n")
  file(APPEND ${_laname} "old_library='${_lname}${CMAKE_STATIC_LIBRARY_SUFFIX}'\n\n")
  file(APPEND ${_laname} "inherited_linker_flags=''\n\n")
  file(APPEND ${_laname} "dependency_libs=' ${_target_dependency_libs}'\n\n")
  file(APPEND ${_laname} "weak_library_names=''\n\n")
  file(APPEND ${_laname} "current=\n")
  file(APPEND ${_laname} "age=\n")
  file(APPEND ${_laname} "revision=\n\n")
  file(APPEND ${_laname} "installed=no\n\n")
  file(APPEND ${_laname} "shouldnotlink=no\n\n")
  file(APPEND ${_laname} "dlopen=''\n")
  file(APPEND ${_laname} "dlpreopen=''\n\n")
  file(APPEND ${_laname} "libdir=''\n\n")


  # Add custom command to symlink the static library so that autotools finds the library in .libs
  # these are executed after the specified target build.
  add_custom_command(TARGET ${_target} POST_BUILD COMMAND 
    cmake -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/.libs")
  add_custom_command(TARGET ${_target} POST_BUILD COMMAND
    cmake -E create_symlink ${_target_location} "${CMAKE_CURRENT_BINARY_DIR}/.libs/${_lname}${CMAKE_STATIC_LIBRARY_SUFFIX}")

endmacro()
