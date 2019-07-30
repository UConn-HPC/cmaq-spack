# Compile CMAQ with spack

CMAQ is a set of Fortran programs from the EPA.

I added the [I/O API
package](https://spack.readthedocs.io/en/latest/package_list.html#ioapi)
to [spack](https://spack.io) to be able to compile the 4 CMAQ models.

# Usage

Clone the repo and run the scripts.

```bash
git clone https://github.com/UConn-HPC/cmaq-spack.git
cd cmaq-spack/
```

## BCON, ICON, CCTM

Running `install.sh` installs files into the `~/CMAQ_Project/`
directory recommended by upstream.

It creates the programs:

- `BCON_v52_profile.exe`
- `ICON_v52_profile.exe`
- `CCTM_v521.exe`

```bash
bash install.sh
```

## MCIP

Create the `mcip.exe` program after running `install.sh` above.

```bash
csh compile-mcip.csh
```
