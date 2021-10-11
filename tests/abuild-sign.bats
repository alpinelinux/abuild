#/usr/bin/env bats

setup() {
	export ABUILD="$PWD/../abuild"
	export ABUILD_SHAREDIR="$PWD/.."
	export ABUILD_CONF=/dev/null
	tmpdir="$BATS_TMPDIR"/abuild
	export REPODEST="$tmpdir"/packages
	export CLEANUP="srcdir bldroot pkgdir deps"
	export WORKDIR="$tmpdir"/work
	export APORTSDIR="$PWD"/testrepo
	export PATH="$PWD/../:$PATH"
	export ARCH=$(apk --print-arch)

	abuild-keygen -ain >/dev/null 2>&1

	mkdir -p "$tmpdir" "$WORKDIR"
}

teardown() {
	rm -rf "$tmpdir"
}

@test 'abuild-sign: do not record user name/id in index' {
	cd testrepo/pkg1
	$ABUILD

	tar tvzf "$REPODEST"/testrepo/"$ARCH"/APKINDEX.tar.gz --numeric-owner|
		while read -r _ user _ _ _ f; do
			if [ "$user" != "0/0" ]; then
				echo "file '$f' is not owned by 0/0 (owned by $user)" >&2
				exit 1
			fi
		done
}
