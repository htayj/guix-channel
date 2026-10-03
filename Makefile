GUIX ?= guix
# kitty-bitmap pins Kitty 0.49.1 internally.  The time-machine command supplies
# the reviewed Guix API and dependency set used by its frozen build recipe.
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
	$(GUIX) package -L guix -A 2>/dev/null | awk '$$1 ~ /-source$$/ { print $$1 }' | sort -u))

# Keep an independent textual inventory solely as a guard against a definition
# that stopped exporting.  It accounts for Lars's dynamically exported lists.
PARSED_SOURCE_PACKAGES := $(shell { \
	rg --no-filename -o -P 'define-public[[:space:]]+[a-z0-9][a-z0-9-]*-source' guix/tay/packages; \
	rg --no-filename '"larsbrinkhoff-[a-z0-9-]*-source"' \
		guix/tay/packages/larsbrinkhoff-a-f.scm guix/tay/packages/larsbrinkhoff-g-m.scm \
		guix/tay/packages/larsbrinkhoff-n-s.scm guix/tay/packages/larsbrinkhoff-t-z.scm; \
	} | sed -E 's/^define-public[[:space:]]+//; /^[^"]*"/ { s/^[^"]*"//; s/".*//; }' | sort -u)
EXPECTED_SOURCE_PACKAGE_COUNT := 629
SOURCE_PACKAGE_COUNT := $(words $(SOURCE_PACKAGES))
RELEASE_FONT_PACKAGES := cadr-fonts-latin cadr-fonts-symbols dec-fonts \
	genera-fonts-latin genera-fonts-symbols
FONT_PACKAGES := atarist-font amstelvar $(RELEASE_FONT_PACKAGES)
PROJECT_PACKAGES := aptitude-custom-aliases bell-museum \
	computer-builder rust-computus custom-nix-pkgs databases-team75 dorxng-mcp buzz \
	hyprland-preview-share-picker hy3 dank-material-shell-shell-only sbcl-ivory-key manna-cadet sbcl-qbcl \
	sbcl-rplaca terminaldrome image-tape klh10 pdp10-suppty ks10-udis emacs-treesit-sexp \
	emacs-org-popup-posframe emacs-forth-mode@0-4450a3a emacs-aidermacs emacs-mentor-pinned emacs-vim-region org-mind-map \
	dipc nrl-text-to-phoneme you-can-datamosh-on-linux ffglitch praat@7.0.02 xq apout kitty-bitmap shader-slang opencode \
	opencode-desktop claude-code claude-desktop axmud blightmud durthang frostbite go-mud godisc kbtin shadow-over-darkmoor \
	kildclient kmuddy flex-launcher lyntin mmapper mudlet mudpuppy notion-river mushkin mushtato ocaml-irc-client \
	ocaml-irc-client-lwt ocaml-irc-client-lwt-ssl ocaml-irc-client-unix ocaml-lwt-ssl notty miou domainslib tui proiel ruby-memoist ruby-sax-machine halloy \
	kbredir potato pycat rune secretpathway tinyfugue trebuchet tapeutils heroic-gogdl \
	vt05 weidu blincolnlights pdp10-its-disassembler itstar pdp11 pdp6 uc-explorer \
	azurra-gtk-theme pdp10-xpl-pdp-10 faugus-launcher react-blessed wanderers \
	clojure-roguelike astx acehack bell-labs-rogue7 aquarium-arena atlas-warriors \
	bcrawl avanor bootrogue brogue brogue-lite rapidbrogue chessrogue corerl cryptrover \
	cutlassrl dhack diabaig dnethack dragonslayer grippy-socks gruesome hack hunger-games hydra-slayer \
	martins-dungeon-bash nlarn robotfindskitten fontra dicom2mesh modus \
	trial-by-combat xrogue keymapper liquid input-remapper emacs-cl \
	liveonce xnethack unnethack grunthack nitrohack qiling ai-code-interface-el chatgpt-el eca-emacs urogue letter-hunt pyrosimple savescummer srogue linerogue bloatcrawl2 ighalsk aquesttoofar freelarn talmudifier rouge sewer-massacre atrogue six-two-one umoria pyro narwharl stoat-soup hackem hellcrawl wired scala-ts \
	crashrun dungeon-monkey-unlimited emigo \
	kraken gened soundthread cotd emacs-eaf-emacs-application-framework eca \
	caelestia-shell caelestia-cli caelestia-panes quickshell-for-caelestia libcava m3shapes \
	dart-sass gpu-screen-recorder font-rubik font-material-symbols-rounded \
	hermes-agent hermes-desktop lbforth legcord \
	font-nerd-caskaydia-cove
