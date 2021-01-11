pkg_field() {
	local pkg=$1
	local field=$2

	tar xzf "$REPODEST"/testrepo/"$(arch)"/"$pkg".apk -O .PKGINFO |
		awk "/^$field =/ { print \$3 }" |
		sort
}

has_dependency() {
	local pkg=$1
	local dependency=$2

	pkg_field "$pkg" depend | grep -qx "$dependency"
}
