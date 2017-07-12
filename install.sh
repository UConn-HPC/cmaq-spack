#!/bin/bash
set -e

# Ticket FIXME

# Variables.
#
# Modify these as necessary.  Some variables are set as an example;
# you will need to change $url at the very least.
#
pn=$(basename $(dirname $PWD))
v=$(basename $PWD)
url=http://ftpmirror.gnu.org/gsl/${pn}-${v}.tar.gz
deps=(
    # Add runtime module depedencies here, e.g. intelics/2017.1
    # Put compile time dependencies in the build section further below.
)
tarball=$(basename ${url})
tardir=$pn-$v
suffix=				# e.g. ics, pgi, plumed, etc
suffix=${suffix:+-${suffix}}	# Prepend "-" if suffix is set.
prefix=${SRCMOD_PREFIX:-/apps2/$pn/$v$suffix}
mod=${SRCMOD_PREFIX_MOD:-/apps2/mod/$pn/$v$suffix}

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

    cd $tardir

    # Add any build time dependencies here.
    #module load intelics/2017.1
    test ! -z $deps && module load ${deps[*]}

    ./configure --prefix=$prefix    
    make
    make install
)

# Install the modulefile
mkdir -p $(dirname $mod)
./modulefile.sh $prefix "${deps[*]}" > $mod
