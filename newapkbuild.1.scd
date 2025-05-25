newapkbuild(1)

# NAME

*newapkbuild* - generate a new APKBUILD


# SYNOPSIS

*newapkbuild* _options_... [_pkgname_[-_pkgver_] | _source_url_]


# DESCRIPTION

*newapkbuild* generates a new APKBUILD for use with abuild(1). _pkgname_
specifies the package name, if not already specified with *-n*. If followed
by a dash (-) and a valid version string _pkgver_, additionally specify
the package's version.

*newapkbuild* will try to automatically detect the build system by inspecting
the source directory if _source_url_ is specified, and write out typical
build instructions for that build system. If you do not specify the source
URL, or want to override auto-detection, you may specify the build system
with the appropriate option. If no _source_url_ and no option are specified,
the generated APKBUILD file will not contain any build instructions.


# OPTIONS

*-a*
	Specifies that the package uses autotools.

*-C*
	Specifies that the package uses CMake. CMake will be added to
	the makedepends.

*-c*
	Causes *newapkbuild* to additionally copy an init.d script, conf.d
	file, and sample pre- and post- install scripts to the APKBUILD
	directory. This allows you to have a quick start for daemon
	packages. See the FILES section for details.

*-d* _DESC_
	Specifies the description (pkgdesc=) for the new package.

*-e*
	Specifies that the package uses a Python PEP517 build
	system. Python's gpep517, setuptools and wheel will be added
	to the makedepends.

*-f*
	Forces *newapkbuild* to overwrite an existing APKBUILD, if one
	already exists in the package directory.

*-h*
	Displays usage information.

*-l* _LICENSE_
	Specifies the license under which the new package is distributed. This
	should match an SPDX Identifier.

*-m*
	Specifies that the package uses Meson. Meson will be added to
	the makedepends.

*-n* _NAME_
	Specifies the name of the new package. A new directory called _NAME_
	will be created in the current directory, with the APKBUILD file.

*-p*
	Specifies that the package uses a Perl Makefile.PL file. The CPAN
	template will be used and Perl will be added to the depends.

*-r*
	Specifies that the package uses Cargo. Cargo will be added to
	the makedepends.

*-s*
	Create an automatic SourceForge URL for the package based on its
	name and version. This is only valid if _pkgname-pkgver_ is specified
	on the command line.

*-u* _URL_
	Specifies the Web page (url=) for the new package. This should _not_
	be the source package URL; it should be the project's main Web page.


# FILES

All files generated will be places in a _pkgname_ directory inside the
current working directory, with _pkgname_ being created if it does not exist.

APKBUILD
	*newapkbuild* will create an APKBUILD with the details gathered
	from the invocation of *newapkbuild*, and introspection of the
	downloaded package source if _source_url_ is provided. For more
	information about APKBUILD and its format, see APKBUILD(5).

_pkgname_.initd
	If *-c* is given, *newapkbuild* will create _pkgname_.initd with
	example data to assist in the creation of an init.d script for
	a daemon.

_pkgname_.confd
	If *-c* is given, *newapkbuild* will create _pkgname_.confd to
	assist in the creation of a conf.d file for a daemon, used by
	init.d scripts. conf.d files are used to configure init.d scripts;
	for more information, see openrc(8) and rc_config(3).

_pkgname_.pre-install
	If *-c* is given, *newapkbuild* will create _pkgname_.pre-install,
	the contents of which will be run by apk(8) before the package
	is installed.

_pkgname_.post-install
	If *-c* is given, *newapkbuild* will create _pkgname_.post-install,
	the contents of which will be run by apk(8) after the package is
	successfully installed. For more information about apk install hooks,
	consult the apk(8) manual.


# EXAMPLES

```
newapkbuild \\
	-n sharutils \\
	-d "Utilities for manipulating shell archives" \\
	-l "GPL-3.0+" \\
	-u "https://www.gnu.org/software/sharutils/" \\
	-a \\
	"https://ftp.gnu.org/gnu/sharutils/sharutils-4.15.2.tar.xz"
```


# SEE ALSO

SPDX license reference (on the Web at <https://spdx.org/licenses/>),
abuild(1), apk(8), APKBUILD(5).


# AUTHORS

*newapkbuild*: Natanael Copa <_ncopa@alpinelinux.org_>

Documentation:++
A. Wilcox <_wilfox@adelielinux.org_>
