PATH=$(atf_get_srcdir)/..:$PATH

export ABUILD_SHAREDIR="$(atf_get_srcdir)/.."
export ABUILD_CONF="$ABUILD_SHAREDIR/abuild.conf"
export ABUILD_USERDIR="$(atf_get_srcdir)/testdata/.abuild"
unset ABUILD_USERCONF ABUILD_DEFCONF
export APK="apk --keys-dir $(atf_get_srcdir)/testdata/.abuild"
export GIT_CONFIG_GLOBAL="$(atf_get_srcdir)/testdata/gitconfig"

export CBUILD=x86_64-alpine-linux-musl
unset CBUILD_ARCH CHOST CARCH CTARGET CTARGET_ARCH

init_tests() {
	TESTS="$*"
	export TESTS
	for t; do
		atf_test_case $t
	done
}

atf_init_test_cases() {
	for t in $TESTS; do
		atf_add_test_case $t
	done
}
