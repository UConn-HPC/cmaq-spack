#!/bin/bash
set -e

# Ticket 48617

# Variables.
#
# Modify these as necessary.  Some variables are set as an example;
# you will need to change $url at the very least.
#
PN=$(basename $(dirname $PWD))
V=$(basename $PWD)
P=$PN-$V
url=https://github.com/USEPA/$PN/archive/$V.zip
DEPENDS=(
    # Add runtime module depedencies here, e.g. intelics/2017.1
    # Put compile time dependencies in the build section further below.
    intelics/2013.1.039-compiler
    zlib/1.2.8-ics
    hdf5/1.8.17-ics-impi
    netcdf/4.3.1-ics-wrf
    ioapi/3.1
)
tarball=$(basename ${url%/download})
tardir=${PN^^}-$V
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

    cd $tardir

    module purge
    # Add any build time dependencies here.
    #module load intelics/2017.1
    test ! -z $DEPENDS && module load ${DEPENDS[*]}

    # Install into home directory.
    sed -i -E \
	-e "s#(.*set CMAQ_HOME = ).*#\1\$HOME/CMAQ_Project#" \
	bldit_project.csh

    ./bldit_project.csh

    cd $HOME/CMAQ_Project/

    # Modify paths.
    ioapi_mod_intel=/apps2/${DEPENDS[4]}/install/Linux2_x86_64ifort
    ioapi_inc_intel=$ioapi_mod_intel
    ioapi_lib_intel=$ioapi_mod_intel
    netcdf_lib_intel=/apps2/${DEPENDS[3]}/lib
    netcdf_inc_intel=/apps2/${DEPENDS[3]}/include
    mpi_lib_intel=/apps/${DEPENDS[0]}/lib/intel64

    sed -i -E \
	-e "0,/IOAPI_MOD_DIR/ s#(.+ IOAPI_MOD_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$ioapi_mod_intel \2#" \
	-e "0,/IOAPI_INCL_DIR/ s#(.+ IOAPI_INCL_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$ioapi_inc_intel \2#" \
	-e "0,/IOAPI_LIB_DIR/ s#(.+ IOAPI_LIB_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$ioapi_lib_intel \2#" \
	-e "0,/NETCDF_LIB_DIR/ s#(.+ NETCDF_LIB_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$netcdf_lib_intel \2#" \
	-e "0,/NETCDF_INCL_DIR/ s#(.+ NETCDF_INCL_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$netcdf_inc_intel \2#" \
	-e "0,/MPI_LIB_DIR/ s#(.+ MPI_LIB_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$mpi_lib_intel \2#" \
	config_cmaq.csh

    # Create configure script.
    cat > configure <<EOF
    #!/bin/bash
module purge
module load ${DEPENDS[*]}
csh -x ./config_cmaq.csh intel
EOF
    chmod +x configure

    # Run configure.
    ./configure
)
