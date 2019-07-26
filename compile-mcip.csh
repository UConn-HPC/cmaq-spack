#!/bin/csh -efx
#
# Compile mcip.

set src = CMAQ-5.2.1/PREP/mcip/src

# Patch mcoutcom_mod.F90 to fix this compilation error:
# https://forum.cmascenter.org/t/mcip-compile-mcoutcom-mod-o/385/2

# (patch -N --dry-run --silent -d $src < fix_array_char_len.patch) || echo $status
# exit 0
# if ! (); then
#     patch -d $src < fix_array_char_len.patch
# endif

# Query the paths we need to compile mcip.
source /etc/profile.d/modules.csh
module purge
source spack/share/spack/setup-env.csh

# Install serial IOAPI because MCIP is a serial program that shouldn't
# need MPI, and if we try to compile against parallel IOAPI we get a
# bunch of linking errors.
# https://forum.cmascenter.org/t/undefined-references-when-compiling-mcip/630/11
set mycompiler = "gcc@9.1.0"
spack install ioapi ^netcdf~mpi %$mycompiler

# CMAQ assumes that netcdf and netcdf-fortran are installed into
# the same directory.  Create symlinks to simulate this.
set netcdf_both = $PWD/netcdf_both_serial
set netcdf = `spack location -i netcdf~mpi`
set netcdf_fortran = `spack location -i netcdf-fortran ^netcdf~mpi`
rm -rf $netcdf_both
mkdir -vp $netcdf_both/{lib,include}
# Symlink static libs.
foreach lib ( $netcdf/lib/* $netcdf_fortran/lib/* )
    set target = $netcdf_both/lib/`basename $lib`
    if ( ! -e $target ) then
        ln -sv $lib $target
    endif
end
foreach header ( $netcdf/include/* $netcdf_fortran/include/* )
    set target = $netcdf_both/include/`basename $header`
    if ( ! -e $target ) then
        ln -sv $header $target
    endif
end
tree -F $netcdf_both

set ioapi = `spack location -i ioapi ^netcdf~mpi`

# Patch Makefile to:
# 1) Use GNU gfortran instead of Intel ifort (3 expressions).
# 2) Set paths of NETCDF and IOAPI_ROOT (2 expressions).
# 3) Fix paths of subdirectories (2 expressions).
sed -E -i \
    -e '49,+7 s/^([^#].*)/#\1/' \
    -e '38,+3 s/^#(.*)/\1/' \
    -e '45,+1 s/^#(.*)/\1/' \
    -e "s#^(NETCDF ).*#\1= $netcdf_both#" \
    -e "s#^(IOAPI_ROOT ).*#\1= $ioapi#" \
    -e 's#-I\$\(IOAPI_ROOT\)/Linux2_x86_64#-I$(IOAPI_ROOT)/include/fixed132#g' \
    -e 's#-L\$\(IOAPI_ROOT\)/Linux2_x86_64#-L$(IOAPI_ROOT)/lib#g' \
    $src/Makefile
# 4) Search for .mod files in $(IOAPI_ROOT)/lib.
set has_include = `grep '[-]I$(IOAPI_ROOT)/lib' $src/Makefile | wc -l`
if ($has_include == 0) then
    sed -i '41 s#$# -I$(IOAPI_ROOT)/lib#' $src/Makefile
endif
# 5) Add rpaths so that executable can be run without modules.
set rpaths = `grep '[-]Wl,-rpath' $src/Makefile | wc -l`
if ($rpaths == 0) then
    sed -i "46 s#"'$'"# -Wl,-rpath,$netcdf/lib -Wl,-rpath,$netcdf_fortran/lib#" $src/Makefile
endif
# 6) Add openmp needed by adding rpaths above?!?
set has_openmp = `grep '[-]fopenmp' $src/Makefile | wc -l`
if ($has_openmp == 0) then
    sed -i "41 s#"'$'"# -fopenmp#" $src/Makefile
endif

# Load the modules we need to compile mcip.
spack load $mycompiler
# spack load -r mpi
module list

# Compile mcip
source ~/CMAQ_Project/config_cmaq.csh gcc
make -C $src |& tee make.mcip.log
