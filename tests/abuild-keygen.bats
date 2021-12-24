setup() {
	export ABUILD_KEYGEN="$PWD/../abuild-keygen"
	export ABUILD_SHAREDIR="$PWD/.."
	export ABUILD_USERDIR="$BATS_TEST_TMPDIR"/user
	mkdir -p "$ABUILD_USERDIR"
	export abuild_keygen_install_root=${ABUILD_USERDIR}

	# provide a fake git
	mkdir -p "$BATS_TEST_TMPDIR"/bin
	cat >"$BATS_TEST_TMPDIR"/bin/git <<-EOF
		#!/bin/sh
		exit 1
	EOF
	chmod +x "$BATS_TEST_TMPDIR"/bin/git
	export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "abuild-keygen: help text" {
	$ABUILD_KEYGEN --help
}

@test "abuild-keygen: generate key non-interactively" {
	$ABUILD_KEYGEN -n
}

@test "abuild-keygen: --append option" {
	PACKAGER="Test User <user@example.com>" $ABUILD_KEYGEN --append -n
	grep '^PACKAGER_PRIVKEY=.*user@example.com' "$ABUILD_USERDIR"/abuild.conf
}

@test "abuild-keygen: --install option fails without SUDO" {
	run SUDO=false $ABUILD_KEYGEN --install
	[ $status -ne 0 ]
}

@test "abuild-keygen: --install option (interactive)" {
	echo | SUDO= $ABUILD_KEYGEN --install
}

@test "abuild-keygen: --install -n (non-interacive)" {
	SUDO= $ABUILD_KEYGEN --install -n
}

