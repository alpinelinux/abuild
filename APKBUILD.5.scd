APKBUILD(5)

# NAME

*APKBUILD* - metadata and instructions to build a package


# SYNOPSIS

/usr/src/packages/<repo>/<package>/APKBUILD


# DESCRIPTION

An *APKBUILD* file is used by tools such as abuild(1) to build a package for
eventual installation by the apk(8) package manager. It defines metadata such
as the name of the package, the version information, the source license,
and contact information for the developer. It additionally contains the
commands needed to build, test, and install the package.

The *APKBUILD* format is similar to a typical shell script; you set
pre-defined variables and implement pre-defined functions, and the abuild(1)
(or similar) utility will use them to create the package.


## Required Variables

The following variables must be set in all *APKBUILD* files:

*pkgname*
	Specifies the name of the package. This is typically the name of the
	package upstream; however, note that all letters must be lowercased.

	Libraries for scripting languages should have a prefix before the
	library name describing the language. Such prefixes include _lua-_,
	_perl-_, _py-_, and _rb-_. Not all languages use prefixes. For a
	definitive list, consult the PREFIXES file in the root directory
	of the repository you are using for packaging.

*pkgver*
	Specifies the version of the software being packaged. The version of
	a package must consist of one or more numbers separated by the radix
	(decimal point). The final number may have a single letter following
	it, for upstreams that use such a versioning scheme (such as 1.5a,
	1.5b, 1.5c).

	After the final number (and optional single letter), a suffix may
	be appended, which must be an underscore (\_) followed by one of
	_alpha_, _beta_, _pre_, _rc_, _cvs_, _svn_, _git_, _hg_, or _p_,
	optionally followed by another number. If the suffix is _alpha_,
	_beta_, _pre_, or _rc_, it is considered to be earlier than the
	version without a suffix; if the suffix is _cvs_, _svn, _git_, _hg_,
	or _p_, it is considered to be later than the version without a
	suffix. All of the following examples are valid versions, in order
	from lowest to highest:

	1.0, 1.1_alpha2, 1.1.3_pre, 1.1.3, 1.1.3_hg, 1.2, 1.2a, 1.2b

*pkgrel*
	Specifies the package release number of this particular package
	version.  This indicates when a package has changed without a
	corresponding change in version. Always increment *pkgrel* when you
	change the contents, dependencies, or metadata of a package. The
	first release of a package is always 0.

*pkgdesc*
	Specifies what the package contains. *pkgdesc* must be 128 characters
	or less, and should concisely describe what actions the software or
	items being package will allow the user to perform. For example,
	“Fully-featured word processor with spell check and plugins”
	would be a sufficient *pkgdesc* for AbiWord.

*url*
	Specifies the Web address of the package's upstream. This allows users
	and future maintainers to find documentation, release information,
	and contact information for the package. If no Web address is
	available for the package, you must set *url* to an empty string ("").

*arch*
	Specifies the architectures for which the package may be built. It
	is highly recommended that you set this variable to "_all_" if the
	package is portable.

	You may use "_noarch_" if the package does not contain any
	architecture-specific binary files - that is, any files that are
	compiled for the target only. Such packages may include pure Python
	packages, shell script packages, and JARs. If you are not sure what
	this means, using "_all_" is safe.

	Architectures can be negated using the _!_ character to exclude them
	from the list of supported architectures. E.g. _arch="all !ppc64le"_
	means that the package is allowed to be built on all architectures
	but the ppc64le architecture.

*license*
	Specifies the license under which the package is distributed. The
	value provided must match a SPDX license identifier.

*source*
	Specifies the location of both local and remote source files
	used to build the package. Typically, the remote source file(s)
	or archive(s) is specified, followed by any local patches, install
	scripts, configuration files, or other necessary files.


## Optional Variables

The following variables are not required, but may be set in any *APKBUILD*
file.

*checkdepends*
	Specifies test-time dependencies of the package. Common packages that
	are used for testing include check, dejagnu, and perl-test-command.

*depends*
	Specifies the run-time dependencies of the package. The abuild(1)
	utility will automatically scan the resultant package for shared
	library (.so) dependencies; do not specify them here.

