GUIX ?= guix
# kitty-bitmap needs the current Kitty package definition.  Keep this separate
# from GUIX so existing channel checks can still be run with a chosen Guix.
KITTY_BITMAP_GUIX ?= guix time-machine -C channels.guix --
# Blightmud's v5.7.1 lockfile requires Rust 1.88 or newer, which is provided
# by the authenticated channel pin but not every host Guix installation.
BLIGHTMUD_GUIX ?= guix time-machine -C channels.guix --

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
	emacs-org-popup-posframe emacs-forth-mode@0-4450a3a \
	dipc nrl-text-to-phoneme you-can-datamosh-on-linux xq apout kitty-bitmap opencode \
	opencode-desktop claude-code claude-desktop axmud blightmud durthang frostbite go-mud godisc kbtin \
	kildclient kmuddy flex-launcher lyntin mmapper mudlet mudpuppy mushkin mushtato ocaml-irc-client \
	ocaml-irc-client-lwt ocaml-irc-client-lwt-ssl ocaml-irc-client-unix ocaml-lwt-ssl \
	kbredir potato pycat rune secretpathway tinyfugue trebuchet tapeutils heroic-gogdl \
	vt05 blincolnlights pdp10-its-disassembler itstar
INSTALLABLE_PACKAGES := $(FONT_PACKAGES) $(PROJECT_PACKAGES)
# These packages are enumerated and linted, but are not part of the default
# build because their source artifacts are proprietary and must be supplied by
# an authorized user.  Override this variable to adjust the optional checks.
OPTIONAL_PROPRIETARY_PACKAGES ?= sentinelone
CHECK_PACKAGES := $(INSTALLABLE_PACKAGES) $(OPTIONAL_PROPRIETARY_PACKAGES)

.PHONY: check check-source-count check-sentinelone check-datamosh-security \
	check-axmud check-blightmud check-durthang check-frostbite check-go-mud check-godisc check-image-tape check-kbtin \
	check-kbredir check-kildclient check-kmuddy check-flex-launcher check-mmapper check-mudlet check-mudpuppy check-mushkin check-mushtato check-ocaml-irc-client check-potato \
	check-kitty-bitmap check-lyntin check-pycat check-rune check-tinyfugue lint lint-cve \
	check-secretpathway check-tapeutils check-trebuchet check-heroic-gogdl check-vt05 check-apout \
	check-blincolnlights check-pdp10-its-disassembler \
	check-itstar \
	check-emacs-org-popup-posframe check-emacs-forth-mode build build-sources

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

check-axmud:
	GUIX="$(GUIX)" tests/axmud-smoke.sh

check-blightmud:
	GUIX="$(BLIGHTMUD_GUIX)" tests/blightmud-smoke.sh

check-image-tape:
	GUIX="$(GUIX)" tests/image-tape-output-regression.sh

# This proof uses a locally generated V7 write/exit fixture, avoiding any
# dependency on redistribution-restricted historical Unix binaries.
check-apout:
	GUIX="$(GUIX)" tests/apout-smoke.sh

check-durthang:
	GUIX="$(GUIX)" tests/durthang-smoke.sh

check-frostbite:
	GUIX="$(GUIX)" tests/frostbite-smoke.sh

check-go-mud:
	GUIX="$(GUIX)" tests/go-mud-smoke.sh

check-godisc:
	GUIX="$(GUIX)" tests/godisc-smoke.sh

check-kbtin:
	GUIX="$(GUIX)" tests/kbtin-smoke.sh

check-kbredir:
	GUIX="$(GUIX)" tests/kbredir-smoke.sh

check-kildclient:
	GUIX="$(GUIX)" tests/kildclient-smoke.sh

check-kmuddy:
	GUIX="$(GUIX)" tests/kmuddy-smoke.sh

check-flex-launcher:
	GUIX="$(GUIX)" tests/flex-launcher-smoke.sh

check-kitty-bitmap:
	GUIX="$(KITTY_BITMAP_GUIX)" tests/kitty-bitmap-smoke.sh

check-lyntin:
	GUIX="$(GUIX)" tests/lyntin-smoke.sh

check-mmapper:
	GUIX="$(GUIX)" tests/mmapper-smoke.sh

check-mudlet:
	GUIX="$(GUIX)" tests/mudlet-smoke.sh

check-mudpuppy:
	GUIX="$(GUIX)" tests/mudpuppy-smoke.sh

check-mushkin:
	GUIX="$(GUIX)" tests/mushkin-smoke.sh

check-mushtato:
	GUIX="$(GUIX)" tests/mushtato-smoke.sh

check-ocaml-irc-client:
	GUIX="$(GUIX)" tests/ocaml-irc-client-smoke.sh

check-potato:
	GUIX="$(GUIX)" tests/potato-smoke.sh

check-pycat:
	GUIX="$(GUIX)" tests/pycat-smoke.sh

check-rune:
	GUIX="$(GUIX)" tests/rune-smoke.sh

check-secretpathway:
	GUIX="$(GUIX)" tests/secretpathway-smoke.sh

check-tinyfugue:
	GUIX="$(GUIX)" tests/tinyfugue-smoke.sh

check-tapeutils:
	GUIX="$(GUIX)" tests/tapeutils-smoke.sh

check-heroic-gogdl:
	GUIX="$(GUIX)" tests/heroic-gogdl-smoke.sh

check-vt05:
	GUIX="$(GUIX)" tests/vt05-smoke.sh

check-blincolnlights:
	GUIX="$(GUIX)" tests/blincolnlights-smoke.sh

check-pdp10-its-disassembler:
	GUIX="$(GUIX)" tests/pdp10-its-disassembler-smoke.sh

check-itstar:
	GUIX="$(GUIX)" tests/itstar-smoke.sh

check-trebuchet:
	GUIX="$(GUIX)" tests/trebuchet-smoke.sh

check-emacs-org-popup-posframe:
	GUIX="$(GUIX)" tests/emacs-org-popup-posframe-smoke.sh

check-emacs-forth-mode:
	GUIX="$(GUIX)" tests/emacs-forth-mode-smoke.sh

check: check-source-count check-sentinelone check-datamosh-security \
	check-axmud check-blightmud check-durthang check-frostbite check-go-mud check-godisc check-image-tape check-kbtin \
	check-kbredir check-kildclient check-kmuddy check-kitty-bitmap check-lyntin check-mmapper check-mudlet check-ocaml-irc-client \
	check-mudpuppy check-mushkin check-mushtato \
	check-potato check-pycat check-rune check-secretpathway \
	check-tinyfugue check-tapeutils check-trebuchet check-heroic-gogdl check-vt05 check-blincolnlights check-pdp10-its-disassembler check-itstar check-emacs-org-popup-posframe \
	check-emacs-forth-mode
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
