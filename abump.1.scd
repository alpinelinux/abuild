abump(1)

# NAME

*abump* - bump pkgver in an APKBUILD file

# SYNOPSIS

*abump* [-s _CVE-1_,...] [-m _MESSAGE_] [-f _ISSUE_] [-p _REMOTE_] [-b|--branch] [-k|--keep] [-r|--rootbld] _PKGNAME-1.2.3_

# DESCRIPTION

*abump* updates the *pkgver* in an APKBUILD file, updates its checksums,
rebuilds it, and finally creates a new commit with the changes resulting.

*abump* looks for the specified package in nested directories inside the current
working directory, assuming a layout like that of the aports repository.

# OPTIONS

*-s, --security CVE1,...*
	Include CVE in the *secfixes* comment section.

*-m, --message MESSAGE*
	Include the given *MESSAGE* in the commit message body.

*-f, --fixes ISSUE*
	Include *Fixes #ISSUE* in the commit message. This will close the upstream
	issue when the commit is merged into the aports master branch.

*-p, --push REMOTE*
	Push the commit and resulting changes to the specified *REMOTE* (e.g. *origin*).

*-b, --branch*
	Create a git branch from HEAD before normal operation.

*-k, --keep*
	Keep existing packages.

*-r, --rootbld*
	Build package in a clean chroot using *abuild rootbld* instead of
	*abuild all*.

*-h, --help*
	Print help information and exit.

# ENVIRONMENT

APORTSDIR
	Force operating on an alternate directory.

# EXAMPLES

```
abump mml-1.0.0
abump glibmm2.68-2.78.0
abump telegram-desktop-4.11.8
```

# SEE ALSO

abuild(1), apkgrel(1), newapkbuild(1), APKBUILD(5), apk(8), checkapk(1).

# AUTHORS

Natanael Copa <_ncopa@alpinelinux.org_> and open source contributors.
