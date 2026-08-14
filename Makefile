GUIX ?= guix

# Derive the build list from Guix's available-package enumeration, which
# observes both define-public forms and dynamically exported snapshot packages.
# These are the only five upstream Guix package names ending in "-source" that
# are visible through the channel's module dependencies rather than exported by
# this channel.
UPSTREAM_SOURCE_PACKAGES := emacs-plz-event-source obs-gradient-source \
	perl-crypt-random-source ruby-method-source texlive-source
SOURCE_PACKAGES := $(filter-out $(UPSTREAM_SOURCE_PACKAGES),$(shell \
	$(GUIX) package -L . -A 2>/dev/null | awk '$$1 ~ /-source$$/ { print $$1 }' | sort -u))

# Keep an independent textual inventory solely as a guard against a definition
# that stopped exporting.  It accounts for Lars's dynamically exported lists.
PARSED_SOURCE_PACKAGES := $(shell { \
	rg --no-filename -o -P 'define-public[[:space:]]+[a-z0-9][a-z0-9-]*-source' tay/packages; \
	rg --no-filename '"larsbrinkhoff-[a-z0-9-]*-source"' \
		tay/packages/larsbrinkhoff-a-f.scm tay/packages/larsbrinkhoff-g-m.scm \
		tay/packages/larsbrinkhoff-n-s.scm tay/packages/larsbrinkhoff-t-z.scm; \
	} | sed -E 's/^define-public[[:space:]]+//; /^[^"]*"/ { s/^[^"]*"//; s/".*//; }' | sort -u)
EXPECTED_SOURCE_PACKAGE_COUNT := 629
SOURCE_PACKAGE_COUNT := $(words $(SOURCE_PACKAGES))
RELEASE_FONT_PACKAGES := cadr-fonts-latin cadr-fonts-symbols dec-fonts \
	genera-fonts-latin genera-fonts-symbols
PROJECT_PACKAGES := aptitude-custom-aliases bell-museum \
	computer-builder rust-computus custom-nix-pkgs databases-team75 dorxng-mcp \
	hyprland-preview-share-picker sbcl-ivory-key manna-cadet sbcl-qbcl \
	sbcl-rplaca terminaldrome
INSTALLABLE_PACKAGES := $(RELEASE_FONT_PACKAGES) $(PROJECT_PACKAGES)

.PHONY: check check-source-count lint lint-cve build build-sources

check-source-count:
	@test "$(SOURCE_PACKAGE_COUNT)" -eq "$(EXPECTED_SOURCE_PACKAGE_COUNT)" || \
		{ echo "expected $(EXPECTED_SOURCE_PACKAGE_COUNT) exported source packages, found $(SOURCE_PACKAGE_COUNT)"; exit 1; }
	@test "$(SOURCE_PACKAGES)" = "$(PARSED_SOURCE_PACKAGES)" || \
		{ echo "exported and parsed source package inventories differ"; exit 1; }

check: check-source-count
	$(GUIX) build -L . --dry-run $(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)
	$(GUIX) lint -L . --exclude=cve,refresh,archival \
		$(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)

lint: check-source-count
	$(GUIX) lint -L . --exclude=cve,refresh,archival \
		$(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)

lint-cve: check-source-count
	$(GUIX) lint -L . --checkers=cve $(INSTALLABLE_PACKAGES) $(SOURCE_PACKAGES)

build:
	$(GUIX) build -L . $(INSTALLABLE_PACKAGES)

build-sources: check-source-count
	$(GUIX) build -L . $(SOURCE_PACKAGES)