INSTALLABLE_PACKAGES := $(FONT_PACKAGES) $(PROJECT_PACKAGES)
# These packages are enumerated and linted, but are not part of the default
# build because their source artifacts are proprietary and must be supplied by
# an authorized user.  Override this variable to adjust the optional checks.
OPTIONAL_PROPRIETARY_PACKAGES ?= sentinelone
CHECK_PACKAGES := $(INSTALLABLE_PACKAGES) $(OPTIONAL_PROPRIETARY_PACKAGES)

.PHONY: check check-source-count check-sentinelone check-datamosh-security check-ffglitch check-praat check-buzz \
	check-axmud check-blightmud check-durthang check-frostbite check-go-mud check-godisc check-image-tape check-kbtin \
	check-kbredir check-kildclient check-kmuddy check-flex-launcher check-mmapper check-mudlet check-mudpuppy check-notion-river check-mushkin check-mushtato check-ocaml-irc-client check-notty check-miou check-domainslib check-tui check-proiel check-potato \
	check-kitty-bitmap check-kitty-bitmap-oldguix check-lyntin check-pycat check-rune check-tinyfugue check-weidu lint lint-cve \
	check-secretpathway check-tapeutils check-trebuchet check-heroic-gogdl check-vt05 check-apout \
	check-blincolnlights check-klh10 check-suppty check-pdp10-its-disassembler \
	check-itstar check-pdp11 check-azurra-gtk-theme check-pdp6 check-pdp10-xpl-pdp-10 check-faugus-launcher \
	check-react-blessed check-shadow-over-darkmoor \
	check-clojure-roguelike \
	check-aquarium-arena \
	check-atlas-warriors \
	check-bcrawl \
	check-bootrogue \
	check-bell-labs-rogue7 \
	check-astx \
	check-acehack \
	check-avanor \
	check-wanderers \
	check-brogue \
	check-brogue-lite \
	check-rapidbrogue \
	check-chessrogue \
	check-corerl \
	check-cutlassrl \
	check-cryptrover \
	check-diabaig \
	check-dnethack \
	check-dragonslayer \
	check-grippy-socks \
	check-hunger-games \
	check-gruesome \
	check-hydra-slayer \
	check-martins-dungeon-bash \
	check-hack \
	check-nlarn \
	check-robotfindskitten \
	check-fontra build-fontra \
	check-emacs-org-popup-posframe check-emacs-forth-mode check-emacs-aidermacs check-emacs-mentor-pinned check-emacs-vim-region check-org-mind-map check-kraken check-gened check-soundthread check-cotd check-emacs-application-framework check-eca build build-sources

check-source-count:
	@test "$(SOURCE_PACKAGE_COUNT)" -eq "$(EXPECTED_SOURCE_PACKAGE_COUNT)" || \
		{ echo "expected $(EXPECTED_SOURCE_PACKAGE_COUNT) exported source packages, found $(SOURCE_PACKAGE_COUNT)"; exit 1; }
	@test "$(SOURCE_PACKAGES)" = "$(PARSED_SOURCE_PACKAGES)" || \
		{ echo "exported and parsed source package inventories differ"; exit 1; }

check-sentinelone:
	tests/sentinelone-smoke.sh

check-buzz:
	GUIX="$(GUIX)" tests/buzz-smoke.sh

check-datamosh-security:
	GUIX="$(GUIX)" tests/you-can-datamosh-on-linux-security-smoke.sh \
		"$$($(GUIX) build -L guix --no-grafts you-can-datamosh-on-linux)"

check-ffglitch:
	GUIX="$(GUIX)" tests/ffglitch-smoke.sh

check-praat:
	GUIX="$(GUIX)" tests/praat-smoke.sh \
		"$$($(GUIX) build -L guix --no-grafts -e '(@ (tay packages praat) praat)')"

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

# kitty-bitmap must also build against a Guix revision whose rolling `kitty'
# predates Kitty 0.49.1's newest Go module requirements.  The check realizes
# the channel-private Go modules and the shader-slang compiler by name first.
# See guix/tay/packages/kitty-bitmap-go-deps.scm and shader-slang.scm.
check-kitty-bitmap-oldguix:
	sh tests/kitty-bitmap-clean-old-guix-build.sh

