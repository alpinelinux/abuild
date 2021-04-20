setup() {
	export ABUILD_FETCH="$PWD/../abuild-fetch"

	tmpdir="$BATS_TMPDIR"/abuild-fetch
	bindir="$tmpdir"/bin
	mkdir -p "$bindir"
	export PATH="$bindir:$PATH"

	# fake curl
	cat > "$bindir"/curl <<-EOF
		#!/bin/sh

		touch \${STAMP:-"$tmpdir"/curl-invoked}
		echo "Fake curl invoked with: \$@"
		if [ -n "\$FIFO" ]; then
			echo "waiting for fifo \$FIFO"
			cat "\$FIFO"
		fi
		exit \${CURL_EXITCODE:-0}
	EOF
	chmod +x "$bindir"/curl

	# fake wget
	cat > "$bindir"/wget <<-EOF
		#!/bin/sh

		PATH=/usr/local/bin:/usr/bin:/bin
		touch "$tmpdir"/wget-invoked
		echo "Fake wget invoked with: \$@"
		exit \${WGET_EXITCODE:-0}
	EOF
	chmod +x "$bindir"/wget

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

@test "abuild-fetch: test wget fallback" {
	rm "$bindir"/curl
	PATH="$bindir" $ABUILD_FETCH -d "$tmpdir" https://example.com/non-existing
	[ -f "$tmpdir"/wget-invoked ]
}

@test "abuild-fetch: test wget fallback failure" {
	rm "$bindir"/curl
	run PATH="$bindir" WGET_EXITCODE=1 $ABUILD_FETCH -d "$tmpdir" https://example.com/non-existing
	[ $status -ne 0 ]
}

@test "abuild-fetch: test locking" {
	fifo="$tmpdir"/fifo
	mkfifo $fifo

	STAMP="$tmpdir"/stamp1 FIFO="$tmpdir"/fifo $ABUILD_FETCH -d "$tmpdir" https://example.com/foo &
	pid1=$!

	# make sure to unblock the fake curl in case test failure so we dont block bats
	teardown() {
		if [ -d /proc/$pid1 ]; then
			echo "done fifo" > "$tmpdir"/fifo
		fi
		rm -rf "$tmpdir"
	}

	ls -la "$tmpdir"

	export STAMP="$tmpdir"/stamp2
	$ABUILD_FETCH -d "$tmpdir" https://example.com/foo &
	pid2=$!
	ls -la "$tmpdir"
	# second stamp should not exist til after first abuild-fetch completes
	[ ! -f "$tmpdir"/stamp2 ]

	echo "done fifo" > "$tmpdir"/fifo
	wait $pid1
	wait $pid2
	ls -la "$tmpdir"
	[ -f "$tmpdir"/stamp2 ]
}
