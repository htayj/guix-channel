;;; Native Ruby library for PROIEL, without bundled treebank corpora.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages proiel)
  #:use-module (gnu packages base)
  #:use-module (gnu packages rails)
  #:use-module (gnu packages ruby-check)
  #:use-module (gnu packages ruby-xyz)
  #:use-module (guix build-system ruby)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-s-z))

;; The bundled teilite.xsd matches TEI P5 1.1.0's dated schema.  Use its
;; contemporaneous GPL grant, not an inferred retroactive BSD relicense.
(define %proiel-tei-license
  (origin
    (method url-fetch)
    (uri "https://tei-c.org/Vault/P5/1.1.0/doc/tei-p5-doc/en/html/COPYING.txt")
    (sha256
     (base32 "0lpyp3frjafyfffy0h8qq4sdywvav6sxkvm8hafqmkhy9xrqn0sy"))))

(define %proiel-selected-gpl
  (origin
    (method url-fetch)
    (uri "https://www.gnu.org/licenses/gpl-3.0.txt")
    (sha256
     (base32 "11k9nggwk1mgsrkdwgdjz65avrradxlpdgrdkc7ryjgn8jbxqwir"))))

;; Upstream ships these mirrored schemas without their third-party notices.
(define %proiel-schema-notices
  (plain-file
   "PROIEL-SCHEMA-LICENSES"
   "teilite.xsd: Copyright 2007 TEI Consortium.
Schema generated 2008-07-08T18:04:12Z, matching
https://tei-c.org/Vault/P5/1.1.0/xml/tei/custom/schema/xsd/teilite.xsd
GPL-3-or-later selected under the release's any-later-version option.
The contemporaneous, unmodified grant is in TEI-COPYING;
the selected GPL version is in COPYING-GPL-3.
https://tei-c.org/Vault/P5/1.1.0/doc/tei-p5-doc/en/html/index.html\n\n
xml.xsd: https://www.w3.org/2009/01/xml.xsd
Copyright (c) 2009 World Wide Web Consortium. All Rights Reserved.
This work is distributed under the W3C Software License in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
https://www.w3.org/copyright/software-license-2002/\n
W3C Software and Document Notice and License (2002)\n
By obtaining, using and/or copying this work, you (the licensee) agree
that you have read, understood, and will comply with the following
terms and conditions.\n
Permission to copy, modify, and distribute this software and its
documentation, with or without modification, for any purpose and
without fee or royalty is hereby granted, provided that you include
the following on ALL copies of the software and documentation or
portions thereof, including modifications:\n
 * The full text of this NOTICE in a location viewable to users of the
   redistributed or derivative work.
 * Any pre-existing intellectual property disclaimers, notices, or
   terms and conditions. If none exist, the W3C Software Short Notice
   should be included (hypertext is preferred, text is permitted)
   within the body of any redistributed or derivative code.
 * Notice of any changes or modifications to the files, including
   the date changes were made. (We recommend you provide URIs to the
   location from which the code is derived.)\n
THIS SOFTWARE AND DOCUMENTATION IS PROVIDED \"AS IS,\" AND COPYRIGHT
HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY OR
FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE
OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS,
COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.\n
COPYRIGHT HOLDERS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT,
SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF ANY USE OF THE
SOFTWARE OR DOCUMENTATION.\n
The name and trademarks of copyright holders may NOT be used in
advertising or publicity pertaining to the software without specific,
written prior permission. Title to copyright in this software and any
associated documentation will at all times remain with copyright holders.\n"))

;; Keep upstream's runtime constraints.  The pinned Guix builder 3.3.0 and
;; json 2.18.1 do not satisfy ~> 3.2.4 and ~> 2.3.0 respectively.
(define ruby-builder-for-proiel
  (package
    (inherit ruby-builder)
    (version "3.2.4")
    (source
     (origin
       (method url-fetch)
       (uri (rubygems-uri "builder" version))
       (sha256
        (base32 "045wzckxpwcqzrjr353cxnyaxgf0qg22jh00dcx7z38cys5g1jlr"))))
    (arguments
     (list
      #:test-target "test_all"
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'hide-late-kernel-includes
            (lambda _
              ;; Modern Ruby propagates late Kernel includes to Object's
              ;; descendants.  Apply the existing Object hiding hook to
              ;; Kernel too; preserve the upstream regression assertion.
              (substitute* "lib/blankslate.rb"
                (("return result if mod != Object")
                 "return result unless mod == Object || mod == Kernel")
                (("# instance methods removed from blank slate\\.  In theory, modules")
                 "# instance methods removed from blank slate.  Modules")
                (("# included into Kernel would have to be removed as well, but a")
                 "# included into Kernel are scanned as well: modern Ruby")
                (("# \\\"feature\\\" of Ruby prevents late includes into modules from being")
                 "# propagates late module includes to existing descendants,")
                (("# exposed in the first place\\.")
                 "# so their methods must also be explicitly hidden.")))))))
    (native-inputs (list ruby-minitest))))

