APKBUILD(5)

# NAME

*APKBUILD* - metadata and instructions to build packages


# DESCRIPTION

An *APKBUILD* file is used by tools such as abuild(1) to build packages for
eventual installation by the apk(8) package manager. It defines metadata such
as the name of packages, the version information, the source license,
and contact information for the developer. It additionally contains the
commands needed to build, test, and install files.

## Syntax and Environment

The *APKBUILD* format is based on the shell command language as specified
in IEEE Std 1003.1-2017 ("POSIX.1-2017"). The *APKBUILD* is sourced into
a prepared shell environment (or evaluated in a way that is equivalent).
The resulting shell environment is referred to as "global environment".
The variables and functions set in the global environment are used by for
example abuild(1) to create packages.

Depending on the implementation different shell extensions might be available
or allowed. The abuild(1) utility as distributed by Alpine Linux uses the
BusyBox Almquist shell, a part of busybox(1) that is currently undocumented.
It is mostly POSIX.1-2017 compliant, with some bash-like extensions. The
abuild(1) utility as distributed by Adélie uses the user's preferred /bin/sh,
which may be bash(1) or dash(1).

After an *APKBUILD* was sourced or an implemented function was run the
shell environment should not be changed in ways not explicitly allowed
here. For example it should not return with a changed *umask*, *set -f*
or *IFS*. When an *APKBUILD* is sourced it should not use external
commands, predefined functions or source additional files.

When an *APKBUILD* is sourced or an implemented function is run the
shell environment may be assumed to use *set -e* and *umask 0022*.

## Variables

The following variables may be set in the global environment. Unless
otherwise specified these variables must not be changed after the
*APKBUILD* was initially sourced. An *APKBUILD* may assume these variables
to be unset/empty when the *APKBUILD* is sourced. Unless otherwise specified
a "list" variable has it's elements seperated by space, tab and/or newline characters
(same as the default *IFS* value). Unless otherwise specified the values
of variables may vary depending on the value of predefined variables.

An *APKBUILD* may set other variables but their name must ether start
with an underscore, start with an uppercase character and be exported
or be set with the *local* shell extension.

*maintainer*
	The name and email of the *APKBUILD* maintainer in RFC 2822 format.
	This may be set through a maintainer comment instead:

	```
	# Maintainer: Joe Q. Public <john.q.public@example.com>
	```

*pkgname*
	Specifies the name of the main package. Must be set to a valid package
	name according to apk-package(5). This is typically the name of the
	package upstream; however, note that all letters should be lowercased.

	Libraries for scripting languages should have a prefix before the
	library name describing the language. Such prefixes include _lua-_,
	_perl-_, _py3-_, and _rb-_. Not all languages use prefixes.

*pkgver*
	Must be set to a non-empty value that specifies the version of the
	software being packaged. The version of a package must consist of one
	or more numbers separated by the radix (decimal point). The final
	number may have a single letter following it, for upstreams that use
	such a versioning scheme (such as 1.5a, 1.5b, 1.5c).

	After the final number (and optional single letter), one or more
	suffixes may be appended, which must be an underscore (\_) followed
	by one of _alpha_, _beta_, _pre_, _rc_, _cvs_, _svn_, _git_, _hg_, or
	_p_, optionally followed by another number. If a suffix is _alpha_,
	_beta_, _pre_, or _rc_, it is considered to be earlier than the
	version without this suffix; if a suffix is _cvs_, _svn, _git_, _hg_,
	or _p_, it is considered to be later than the version without this
	suffix. All of the following examples are valid versions, in order
	from lowest to highest:

	1.0, 1.1_alpha2, 1.1.3_pre, 1.1.3_pre_p2, 1.1.3, 1.1.3_hg, 1.2, 1.2a, 1.2b

*pkgrel*
	Must be set to an unsigned integer that specifies the *APKBUILD* release
	number of this particular *APKBUILD* version. This indicates when a
	*APKBUILD* has changed without a corresponding change in version. Always
	increment *pkgrel* when the resulting packages change. The first
	release of a *APKBUILD* is always 0.

