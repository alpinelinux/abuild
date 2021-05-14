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
		echo "[\$\$] Fake curl invoked with: \$@"
		if [ -n "\$FIFO" ]; then
			echo "[\$\$] waiting for fifo \$FIFO"
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

@test "abuild-fetch: that --insecure is passed for http://" {
	$ABUILD_FETCH -d "$tmpdir" http://example.com/non-existing | grep insecure
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

@test "abuild-fetch: test that --no-check-certificate is passed to wget fallback with http://" {
	rm "$bindir"/curl
	PATH="$bindir" $ABUILD_FETCH -d "$tmpdir" http://example.com/non-existing | grep no-check-certificate
}

@test "abuild-fetch: test locking" {
	fifo1="$tmpdir"/fifo1
	fifo2="$tmpdir"/fifo2
	mkfifo $fifo1 $fifo2

	# make sure to unblock the fake curl in case test failure so we dont block bats
	teardown() {
		if [ -d /proc/$pid1 ]; then
			echo "done fifo1" > "$tmpdir"/fifo1
		fi
		if [ -d /proc/$pid2 ]; then
			echo "done fifo2" > "$tmpdir"/fifo2
		fi
		rm -rf "$tmpdir"
	}

	CURL_EXITCODE=1 STAMP="$tmpdir"/stamp1 FIFO="$tmpdir"/fifo1 $ABUILD_FETCH -d "$tmpdir" https://example.com/foo &
	pid1=$!

	# wait til curl is called
	while !  [ -f "$tmpdir"/stamp1 ]; do
		sleep 0.1
	done

	# try a second fetch, while the first one is still running
	STAMP="$tmpdir"/stamp2 FIFO="$tmpdir"/fifo2 $ABUILD_FETCH -d "$tmpdir" https://example.com/foo &
	pid2=$!
	ls -la "$tmpdir"
	# second stamp should not exist til after first abuild-fetch completes
	[ ! -f "$tmpdir"/stamp2 ]

	# tell curl to similuate download complete of first
	echo "done fifo1" > "$tmpdir"/fifo1
	run wait $pid1
	[ $status -ne 0 ]

	# wait til second instance gets lock to simulate download start
	while ! [ -f "$tmpdir"/stamp2 ]; do
		sleep 0.1
	done

	# first instance is done. lets retry download. second instance should block us
	rm "$tmpdir"/stamp1
	STAMP="$tmpdir"/stamp1 FIFO="$tmpdir"/fifo1 $ABUILD_FETCH -d "$tmpdir" https://example.com/foo &
	pid1=$!

	sleep 0.2
	# the first stamp should not exist, second instance should block the retry
	# skip this test on s390x, due to sleep(0) not working there
	if [ "$(uname -m)" != "s390x" ]; then
		[ ! -f "$tmpdir"/stamp1 ]
	fi

	# simulate second download finished
	echo "done fifo2" > "$tmpdir"/fifo2
	wait $pid2

	# first should get unblocked
	echo "done fifo1" > "$tmpdir"/fifo1
	wait $pid1

	# verify that first actually called curl
	[ -f "$tmpdir"/stamp1 ]

	ls -la "$tmpdir"
}
