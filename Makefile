NAME=pandoc
VERSION=1.19.2.4
ITERATION=1.lru
PREFIX=/usr/local
LICENSE=PHP
VENDOR="John McFarlane"
MAINTAINER="Ryan Parman"
DESCRIPTION="Universal markup converter. If you need to convert files from one markup format into another, pandoc is your swiss-army knife."
URL=https://pandoc.org
ACTUALOS=$(shell osqueryi "select * from os_version;" --json | jq -r ".[].name")
EL=$(shell if [[ "$(ACTUALOS)" == "Amazon Linux AMI" ]]; then echo alami; else echo el; fi)
RHEL=$(shell [[ -f /etc/centos-release ]] && rpm -q --queryformat '%{VERSION}' centos-release)

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
	@ echo "OS:          $(ACTUALOS)"
	@ echo "EL:          $(EL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* pandoc*
	yum -y remove cabal-install

.PHONY: cleanall
cleanall: clean
	rm -Rf ~/.ghc ~/.cabal

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:
	wget -O /etc/yum.repos.d/petersen-ghc.repo https://copr.fedorainfracloud.org/coprs/petersen/ghc-7.10.2/repo/epel-7/petersen-ghc-7.10.2-epel-7.repo && \
	yum clean all && \
	yum install -y \
		cabal-install \
		ghc \
	;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	git clone -q -b $(VERSION) https://github.com/jgm/pandoc.git --recursive --depth=1;
	cd pandoc && \
		export PATH=/root/.cabal/bin:$$PATH && \
		cabal update && \
		cabal install happy && \
		cabal install --only-dependencies && \
		cabal install hsb2hs && \
		cabal configure --prefix=$(PREFIX) --flags="embed_data_files" && \
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
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
		usr/local/lib \
		usr/local/share \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	[[ -d /vagrant/repo ]] && mv *.rpm /vagrant/repo/
