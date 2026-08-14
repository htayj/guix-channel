GUIX ?= guix

SOURCE_PACKAGES := $(shell rg -o 'htayj-[a-z0-9-]+-source' \
	tay/packages/projects.scm | sort -u)
FONT_PACKAGES := cadr-fonts-latin cadr-fonts-symbols dec-fonts \
	genera-fonts-latin genera-fonts-symbols

.PHONY: check lint lint-cve build build-sources

check:
	$(GUIX) build -L . --dry-run $(FONT_PACKAGES) $(SOURCE_PACKAGES)
	$(GUIX) lint -L . --exclude=cve,refresh,archival \
		$(FONT_PACKAGES) $(SOURCE_PACKAGES)

lint:
	$(GUIX) lint -L . --exclude=cve,refresh,archival \
		$(FONT_PACKAGES) $(SOURCE_PACKAGES)

lint-cve:
	$(GUIX) lint -L . --checkers=cve $(FONT_PACKAGES) $(SOURCE_PACKAGES)

build:
	$(GUIX) build -L . $(FONT_PACKAGES)

build-sources:
	$(GUIX) build -L . $(SOURCE_PACKAGES)