check-lyntin:
	GUIX="$(GUIX)" tests/lyntin-smoke.sh

check-mmapper:
	GUIX="$(GUIX)" tests/mmapper-smoke.sh

check-mudlet:
	GUIX="$(GUIX)" tests/mudlet-smoke.sh

check-mudpuppy:
	GUIX="$(GUIX)" tests/mudpuppy-smoke.sh

check-notion-river:
	GUIX="$(GUIX)" tests/notion-river-smoke.sh

check-mushkin:
	GUIX="$(GUIX)" tests/mushkin-smoke.sh

check-mushtato:
	GUIX="$(GUIX)" tests/mushtato-smoke.sh

check-ocaml-irc-client:
	GUIX="$(GUIX)" tests/ocaml-irc-client-smoke.sh

check-notty:
	GUIX="$(GUIX)" sh tests/notty-smoke.sh

check-miou:
	GUIX="$(GUIX)" tests/miou-smoke.sh

check-tui:
	GUIX="$(GUIX)" sh tests/tui-smoke.sh

check-proiel:
	GUIX="$(GUIX)" sh tests/proiel-smoke.sh

check-domainslib:
	GUIX="$(GUIX)" tests/domainslib-smoke.sh

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

check-weidu:
	GUIX="$(GUIX)" tests/weidu-smoke.sh

check-tapeutils:
	GUIX="$(GUIX)" tests/tapeutils-smoke.sh

check-heroic-gogdl:
	GUIX="$(GUIX)" tests/heroic-gogdl-smoke.sh

check-vt05:
	GUIX="$(GUIX)" tests/vt05-smoke.sh

check-blincolnlights:
	GUIX="$(GUIX)" tests/blincolnlights-smoke.sh

check-klh10:
	GUIX="$(GUIX)" tests/klh10-smoke.sh

check-suppty:
	GUIX="$(GUIX)" tests/suppty-smoke.sh

check-pdp10-its-disassembler:
	GUIX="$(GUIX)" tests/pdp10-its-disassembler-smoke.sh

check-itstar:
	GUIX="$(GUIX)" tests/itstar-smoke.sh

check-pdp11:
	GUIX="$(GUIX)" tests/pdp11-smoke.sh

check-azurra-gtk-theme:
	GUIX="$(GUIX)" tests/azurra-gtk-theme-smoke.sh

check-pdp6:
	GUIX="$(GUIX)" tests/pdp6-smoke.sh

check-pdp10-xpl-pdp-10:
	GUIX="$(GUIX)" tests/pdp10-xpl-pdp-10-smoke.sh \
		"$$($(GUIX) build -L guix --no-grafts pdp10-xpl-pdp-10)"

check-faugus-launcher:
	GUIX="$(GUIX)" tests/faugus-launcher-smoke.sh \
		"$$($(GUIX) build -L guix --no-grafts faugus-launcher)"

check-react-blessed:
	GUIX="$(GUIX)" tests/react-blessed-smoke.sh

check-shadow-over-darkmoor:
	GUIX="$(GUIX)" tests/shadow-over-darkmoor-smoke.sh

check-clojure-roguelike:
	GUIX="$(GUIX)" tests/clojure-roguelike-smoke.sh

check-bell-labs-rogue7:
	GUIX="$(GUIX)" tests/bell-labs-rogue7-smoke.sh

check-astx:
	GUIX="$(GUIX)" tests/astx-smoke.sh

check-acehack:
	GUIX="$(GUIX)" tests/acehack-smoke.sh

check-avanor:
	GUIX="$(GUIX)" tests/avanor-smoke.sh

check-aquarium-arena:
	GUIX="$(GUIX)" tests/aquarium-arena-smoke.sh

check-atlas-warriors:
	GUIX="$(GUIX)" tests/atlas-warriors-smoke.sh

check-bcrawl:
	GUIX="$(GUIX)" tests/bcrawl-smoke.sh

check-bootrogue:
	GUIX="$(GUIX)" tests/bootrogue-smoke.sh

check-wanderers:
	GUIX="$(GUIX)" tests/wanderers-smoke.sh

check-brogue:
	GUIX="$(GUIX)" tests/brogue-smoke.sh

check-brogue-lite:
	GUIX="$(GUIX)" tests/brogue-lite-smoke.sh

