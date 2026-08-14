GUIX ?= guix

SOURCE_PACKAGES := $(shell rg --no-filename -o -P \
	'define-public[[:space:]]+[a-z0-9][a-z0-9-]*-source' tay/packages | \
	sed -E 's/^define-public[[:space:]]+//' | sort -u)
RELEASE_FONT_PACKAGES := cadr-fonts-latin cadr-fonts-symbols dec-fonts \
	genera-fonts-latin genera-fonts-symbols
PROJECT_PACKAGES := aptitude-custom-aliases bell-museum computer-builder \
	rust-computus custom-nix-pkgs databases-team75 dorxng-mcp \
	sbcl-ivory-key manna-cadet sbcl-qbcl sbcl-rplaca
INSTALLABLE_PACKAGES := $(RELEASE_FONT_PACKAGES) $(PROJECT_PACKAGES)

.PHONY: check lint lint-cve build build-sources

check:
	$(GUIX) build -L . --dry-run $(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)
	$(GUIX) lint -L . --exclude=cve,refresh,archival \
		$(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)

lint:
	$(GUIX) lint -L . --exclude=cve,refresh,archival \
		$(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)

lint-cve:
	$(GUIX) lint -L . --checkers=cve $(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)

build:
	$(GUIX) build -L . $(INSTALLABLE_PACKAGES)

build-sources:
	$(GUIX) build -L . $(SOURCE_PACKAGES)