(define ruby-json-for-proiel
  (package
    (inherit ruby-json)
    (version "2.3.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ruby/json")
             (commit "0a76a1f509d78b948da59df51b2253f63b05ef2a")))
       (file-name (git-file-name "ruby-json" version))
       (sha256
        (base32 "0abbx00wg24gr65pca8n27f4dvhrk67n6i90m5wli84rl6l0h6fq"))))
    ;; Unlike the current Guix package, run the full pure and C-extension
    ;; suites.  This release needs no sdoc dependency to run its tests.
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'select-native-gemspec
            (lambda _
              (delete-file "json-java.gemspec")
              (delete-file "json_pure.gemspec")
              ;; The release's explicit file list omitted its license.
              (substitute* "json.gemspec"
                (("s.files = \\[") "s.files = [\"LICENSE\","))
              (substitute* "json.gemspec"
                (("\"json-java.gemspec\",?") "")
                (("\"json_pure.gemspec\",?") ""))
              (substitute* "Rakefile"
                (("`git ls-files`") "`find . -type f | sort`"))))
          (add-before 'build 'compile-extensions
            (lambda _ (invoke "rake" "compile")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "rake" "test_pure")
                (setenv "JSON" "ext")
                (invoke "rake" "test_ext")))))))
    (native-inputs (list ruby-test-unit ruby-sorted-set which))
    ;; LICENSE in this exact release offers the Ruby terms or BSD-2, not GPL.
    ;; The UTF conversion table has its own Unicode redistribution grant.
    (license
     (list license:ruby
           (license:non-copyleft
            "https://github.com/ruby/json/blob/0a76a1f509d78b948da59df51b2253f63b05ef2a/ext/json/ext/generator/generator.c"
            "Unicode UTF conversion code; preserve the embedded notice.")))))

(define-public ruby-memoist
  (package
    (name "ruby-memoist")
    (version "0.16.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/matthewrudy/memoist")
             (commit "b12aff232bd3a41dcab6eb5763907c9c4d13bc41")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0w1phkda7dbzhfyvkckfkwfs91p7g8z40414chsbm4n8qfllnzfm"))))
    (build-system ruby-build-system)
    (arguments
     (list #:phases
           #~(modify-phases %standard-phases
               (replace 'check
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     (invoke "ruby" "-Ilib:test" "test/memoist_test.rb")))))))
    (native-inputs (list ruby-minitest))
    (home-page "https://github.com/matthewrudy/memoist")
    (synopsis "Memoize Ruby method calls")
    (description "Memoist caches Ruby method results, including methods with
arguments, and supports flushing and reloading the cached values.")
    (license license:expat)))

(define-public ruby-sax-machine
  (package
    (name "ruby-sax-machine")
    (version "1.3.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/pauldix/sax-machine")
             (commit "6d193af3b139215d6946b2db050501024820fa89")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0k4dn65sv2vjmgm9x350fk8aszz6ii4la6wibmzsncbprrz1amgv"))))
    (build-system ruby-build-system)
    (arguments
     (list #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'deterministic-test-file-list
                 (lambda _
                   (substitute* "sax-machine.gemspec"
                     (((string-append
                        "`git ls-files -- \\{test,spec,features\\}/\\*`"
                        "\\.split\\(\"\\\\n\"\\)"))
                      (string-append
                       "Dir.glob('{test,spec,features}/**/*').select "
                       "{ |f| File.file?(f) }.sort")))))
               (add-after 'unpack 'initialize-base-object
                 (lambda _
                   ;; ActiveRecord::Inheritance.new forwards nil; initialize
                   ;; the base object's lifecycle before SAX assignment.
                   ;; Object#initialize requires the explicit zero-arg super.
                   (substitute* "lib/sax-machine/sax_document.rb"
                     (("def initialize\\(attributes = \\{\\}\\)")
                      "def initialize(attributes = nil)\n      super()")
                     (("^      attributes\\.each do")
                      "      (attributes || {}).each do"))))
               (replace 'check
                 (lambda* (#:key tests? #:allow-other-keys)
                   (when tests?
                     ;; ActiveRecord 7 initializes attribute metadata even for
                     ;; this unsaved SAX object.  Use no persistent database.
                     (call-with-output-file "spec/guix-activerecord.rb"
                       (lambda (port)
                         (display
                          (string-append
                           "require 'active_record'\n"
                           "ActiveRecord::Base.establish_connection("
                           "adapter: 'sqlite3', database: ':memory:')\n"
                           "ActiveRecord::Schema.define { "
                           "create_table(:my_sax_models) }\n")
                          port)))
                     (setenv "HANDLER" "nokogiri")
                     (invoke "rspec" "-r" "./spec/guix-activerecord.rb" "spec")))))))
    (native-inputs (list ruby-rspec ruby-activerecord))
    (propagated-inputs (list ruby-nokogiri))
    (home-page "https://github.com/pauldix/sax-machine")
    (synopsis "Declarative SAX XML parsing for Ruby")
    (description "SAX Machine maps XML elements and attributes to Ruby objects
using a declarative interface.  This package provides the Nokogiri backend.")
    (license license:expat)))