check-rapidbrogue:
	@set -eu; \
	output="$$($(GUIX) build -L guix --no-grafts rapidbrogue)"; \
	evidence=$$(mktemp -d "$${TMPDIR:-/tmp}/rapidbrogue-proof.XXXXXX"); \
	printf '%s\n' "RapidBrogue evidence: $$evidence"; \
	GUIX="$(GUIX)" tests/rapidbrogue-smoke.sh "$$output" "$$evidence"

check-chessrogue:
	GUIX="$(GUIX)" tests/chessrogue-smoke.sh

check-corerl:
	GUIX="$(GUIX)" tests/corerl-smoke.sh

check-cutlassrl:
	GUIX="$(GUIX)" tests/cutlassrl-smoke.sh

check-dhack:
	GUIX="$(GUIX)" tests/dhack-smoke.sh

check-cryptrover:
	GUIX="$(GUIX)" tests/cryptrover-smoke.sh

check-diabaig:
	GUIX="$(GUIX)" tests/diabaig-smoke.sh

check-dnethack:
	GUIX="$(GUIX)" tests/dnethack-smoke.sh

check-dragonslayer:
	GUIX="$(GUIX)" tests/dragonslayer-smoke.sh

check-grippy-socks:
	GUIX="$(GUIX)" tests/grippy-socks-smoke.sh

check-hunger-games:
	GUIX="$(GUIX)" tests/hunger-games-smoke.sh

check-gruesome:
	GUIX="$(GUIX)" tests/gruesome-smoke.sh

check-hydra-slayer:
	GUIX="$(GUIX)" tests/hydra-slayer-smoke.sh

check-martins-dungeon-bash:
	GUIX="$(GUIX)" tests/martins-dungeon-bash-smoke.sh

check-nlarn:
	GUIX="$(GUIX)" tests/nlarn-smoke.sh

check-robotfindskitten:
	GUIX="$(GUIX)" tests/robotfindskitten-smoke.sh

.PHONY: check-dicom2mesh
check-dicom2mesh:
	GUIX="$(GUIX)" tests/dicom2mesh-smoke.sh

.PHONY: check-modus
check-modus:
	GUIX="$(GUIX)" tests/modus-smoke.sh

.PHONY: check-amstelvar
check-amstelvar:
	GUIX="$(GUIX)" tests/amstelvar-smoke.sh

.PHONY: check-trial-by-combat
check-trial-by-combat:
	GUIX="$(GUIX)" tests/trial-by-combat-smoke.sh --evidence

.PHONY: check-xrogue
check-xrogue:
	GUIX="$(GUIX)" tests/xrogue-smoke.sh

.PHONY: check-keymapper
check-keymapper:
	GUIX="$(GUIX)" tests/keymapper-smoke.sh

.PHONY: check-liquid
check-liquid:
	GUIX="$(GUIX)" tests/liquid-smoke.sh

.PHONY: check-input-remapper
check-input-remapper:
	GUIX="$(GUIX)" tests/input-remapper-smoke.sh

.PHONY: check-emacs-cl
check-emacs-cl:
	GUIX="$(GUIX)" tests/emacs-cl-smoke.sh

.PHONY: check-liveonce
check-liveonce:
	GUIX="$(GUIX)" tests/liveonce-smoke.sh

.PHONY: check-xnethack
check-xnethack:
	GUIX="$(GUIX)" tests/xnethack-smoke.sh

.PHONY: check-unnethack
check-unnethack:
	GUIX="$(GUIX)" sh tests/unnethack-smoke.sh

.PHONY: check-grunthack
check-grunthack:
	GUIX="$(GUIX)" sh tests/grunthack-smoke.sh

.PHONY: check-nitrohack
check-nitrohack:
	GUIX="$(GUIX)" sh tests/nitrohack-smoke.sh

.PHONY: check-hackem check-hellcrawl check-wired check-scala-ts
check-hackem:
	GUIX="$(GUIX)" sh tests/hackem-smoke.sh

check-hellcrawl:
	GUIX="$(GUIX)" sh tests/hellcrawl-smoke.sh

check-wired:
	GUIX="$(GUIX)" sh tests/wired-smoke.sh

check-scala-ts:
	GUIX="$(GUIX)" sh tests/scala-ts-smoke.sh

.PHONY: check-hermes-desktop
check-hermes-desktop:
	GUIX="$(GUIX)" sh tests/hermes-desktop-smoke.sh

.PHONY: check-lbforth
check-lbforth:
	GUIX="$(GUIX)" sh tests/lbforth-smoke.sh

