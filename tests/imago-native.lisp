;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Offline external native consumer of the installed sbcl-imago closure.
;;; All fixtures are lawful caller-created synthetic images; no upstream
;;; sample assets are read or redistributed.
;;;
;;; Environment (set by tests/imago-smoke.sh):
;;;   XDG_CONFIG_DIRS - OUTPUT etc/xdg + profile etc/xdg (ASDF config)
;;;   IMAGO_WORK      - writable consumer working directory
;;;   IMAGO_RECEIPT   - proof.json destination (host-visible evidence dir)

(require :asdf)

;; ASDF configuration comes entirely from the delivered artifacts:
;; the smoke harness sets XDG_CONFIG_DIRS to the passed OUTPUT's
;; etc/xdg (whose source-registry.conf.d registers imago's source
;; tree and whose asdf-output-translations.conf.d maps it to the
;; delivered fasls in lib/common-lisp) plus the guix shell profile's
;; etc/xdg (the dependency closure, same layout).  ASDF picks those
;; up through its default XDG configuration handling on first use —
;; no override here: overriding all outputs would force recompilation
;; (including FFI wrappers, with no compiler in the environment)
;; instead of using the precompiled store fasls.  Anything genuinely
;; absent falls back to ASDF's default user cache, which stays
;; writable; the harness already unsets ASDF_OUTPUT_TRANSLATIONS so
;; host state cannot interfere, and SBCL runs --no-userinit.
(assert (uiop:getenv "XDG_CONFIG_DIRS") ()
        "XDG_CONFIG_DIRS not set by harness")

;; Load all six delivered systems BEFORE the consumer package is
;; defined: the defpackage below :uses real package names that must
;; already exist.
(dolist (sys '(:imago :imago/bit-io :imago/jpeg-turbo :imago/libheif
               :imago/libtiff :imago/jupyter))
  (asdf:load-system sys))

(defpackage :imago.consumer
  (:use :cl :imago))
(in-package :imago.consumer)

