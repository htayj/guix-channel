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
	ocaml-irc-client-lwt ocaml-irc-client-lwt-ssl ocaml-irc-client-unix ocaml-lwt-ssl notty miou domainslib affect minttea tui proiel ruby-memoist ruby-sax-machine halloy \
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
	kraken gened soundthread cotd emacs-eaf-emacs-application-framework eca pi-coding-agent squad oh-my-opencode-slim oh-my-opencode-slim-companion \
	caelestia-shell caelestia-cli caelestia-panes quickshell-for-caelestia libcava m3shapes \
	dart-sass gpu-screen-recorder font-rubik font-material-symbols-rounded \
	hermes-agent hermes-desktop lbforth legcord \
	font-nerd-caskaydia-cove \
	aiwnios aiwnios-bytecode wrogue babel7drl \
	the-smiths-hand tetraworld splicehack-rewrite space-privateers slashem shamogu revengate plomrogue obumbrata \
	lambdahack kimchi keeperrl \
	gearhead2 gearhead fiqhack evilhack dynahack alone-rl allure \
	agduria wenyan ludviglundgren-qbittorrent-cli \
	lispy-rogue bodge-nuklear litegraph maiko interlisp-medley natron
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
	check-emacs-org-popup-posframe check-emacs-forth-mode check-emacs-aidermacs check-emacs-mentor-pinned check-emacs-vim-region check-org-mind-map check-kraken check-gened check-soundthread check-cotd check-emacs-application-framework check-eca \
	check-pi-coding-agent check-squad check-oh-my-opencode-slim check-oh-my-opencode-slim-companion build build-sources \
	check-aiwnios check-aiwnios-bytecode check-wrogue check-babel7drl \
	check-smiths-hand check-tetraworld check-splicehack-rewrite \
	check-space-privateers check-slashem check-shamogu \
	check-revengate check-plomrogue check-obumbrata \
	check-lambdahack check-kimchi check-keeperrl \
	check-gearhead2 check-gearhead check-fiqhack \
	check-evilhack check-dynahack check-alone-rl check-allure \
	check-agduria check-wenyan check-ludviglundgren-qbittorrent-cli \
	check-lispy-rogue check-bodge-nuklear check-litegraph check-interlisp-medley check-natron
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
	@test -n "$(APOUT_OUTPUT)" -a -n "$(APOUT_EVIDENCE)" || { echo 'Set APOUT_OUTPUT and APOUT_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/apout-smoke.sh "$(APOUT_OUTPUT)" "$(APOUT_EVIDENCE)"

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

.PHONY: check-affect
check-affect:
	@test -n "$(AFFECT_OUTPUT)" -a -n "$(AFFECT_EVIDENCE)" || { echo 'Set AFFECT_OUTPUT and AFFECT_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/affect-smoke.sh "$(AFFECT_OUTPUT)" "$(AFFECT_EVIDENCE)"

.PHONY: check-minttea
check-minttea:
	@test -n "$(MINTTEA_OUTPUT)" -a -n "$(MINTTEA_EVIDENCE)" || { echo 'Set MINTTEA_OUTPUT and MINTTEA_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/minttea-smoke.sh "$(MINTTEA_OUTPUT)" "$(MINTTEA_EVIDENCE)"

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
	@test -n "$(WEIDU_OUTPUT)" -a -n "$(WEIDU_EVIDENCE)" || { echo 'Set WEIDU_OUTPUT and WEIDU_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/weidu-smoke.sh "$(WEIDU_OUTPUT)" "$(WEIDU_EVIDENCE)"

check-tapeutils:
	GUIX="$(GUIX)" tests/tapeutils-smoke.sh

check-heroic-gogdl:
	GUIX="$(GUIX)" tests/heroic-gogdl-smoke.sh

check-vt05:
	GUIX="$(GUIX)" tests/vt05-smoke.sh

check-blincolnlights:
	@test -n "$(BLINCOLNLIGHTS_OUTPUT)" -a -n "$(BLINCOLNLIGHTS_EVIDENCE)" || { echo 'Set BLINCOLNLIGHTS_OUTPUT and BLINCOLNLIGHTS_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/blincolnlights-smoke.sh "$(BLINCOLNLIGHTS_OUTPUT)" "$(BLINCOLNLIGHTS_EVIDENCE)"

check-klh10:
	GUIX="$(GUIX)" tests/klh10-smoke.sh

check-suppty:
	GUIX="$(GUIX)" tests/suppty-smoke.sh

check-pdp10-its-disassembler:
	GUIX="$(GUIX)" tests/pdp10-its-disassembler-smoke.sh

check-itstar:
	GUIX="$(GUIX)" tests/itstar-smoke.sh

check-pdp11:
	@test -n "$(PDP11_OUTPUT)" -a -n "$(PDP11_EVIDENCE)" || { echo 'Set PDP11_OUTPUT and PDP11_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/pdp11-smoke.sh "$(PDP11_OUTPUT)" "$(PDP11_EVIDENCE)"

check-azurra-gtk-theme:
	GUIX="$(GUIX)" tests/azurra-gtk-theme-smoke.sh

check-pdp6:
	@test -n "$(PDP6_OUTPUT)" -a -n "$(PDP6_EVIDENCE)" || { echo 'Set PDP6_OUTPUT and PDP6_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/pdp6-smoke.sh "$(PDP6_OUTPUT)" "$(PDP6_EVIDENCE)"

.PHONY: check-uc-explorer
check-uc-explorer:
	@test -n "$(UC_EXPLORER_OUTPUT)" -a -n "$(UC_EXPLORER_EVIDENCE)" || { echo 'Set UC_EXPLORER_OUTPUT and UC_EXPLORER_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/uc-explorer-smoke.sh "$(UC_EXPLORER_OUTPUT)" "$(UC_EXPLORER_EVIDENCE)"

check-pdp10-xpl-pdp-10:
	@test -n "$(PDP10_XPL_OUTPUT)" -a -n "$(PDP10_XPL_EVIDENCE)" || { echo 'Set PDP10_XPL_OUTPUT and PDP10_XPL_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/pdp10-xpl-pdp-10-smoke.sh "$(PDP10_XPL_OUTPUT)" "$(PDP10_XPL_EVIDENCE)"

check-faugus-launcher:
	@test -n "$(FAUGUS_OUTPUT)" -a -n "$(FAUGUS_EVIDENCE)" || { echo 'Set FAUGUS_OUTPUT and FAUGUS_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/faugus-launcher-smoke.sh "$(FAUGUS_OUTPUT)" "$(FAUGUS_EVIDENCE)"

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
	@test -n "$(WANDERERS_OUTPUT)" -a -n "$(WANDERERS_EVIDENCE)" || { echo 'Set WANDERERS_OUTPUT and WANDERERS_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/wanderers-smoke.sh "$(WANDERERS_OUTPUT)" "$(WANDERERS_EVIDENCE)"

check-brogue:
	@test -n "$(BROGUE_OUTPUT)" -a -n "$(BROGUE_EVIDENCE)" || { echo 'Set BROGUE_OUTPUT and BROGUE_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/brogue-smoke.sh "$(BROGUE_OUTPUT)" "$(BROGUE_EVIDENCE)"

.PHONY: check-boohu
check-boohu:
	@test -n "$(BOOHU_OUTPUT)" -a -n "$(BOOHU_EVIDENCE)" || { echo 'Set BOOHU_OUTPUT and BOOHU_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/boohu-smoke.sh "$(BOOHU_OUTPUT)" "$(BOOHU_EVIDENCE)"

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
.PHONY: check-pi-coding-agent
check-pi-coding-agent:
	GUIX="$(GUIX)" python3 tests/pi-smoke.py

.PHONY: check-squad
check-squad:
	GUIX="$(GUIX)" sh tests/squad-smoke.sh

.PHONY: check-oh-my-opencode-slim
check-oh-my-opencode-slim:
	GUIX="$(GUIX)" bash tests/oh-my-opencode-slim.sh

.PHONY: check-oh-my-opencode-slim-companion
check-oh-my-opencode-slim-companion:
	GUIX="$(GUIX)" sh tests/oh-my-opencode-slim-companion.sh


.PHONY: check-aiwnios check-aiwnios-bytecode check-wrogue check-babel7drl
check-aiwnios:
	GUIX="$(GUIX)" sh tests/aiwnios-smoke.sh

check-aiwnios-bytecode:
	GUIX="$(GUIX)" sh tests/aiwnios-smoke.sh "$$($(GUIX) build -L guix --no-grafts aiwnios-bytecode)"

check-wrogue:
	GUIX="$(GUIX)" sh tests/wrogue-smoke.sh

check-babel7drl:
	GUIX="$(GUIX)" sh tests/babel7drl-smoke.sh

check-trebuchet:
	GUIX="$(GUIX)" tests/trebuchet-smoke.sh

check-emacs-org-popup-posframe:
	GUIX="$(GUIX)" tests/emacs-org-popup-posframe-smoke.sh

check-emacs-forth-mode:
	GUIX="$(GUIX)" tests/emacs-forth-mode-smoke.sh

check-emacs-aidermacs:
	@test -n "$(AIDERMACS_OUTPUT)" -a -n "$(AIDERMACS_EVIDENCE)" || { echo 'Set AIDERMACS_OUTPUT and AIDERMACS_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/emacs-aidermacs-smoke.sh "$(AIDERMACS_OUTPUT)" "$(AIDERMACS_EVIDENCE)"

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
	check-crashrun check-dungeon-monkey-unlimited check-emigo check-kraken check-gened check-soundthread check-cotd check-emacs-application-framework check-eca check-pi-coding-agent check-squad check-oh-my-opencode-slim check-oh-my-opencode-slim-companion \
	check-rapidbrogue \
	check-axmud check-blightmud check-durthang check-frostbite check-go-mud check-godisc check-image-tape check-kbtin \
	check-kbredir check-kildclient check-kmuddy check-kitty-bitmap check-kitty-bitmap-oldguix check-lyntin check-mmapper check-mudlet check-ocaml-irc-client check-notty check-miou check-domainslib check-tui check-proiel \
	check-mudpuppy check-notion-river check-mushkin check-mushtato \
	check-potato check-pycat check-rune check-secretpathway \
	check-tinyfugue check-tapeutils check-trebuchet check-heroic-gogdl check-vt05 check-blincolnlights check-klh10 check-suppty check-pdp10-its-disassembler check-itstar check-pdp11 check-shadow-over-darkmoor check-clojure-roguelike check-bell-labs-rogue7 check-astx check-acehack check-avanor check-bootrogue check-hack check-emacs-org-popup-posframe \
	check-emacs-forth-mode check-emacs-mentor-pinned check-emacs-vim-region check-org-mind-map check-aquarium-arena check-atlas-warriors check-bcrawl check-chessrogue check-corerl check-cutlassrl check-dhack check-cryptrover check-dnethack check-dragonslayer check-grippy-socks check-hunger-games check-gruesome check-hydra-slayer check-martins-dungeon-bash check-nlarn check-robotfindskitten check-fontra \
	check-aiwnios check-aiwnios-bytecode check-wrogue check-babel7drl \
	check-smiths-hand check-tetraworld check-splicehack-rewrite \
	check-space-privateers check-slashem check-shamogu \
	check-revengate check-plomrogue check-obumbrata \
	check-lambdahack check-kimchi check-keeperrl \
	check-gearhead2 check-gearhead check-fiqhack \
	check-evilhack check-dynahack check-alone-rl check-allure \
	check-agduria check-wenyan check-ludviglundgren-qbittorrent-cli \
	check-lispy-rogue check-bodge-nuklear check-litegraph
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

.PHONY: check-smiths-hand
check-smiths-hand:
	GUIX="$(GUIX)" sh tests/smiths-hand-smoke.sh

.PHONY: check-tetraworld
check-tetraworld:
	GUIX="$(GUIX)" sh tests/tetraworld-smoke.sh

.PHONY: check-splicehack-rewrite
check-splicehack-rewrite:
	GUIX="$(GUIX)" sh tests/splicehack-rewrite-smoke.sh

.PHONY: check-space-privateers
check-space-privateers:
	GUIX="$(GUIX)" sh tests/space-privateers-smoke.sh

.PHONY: check-slashem
check-slashem:
	GUIX="$(GUIX)" sh tests/slashem-smoke.sh

.PHONY: check-shamogu
check-shamogu:
	GUIX="$(GUIX)" sh tests/shamogu-smoke.sh


.PHONY: check-revengate
check-revengate:
	GUIX="$(GUIX)" sh tests/revengate-smoke.sh

.PHONY: check-plomrogue
check-plomrogue:
	GUIX="$(GUIX)" sh tests/plomrogue-smoke.sh

.PHONY: check-obumbrata
check-obumbrata:
	GUIX="$(GUIX)" sh tests/obumbrata-smoke.sh

.PHONY: check-lambdahack
check-lambdahack:
	GUIX="$(GUIX)" sh tests/lambdahack-smoke.sh

.PHONY: check-kimchi
check-kimchi:
	GUIX="$(GUIX)" sh tests/kimchi-smoke.sh

.PHONY: check-keeperrl
check-keeperrl:
	GUIX="$(GUIX)" sh tests/keeperrl-smoke.sh
.PHONY: check-gearhead2
check-gearhead2:
	GUIX="$(GUIX)" sh tests/gearhead2-smoke.sh

.PHONY: check-gearhead
check-gearhead:
	@test -n "$(GEARHEAD_OUTPUT)" -a -n "$(GEARHEAD_EVIDENCE)" || { echo 'Set GEARHEAD_OUTPUT and GEARHEAD_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/gearhead-smoke.sh "$(GEARHEAD_OUTPUT)" "$(GEARHEAD_EVIDENCE)"

.PHONY: check-fiqhack
check-fiqhack:
	@test -n "$(FIQHACK_OUTPUT)" -a -n "$(FIQHACK_EVIDENCE)" || { echo 'Set FIQHACK_OUTPUT and FIQHACK_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/fiqhack-smoke.sh "$(FIQHACK_OUTPUT)" "$(FIQHACK_EVIDENCE)"

.PHONY: check-evilhack
check-evilhack:
	@test -n "$(EVILHACK_OUTPUT)" -a -n "$(EVILHACK_EVIDENCE)" || { echo 'Set EVILHACK_OUTPUT and EVILHACK_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/evilhack-smoke.sh "$(EVILHACK_OUTPUT)" "$(EVILHACK_EVIDENCE)"

.PHONY: check-dynahack
check-dynahack:
	@test -n "$(DYNAHACK_OUTPUT)" -a -n "$(DYNAHACK_EVIDENCE)" || { echo 'Set DYNAHACK_OUTPUT and DYNAHACK_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/dynahack-smoke.sh "$(DYNAHACK_OUTPUT)" "$(DYNAHACK_EVIDENCE)"

.PHONY: check-alone-rl
check-alone-rl:
	@test -n "$(ALONE_RL_OUTPUT)" -a -n "$(ALONE_RL_EVIDENCE)" || { echo 'Set ALONE_RL_OUTPUT and ALONE_RL_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/alone-rl-smoke.sh "$(ALONE_RL_OUTPUT)" "$(ALONE_RL_EVIDENCE)"

.PHONY: check-allure
check-allure:
	@test -n "$(ALLURE_OUTPUT)" -a -n "$(ALLURE_EVIDENCE)" || { echo 'Set ALLURE_OUTPUT and ALLURE_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/allure-smoke.sh "$(ALLURE_OUTPUT)" "$(ALLURE_EVIDENCE)"

.PHONY: check-agduria
check-agduria:
	@test -n "$(AGDURIA_OUTPUT)" -a -n "$(AGDURIA_EVIDENCE)" || { echo 'Set AGDURIA_OUTPUT and AGDURIA_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/agduria-smoke.sh "$(AGDURIA_OUTPUT)" "$(AGDURIA_EVIDENCE)"

.PHONY: check-wenyan
check-wenyan:
	@test -n "$(WENYAN_OUTPUT)" -a -n "$(WENYAN_EVIDENCE)" || { echo 'Set WENYAN_OUTPUT and WENYAN_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/wenyan-smoke.sh "$(WENYAN_OUTPUT)" "$(WENYAN_EVIDENCE)"

.PHONY: check-ludviglundgren-qbittorrent-cli
check-ludviglundgren-qbittorrent-cli:
	@test -n "$(QBT_CLI_OUTPUT)" -a -n "$(QBT_CLI_EVIDENCE)" || { echo 'Set QBT_CLI_OUTPUT and QBT_CLI_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/ludviglundgren-qbittorrent-cli-smoke.sh "$(QBT_CLI_OUTPUT)" "$(QBT_CLI_EVIDENCE)"

.PHONY: check-lispy-rogue
check-lispy-rogue:
	@test -n "$(LISPY_ROGUE_OUTPUT)" -a -n "$(LISPY_ROGUE_EVIDENCE)" || { echo 'Set LISPY_ROGUE_OUTPUT and LISPY_ROGUE_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/lispy-rogue-smoke.sh "$(LISPY_ROGUE_OUTPUT)" "$(LISPY_ROGUE_EVIDENCE)"

.PHONY: check-bodge-nuklear
check-bodge-nuklear:
	@test -n "$(BODGE_NUKLEAR_OUTPUT)" -a -n "$(BODGE_NUKLEAR_EVIDENCE)" || { echo 'Set BODGE_NUKLEAR_OUTPUT and BODGE_NUKLEAR_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/bodge-nuklear-smoke.sh "$(BODGE_NUKLEAR_OUTPUT)" "$(BODGE_NUKLEAR_EVIDENCE)"

.PHONY: check-litegraph
check-litegraph:
	@test -n "$(LITEGRAPH_OUTPUT)" -a -n "$(LITEGRAPH_EVIDENCE)" || { echo 'Set LITEGRAPH_OUTPUT and LITEGRAPH_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/litegraph-smoke.sh "$(LITEGRAPH_OUTPUT)" "$(LITEGRAPH_EVIDENCE)"

.PHONY: check-interlisp-medley
check-interlisp-medley:
	@test -n "$(INTERLISP_MEDLEY_OUTPUT)" -a -n "$(INTERLISP_MEDLEY_EVIDENCE)" || { echo 'Set INTERLISP_MEDLEY_OUTPUT and INTERLISP_MEDLEY_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/interlisp-medley-smoke.sh "$(INTERLISP_MEDLEY_OUTPUT)" "$(INTERLISP_MEDLEY_EVIDENCE)"

.PHONY: check-natron
check-natron:
	@test -n "$(NATRON_OUTPUT)" -a -n "$(NATRON_EVIDENCE)" || { echo 'Set NATRON_OUTPUT and NATRON_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/natron-smoke.sh "$(NATRON_OUTPUT)" "$(NATRON_EVIDENCE)"

.PHONY: check-tassh
check-tassh:
	@test -n "$(TASSH_OUTPUT)" -a -n "$(TASSH_EVIDENCE)" || { echo 'Set TASSH_OUTPUT and TASSH_EVIDENCE (prebuilt output and new/empty evidence directory).' >&2; exit 1; }
	GUIX="$(GUIX)" sh tests/tassh-smoke.sh "$(TASSH_OUTPUT)" "$(TASSH_EVIDENCE)"