.PHONY: check-legcord
check-legcord:
	GUIX="$(GUIX)" sh tests/legcord-smoke.sh

.PHONY: check-qiling
check-qiling:
	GUIX="$(GUIX)" tests/qiling-smoke.sh

.PHONY: check-ai-code-interface-el
check-ai-code-interface-el:
	GUIX="$(GUIX)" tests/ai-code-interface-el-smoke.sh

.PHONY: check-chatgpt-el
check-chatgpt-el:
	GUIX="$(GUIX)" tests/chatgpt-el-smoke.sh

.PHONY: check-eca-emacs
check-eca-emacs:
	GUIX="$(GUIX)" tests/eca-emacs-smoke.sh

.PHONY: check-urogue
check-urogue:
	GUIX="$(GUIX)" tests/urogue-smoke.sh

.PHONY: check-letter-hunt
check-letter-hunt:
	GUIX="$(GUIX)" tests/letter-hunt-smoke.sh

.PHONY: check-pyrosimple
check-pyrosimple:
	GUIX="$(GUIX)" tests/pyrosimple-smoke.sh

.PHONY: check-savescummer
check-savescummer:
	GUIX="$(GUIX)" tests/savescummer-smoke.sh

.PHONY: check-srogue
check-srogue:
	GUIX="$(GUIX)" tests/srogue-smoke.sh

.PHONY: check-linerogue
check-linerogue:
	GUIX="$(GUIX)" tests/linerogue-smoke.sh

.PHONY: check-bloatcrawl2
check-bloatcrawl2:
	GUIX="$(GUIX)" tests/bloatcrawl2-smoke.sh

.PHONY: check-ighalsk
check-ighalsk:
	GUIX="$(GUIX)" tests/ighalsk-smoke.sh

.PHONY: check-aquesttoofar
check-aquesttoofar:
	GUIX="$(GUIX)" tests/aquesttoofar-smoke.sh

.PHONY: check-freelarn
check-freelarn:
	GUIX="$(GUIX)" tests/freelarn-smoke.sh

.PHONY: check-talmudifier
check-talmudifier:
	GUIX="$(GUIX)" tests/talmudifier-smoke.sh

.PHONY: check-rouge
check-rouge:
	GUIX="$(GUIX)" tests/rouge-smoke.sh

.PHONY: check-sewer-massacre
check-sewer-massacre:
	GUIX="$(GUIX)" tests/sewer-massacre-smoke.sh

.PHONY: check-atrogue
check-atrogue:
	GUIX="$(GUIX)" tests/atrogue-smoke.sh

.PHONY: check-six-two-one
check-six-two-one:
	GUIX="$(GUIX)" tests/six-two-one-smoke.sh

.PHONY: check-umoria
check-umoria:
	GUIX="$(GUIX)" tests/umoria-smoke.sh

.PHONY: check-pyro
check-pyro:
	GUIX="$(GUIX)" tests/pyro-smoke.sh

.PHONY: check-narwharl
check-narwharl:
	GUIX="$(GUIX)" tests/narwharl-smoke.sh

.PHONY: check-stoat-soup
check-stoat-soup:
	GUIX="$(GUIX)" tests/stoat-soup-smoke.sh

check-fontra:
	GUIX="$(GUIX)" tests/fontra-smoke.sh

build-fontra:
	$(GUIX) build -L guix --no-grafts --no-offload fontra

check-hack:
	GUIX="$(GUIX)" tests/hack-smoke.sh

.PHONY: check-crashrun
check-crashrun:
	GUIX="$(GUIX)" sh tests/crashrun-smoke.sh

.PHONY: check-dungeon-monkey-unlimited
check-dungeon-monkey-unlimited:
	GUIX="$(GUIX)" sh tests/dungeon-monkey-unlimited-smoke.sh

.PHONY: check-emigo
check-emigo:
	GUIX="$(GUIX)" sh tests/emigo-smoke.sh

.PHONY: check-kraken
check-kraken:
	GUIX="$(GUIX)" sh tests/kraken-smoke.sh

.PHONY: check-gened
check-gened:
	GUIX="$(GUIX)" sh tests/gened-smoke.sh

.PHONY: check-soundthread
check-soundthread:
	GUIX="$(GUIX)" sh tests/soundthread-smoke.sh

.PHONY: check-cotd
check-cotd:
	GUIX="$(GUIX)" sh tests/cotd-smoke.sh