*pkgdesc*
	Must be set to a non-empty value the specifies what the package
	contains. *pkgdesc* must be 128 characters or less, and should
	concisely describe what actions the software or items being package
	will allow the user to perform. For example,
	"Fully-featured word processor with spell check and plugins"
	would be a sufficient *pkgdesc* for AbiWord.

*url*
	Must be set to a non-empty value that specifies the Web address of
	the package's upstream. This should allow users and future maintainers
	to find documentation, release information, and contact information
	for the package.

*arch*
	Specifies on which architectures the *APKBUILD* may be built. It
	is highly recommended that you set this variable to "_all_" if the
	software is portable.

	*arch* may be ether a disallow list that includes one of _all_ or
	_noarch_ and the rest being architecture names prefixed with _!_.
	E.g. _arch="all !ppc64le"_ means that the *APKBUILD* is allowed to be
	built on all architectures except for ppc64le.

	When _noarch_ is used instead of _all_ it indicates that a package does
	not contain any architecture specific files. Such packages may include
	pure Python packages, shell script packages, and JARs. If you are not
	sure what this means, using _all_ is safe.

	Alternatively *arch* may be an allow list that includes a list of
	architecture names. Consequently when *arch* is empty the *APKBUILD*
	is not enabled on any arch.

*license*
	Specifies the license under which the package is distributed. It
	must be set to a SPDX license expression.

*depends*
	List of run-time dependencies of the package.

