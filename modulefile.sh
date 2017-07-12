#!/bin/bash

function print_modulefile () {
    # Validate first argument prefix directory.
    local prefix=$1
    if [[ -z "$prefix" ]]; then
	echo "Error: Missing \$prefix argument to function ${FUNCNAME[0]}!"
	exit 1
    fi
    if ! [[ -d "$prefix" ]]; then
	echo "Error: \$prefix argument must be a root directory of an installed package."
    fi
    # Extract
    re='/[^/]+/([^/]+)/([^/]+)'
    if [[ $prefix =~ $re ]]; then
	pn=${BASH_REMATCH[1]}
	v=${BASH_REMATCH[2]}
    else
	echo "Internal error: Regex failed"
    fi
    # Use dependencies, if provided.
    shift
    local deps=($@)

    echo "\
#%Module1.0

# Do not edit this file!  It was automagically generated by:
# $PWD/$(basename $0)

conflict $pn"
    for dep in ${deps[*]}; do
	echo "prereq $dep"
    done
    echo "
set		prefix		/apps2/[module-info name]
"
    test -d $prefix/bin &&
	echo "prepend-path	PATH		\$prefix/bin"
    test -d $prefix/include &&
	echo "\
prepend-path	CPATH		\$prefix/include
prepend-path	INCLUDE		\$prefix/include"
    test -d $prefix/lib &&
	echo "\
prepend-path	LIBRARY_PATH	\$prefix/lib
prepend-path	LD_LIBRARY_PATH	\$prefix/lib"
    test -d $prefix/lib32 &&
	echo "\
prepend-path	LIBRARY_PATH	\$prefix/lib32
prepend-path	LD_LIBRARY_PATH	\$prefix/lib32"
    test -d $prefix/lib64 &&
	echo "\
prepend-path	LIBRARY_PATH	\$prefix/lib64
prepend-path	LD_LIBRARY_PATH	\$prefix/lib64"
    test -d $prefix/lib/pkgconfig &&
	echo "prepend-path	PKG_CONFIG_PATH	\$prefix/lib/pkgconfig"
    test -d $prefix/share/man &&
	echo "prepend-path	MANPATH		\$prefix/share/man"
    test -d $prefix/share/info &&
	echo "prepend-path	INFOPATH	\$prefix/share/info"
    echo "
system echo $pn-$v \`whoami\` \`date\` >> /apps2/mod/survey
"
}

print_modulefile $@