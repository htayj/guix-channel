;;; PDP-10 public source snapshots outside the alphabetic shards.

(define-module (tay packages pdp10-misc)
  #:use-module (tay packages source-snapshot)
  #:export (pdp10-20xsim-source))

;; Archived upstream; retained as an immutable preservation source snapshot.
(define-public pdp10-20xsim-source
  (make-github-source-snapshot
   "pdp10-20xsim-source" "pdp10" "PDP-10" "20xsim"
   "4257877be16cf77d33954c56b2fdf73557015f2f"
   "1n8wjyck9x8j095zv2apq93wscpx26nypzrir2gn0h4h1k2ilaiw"
   "Source snapshot of the TOPS-20 simulator for TOPS-10"
   "https://github.com/PDP-10/20xsim" #f))
