# MagicPO makefile
# $Id$

VERSION=0.4
MYVERSION=$(VERSION)

ifndef prefix
# This little trick ensures that make install will succeed both for a local
# user and for root. It will also succeed for distro installs as long as
# prefix is set by the builder.
prefix=$(shell perl -e 'if($$< == 0 or $$> == 0) { print "/usr" } else { print "$$ENV{HOME}/.local"}')
endif

BINDIR ?= $(prefix)/bin
DATADIR ?= $(prefix)/share
mandir ?= $(prefix)/share/man
# Create the manpage if required
POD2MAN = $(shell [ ! -e "./magicpo.1" ] && echo man)
ifneq ($(POD2MAN), man)
POD2MAN = $(shell [ ! -e "./magicpo.dict.5" ] && echo man)
endif
# Extract the svn revision from the Id string
SVNREV=$(shell perl -e "\$$_ = '$$Id$$';s/^\S+\s+\S+\s+(\d+)\s+.*$$/\$$1/;s/\D//g;print")

# Install magicpo
install: $(POD2MAN)
	mkdir -p "$(BINDIR)"
	mkdir -p "$(DATADIR)/magicpo"
	cp -f magicpo "$(DATADIR)/magicpo/"
	cp -f gtk-magicpo "$(DATADIR)/magicpo/"
	ln -sf "$(DATADIR)/magicpo/magicpo" "$(DATADIR)/magicpo/gtk-magicpo" "$(BINDIR)"
	cp -rf dictionaries modules "$(DATADIR)/magicpo"
	mkdir -p "$(mandir)/man1"
	mkdir -p "$(mandir)/man5"
	cp -f magicpo.1 "$(mandir)/man1/"
	cp -f magicpo.dict.5 "$(mandir)/man5/"
	chmod 755 "$(BINDIR)/magicpo"
# Uninstall an installed magicpo
uninstall:
	rm -f "$(BINDIR)/magicpo" "$(BINDIR)/gtk-magicpo"
	rm -rf "$(DATADIR)/magicpo"
# Clean up the tree
clean:
	rm -f `find|egrep '~$$'`
	rm -f *.po
	rm -f *.tmp
	rm -f magicpo-$(MYVERSION).tar.bz2 magicpo-svnsnapshot.tar.bz2
	rm -rf magicpo-$(MYVERSION) magicpo-$(MYVERSION)-*svn
# Verify syntax and run automated tests
test:
	@perl -Imodules -c modules/MagicPO/Parser.pm
	@perl -Imodules -c modules/MagicPO/DictLoader.pm
	@perl -Imodules -c modules/MagicPO/Magic.pm
	@perl -Imodules -c modules/MagicPO/TransDB.pm
	@perl -c magicpo
	@perl -c gtk-magicpo
	@perl -c tools/dictlint
	@perl -c tools/ReverseDict
	@echo
	perl -Imodules -mTest::Harness -e 'Test::Harness::runtests(glob("tools/tests/*.t"))'
# Create a manpage from the POD
man:
	pod2man --name "magicpo" --center "" --release "MagicPO $(MYVERSION)" ./magicpo ./magicpo.1
	pod2man --name "magicpo.dict" --center "" --release "MagicPO dictionary $(MYVERSION)" ./magicpo.dict.pod ./magicpo.dict.5
# Clean up the tree to prepare for distrib
distclean: clean
	perl -MFile::Find -e 'use File::Path qw/rmtree/;find(sub { return if $$File::Find::name =~ m#/\.svn#; if(not -d $$_) { if(not -e "./.svn/text-base/$$_.svn-base") { print "unlink: $$File::Find::name\n";unlink($$_);}} else { if (not -d "$$_/.svn") { print "rmtree: $$_\n";rmtree($$_)}} },"./");'
# Create the tarball
distrib: distclean test man
	mkdir -p magicpo-$(MYVERSION)
	cp -r ./`ls|grep -v magicpo-$(MYVERSION)` ./magicpo-$(MYVERSION)
	rm -rf `find magicpo-$(MYVERSION) -name \\.svn`
	tar -jcvf magicpo-$(MYVERSION).tar.bz2 ./magicpo-$(MYVERSION)
	rm -rf magicpo-$(MYVERSION)
# Create a svn snapshot
svnsnapshot:
	./tools/SetVersion "$(VERSION)-$(SVNREV)svn"
	-make distrib
	mv magicpo-$(VERSION)-$(SVNREV)svn.tar.bz2 magicpo-svnsnapshot.tar.bz2
	./tools/SetVersion "$(VERSION)"
# User-facing version of svnsnapshot
svndistrib: MYVERSION =$(VERSION)-$(SVNREV)svn
svndistrib: distrib