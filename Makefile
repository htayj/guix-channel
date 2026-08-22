GUIX ?= guix
# kitty-bitmap needs the current Kitty package definition.  Keep this separate
# from GUIX so existing channel checks can still be run with a chosen Guix.
KITTY_BITMAP_GUIX ?= guix time-machine -C channels.guix --

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
FONT_PACKAGES := atarist-font $(RELEASE_FONT_PACKAGES)
PROJECT_PACKAGES := aptitude-custom-aliases bell-museum \
	computer-builder rust-computus custom-nix-pkgs databases-team75 dorxng-mcp \
	hyprland-preview-share-picker sbcl-ivory-key manna-cadet sbcl-qbcl \
	sbcl-rplaca terminaldrome image-tape ks10-udis emacs-treesit-sexp \
	dipc nrl-text-to-phoneme you-can-datamosh-on-linux xq kitty-bitmap opencode \
	opencode-desktop claude-code claude-desktop durthang godisc kbtin kildclient \
	lyntin pycat secretpathway tinyfugue trebuchet
INSTALLABLE_PACKAGES := $(FONT_PACKAGES) $(PROJECT_PACKAGES)
# These packages are enumerated and linted, but are not part of the default
# build because their source artifacts are proprietary and must be supplied by
# an authorized user.  Override this variable to adjust the optional checks.
OPTIONAL_PROPRIETARY_PACKAGES ?= sentinelone
CHECK_PACKAGES := $(INSTALLABLE_PACKAGES) $(OPTIONAL_PROPRIETARY_PACKAGES)

.PHONY: check check-source-count check-sentinelone check-datamosh-security \
	check-durthang check-godisc check-image-tape check-kbtin check-kildclient \
	check-kitty-bitmap check-lyntin check-pycat check-tinyfugue lint lint-cve \
	check-secretpathway check-trebuchet build build-sources

check-source-count:
	@test "$(SOURCE_PACKAGE_COUNT)" -eq "$(EXPECTED_SOURCE_PACKAGE_COUNT)" || \
		{ echo "expected $(EXPECTED_SOURCE_PACKAGE_COUNT) exported source packages, found $(SOURCE_PACKAGE_COUNT)"; exit 1; }
	@test "$(SOURCE_PACKAGES)" = "$(PARSED_SOURCE_PACKAGES)" || \
		{ echo "exported and parsed source package inventories differ"; exit 1; }

check-sentinelone:
	tests/sentinelone-smoke.sh

check-datamosh-security:
	GUIX="$(GUIX)" tests/you-can-datamosh-on-linux-security-smoke.sh \
		"$$($(GUIX) build -L . --no-grafts you-can-datamosh-on-linux)"

check-image-tape:
	GUIX="$(GUIX)" tests/image-tape-output-regression.sh

check-durthang:
	GUIX="$(GUIX)" tests/durthang-smoke.sh

check-godisc:
	GUIX="$(GUIX)" tests/godisc-smoke.sh

check-kbtin:
	GUIX="$(GUIX)" tests/kbtin-smoke.sh

check-kildclient:
	GUIX="$(GUIX)" tests/kildclient-smoke.sh

check-kitty-bitmap:
	GUIX="$(KITTY_BITMAP_GUIX)" tests/kitty-bitmap-smoke.sh

check-lyntin:
	GUIX="$(GUIX)" tests/lyntin-smoke.sh

check-pycat:
	GUIX="$(GUIX)" tests/pycat-smoke.sh

check-secretpathway:
	GUIX="$(GUIX)" tests/secretpathway-smoke.sh

check-tinyfugue:
	GUIX="$(GUIX)" tests/tinyfugue-smoke.sh

check-trebuchet:
	GUIX="$(GUIX)" tests/trebuchet-smoke.sh

check: check-source-count check-sentinelone check-datamosh-security \
	check-durthang check-godisc check-image-tape check-kbtin check-kildclient \
	check-kitty-bitmap check-lyntin check-pycat check-secretpathway \
	check-tinyfugue check-trebuchet
	$(GUIX) build -L . --no-substitutes --dry-run $(CHECK_PACKAGES) $(SOURCE_PACKAGES)
	$(GUIX) lint -L . --no-network --exclude=cve,refresh,archival \
		$(CHECK_PACKAGES) $(SOURCE_PACKAGES)

lint: check-source-count
	$(GUIX) lint -L . --no-network --exclude=cve,refresh,archival \
		$(CHECK_PACKAGES) $(SOURCE_PACKAGES)

lint-cve: check-source-count
	$(GUIX) lint -L . --checkers=cve $(CHECK_PACKAGES) $(SOURCE_PACKAGES)

build:
	$(GUIX) build -L . $(INSTALLABLE_PACKAGES)

build-sources: check-source-count
	$(GUIX) build -L . $(SOURCE_PACKAGES)