*depends_lang*, *depends_doc*, *depends_dev*, *depends_static*,
*depends_libs*, *depends_openrc*, *depends_systemd*, *depends_udev*
	Default *depends* value used by the predefined functions named
	*default_${name#depends_}* (eg. *default_lang* uses *depends="$depends_lang"*).
	These variables should not be used when the respective function is not
	(directly or indirectly) used.

*makedepends*
	List of build dependencies for the package. Defaults to
	*$makedepends_build $makedepends_host*.

*makedepends_build*
	List of build dependencies for the *CBUILD* machine, installed
	without *--root*.

*makedepends_host*
	List of build dependencies for the *CHOST* machine, installed into
	*CBUILDROOT*.

*checkdepends*
	List of test-time dependencies of the package. Common packages that
	are used for testing include check, dejagnu, and perl-test-command.
	Installed if *check* will be run (see *want_check*).

*pkggroups*
	List of login groups to create during build-time. Note that you will
	need to create the login groups in a pre-install script as well; see
	_Install Scripts_ for more information about install scripts.

*pkgusers*
	List of user logins to create during build-time. Note that you will
	need to create the user logins in a pre-install install script as well;
	see _Install Scripts_ for more information about install scripts.

*provides*
	List of providers that the package may be referred to in addition
	to *$pkgname=$pkgver-r$pkgrel*.

	Specifying a provider with version such as _foobar=1.2_ will
	cause the package to be an "alias" of _foobar_ version _1.2_. It
	will be automatically installed if a user then runs `apk add foobar`
	or similar, and it will conflict with a package named _foobar_.

	Specifying a provider without a version such as _baz_ will
	cause the package to provide a "virtual" called _baz_. Multiple
	packages with the same virtual provider can be installed on a system;
	however, if a user runs `apk add baz` they will be provided a list
	of packages that provide _baz_ and must select one and install it.

*provider_priority*
	An unsigned integer for apk(8) to use when considering which provider
	should be installed for the same *provides* virtual provider.

*replaces*
	List of packages that the package should replace files from when
	both are installed.

*replaces_priority*
	Specifies an unsigned integer that is used by apk(8) when multiple
	packages with *replaces* include the same file. It is also used
	to decide which package should define the permissions of a directory
	even without *replaces* set.

*install_if*
	List of conditions when apk(8) should automatically install the
	(sub)package. For instance, the *default_openrc* split function set

	```
	install_if="openrc ${subpkgname%-openrc}=$pkgver-r$pkgrel"
	```

	which means that the subpackage will be automatically installed if
	both *openrc* and the *${subpkgname%-openrc}* package are installed.

*install*
	List of install scripts for the package, if any. See _Install
	Scripts_ for more information about install scripts.

*triggers*
	List of trigger scripts used by the specified (sub)packages. A
	trigger script is a shell script that is called whenever monitored
	files or directories are modified. You may specify the paths to
	monitor using the triggers variable as follows:

	```
	$pkgname.trigger=/usr/share/man:/usr/local/share/man
	```

	This will run the trigger script for _$pkgname_ whenever files in
	_/usr/share/man_ or _/usr/local/share/man_ are created, modified,
	or removed.

*subpackages*
	List of subpackage descriptions with the following syntax:
	*subpkgname*[:[*splitfunc*][:[all|noarch|*triplet*]]] ++
	Typically, this will include _$pkgname-dev_ for development
	files (such as _/usr/include_ and pc(5) files) and
	_$pkgname-doc_ for documentation (such as _/usr/share/doc_ and
	_/usr/share/man_).

	By default the split function name is the end of the package name after
	the last hyphen. Eg. for _$pkgname-foo_ and _libfoo_ the split functions
	are _foo_ and _libfoo_ respectively. When the package name ends with
	*-bash-completion*, *-zsh-completion* or *-fish-completion* the default
	split function name is *bashcomp*, *zshcomp*, *fishcomp* respectively
	instead. A custom split function name may be set by using _foo:funcname_.

	By default *arch* determines whether or not a subpackage is considered
	arch independant or not. Subpackages ending in *-doc*, *-openrc*,
	*-lang*, *sh-completion*, *-pyc*, *-nftrules*, *-systemd* or *-udev*
	default to being arch independant regardless of *arch*. This may be
	changed by using _foo::noarch_ or _foo:funcname:all_.

	If mandatory a subpackage may be specified with _foo::$CBUILD_ or
	_foo::$CTARGET_ to specify that the subpackage is architecture
	dependant and not for *CHOST*. This is should normally not be used.

	When multiple subpackages are specified their split functions are
	executed in the order in which they occur in *subpackages*.

	When used the _$pkgname-dbg_ subpackage should be the first one
	and _$pkgname-static_ should be placed before _$pkgname-dev_.

*source*
	List of local and remote files. Local files are specified through
	the file name and should be present in the same directory as the
	*APKBUILD*. Remote files are specified by an URL using the http, https
	or ftp scheme which is optionally prefixed with *filename::*. The
	default file name for remote files is the text after the last slash
	in the URL. The resulting value must not vary depending on the
	environment (eg. *CHOST*) that the *APKBUILD* was sourced with.
	Typically *source* will be a remote source archive followed by local
	patches, and configuration files.

*builddir*
	Specifies the directory where the source code of the package will
	be built. The default value is _$srcdir/$pkgname-$pkgver_. The
	directory should either be *srcdir* or be inside of *srcdir*. The
	directory must exist before *default_prepare* is called. This should
	be set to a value that avoids usage of *cd* and absolute paths in
	*build*, *check* and *package* if the default value is not adequate.

*options*
	List of options for the entire *APKBUILD*. Each option should be
	in the list below or contain exactly one _:_ to indicate that it is a
	custom option. Options may be set for a specific (sub)packages by using
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
		fakeroot(8). This is necessary for some test suites which
		fail when run as non-root.

	*!dbg*
		Specifies that the package should not be built with a debug
		information package. This option only has an effect when DEFAULT_DBG
		has been set for abuild(1) and the package is not *noarch*. This
		may be used for packages with signed binaries.

	*!fhs*
		Specifies that the package violates FHS and installs to a
		location such as _/usr/local_, _/opt_, or _/srv_.

	*ldpath-recursive*
		Specifies that abuild(1) should use the *--recursive* argument
		to scanelf(1) when attempting to find shared library (.so)
		dependencies for the package. See also *ldpath*.

	*lib64*
		Specifies that the package installs files under _/lib64_
		or _/usr/lib64_ and that the test for those directories
		should be skipped. This is discouraged and should only be
		used for packages providing compatibility for GNU libc.

	*libtool*
		Specifies that the package requires its libtool (.la)
		files. They will not be automatically removed by abuild(1).

	*net*
		Specifies that the package build system requires access
		to a network. This is discouraged and an issue should be
		filed with the package's authors.

	*!strip*
		Specifies that strip(1) should not be run on any of the
		package's binaries. In abuild(1) this is implied if the DEBUG
		variable is set.

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
		*depends* and *provides* with shared library (.so), symlink
		target dependencies and similar.

	*sover-namecheck*
		May be removed in the future.

*ldpath*
	Colon seperated list of directory paths that should be searched for
	shared objects. These are not searched recursively unless the
	*ldpath-recursive* option is specified.
	abuild(1) always searches _/usr/lib_, _/lib_ and paths referenced by
	DT_RPATH/DT_RUNPATH.

*sonameprefix*
	Used to namespace traced soname providers: *so:$sonameprefix$soname*.
	When set to a non-empty value it should end with a colon.

*pcprefix*
	Used to namespace traced pc(5) providers: *pc:$pcprefix$pcname*.
	When set to a non-empty value it should end with a colon.

*langdir*
	Used by *default_lang* to amove language files. Defaults to
	*/usr/share/locale*.

*somask*
	List of sonames that will be ignored when tracing providers and
	dependencies of shared objects.

*giturl*
	URL of the Git repository to use with `abuild snapshot`. If the default
	branch of the repository is not desired, a different one may be specified by
	appending *-b* _branch_ where _branch_ is the branch to checkout.
	This should typically not be used.

*disturl*
	URL to an rsync server which will be used by `abuild snapshot` to
	upload the generated archive to. This should typically not be used.

*reporev*
	git revision that `abuild snapshot` generates the archive for. This
	should typically not be used.

*sha512sums*
	Variable generated by *abuild checksum* and used by *fetch* to verify
	the hashes of remote files. It must be at the end of the *APKBUILD* file
	for *abuild checksum* to work and should not be manually written.

## Predefined Variables

The following variables are defined for you by abuild(1) and must not
be overridden or unset.

*pkgdir*
	The absolute path to the directory where the built files will be
	installed. Typically, an APKBUILD calls `make DESTDIR="$pkgdir" install`
	or similar to install the files.

*srcdir*
	The absolute path to the directory where the files specified in *source*
	are symlinked and unpacked to.

*tmpdir*
	The absolute path to a directory that may be used for temporary files
	and is automatically cleaned up. This should be used instead of
	mktemp(1), /tmp, *TMPDIR* or similar.

*startdir*
	The absolute path to the directory where the *APKBUILD* file resides.
	This should normally not be used.

*APKBUILD*
	Specifies the absolute path of the *APKBUILD* file itself. This should
	normally not be used.

*subpkgname*
	Specifies the name of the current subpackage. This variable is only
	set when a split function is invoked.

*subpkgdir*
	Specifies the directory where the subpackage's files should be
	placed. This variable is only set when a split function is invoked.

*subpkgarch*
	The architecture for the current subpackage. This variable is
	only set when a split function is invoked. This should normally not be
	used.

*subpkgtriplet*
	The triplet that the current subpackage is for. This variable is
	only set when a split function is invoked. This should normally not be
	used.

*CBUILD*, *CHOST*, *CTARGET*
	Triplets of machines. See abuild(1) for more details.

*CBUILD_ARCH*, *CARCH*, *CTARGET_ARCH*
	Specifies the architecture of *CBUILD*, *CHOST*, *CTARGET* respectively.

*BOOTSTRAP*
	See abuild(1). This should normally not be used.

*SOURCE_DATE_EPOCH*
	Timestamp for reproducible builds. When *prepare*, *build*,
	*check*, *package* or split function is invoked this is always set.
	This variable is always exported.

## Functions

Functions specified here may be implemented in the global environment.
An *APKBUILD* may implement other functions but their names should start
with an underscore. Between external invocation of functions the shell
environment may be reset to the global environment.

*fetch*
	The default implementation is a single call to *default_fetch*. This
	function should not be overwritten. Instead use *prepare* and *net*
	in *options*.

*unpack*
	The default implementation is a single call to *default_unpack*. This
	function should not be overwritten. Instead use *prepare*.

*prepare*
	Prepares the source in *srcdir* and *builddir* to be built. The default
	implementation is a single call of *default_prepare*. You must call
	*default_prepare* if you write a custom *prepare* function.

	A custom *prepare* function may call *update_config_sub* or
	*update_config_guess* to update *config.sub* and *config.guess* files
	respectively.

*build*
	Compiles the source in *builddir*. The default implementation does
	nothing.

*check*
	Runs the package's test suite. This function must be implemented unless
	*!check* was specified in *options*. It may be implemented even when
	*!check* is specified in *options*. Whether or not this function is
	run should not effect the resulting package.

*package*
	Install files from *srcdir* or *builddir* to *pkgdir*. This function
	must be implemented. Note that *pkgdir* is not created for you; if
	this package installs no files (for example, a metapackage), you must
	use `mkdir -p "$pkgdir"`. If mandatory the *package* function may
	append generated dependencies or providers to *depends*, *provides*.

*split functions*
	Functions with names as specified by *subpackages*. It should move
	files from *pkgdir*, *srcdir* or *builddir* to *subpkgdir*. The default
	working directory is *pkgdir*. It must create *subpkgdir*. A split
	function may set *pkgdesc*, *url*, *license*, *depends*, *install_if*,
	*provides*, *provider_priority*, *replaces*, *replaces_priority* to
	change the value for the current subpackage. By default *provides*
	and *install_if* is emptied for subpackages, *depends* may be emptied
	in the future.

*lang*, *doc*, *dbg*, *dev*, *static*, *libs*, *openrc*, *systemd*,
*udev*, *devhelp*, *bashcomp*, *zshcomp*, *fishcomp*, *pyc*, *nftables*
	Special split functions in the sense that they have a default
	implementation that call *default_<name>*. These should typically not
	need to be overwritten.

## Predefined Functions

The following functions may be (directly or indirectly) used in an
*APKBUILD* but must not be overwritten or unset.

*default_fetch*
	When called in *fetch* it fetches remote files specified in *source*
	and verifies their hashes with *sha512sums*.

*default_unpack*
	When called in *unpack* it unpacks archives from *source* into *srcdir*.

*default_prepare*
	When called in *prepare* it changes the working directory to *builddir*
	and applies all _\*.patch_, _\*.patch.gz_ and _\*.patch.xz_ files
	specified in *source*. Implementation may differ slightly.

*want_check*
	Returns 0 if the *check* function will be run and 1 otherwise. The
	return value should not effect the resulting packages.

*amove*
	Inside of split functions this moves the given file hierarchies from
	*pkgdir* or the current working directory to *subpkgdir*, creating
	directories as needed. The created directories may not have the same
	attributes as the original ones.

*default_lang*, *default_doc*, *default_dbg*, *default_dev*,
*default_static*, *default_libs*, *default_openrc*, *default_systemd*,
*default_udev*, *default_devhelp*, *default_bashcomp*, *default_zshcomp*,
*default_fishcomp*, *default_pyc*, *default_nftables*
	Move common files and set common variables in a split function.
	*depends* is typically set to the value of *depends_${name#default_}*
	(eg. *default_lang* uses *depends="$depends_lang"*). They may override
	or change variables set in the split function before calling *default_\**.

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


# SEE ALSO

SPDX license reference (on the Web at <https://spdx.org/licenses/>),
abuild(1), newapkbuild(1), apk(8), buildrepo(1), ap(1), checkapk(1).


# HISTORY

The *APKBUILD* format and abuild(1) utility first appeared in Alpine
Linux 1.9.


# AUTHORS

Timo Teräs <_timo.teras@iki.fi_>++
Natanael Copa <_ncopa@alpinelinux.org_>

Documentation:++
A. Wilcox <_awilfox@adelielinux.org_>