*install*
	Specifies install scripts for the package, if any. See _Install
	Scripts_ for more information about install scripts.

*install_if*
	Specifies a condition when apk(8) should automatically install the
	package (or subpackage). For instance, the OpenRC subpackages set

	```
	install_if="openrc ${subpkgname%-openrc}=$pkgver-r$pkgrel"
	```

	which means that the OpenRC subpackage will be automatically
	installed if both OpenRC and the origin package are installed on
	the same computer.

*makedepends*
	Specifies build dependencies for the package.

*maintainer*
	The name and email of the package maintainer in RFC 2822 format.
	E.g.: _maintainer="Joe Q. Public <john.q.public@example.com>"_

*pkggroups*
	Specifies a space-separated list of login groups to create during
	build-time. Note that you will need to create the login groups
	in a pre-install script as well; see _Install Scripts_ for more
	information about install scripts.

*pkgusers*
	Specifies a space-separated list of user logins to create during
	build-time. Note that you will need to create the user logins in a
	pre-install install script as well; see _Install Scripts_ for more
	information about install scripts.

*provides*
	Specifies that the package "provides" the same contents as another
	package.  There are two formats that you may use for *provides*:
	a provider name, and a provider name with version.

	Specifying a provider name with version such as _foobar=1.2_ will
	cause the package to be an "alias" of _foobar_ version _1.2_. It
	will be automatically installed if a user then runs `apk add foobar`
	or similar, and it will conflict with a package named _foobar_.

	Specifying a provider name without a version such as _baz_ will
	cause the package to provide a "virtual" called _baz_. Multiple
	packages with the same virtual provider can be installed on a system;
	however, if a user runs \`apk add baz` they will be provided a list
	of packages that provide _baz_ and must select one and install it.

*provider_priority*
	Specifies the numeric value for apk(8) to use for the package when
	considering which provider should be installed for the same *provides*
	virtual provider.

*replaces*
	Specifies packages that the package replaces. This is typically
	used for packages renamed by upstream.

*replaces_priority*
	Specifies the numeric value that is used by apk(8) when multiple
	packages with *replaces* include the same file. It is also used
	to decide which package should define the permissions of a directory
	even without *replaces* set.

*subpackages*
	Specifies subpackages or split packages built with this
	package. Typically, this will include _$pkgname-dev_ for development
	files (such as _/usr/include_ and static library files) and
	_$pkgname-doc_ for documentation (such as _/usr/share/doc_ and
	_/usr/share/man_).

	Each subpackage may be specified using three different methods. The
	first, and most common, is _$pkgname-foo_ where _foo_ is the name
	of the split function specified later in the file. Similar to the
	*package* function, the _foo_ function must move files from _$pkgdir_
	or _$srcdir_ to _$subpkgdir_ after creating _$subpkgdir_.

	The second method is to simply call the subpackage _foo_ which will
	create a package called _foo_ instead of _$pkgname-foo_.

	However, _foo_ in both of these examples cannot contain an hyphen,
	as shell function names cannot have hyphens in them. In this case,
	the third method may be used: _foo:funcname_ where _foo_ is the name
	of the subpackage and _funcname_ is the name of the shell function
	in the *APKBUILD* that creates it.

*triggers*
	Specifies a trigger script used by the package. A trigger script
	is a shell script that is called whenever monitored files or
	directories are modified.  You may specify the paths to monitor
	using the triggers variable as follows:

	```
	$pkgname.trigger=/usr/share/man:/usr/local/share/man
	```

	This will run the package trigger script whenever files in
	_/usr/share/man_ or _/usr/local/share/man_ are created, modified,
	or removed.