(define-public proiel
  (package
    (name "proiel")
    (version "1.3.3")
    ;; Reuse the exact recorded snapshot origin, without changing the
    ;; preservation package or redistributing its non-commercial corpora.
    (source
     (origin
       (inherit (package-source syntacticus-proiel-source))
       (modules '((guix build utils) (rnrs io ports) (srfi srfi-13)))
       (snippet
        #~(begin
            ;; Even the files named dummy contain corpus-derived annotations
            ;; labelled CC BY-NC-SA.  Regenerate independently, never relabel.
            (for-each delete-file (find-files "spec" "\\.xml$"))
            ;; Retain the independent Obliqueness examples preceding the
            ;; corpus-derived heredocs; the generator restores all remaining
            ;; examples with fresh graphs during unpack.
            (let* ((file "spec/valency_spec.rb")
                   (text (call-with-input-file file get-string-all))
                   (offset (string-contains text "describe PROIEL::Valency do")))
              (unless offset (error "Pinned valency source mismatch"))
              (call-with-output-file file
                (lambda (port) (display (string-take text offset) port))))))))
    (build-system ruby-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'generate-corpus-free-tests
            (lambda _
              (invoke "ruby"
                      #$(local-file (search-tay-package-file
                                     "../../../tests/proiel-smoke-sanitize.rb")))))
          (add-after 'generate-corpus-free-tests 'attribute-schema-mirrors
            (lambda _
              (copy-file #$%proiel-schema-notices "SCHEMA-LICENSES")
              (copy-file #$%proiel-tei-license "TEI-COPYING")
              (copy-file #$%proiel-selected-gpl "COPYING-GPL-3")
              (substitute* "proiel.gemspec"
                (("spec.license       = 'MIT'")
                 "spec.licenses      = ['MIT', 'GPL-3.0-or-later', 'W3C']"))
              (substitute* "proiel.gemspec"
                (("%w\\(README.md LICENSE\\)")
                 "%w(README.md LICENSE SCHEMA-LICENSES TEI-COPYING COPYING-GPL-3)"))
              (substitute* "lib/proiel/proiel_xml/proiel-1.0/xml.xsd"
                (("<xs:schema")
                 (string-append
                  "<!-- XML namespace schema: Copyright 2009 W3C. "
                  "All Rights Reserved.\n"
                  "Distributed under https://www.w3.org/copyright/"
                  "software-license-2002/\n"
                  "WITHOUT ANY WARRANTY, including MERCHANTABILITY or "
                  "FITNESS FOR A PARTICULAR PURPOSE.\n"
                  "2026-10-02: added this required attribution notice; "
                  "schema unchanged. -->\n"
                  "<xs:schema")))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Invoke the upstream RSpec suite directly: Bundler's
                ;; development-only rake/rspec pins are not runtime deps.
                (invoke "rspec" "spec"))))
          (add-after 'install 'install-local-example
            (lambda _
              (mkdir-p (string-append #$output "/share/proiel/examples"))
              (copy-file #$(local-file (search-tay-package-file
                                       "../../../tests/proiel-smoke.xml"))
                         (string-append #$output
                                        "/share/proiel/examples/minimal.xml"))))
          (add-after 'install-local-example 'check-installed-library
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (setenv "GEM_PATH"
                        (string-append #$output "/lib/ruby/vendor_ruby:"
                                       (or (getenv "GEM_PATH") "")))
                (mkdir-p "installed-consumer")
                (with-directory-excursion "installed-consumer"
                  (invoke "ruby"
                          #$(local-file (search-tay-package-file
                                         "../../../tests/proiel-smoke.rb"))
                          (string-append #$output
                                         "/share/proiel/examples/minimal.xml")))))))))
    (native-inputs (list ruby-rspec))
    (propagated-inputs
     (list ruby-builder-for-proiel ruby-json-for-proiel ruby-memoist
           ruby-nokogiri ruby-sax-machine))
    (home-page "https://github.com/syntacticus/proiel")
    (synopsis "Read and manipulate PROIEL dependency treebanks")
    (description "This Ruby library reads, validates, and manipulates treebanks
using the PROIEL dependency format.  It provides sentence and token objects,
annotation schemas, dictionaries, and valency analysis.  This package contains
no external treebank corpora; its example and tests use synthetic data.")
    (license (list license:expat license:gpl3+ license:w3c))))
