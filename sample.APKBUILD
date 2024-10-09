# This is an example APKBUILD file. Use this as a start to creating your own,
# and remove these comments.

# Contributor: Your Name <youremail@domain.com>
maintainer="Your Name <youremail@domain.com>"
pkgname=NAME
pkgver=VERSION
pkgrel=0
pkgdesc=""
url=""
arch="all"
license="unknown"
depends=
depends_dev=
makedepends="$depends_dev"
install=
subpackages="$pkgname-dev $pkgname-doc"
source="https://downloads.sourceforge.net/NAME/NAME-$pkgver.tar.gz"

builddir="$srcdir"/$pkgname-$pkgver

prepare() {
	default_prepare
	# When needed add additional preparation below. Otherwise remove this function
}

build() {
	./configure --prefix=/usr \
		--sysconfdir=/etc \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info
	make
}

package() {
	make DESTDIR="$pkgdir" install

	# remove the 2 lines below (and this) if there is no init.d script
	# install -m755 -D "$srcdir"/$pkgname.initd "$pkgdir"/etc/init.d/$pkgname
	# install -m644 -D "$srcdir"/$pkgname.confd "$pkgdir"/etc/conf.d/$pkgname
}

check() {
	# uncomment the line below if there is a testsuite.  we assume the testsuite
	# is run using "make check", which is the default for autotools-based build systems.
	# make check
}

sha512sums="" #generate with 'abuild checksum'
