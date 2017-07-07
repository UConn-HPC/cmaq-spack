# srcmod

Simple, lightweight, build automation and
[environment module](https://en.wikipedia.org/wiki/Environment_Modules_(software)) installer
intended for installing software in HPC environments.

Projects like [spack](/llnl/spack) are fantastic,
but are overkill for small compilation tasks.

# Usage

Create a directory structure in the form of:

    package_name/package_version

Clone this git repo to use the "package_version" directory:

	git clone https://github.uconn.edu/srcmod .

Then modify `install.sh` as necessary.

If changes to `modulefile.sh` are necessary,
consider contributing them back to this repository.
