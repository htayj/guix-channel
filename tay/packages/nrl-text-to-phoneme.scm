;;; Installable package for greg-kennedy/p5-NRL-TextToPhoneme.

(define-module (tay packages nrl-text-to-phoneme)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages perl)
  #:use-module (tay packages starred-d-h))

(define-public nrl-text-to-phoneme
  (package
    (name "nrl-text-to-phoneme")
    ;; Keep the executable tied to the channel's immutable source snapshot.
    (version (package-version greg-kennedy-p5-nrl-texttophoneme-source))
    (source (package-source greg-kennedy-p5-nrl-texttophoneme-source))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("NRL-TTP.pl" "bin/nrl-text-to-phoneme")
          ("rules/" "share/nrl-text-to-phoneme/rules")
          ("README.md" "share/doc/nrl-text-to-phoneme/"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'patch-source-shebangs 'patch-default-rules-path
            (lambda* (#:key outputs #:allow-other-keys)
              ;; The upstream script defaults to a rules path relative to the
              ;; current directory.  Point that default at the installed rule
              ;; table so the command works from any directory; an explicit
              ;; first argument remains a supported custom ruleset path.
              (substitute* "NRL-TTP.pl"
                (("'rules/eng_to_ipa\\.json'")
                 (string-append "'"
                                (assoc-ref outputs "out")
                                "/share/nrl-text-to-phoneme/rules/eng_to_ipa.json'")))))
          (add-after 'install 'check-upstream
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (invoke "perl" "test.pl")))))))
    (inputs
     (list perl))
    (synopsis "Text-to-phoneme converter using the NRL rules")
    (description
     "NRL-TTP converts normalized English text to phoneme sequences using the
Naval Research Laboratory letter-to-sound rules described by Elovitz et al.
It installs the Perl command-line converter and its English-to-IPA rule table,
along with the upstream Votrax and SP0256 rule tables for explicit use.")
    (home-page "https://github.com/greg-kennedy/p5-NRL-TextToPhoneme")
    (license license:unlicense)))
