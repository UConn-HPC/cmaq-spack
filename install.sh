#!/bin/bash
set -e

# Ticket 48617

# Variables.
#
# Modify these as necessary.  Some variables are set as an example;
# you will need to change $url at the very least.
#
PN=cmaq
V=5.2.1
P=$PN-$V
url=https://github.com/USEPA/$PN/archive/$V.zip
tarball=$(basename ${url%/download})
tardir=${PN^^}-$V

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
set -e
module purge

# Compile dependencies with spack.
if ! [[ -d spack ]]; then
    git clone https://github.com/UCONN-HPC/spack.git -b ioapi spack
fi
source spack/share/spack/setup-env.sh
compiler=gcc@9.1.0
if ! grep -q $compiler <<< $(spack compiler info $compiler); then
    spack compiler find	# System compiler
    spack install $compiler
    spack find -p $compiler |
	tail -1 |
	awk '{print $2}' |
	xargs spack compiler find
fi

spec="ioapi ^netcdf+parallel-netcdf %$compiler"
if ! grep -q installed <<< $(spack find $spec); then
    spack install $spec
fi

cd $tardir

# Add any build time dependencies here.
spack load $compiler
spack load mpi
module list

# Install into home directory.
CMAQ_HOME=$HOME/CMAQ_Project
rm -rf $CMAQ_HOME
sed -i -E \
    -e "s#(.*set CMAQ_HOME = ).*#\1$CMAQ_HOME#" \
    bldit_project.csh

./bldit_project.csh

cd $CMAQ_HOME

# Modify paths.
ioapi=$(spack location -i ioapi ^netcdf+parallel-netcdf)
netcdf=$(spack location -i netcdf+parallel-netcdf)
netcdf_fortran=$(spack location -i netcdf-fortran)
netcdf_both=$PWD/netcdf_both
mpi=$(spack location -i mpi)

ioapi_mod=$ioapi/lib
ioapi_inc=$ioapi/include/fixed132
ioapi_lib=$ioapi/lib
netcdf_lib=$netcdf_both/lib
netcdf_inc=$netcdf_both/include
mpi_lib=$mpi

# CMAQ assumes that netcdf and netcdf-fortran are installed into
# the same directory.  Create symlinks to simulate this.
rm -rf $netcdf_both
mkdir -vp $netcdf_both/{lib,include}
# Symlink static libs.
for lib in $netcdf/lib/* $netcdf_fortran/lib/*
do
    target=$netcdf_both/lib/$(basename $lib)
    if ! [[ -L $target ]]
    then
	ln -sv $lib $target
    fi
done
for header in $netcdf/include/* $netcdf_fortran/include/*
do
    target=$netcdf_both/include/$(basename $header)
    if ! [[ -L $target ]]
    then
	ln -sv $header $target
    fi
done
tree -F $netcdf_both

sed -i -E \
    -e "/setenv IOAPI_MOD_DIR/ s#(.+ IOAPI_MOD_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$ioapi_mod \2#" \
    -e "/setenv IOAPI_INCL_DIR/ s#(.+ IOAPI_INCL_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$ioapi_inc \2#" \
    -e "/setenv IOAPI_LIB_DIR/ s#(.+ IOAPI_LIB_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$ioapi_lib \2#" \
    -e "/setenv NETCDF_LIB_DIR/ s#(.+ NETCDF_LIB_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$netcdf_lib \2#" \
    -e "/setenv NETCDF_INCL_DIR/ s#(.+ NETCDF_INCL_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$netcdf_inc \2#" \
    -e "/setenv MPI_LIB_DIR/ s#(.+ MPI_LIB_DIR[ ]+)[[:graph:]]+[ ]+(.*)#\1$mpi_lib \2#" \
    -e "/setenv mpi_lib/ s#(.+ mpi_lib[ ]+)[[:graph:]]+[ ]+(.*)#\1\"-lmpi\"\2#" \
    -e "/setenv myLINK_FLAG/ s#(.+ myLINK_FLAG[ ]+)(.*)#\1\"-fopenmp -Wl,-rpath,$netcdf/lib -Wl,-rpath,$netcdf_fortran/lib\" \2#" \
    config_cmaq.csh

# Run configure.
csh -ex <<EOF
source ./config_cmaq.csh gcc

cd $CMAQ_HOME/PREP/icon/scripts
./bldit_icon.csh gcc |& tee build_icon.log

cd $CMAQ_HOME/PREP/bcon/scripts
./bldit_bcon.csh gcc |& tee build_bcon.log

cd $CMAQ_HOME/CCTM/scripts
./bldit_cctm.csh gcc |& tee build_cctm.log
EOF

# cd $CMAQ_HOME/PREP/icon/scripts
# ./run_icon.csh |& tee run_icon.log

# cd $CMAQ_HOME/PREP/bcon/scripts
# ./run_bcon.csh |& tee run_bcon.log

# cd $CMAQ_HOME/CCTM/scripts
# ./run_cctm.csh |& tee cctm.log
