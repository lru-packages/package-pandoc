NAME=pandoc
VERSION=1.19
EPOCH=1
ITERATION=1
PREFIX=/usr/local
LICENSE=PHP
VENDOR="John McFarlane"
MAINTAINER="Ryan Parman"
DESCRIPTION="Universal markup converter. If you need to convert files from one markup format into another, pandoc is your swiss-army knife."
URL=https://pandoc.org
RHEL=$(shell rpm -q --queryformat '%{VERSION}' centos-release)

#-------------------------------------------------------------------------------

all: info clean install-deps compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "EPOCH:       $(EPOCH)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* pandoc*

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:
	yum install -y \
		cabal-install \
	;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	git clone -q -b $(VERSION) https://github.com/jgm/pandoc.git --recursive --depth=1;
	cd pandoc && \
		cabal update && \
		cabal install cabal-install && \
		export PATH=/root/.cabal/bin:$$PATH && \
		cabal install --only-dependencies && \
		cabal install hsb2hs && \
		cabal configure --prefix=/usr/local --flags="embed_data_files" && \
		cabal build \
	;

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd pandoc && \
		cabal copy --destdir=/tmp/installdir-$(NAME)-$(VERSION);

#-------------------------------------------------------------------------------

.PHONY: package
package:

	# Main package
	fpm \
		-f \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--epoch $(EPOCH) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist el$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
		usr/local/lib \
		usr/local/share \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	mv *.rpm /vagrant/repo/
