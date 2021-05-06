setup() {
	export ABUILD_KEYGEN="$PWD/../abuild-keygen"
	export ABUILD_SHAREDIR="$PWD/.."
	tmpdir="$BATS_TMPDIR"/abuild-keygen
	export ABUILD_USERDIR="$tmpdir"/user
	mkdir -p "$ABUILD_USERDIR"

	# provide a fake git
	mkdir -p "$tmpdir"/bin
	cat >"$tmpdir"/bin/git <<-EOF
		#!/bin/sh
		exit 1
	EOF
	chmod +x "$tmpdir"/bin/git
	export PATH="$tmpdir/bin:$PATH"
}

teardown() {
	rm -rf "$tmpdir"
}

@test "abuild-keygen: help text" {
	$ABUILD_KEYGEN --help
}

@test "abuild-keygen: generate key non-interactively" {
	$ABUILD_KEYGEN -n
}

@test "abuild-keygen: --append option" {
	$ABUILD_KEYGEN --append -n
	grep ^PACKAGER_PRIVKEY= "$ABUILD_USERDIR"/abuild.conf
}

@test "abuild-keygen: --install option fails without SUDO" {
	run SUDO=false $ABUILD_KEYGEN --install
	[ $status -ne 0 ]
}