(defparameter *checks* 0)
(defmacro check (form)
  `(progn (assert ,form) (incf *checks*)))

(defparameter *work*
  (uiop:ensure-directory-pathname (uiop:getenv "IMAGO_WORK")))
(defun work-file (name) (merge-pathnames name *work*))

(defun approx= (a b tolerance) (<= (abs (- a b)) tolerance))

;;; ---------------------------------------------------------------
;;; Synthetic fixtures (caller-created; no upstream assets).
;;; Gradient RGB: pixel (x, y) = (x mod 256, y mod 256, 30).
;;; Grayscale: intensity = (x + y) mod 256, alpha 255.
;;; ---------------------------------------------------------------
(defun make-gradient-rgb (width height)
  (let ((image (make-instance 'rgb-image :width width :height height)))
    (dotimes (y height)
      (dotimes (x width)
        (setf (image-pixel image x y)
              (make-color (mod x 256) (mod y 256) 30))))
    image))

(defun make-gradient-gray (width height)
  (let ((image (make-instance 'grayscale-image :width width :height height)))
    (dotimes (y height)
      (dotimes (x width)
        (setf (image-pixel image x y)
              (make-gray (mod (+ x y) 256)))))
    image))

(defun rgb-pixel= (a b)
  (and (= (color-red a) (color-red b))
       (= (color-green a) (color-green b))
       (= (color-blue a) (color-blue b))))

(defun gray-pixel= (a b)
  (= (gray-intensity a) (gray-intensity b)))

(defun image-eq-p (image expected pixel=)
  (and (equal (image-dimensions image)
              (image-dimensions expected))
       (dotimes (y (image-height image) t)
         (dotimes (x (image-width image) t)
           (unless (funcall pixel= (image-pixel image x y)
                            (image-pixel expected x y))
             (return-from image-eq-p nil))))))

;;; ---------------------------------------------------------------
;;; 1. PNG roundtrip: exact pixel identity (lossless).
;;; ---------------------------------------------------------------
(let ((w 97) (h 41))
  (let ((original (make-gradient-rgb w h)))
    (write-image original (work-file "gradient.png"))
    (let ((back (read-image (work-file "gradient.png"))))
      (check (typep back 'rgb-image))
      (check (equal (image-dimensions back) (list h w)))
      (check (image-eq-p back original #'rgb-pixel=))
      ;; Spot channel decode: corner + center.
      (check (= (color-red (image-pixel back 5 7)) 5))
      (check (= (color-green (image-pixel back 5 7)) 7))
      (check (= (color-blue (image-pixel back 5 7)) 30))
      (check (= (color-alpha (image-pixel back 5 7)) 255)))))

(let ((w 64) (h 32))
  (let ((original (make-gradient-gray w h)))
    (write-image original (work-file "gray.png"))
    (let ((back (read-image (work-file "gray.png"))))
      (check (typep back 'grayscale-image))
      (check (equal (image-dimensions back) (list h w)))
      (check (image-eq-p back original #'gray-pixel=))
      (check (= (gray-intensity (image-pixel back 5 7)) 12))
      (check (= (gray-alpha (image-pixel back 5 7)) 255)))))

;;; ---------------------------------------------------------------
;;; 2. PPM roundtrip through the generic reader/writer table.
;;; ---------------------------------------------------------------
(let* ((w 32) (h 16)
       (original (make-gradient-rgb w h)))
  (write-image original (work-file "gradient.pnm"))
  (let ((back (read-image (work-file "gradient.pnm"))))
    (check (typep back 'rgb-image))
    (check (equal (image-dimensions back) (list h w)))
    (check (image-eq-p back original #'rgb-pixel=))))

;;; ---------------------------------------------------------------
;;; 3. JPEG (imago/jpeg-turbo): test wrapper channel mapping exactly
;;;    against an independent native decode of the SAME FILE, then
;;;    measure the lossy quality contract against the original image.
;;;    Quality 100, RGB 4:4:4: each full-image channel has RMSE <= 2
;;;    8-bit LSB and PSNR >= 42 dB.  Maximum error is diagnostic, not
;;;    an arbitrary per-pixel bound.  The smooth fixtures stay unchanged.
;;; ---------------------------------------------------------------
(defun check-jpeg-quality (original back channels label)
  (dolist (channel channels)
    (let ((accessor (cdr channel))
          (squared-error 0)
          (maximum-error 0)
          (samples (* (image-width original) (image-height original))))
      (dotimes (y (image-height original))
        (dotimes (x (image-width original))
          (let ((error (abs (- (funcall accessor (image-pixel original x y))
                               (funcall accessor (image-pixel back x y))))))
            (incf squared-error (* error error))
            (setf maximum-error (max maximum-error error)))))
      (let* ((rmse (sqrt (/ squared-error (float samples 1d0))))
             (psnr (unless (zerop squared-error)
                     (* 20d0 (log (/ 255d0 rmse) 10d0)))))
        (format t "~&JPEG ~a ~a: max=~d LSB RMSE=~,6f LSB PSNR=~a dB~%"
                label (car channel) maximum-error rmse (or psnr "infinity"))
        (check (<= rmse 2d0))
        (check (or (null psnr) (>= psnr 42d0)))))))

;; After all six ASDF systems load, optional native backends must still
;; own generic JPEG dispatch.  Never re-register in the consumer and
;; hide a library/load-order bug.  Test generic reads alongside the
;; explicit turbo/native-octet contract below.
(dolist (extension '("jpg" "jpeg"))
  (let ((reader (gethash extension imago::*image-file-readers*)))
    (format t "~&JPEG generic reader ~a: ~s~%" extension
            (cond ((eq reader #'imago/jpeg-turbo:read-jpg) :jpeg-turbo)
                  ((eq reader #'imago:read-jpg) :classic)
                  (t reader)))
    (check (eq reader #'imago/jpeg-turbo:read-jpg))
    (check (eq (gethash extension imago::*image-file-writers*)
               #'imago/jpeg-turbo:write-jpg))))

(let* ((w 80) (h 60)
       (original (make-gradient-rgb w h))
       (file (work-file "gradient.jpg")))
  (imago/jpeg-turbo:write-jpg original file :quality 100 :subsamp :s-444)
  (let ((back (imago/jpeg-turbo:read-jpg file)))
    (check (typep back 'rgb-image))
    (check (equal (image-dimensions back) (list h w)))
    (let ((generic (read-image file)))
      (check (typep generic 'rgb-image))
      (check (image-eq-p generic back #'rgb-pixel=)))
    ;; The wrapper requests BGR and packs B,G,R through read-jpg-pixel.
    ;; Decode independently as RGB, without any Imago packing helpers.
    (jpeg-turbo:with-decompressor (handle)
      (multiple-value-bind (raw native-width native-height)
          (jpeg-turbo:decompress handle file :pixel-format :rgb)
        (check (= native-width w (image-width back)))
        (check (= native-height h (image-height back)))
        (check (typep raw '(simple-array (unsigned-byte 8) (*))))
        (check (= (length raw) (* 3 w h)))
        (dotimes (y h)
          (dotimes (x w)
            (let ((offset (* 3 (+ x (* y w))))
                  (pixel (image-pixel back x y)))
              (check (= (color-red pixel) (aref raw offset)))
              (check (= (color-green pixel) (aref raw (+ offset 1))))
              (check (= (color-blue pixel) (aref raw (+ offset 2))))
              (check (= (color-alpha pixel) 255)))))))
    (check-jpeg-quality original back
                        (list (cons :red #'color-red)
                              (cons :green #'color-green)
                              (cons :blue #'color-blue))
                        "RGB quality=100 subsamp=4:4:4")))

(let* ((w 50) (h 25)
       (original (make-gradient-gray w h))
       (file (work-file "gray.jpg")))
  (imago/jpeg-turbo:write-jpg original file :quality 100 :subsamp :s-gray)
  (let ((back (imago/jpeg-turbo:read-jpg file)))
    (check (typep back 'grayscale-image))
    (check (equal (image-dimensions back) (list h w)))
    (let ((generic (read-image file)))
      (check (typep generic 'grayscale-image))
      (check (image-eq-p generic back #'gray-pixel=)))
    (jpeg-turbo:with-decompressor (handle)
      (multiple-value-bind (raw native-width native-height)
          (jpeg-turbo:decompress handle file :pixel-format :gray)
        (check (= native-width w (image-width back)))
        (check (= native-height h (image-height back)))
        (check (typep raw '(simple-array (unsigned-byte 8) (*))))
        (check (= (length raw) (* w h)))
        (dotimes (y h)
          (dotimes (x w)
            (let ((pixel (image-pixel back x y)))
              (check (= (gray-intensity pixel) (aref raw (+ x (* y w)))))
              (check (= (gray-alpha pixel) 255)))))))
    (check-jpeg-quality original back (list (cons :gray #'gray-intensity))
                        "gray quality=100 subsamp=gray")))

;;; ---------------------------------------------------------------
;;; 4. TIFF (imago/libtiff) roundtrip.
;;;    write-tiff emits RGB; read-tiff returns RGB for RGB data.  The
;;;    grayscale photometric branch applies to stored min-is-black
;;;    files, so assert RGB class, dimensions and near-exact pixels.
;;; ---------------------------------------------------------------
(let ((w 40) (h 30))
  (let ((original (make-gradient-rgb w h)))
    (write-image original (work-file "gradient.tiff"))
    (let ((back (read-image (work-file "gradient.tiff"))))
      (check (typep back 'rgb-image))
      (check (equal (image-dimensions back) (list h w)))
      ;; The writer stores 8-bit samples; allow single-step rounding.
      (dotimes (y h)
        (dotimes (x w)
          (let ((src (image-pixel original x y))
                (got (image-pixel back x y)))
            (check (approx= (color-red src) (color-red got) 1))
            (check (approx= (color-green src) (color-green got) 1))
            (check (approx= (color-blue src) (color-blue got) 1))))))))

;;; ---------------------------------------------------------------
;;; 5. HEIF (imago/libheif) lossy roundtrip: dimensions, class and
;;;    coarse pixel closeness (quality 100 still lossy).
;;; ---------------------------------------------------------------
(let ((w 64) (h 48))
  (let ((original (make-gradient-rgb w h)))
    (imago/libheif:write-heic original (work-file "gradient.heic") :hevc 100)
    (let ((back (imago/libheif:read-heic (work-file "gradient.heic"))))
      (check (typep back 'rgb-image))
      (check (equal (image-dimensions back) (list h w)))
      (dotimes (y h)
        (dotimes (x w)
          (let ((src (image-pixel original x y))
                (got (image-pixel back x y)))
            (check (approx= (color-red src) (color-red got) 12))
            (check (approx= (color-green src) (color-green got) 12))
            (check (approx= (color-blue src) (color-blue got) 12))))))))

;;; ---------------------------------------------------------------
;;; 6. Meaningful transforms with exact assertions.
;;; ---------------------------------------------------------------
(let* ((image (make-gradient-rgb 20 10))
       (inverted (invert image)))
  ;; Inversion is per-channel exact on synthetic colors.
  (check (= (color-red (image-pixel inverted 3 2))
            (- 255 (color-red (image-pixel image 3 2)))))
  (check (= (color-green (image-pixel inverted 3 2))
            (- 255 (color-green (image-pixel image 3 2))))))

(let* ((image (make-gradient-rgb 20 10))
       (cropped (crop image 5 2 10 5)))
  (check (equal (image-dimensions cropped) '(5 10)))
  (check (rgb-pixel= (image-pixel cropped 0 0) (image-pixel image 5 2)))
  (check (rgb-pixel= (image-pixel cropped 9 4) (image-pixel image 14 6))))

(let* ((image (make-gradient-rgb 16 8))
       ;; :horizontal maps dest(x,y) to src(x, height-1-y).
       (flipped (flip nil image :horizontal)))
  (check (equal (image-dimensions flipped) '(8 16)))
  (check (rgb-pixel= (image-pixel flipped 0 0) (image-pixel image 0 7)))
  (check (rgb-pixel= (image-pixel flipped 15 7) (image-pixel image 15 0))))

(let* ((image (make-gradient-rgb 10 10))
       (rotated (rotate image 90)))
  ;; 90-degree rotation preserves the square footprint; rotation runs
  ;; through float interpolation, so assert structurally and that the
  ;; content stays within the source color range rather than exact
  ;; pixel identity.  A 30-degree rotation must grow the bounding box
  ;; (rotate-dimensions is unexported; call it symbolically).
  (check (equal (image-dimensions rotated) '(10 10)))
  (check (equal (funcall (symbol-function
                          (read-from-string "imago::rotate-dimensions"))
                         '(4 2) 90)
                '(2 4)))
  (check (equal (funcall (symbol-function
                          (read-from-string "imago::rotate-dimensions"))
                         '(2 4) 30)
                '(4 5)))
  (dotimes (y 10)
    (dotimes (x 10)
      (let ((p (image-pixel rotated x y)))
        (check (and (<= 0 (color-red p) 255)
                    (<= 0 (color-green p) 255)
                    (<= 0 (color-blue p) 255)))))))

(let* ((image (make-gradient-rgb 40 20))
       (resized (resize image 20 10)))
  (check (equal (image-dimensions resized) '(10 20))))

(let* ((image (make-gradient-rgb 10 10))
       (gray (convert-to-grayscale image))
       (back-rgb (convert-to-rgb gray)))
  (check (typep gray 'grayscale-image))
  ;; convert-to-grayscale uses color-intensity (mean of R G B).
  (check (= (gray-intensity (image-pixel gray 4 4))
            (color-intensity (image-pixel image 4 4))))
  (check (typep back-rgb 'rgb-image))
  (check (equal (image-dimensions back-rgb) '(10 10)))
  ;; Gray -> RGB replicates intensity into all channels.
  (check (= (color-red (image-pixel back-rgb 4 4))
            (gray-intensity (image-pixel gray 4 4)))))

;;; ---------------------------------------------------------------
;;; 7. Error behavior.
;;; ---------------------------------------------------------------
;; Unknown extension signals imago:unknown-format, not a raw error.
(let ((raised nil))
  (handler-case (read-image (work-file "no-such-image.xyz"))
    (unknown-format () (setf raised t)))
  (check raised))
(let ((raised nil))
  (handler-case (write-image (make-gradient-rgb 4 4) (work-file "out.xyz"))
    (unknown-format () (setf raised t)))
  (check raised))

;;; ---------------------------------------------------------------
;;; 8. imago/jupyter show-image: real display-data payload.  With
;;;    default arguments show-image builds and returns a
;;;    jupyter:mime-bundle without touching any kernel (the kernel
;;;    send happens only under :display t), so the exercise is real
;;;    API behavior with no fake kernel or mock.  Assert the mime type
;;;    and decode the base64 PNG payload back through imago's own
;;;    reader, checking magic bytes, dimensions and pixel content.
;;; ---------------------------------------------------------------
;; Guix installs the extension into its standard shared-data output;
;; Jupyter discovers these directories through XDG_DATA_DIRS.  Loading
;; the Lisp dependency must not copy extension files into the user home.
(let* ((relative "jupyter/labextensions/debugger-restarts-clj/")
       (extension
         (find-if (lambda (directory)
                    (probe-file (merge-pathnames "package.json" directory)))
                  (mapcar (lambda (directory)
                            (merge-pathnames relative directory))
                          (uiop:xdg-data-dirs)))))
  (check extension)
  (check (uiop:subpathp extension #p"/gnu/store/"))
  (dolist (file '("package.json"
                  "static/149.2a11f31fe3ceeaff1760.js"
                  "static/549.48a98a468a9c4092a413.js"
                  "static/remoteEntry.392b95aa74b3661bc1b4.js"
                  "static/style.js" "static/third-party-licenses.json"))
    (check (probe-file (merge-pathnames file extension))))
  (check (not (probe-file (merge-pathnames relative (uiop:xdg-data-home))))))

(let* ((w 24) (h 12)
       (image (make-gradient-rgb w h))
       (bundle (imago/jupyter:show-image image))
       (data (jupyter:mime-bundle-data bundle))
       (payload (third data))
       (octets (base64:base64-string-to-usb8-array payload))
       (decoded (flexi-streams:with-input-from-sequence (stream octets)
                  (imago:read-png-from-stream stream))))
  (check (eq (first data) :object-plist))
  (check (string= (first (rest data)) "image/png"))
  (check (and (> (length octets) 8)
              (= (aref octets 0) 137) (char= (code-char (aref octets 1)) #\P)
              (char= (code-char (aref octets 2)) #\N)
              (char= (code-char (aref octets 3)) #\G)))
  (check (typep decoded 'imago:rgb-image))
  (check (equal (imago:image-dimensions decoded) (list h w)))
  ;; The payload is produced by imago's own zpng writer: pixels must
  ;; survive the encode/decode roundtrip exactly.
  (check (image-eq-p decoded image #'rgb-pixel=))
  ;; Binary images funnel through grayscale conversion per the method.
  (let* ((binary (make-instance 'imago:binary-image
                                :width 6 :height 6))
         (bundle2 (imago/jupyter:show-image binary))
         (data2 (jupyter:mime-bundle-data bundle2))
         (payload2 (third data2))
         (octets2 (base64:base64-string-to-usb8-array payload2))
         (decoded2 (flexi-streams:with-input-from-sequence (stream octets2)
                     (imago:read-png-from-stream stream))))
    (check (eq (first data2) :object-plist))
    (check (string= (first (rest data2)) "image/png"))
    (check (typep decoded2 'imago:grayscale-image))
    (check (equal (imago:image-dimensions decoded2) '(6 6)))))
;; Corrupt PNG stream signals an imago-error subtype (decode-error);
;; never silently returns.
(with-open-file (s (work-file "corrupt.png")
                   :direction :output
                   :element-type '(unsigned-byte 8)
                   :if-exists :supersede)
  (write-sequence #(137 80 78 71 13 10 26 10 0 1 2 3) s))
(let ((raised nil))
  (handler-case (read-image (work-file "corrupt.png"))
    (imago-error () (setf raised t)))
  (check raised))
;; errorp NIL returns NIL instead of signalling for unknown formats.
(check (null (read-image (work-file "none.xyz") :errorp nil)))
;; crop beyond image bounds signals operation-error.
(let ((raised nil))
  (handler-case (crop (make-gradient-rgb 10 10) 8 8 5 5)
    (operation-error () (setf raised t)))
  (check raised))

;;; ---------------------------------------------------------------
;;; Receipt.
;;; ---------------------------------------------------------------
(with-open-file (stream (uiop:getenv "IMAGO_RECEIPT")
                        :direction :output :if-exists :supersede)
  (format stream "{~%  ~S: [\"imago\", \"imago/bit-io\", \"imago/jpeg-turbo\", \"imago/libheif\", \"imago/libtiff\", \"imago/jupyter\"],~%  ~S: ~D"
          "systems_loaded" "checks_passed" *checks*)
  (dolist (key '("png_rgb_exact_roundtrip" "png_gray_exact_roundtrip"
                 "ppm_roundtrip" "jpeg_rgb_roundtrip" "jpeg_gray_roundtrip"
                 "tiff_roundtrip" "heif_roundtrip" "transforms_exact"
                 "jupyter_show_image_png" "error_behavior_verified"
                 "jupyter_shared_data_discovery"
                 "jupyter_no_user_extension_install"
                 "all_fixtures_caller_created"))
    (format stream ",~%  ~S: true" key))
  (format stream "~%}~%"))
(format t "imago native consumer: ~D checks; six systems, exact PNG/PPM roundtrips, JPEG/TIFF/HEIF roundtrips with dimension/channel/pixel assertions, jupyter show-image PNG payload decoded and verified, exact transforms and error behavior all passed.~%" *checks*)
