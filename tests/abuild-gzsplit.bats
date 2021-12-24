setup() {
	export ABUILD_GZSPLIT="$PWD/../abuild-gzsplit"
	datadir="$PWD/testdata"
	cd "$BATS_TEST_TMPDIR"
}

@test "abuild-gzsplit: 3.11 package" {
	run $ABUILD_GZSPLIT < "$datadir"/alpine-base-3.11.6-r0.apk
	[ "$status" -eq 0 ]
}

@test "abuild-gzsplit: 3.12 package" {
	run $ABUILD_GZSPLIT < "$datadir"/alpine-base-3.12.0-r0.apk
	[ "$status" -eq 0 ]
}
