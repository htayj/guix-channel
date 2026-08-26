;; UTF-8 contract: Goocastle launches this pure container with
;; LANG, LC_ALL, and LC_CTYPE fixed to C.UTF-8. glibc-locales is pinned here
;; so GNU find and provider argv use the same locale on every supported host.
(use-modules (guix profiles)
             (ice-9 ftw))
(load (string-append (dirname (canonicalize-path (current-filename)))
                     "/agent-packages.scm"))

(concatenate-manifests
 (list
  (specifications->manifest
   (list "bash"
         "coreutils"
         "curl"
         "findutils"
         "gawk"
         "glibc-locales"
         "git"
         "gnupg"
         "github-cli"
         "gzip"
         "grep"
         "jq"
         "guix"
         "make"
         "node"
         "nss-certs"
         "ripgrep"
         "sed"
         "tar"))
  (packages->manifest (list goocastle-gitleaks goocastle-codex))))
