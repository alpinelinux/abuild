setup() {
	export ABUILD_KEYGEN="$PWD/../abuild-keygen"
	export ABUILD_SHAREDIR="$PWD/.."
	tmpdir="$BATS_TMPDIR"/abuild-keygen
	export ABUILD_USERDIR="$tmpdir"/user
	export PACKAGER="Test User <user@example.com>"
	mkdir -p "$ABUILD_USERDIR"
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

