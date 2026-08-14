(define-module (channels)
  #:use-module (guix channels)
  #:export (%channels))

(define %channels
  (list
   (channel
    (name 'tay)
    (url "https://github.com/htayj/guix-channel")
    (branch "master"))))

%channels