*options*
	The *options* variable allows you to set parameters for the package
	at build time. There are a number of valid options you may set,
	and you may set multiple options by writing a space between each one.
	Custom option names can be used when they contain exactly one _:_.
	Options can be set for a specific (sub)packages by using
	_subpkgname::option_ (or _subpkgname:option_ for custom options).

	*!archcheck*
		Specifies that the package contains binaries that cannot
		run on the target architecture. This is primarily used for
		packages containing firmware, and should typically never
		be needed.

	*bigdocs*
		Specifies that this packages intentionally has a large -doc subpackage.
		Thereby suppressing a warning to be emitted if the -doc subpackage
		exceeds a certain package size threshold (currently 2 MiB).

	*charset.alias*
		Specifies that the package ships a _/usr/lib/charset.alias_
		file and that it should be installed on the user's
		system. This is almost never the case. Do not use this option.

	*!check*
		Specifies that the package will not run a test suite. The
		reason for disabling the check phase should be noted in
		a comment.

	*checkroot*
		Specifies that this package's test suite will be run in
		fakeroot(8).  This is necessary for some test suites which
		fail when run as non-root.

	*!dbg*
		Specifies that the package should not be built with a debug
		information package. This is the default unless DEFAULT_DBG
		is set in the environment or abuild.conf(5). It is typically
		used on packages that do not generate debug information
		(such as pure Python packages) or packages that do not
		support debug information packages.

	*!fhs*
		Specifies that the package violates FHS and installs to a
		location such as _/usr/local_, _/opt_, or _/srv_.

	*ldpath-recursive*
		Specifies that abuild(1) should use the *--recursive* argument
		to scanelf(1) when attempting to find shared library (.so)
		dependencies for the package.

	*lib64*
		Specifies that the package installs files under _/lib64_
		or _/usr/lib64_ and that the test for those directories
		should be skipped.  This is discouraged and should only be
		used for packages providing compatibility for GNU libc.

	*libtool*
		Specifies that the package requires its libtool (.la)
		files. They will not be automatically removed by abuild(1).

	*net*
		Specifies that the package build system requires access
		to a network.  This is discouraged and an issue should be
		filed with the package's authors.

	*!strip*
		Specifies that strip(1) should not be run on any of the
		package's binaries. This is automatically implying if the
		_-dbg_ subpackage is enabled, or if you are using DEFAULT_DBG.

	*suid*
		Specifies that binaries in the package may be installed
		set-uid. This is a security risk and it is highly recommended
		to use capabilities or process separation instead of set-uid
		where available.

	*setcap*
		Specifies that binaries in the package may be installed
		with extra setcap(8) capabilities. If this option is enabled,
		it is highly recommended to only make these binaries executable
		by root and users of a specific group, not by others.

	*textrels*
		Specifies that the package's binaries are known to contain
		relocations against text segments. By default, abuild(1)
		will refuse to create such a package because this is a
		security concern.

	*toolchain*
		Specifies that the package is part of the base toolchain
		set and may depend on packages like _g++_.

	*!tracedeps*
		Specifies that abuild(1) should not automatically populate
		*depends* with shared library (.so) or symlink target
		dependencies.


## Automatic Variables

The following variables are defined for you by abuild(1), but may be
overridden if necessary.

*builddir*
	Specifies the directory where the source code of the package will
	be built.  The default value is _$srcdir/$pkgname-$pkgver_ which
	is appropriate for most source distributions. If the source tarball
	does not create a _$pkgname-$pkgver_ directory when it is unpacked,
	you must override *builddir*.

*pkgdir*
	Specifies the directory where the built files will be
	installed. Typically, you will call `make DESTDIR="$pkgdir" install`
	or similar to install the files. The default value is _$startdir/pkg_
	and you should not modify this variable.

*srcdir*
	Specifies the directory where the files specified in *source*
	are downloaded and unpacked. The default value is _$startdir/src_
	and you should not need to modify this.

*startdir*
	Specifies the directory where the *APKBUILD* file resides.

*subpkgdir*
	Specifies the directory where the subpackage's files should be
	placed. This variable is only set inside subpackage functions.


## Special Variables

The following variables are used only in special circumstances, and may
be required or optional depending on their usage and the contents of other
variables.

*depends_dev*
	Specifies the run-time dependencies of the _-dev_ subpackage.

*depends_doc*
	Specifies the run-time dependencies of the _-doc_ subpackage.

