#!/bin/bash
set -e

# Ticket FIXME

# Variables.
#
# Modify these as necessary.  Some variables are set as an example;
# you will need to change $url at the very least.
#
PN=$(basename $(dirname $PWD))
V=$(basename $PWD)
P=$PN-$V
url=http://ftpmirror.gnu.org/gsl/${PN}-${V}.tar.gz
DEPENDS=(
    # Add runtime module depedencies here, e.g. intelics/2017.1
    # Put compile time dependencies in the build section further below.
)
tarball=$(basename ${url%/download})
tardir=$PN-$V
builddir=build-$PN
suffix=				# e.g. ics, pgi, plumed, etc
suffix=${suffix:+-${suffix}}	# Prepend "-" if suffix is set.
PREFIX=${SRCMOD_PREFIX:-/apps2/$PN/$V$suffix}
mod=${SRCMOD_PREFIX_MOD:-/apps2/mod/$PN/$V$suffix}

# Fetch and unpack tarball.
#
test ! -e $tarball && wget $url -O $tarball
if ! [[ -e $tardir ]]; then
    case ${tarball##*.} in
	zip) unzip -o $tarball ;;
	*) tar -xf $tarball ;;
    esac
fi

# Build and install
#
# Runs in subshell to 1) preserve environment changed by the module
# function, and 2) preserve local directory in case of error.
(
    set -e

    cd $builddir

    module purge
    # Add any build time dependencies here.
    #module load intelics/2017.1
    test ! -z $DEPENDS && module load ${DEPENDS[*]}

    ../$tardir/configure --prefix=$PREFIX
    make
    make install
)

# Install the modulefile
mkdir -p $(dirname $mod)
unset deps
if [[ ${#DEPENDS[*]} -gt 0 ]]; then
    deps=$(printf -- "--dep %s " ${DEPENDS[*]})
fi
modulefile $deps $PREFIX > $mod
