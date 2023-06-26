PACKAGE		:= abuild
VERSION		:= 3.11.15

prefix		?= /usr
bindir		?= $(prefix)/bin
sysconfdir	?= /etc
sharedir		?= $(prefix)/share/$(PACKAGE)
mandir		?= $(prefix)/share/man

SCRIPTS		:= abuild abuild-keygen abuild-sign newapkbuild \
		   abump apkgrel buildlab apkbuild-cpan apkbuild-pypi checkapk \
		   apkbuild-gem-resolver
USR_BIN_FILES	:= $(SCRIPTS) abuild-tar abuild-gzsplit abuild-sudo abuild-fetch abuild-rmtemp
MAN_1_PAGES	:= newapkbuild.1 abuild.1
MAN_5_PAGES	:= APKBUILD.5
SAMPLES		:= sample.APKBUILD sample.initd sample.confd \
		sample.pre-install sample.post-install
MAN_PAGES	:= $(MAN_1_PAGES) $(MAN_5_PAGES)
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
SCDOC		:= scdoc
LINK		= $(CC) $(OBJS-$@) -o $@ $(LDFLAGS) $(LDFLAGS-$@) $(LIBS-$@)

CFLAGS		?= -Wall -Werror -g -pedantic

SED_REPLACE	:= -e 's:@VERSION@:$(FULL_VERSION):g' \
			-e 's:@prefix@:$(prefix):g' \
			-e 's:@sysconfdir@:$(sysconfdir):g' \
			-e 's:@sharedir@:$(sharedir):g' \

SSL_CFLAGS	?= $(shell pkg-config --cflags openssl)
SSL_LDFLAGS	?= $(shell pkg-config --cflags openssl)
SSL_LIBS	?= $(shell pkg-config --libs openssl)
ZLIB_LIBS	?= $(shell pkg-config --libs zlib)

OBJS-abuild-tar  = abuild-tar.o
CFLAGS-abuild-tar.o = $(SSL_CFLAGS)
LDFLAGS-abuild-tar = $(SSL_LDFLAGS)
LIBS-abuild-tar = $(SSL_LIBS)
LIBS-abuild-tar.static = $(LIBS-abuild-tar)

OBJS-abuild-gzsplit = abuild-gzsplit.o
LDFLAGS-abuild-gzsplit = $(ZLIB_LIBS)

OBJS-abuild-sudo = abuild-sudo.o
OBJS-abuild-fetch = abuild-fetch.o

TEST_TIMEOUT = 15

.SUFFIXES:	.conf.in .sh.in .in
%.conf: %.conf.in
	${SED} ${SED_REPLACE} ${SED_EXTRA} $< > $@

%.sh: %.sh.in
	${SED} ${SED_REPLACE} ${SED_EXTRA} $< > $@
	${CHMOD} +x $@

%: %.in
	${SED} ${SED_REPLACE} ${SED_EXTRA} $< > $@
	${CHMOD} +x $@

%.1: %.1.scd
	${SCDOC} < $< > $@

%.5: %.5.scd
	${SCDOC} < $< > $@

P=$(PACKAGE)-$(VERSION)

all:	$(USR_BIN_FILES) $(MAN_PAGES) functions.sh abuild.conf

clean:
	@rm -f $(USR_BIN_FILES) $(MAN_PAGES) *.o functions.sh abuild.conf Kyuafile \
		tests/Kyuafile tests/testdata/abuild.key*

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(CFLAGS-$@) -o $@ -c $<

abuild-sudo: abuild-sudo.o
	$(LINK)

abuild-tar: abuild-tar.o
	$(LINK)

abuild-fetch: abuild-fetch.o
	$(LINK)

abuild-gzsplit: abuild-gzsplit.o
	$(LINK)

abuild-tar.static: abuild-tar.o
	$(CC) -static $(CPPFLAGS) $(CFLAGS) $(CFLAGS-$@) $^ -o $@ $(LIBS-$@)

help:
	@echo "$(P) makefile"
	@echo "usage: make install [ DESTDIR=<path> ]"

tests/testdata/abuild.key:
	openssl genrsa -out "$@" 4096

tests/testdata/abuild.key.pub: tests/testdata/abuild.key
	openssl rsa -in "$<" -pubout -out "$@"

tests/Kyuafile: $(wildcard tests/*_test)
	echo "syntax(2)" > $@
	echo "test_suite('abuild')" >> $@
	for i in $(notdir $(wildcard tests/*_test)); do \
		echo "atf_test_program{name='$$i',timeout=$(TEST_TIMEOUT)}" >> $@ ; \
	done

Kyuafile: tests/Kyuafile
	echo "syntax(2)" > $@
	echo "test_suite('abuild')" >> $@
	echo "include('tests/Kyuafile')" >> $@

check: $(SCRIPTS) $(USR_BIN_FILES) functions.sh tests/Kyuafile Kyuafile tests/testdata/abuild.key.pub
	kyua test || (kyua report --verbose && exit 1)

install: $(USR_BIN_FILES) $(SAMPLES) $(MAN_PAGES) default.conf abuild.conf functions.sh
	install -d $(DESTDIR)/$(bindir) $(DESTDIR)/$(sysconfdir) \
		$(DESTDIR)/$(sharedir) $(DESTDIR)/$(mandir)/man1 \
		$(DESTDIR)/$(mandir)/man5
	for i in $(USR_BIN_FILES); do\
		install -m 755 $$i $(DESTDIR)/$(bindir)/$$i;\
	done
	chmod 4555 $(DESTDIR)/$(prefix)/bin/abuild-sudo
	for i in adduser addgroup apk; do \
		ln -fs abuild-sudo $(DESTDIR)/$(bindir)/abuild-$$i; \
	done
	for i in $(MAN_1_PAGES); do\
		install -m 644 $$i $(DESTDIR)/$(mandir)/man1/$$i;\
	done
	for i in $(MAN_5_PAGES); do\
		install -m 644 $$i $(DESTDIR)/$(mandir)/man5/$$i;\
	done
	if [ -n "$(DESTDIR)" ] || [ ! -f "/$(sysconfdir)"/abuild.conf ]; then\
		install -t $(DESTDIR)/$(sysconfdir)/ abuild.conf; \
	fi

	install -t $(DESTDIR)/$(prefix)/share/abuild/ $(SAMPLES)
	install -t $(DESTDIR)/$(prefix)/share/abuild/ $(AUTOTOOLS_TOOLCHAIN_FILES)
	install -t $(DESTDIR)/$(sharedir)/ functions.sh default.conf

depends depend:
	sudo apk --no-cache -U --virtual .abuild-depends add openssl-dev zlib-dev

.gitignore: Makefile
	echo "*.tar.bz2" > $@
	for i in $(USR_BIN_FILES); do\
		echo $$i >>$@;\
	done


.PHONY: install
