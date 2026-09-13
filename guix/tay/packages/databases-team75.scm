;;; Preserved client for the Databases Team75 course project.

(define-module (tay packages databases-team75)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (tay packages projects))

(define-public databases-team75
  (package
    (name "databases-team75")
    ;; Use the channel's audited source ledger.  It pins the upstream commit
    ;; and content hash without creating a second independently-maintained
    ;; source identity.
    (version (package-version htayj-databases-team75-source))
    (source (package-source htayj-databases-team75-source))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." "share/databases-team75/"))))
    (synopsis "Preserved source of a legacy city-data database client")
    (description
     "Databases Team75 preserves a 2017 Python 2 and Tk client for a city-data
course database project.  The installed source includes the graphical client
and its database-access layer under @file{share/databases-team75}.  It is a
historical source package rather than an executable offline application: the
upstream repository supplies neither a schema nor seed data, and its sole
database endpoint was an external academic MySQL service.  Consequently, this
package deliberately does not claim to provide a working local database or a
launcher that would contact that service.")
    (home-page "https://github.com/htayj/Databases-Team75")
    ;; The source ledger records that upstream provides no license.  Reuse its
    ;; exact metadata rather than inferring redistribution permission.
    (license (package-license htayj-databases-team75-source))))
