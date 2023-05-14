# Sample Code for "Options for Consuming REST APIs from RPG"

Main website https://www.scottklement.com/presentations

LICENSE
---------------------------------------------------------------------
See the LICENSE file provided for details on how you may use this 
source code.

REQUIREMENTS
---------------------------------------------------------------------
If you wish to view the source code, you will find it all within the 
'src' subdirectory.

- IBM i 7.3 ("V7R3") or newer.
- The PASE environment (5770-SS1 option 33)
- YUM for IBM i https://ibmi-oss-docs.readthedocs.io/en/latest/yum/README.html
- Current cumulative and group PTFs.
- Git (see below)
- GNU Make (see below)
- ILE RPG Compiler
- The HTTPAPI open source tool from https://www.scottklement.com/httpapi/
- The YAJL open source tool from https://www.scottklement.com/yajl/

GIT & GNU MAKE
---------------------------------------------------------------------
You'll need `git` and `GNU make`. If not already installed, from a 
PASE command line, type:

 - `yum install git`
 - `yum install make-gnu`

COMPILING
---------------------------------------------------------------------
To compile everything in this package, from a PASE command line, type:

 - `make BUILDLIB=yourlib clean all`

*NOTE:* you may replace 'yourlib' with the name of a library that
you would like the resulting objects to be compiled into.

 - omit `clean` if you wish to only recompile sources that have changed.
 - omit `all` if you wish to delete everything this builds.

WORKING WITH NONSTANDARD LOCATIONS FOR HTTPAPI/YAJL
---------------------------------------------------------------------
This code assumes that HTTPAPI is install it's its default location,
which is library LIBHTTP, and that YAJL is installed in a library named
YAJL.

To use a different location for these objects, edit the `Makefile`
and change the HTTPLIB and YAJLLIB variables near the top to point to
the libraries where you have these tools.