*depends_libs*
	Specifies the run-time dependencies of the _-libs_ subpackage.

*depends_openrc*
	Specifies the run-time dependencies of the _-openrc_ subpackage.

*depends_static*
	Specifies the run-time dependencies of the _-static_ subpackage.

*giturl*
	Specifies the URL of the Git repository to use with `abuild
	snapshot`. If the default branch of the repository is not desired,
	a different one may be specified by appending *-b* _branch_ where
	_branch_ is the branch to checkout.


## Functions

Functions specified here may be present in any *APKBUILD* file, but with
the exception of *package*, are not strictly required.

*fetch*
	This function is called to download the remote files in *source*.

*unpack*
	This function unpacks any archives in *source* to *srcdir*.

*prepare*
	Prepares the source in *srcdir* to be built. The default *prepare*
	function ensures the build directories are set up correctly and
	applies any _\*.patch_ files specified in *source*. You must call
	*default_prepare* if you write a custom *prepare* function.

*build*
	Compiles the source in *builddir*. You must implement this function
	yourself. If no compilation is required, you may omit it.

*check*
	Runs the package's test suite. This function must implemented unless
	*!check* was specified in *options*.

*package*
	Installs the package into *pkgdir*. Note that *pkgdir* is not
	created for you; if this package installs no files (for example,
	a metapackage), you must use `mkdir -p "$pkgdir"` to skip the
	package phase.


## Install Scripts

An install script is run when an action is taken on a package by apk(8). An
install script must be written in shell and must have a _#!/bin/sh_
interpreter declaration as the first line. The *install* variable must
contain the install scripts needed by the package.

The install script will be run inside the root filesystem where the package
is being installed. A single argument will be passed to call scripts, which
is the version of the package being currently installed (or deinstalled). The
pre-upgrade and post-upgrade scripts will have an additional second argument,
which specifies the version of the package before the upgrade process.

The different actions that may have install scripts specified are as follows:

*$pkgname.pre-install*
	Executed before the package is installed. If this script exits with
	an error (non-zero exit code), apk(8) will halt the installation and
	the package will not be installed. This install script is typically
	used to create any users or groups needed as described in *pkggroups*
	and *pkgusers*.

*$pkgname.post-install*
	Executed after the package is installed. If this script exits
	with an error (non-zero exit code), apk(8) will mark the package as
	broken. The `apk fix` command will attempt to re-run the post-install
	script if this occurs.

*$pkgname.pre-upgrade*
	Executed before the package is upgraded. If this script exits with
	an error (non-zero exit code), apk(8) will mark the package as broken.

*$pkgname.post-upgrade*
	Executed after the package is upgraded. If this script exits with
	an error (non-zero exit code), apk(8) will mark the package as
	broken. The `apk fix` command will attempt to re-run the post-upgrade
	script if this occurs.

*$pkgname.pre-deinstall*
	Executed before the package is removed from the system. If this
	script exits with an error (non-zero exit code), apk(8) will not
	remove the package from the system.

*$pkgname.post-deinstall*
	Executed after the package is removed from the system. Exiting with
	an error will have no effect.


# IMPLEMENTATION NOTES

Currently, *APKBUILD* files are sourced as normal shells scripts. This may
change at a later date.


# COMPATIBILITY

The abuild(1) utility as distributed by Alpine Linux uses the BusyBox
Almquist shell, a part of busybox(1) that is currently undocumented. It is
mostly compliant with IEEE Std 1003.2 (“POSIX.2”), with some bash-like
extensions. The abuild(1) utility as distributed by Adélie uses the user's
preferred /bin/sh, which is typically bash(1).


# SEE ALSO

SPDX license reference (on the Web at <https://spdx.org/licenses/>),
abuild(1), newapkbuild(1), apk(8), buildrepo(1).


# HISTORY

The *APKBUILD* format and abuild(1) utility first appeared in Alpine
Linux 1.9.


# AUTHORS

Timo Teräs <_timo.teras@iki.fi_>++
Natanael Copa <_ncopa@alpinelinux.org_>

Documentation:++
A. Wilcox <_awilfox@adelielinux.org_>

