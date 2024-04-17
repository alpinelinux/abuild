abuild(1)

# NAME

*abuild* - build an apk from an APKBUILD

# SYNOPSIS

*abuild* [options] [-P _REPODEST_] [-s _SRCDEST_] [-D _DESCRIPTION_] [cmd] ...

# DESCRIPTION

*abuild* builds an apk binary package based on an input APKBUILD(5), as well as
other related operations.

# OPTIONS

*-A*
	Print CARCH and exit

*-c*
	Enable colored output

*-d*
	Disable dependency checking

*-D*
	Set APKINDEX description (default: *$repo $(git describe)*)

*-f*
	Force specified cmd (skip checks: apk up to date, arch)

*-F*
	Force run as root

*-h*
	Show this help

*-k*
	Keep built packages, even if APKBUILD or sources are newer

*-K*
	Keep buildtime temp dirs and files (srcdir/pkgdir/deps)

*-m*
	Disable colors (monochrome)

*-P*
	Set REPODEST as the repository location for created packages

*-q*
	Quiet

*-r*
	Install missing dependencies from system repository

*-s*
	Set source package destination directory

*-v*
	Verbose: show every command as it is run (very noisy)

# COMMANDS

*all*
	Runs the entire build process. This is the default when no other command is
	specified, and is roughly an alias for *sanitycheck builddeps clean fetch
	unpack prepare mkusers build check rootpkg*.

*build*
	Compile and install package into *$pkgdir*.

*check*
	Run any defined tests concerning the package

*checksum*
	Generate checksum to be included in APKBUILD

*clean*
	Remove temp build and install dirs

*cleancache*
	Remove downloaded files from $SRCDEST

*cleanoldpkg*
	Remove binary packages except current version

*cleanpkg*
	Remove already built binary and source package

*deps*
	Install packages listed in makedepends and depends

*fetch*
	Fetch sources to $SRCDEST (consider: 'abuild fetch verify')

*index*
	Regenerate indexes in $REPODEST

*listpkg*
	List target packages

*package*
	Install project into

*prepare*
	Apply patches

*rootbld*
	Build package in clean chroot. Requires *abuild-rootbld*.

*rootpkg*
	Run 'package', the split functions and create apks as fakeroot

*sanitycheck*
	Basic sanity check of APKBUILD

*snapshot*
	Create a *$giturl* snapshot and upload to *$disturl*

*sourcecheck*
	Check if remote source package exists upstream

*srcpkg*
	Make a source package

*undeps*
	Uninstall packages listed in makedepends and depends

*unpack*
	Unpack sources to $srcdir

*up2date*
	Compare target and sources dates

*verify*
	Verify checksums

# FILES

/etc/abuild.conf
	Configuration is read from this file by default.

$HOME/.abuild/abuild.conf
	User-specific configuration is read from this file, if it exists.

# EXAMPLES

Update checksums for an APKBUILD:

```
abuild checksum
```

Build an APKBUILD and print coloured output:

```
abuild -rc
```

# SEE ALSO

SPDX license reference (on the Web at <https://spdx.org/licenses/>),
newapkbuild(1), apk(8), APKBUILD(5).

# AUTHORS

*abuild*: Natanael Copa <_ncopa@alpinelinux.org_>

Documentation:++
Hugo Osvaldo Barrera <_hugo@whynothugo.nl_>