.PHONY: check-emacs-application-framework
check-emacs-application-framework:
	GUIX="$(GUIX)" sh tests/emacs-application-framework-smoke.sh

.PHONY: check-eca
check-eca:
	GUIX="$(GUIX)" python3 tests/eca-server-smoke.py

check-trebuchet:
	GUIX="$(GUIX)" tests/trebuchet-smoke.sh

check-emacs-org-popup-posframe:
	GUIX="$(GUIX)" tests/emacs-org-popup-posframe-smoke.sh

check-emacs-forth-mode:
	GUIX="$(GUIX)" tests/emacs-forth-mode-smoke.sh

check-emacs-aidermacs:
	GUIX="$(GUIX)" tests/emacs-aidermacs-smoke.sh

check-emacs-mentor-pinned:
	GUIX="$(GUIX)" tests/emacs-mentor-pinned-smoke.sh

check-emacs-vim-region:
	GUIX="$(GUIX)" sh tests/emacs-vim-region-smoke.sh

check-org-mind-map:
	GUIX="$(GUIX)" sh tests/org-mind-map-smoke.sh

check: check-source-count check-sentinelone check-datamosh-security check-ffglitch check-praat check-dicom2mesh \
	check-modus check-amstelvar check-trial-by-combat check-xrogue check-keymapper \
	check-liquid check-input-remapper check-emacs-cl check-liveonce check-xnethack check-unnethack check-grunthack check-nitrohack check-hermes-desktop check-lbforth check-legcord \
	check-qiling check-ai-code-interface-el check-chatgpt-el check-eca-emacs check-urogue check-letter-hunt check-pyrosimple check-savescummer check-srogue check-linerogue check-bloatcrawl2 check-ighalsk check-aquesttoofar check-freelarn check-talmudifier check-rouge check-sewer-massacre check-atrogue check-six-two-one check-umoria check-pyro check-narwharl check-stoat-soup check-hackem check-hellcrawl check-wired check-scala-ts \
	check-crashrun check-dungeon-monkey-unlimited check-emigo check-kraken check-gened check-soundthread check-cotd check-emacs-application-framework check-eca \
	check-rapidbrogue \
	check-axmud check-blightmud check-durthang check-frostbite check-go-mud check-godisc check-image-tape check-kbtin \
	check-kbredir check-kildclient check-kmuddy check-kitty-bitmap check-kitty-bitmap-oldguix check-lyntin check-mmapper check-mudlet check-ocaml-irc-client check-notty check-miou check-domainslib check-tui check-proiel \
	check-mudpuppy check-notion-river check-mushkin check-mushtato \
	check-potato check-pycat check-rune check-secretpathway \
	check-tinyfugue check-weidu check-tapeutils check-trebuchet check-heroic-gogdl check-vt05 check-blincolnlights check-klh10 check-suppty check-pdp10-its-disassembler check-itstar check-pdp11 check-shadow-over-darkmoor check-clojure-roguelike check-bell-labs-rogue7 check-astx check-acehack check-avanor check-bootrogue check-wanderers check-hack check-emacs-org-popup-posframe \
	check-emacs-forth-mode check-emacs-aidermacs check-emacs-mentor-pinned check-emacs-vim-region check-org-mind-map check-aquarium-arena check-atlas-warriors check-bcrawl check-chessrogue check-corerl check-cutlassrl check-dhack check-cryptrover check-dnethack check-dragonslayer check-grippy-socks check-hunger-games check-gruesome check-hydra-slayer check-martins-dungeon-bash check-nlarn check-robotfindskitten check-fontra
	$(GUIX) build -L guix --no-substitutes --dry-run $(CHECK_PACKAGES) $(SOURCE_PACKAGES)
	$(GUIX) lint -L guix --no-network --exclude=cve,refresh,archival \
		$(CHECK_PACKAGES) $(SOURCE_PACKAGES)

lint: check-source-count
	$(GUIX) lint -L guix --no-network --exclude=cve,refresh,archival \
		$(CHECK_PACKAGES) $(SOURCE_PACKAGES)

lint-cve: check-source-count
	$(GUIX) lint -L guix --checkers=cve $(CHECK_PACKAGES) $(SOURCE_PACKAGES)

build:
	$(GUIX) build -L guix $(INSTALLABLE_PACKAGES)

build-sources: check-source-count
	$(GUIX) build -L guix $(SOURCE_PACKAGES)
