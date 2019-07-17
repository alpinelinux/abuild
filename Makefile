
PACKAGE		:= abuild
VERSION		:= 3.4.0
P=$(PACKAGE)-$(VERSION)

ABUILD_DEPS	:=

prefix		?= /usr
bindir		?= $(prefix)/bin
sysconfdir	?= /etc
datadir		?= $(prefix)/share/$(PACKAGE)
mandir		?= $(prefix)/share/man

BINS		:= $(addprefix abuild-,fetch gzsplit rmtemp sudo tar)
SCRIPTS		:= abuild $(addprefix abuild-,keygen sign) abump \
		   $(addprefix apkbuild-,cpan gem-resolver pypi) \
		   apkgrel buildlab checkapk newapkbuild
USR_BIN_FILES	:= $(SCRIPTS) $(BINS)
MAN_1_PAGES	:= newapkbuild.1
MAN_5_PAGES	:= APKBUILD.5
SAMPLES		:= sample.APKBUILD sample.initd sample.confd \
		   sample.pre-install sample.post-install
AUTOTOOLS_TOOLCHAIN_FILES := config.sub config.guess

SCRIPT_SOURCES	:= $(addsuffix .in,$(SCRIPTS))

GIT_REV		:= $(shell test -d .git && git describe || echo exported)
ifneq ($(GIT_REV), exported)
FULL_VERSION    := $(patsubst $(PACKAGE)-%,%,$(GIT_REV))
FULL_VERSION    := $(patsubst v%,%,$(FULL_VERSION))
else
FULL_VERSION    := $(VERSION)
endif

CHMOD		:= chmod
SED		:= sed
TAR		:= tar
COMPILE		= $(CC) $(CPPFLAGS) $(CFLAGS) $(CFLAGS-$@) -c $^
LINK		= $(CC) -o $@ $^ $(LDFLAGS) $(LDFLAGS-$@) $(LIBS-$@)

SED_REPLACE	:= -e 's:@VERSION@:$(FULL_VERSION):g' \
			-e 's:@prefix@:$(prefix):g' \
			-e 's:@sysconfdir@:$(sysconfdir):g' \
			-e 's:@datadir@:$(datadir):g' \

ABUILD_DEPS	+= openssl-dev
SSL_CFLAGS	?= $(shell pkg-config --cflags openssl)
SSL_LDFLAGS	?= $(shell pkg-config --cflags openssl)
SSL_LIBS	?= $(shell pkg-config --libs openssl)

ABUILD_EXT	:= abuild-tar
CFLAGS-$(ABUILD_EXT).o = $(SSL_CFLAGS)
LDFLAGS-$(ABUILD_EXT) = $(SSL_LDFLAGS)
LIBS-$(ABUILD_EXT) = $(SSL_LIBS)
ABUILD_EXT	:=

ABUILD_DEPS	+= zlib-dev
ZLIB_CFLAGS	?= $(shell pkg-config --cflags zlib)
ZLIB_LDFLAGS	?= $(shell pkg-config --cflags zlib)
ZLIB_LIBS	?= $(shell pkg-config --libs zlib)

ABUILD_EXT	:= abuild-gzsplit
CFLAGS-$(ABUILD_EXT).o = $(ZLIB_CFLAGS)
LDFLAGS-$(ABUILD_EXT) = $(ZLIB_LDFLAGS)
LIBS-$(ABUILD_EXT) = $(ZLIB_LIBS)
ABUILD_EXT	:=

all: templates bins.static bins

bins: $(BINS) undeps

bins.static: $(addsuffix .static,$(BINS))

clean: mostlyclean | undeps
	@rm -f functions.sh $(SCRIPTS)
	@rm -f $(BINS) $(addsuffix .static,$(BINS))
	@rm -f $(addsuffix .o,$(BINS))

deps:
	@abuild-apk add --virtual .$(PACKAGE)-makedepends $(ABUILD_DEPS)

help:
	@echo "$(P) makefile"
	@echo "usage: make install [ DESTDIR=<path> ]"

install: abuild.conf $(SAMPLES) templates bins
	install -d $(DESTDIR)/$(bindir) $(DESTDIR)/$(sysconfdir) \
		$(DESTDIR)/$(datadir) $(DESTDIR)/$(mandir)/man1 \
		$(DESTDIR)/$(mandir)/man5
	for i in $(USR_BIN_FILES); do\
		install -v -m 755 $$i $(DESTDIR)/$(bindir)/$$i;\
	done
	chmod -c 4111 $(DESTDIR)/$(prefix)/bin/abuild-sudo
	for i in adduser addgroup apk; do \
		ln -v -fs abuild-sudo $(DESTDIR)/$(bindir)/abuild-$$i; \
	done
	for i in $(MAN_1_PAGES); do\
		install -v -m 644 $$i $(DESTDIR)/$(mandir)/man1/$$i;\
	done
	for i in $(MAN_5_PAGES); do\
		install -v -m 644 $$i $(DESTDIR)/$(mandir)/man5/$$i;\
	done
	if [ -n "$(DESTDIR)" ] || [ ! -f "/$(sysconfdir)"/abuild.conf ]; then\
		cp -v abuild.conf $(DESTDIR)/$(sysconfdir)/; \
	fi
	cp -v $(SAMPLES) $(DESTDIR)/$(prefix)/share/abuild/
	cp -v $(AUTOTOOLS_TOOLCHAIN_FILES) $(DESTDIR)/$(prefix)/share/abuild/
	cp -v functions.sh $(DESTDIR)/$(datadir)/

mostlyclean: | undeps
	@rm -f functions.sh $(SCRIPTS)
	@rm -f $(BINS) $(addsuffix .static,$(BINS))

templates: functions.sh $(SCRIPTS)

undeps:
	@abuild-apk del --purge .$(PACKAGE)-makedepends || :

.PHONY: all bins bins.static clean deps help install mostlyclean templates undeps

.gitignore: Makefile
	echo "*.tar.bz2" > $@
	for i in $(USR_BIN_FILES); do\
		echo $$i >>$@;\
	done

.SECONDARY: $(addsuffix .o,$(BINS))

%: %.c

%.o: %.c | deps
	$(COMPILE)

%.static: %.o | deps
	$(LINK) -static $(LDFLAGS-$*) $(LIBS-$*)

%:: %.in
	${SED} ${SED_REPLACE} ${SED_EXTRA} $< > $@
	${CHMOD} +x $@

%: %.o | deps
	$(LINK)

