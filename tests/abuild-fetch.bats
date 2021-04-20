setup() {
	export ABUILD_FETCH="$PWD/../abuild-fetch"

	tmpdir="$BATS_TMPDIR"/abuild-fetch
	bindir="$tmpdir"/bin
	mkdir -p "$bindir"
	export PATH="$bindir:$PATH"

	# fake curl
	cat >> "$bindir"/curl <<-EOF
		#!/bin/sh

		touch "$tmpdir"/curl-invoked
		echo "Fake curl invoked with: \$@"
		exit \${CURL_EXITCODE:-0}
	EOF
	chmod +x "$bindir"/curl
}

teardown() {
	rm -rf "$tmpdir"
}

@test "abuild-fetch: help text" {
	$ABUILD_FETCH -h
}

@test "abuild-fetch: test curl invocation" {
	$ABUILD_FETCH -d "$tmpdir" https://example.com/non-existing
	[ -f "$tmpdir"/curl-invoked ]
}

@test "abuild-fetch: test curl failure" {
	run CURL_EXITCODE=1 $ABUILD_FETCH -d "$tmpdir" https://example.com/non-existing
	[ $status -ne 0 ]
}
