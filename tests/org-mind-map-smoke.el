;;; org-mind-map-smoke.el --- Installed offline SVG proof -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'xml)
(require 'ox-org)
(require 'org-mind-map)

(defconst org-mind-map-smoke--plain
  "* Plan\n** Design\n*** Sketch :research:\nCapture user goals.\n** Build\n*** Assemble\nConnect local parts.\n*** Check\nVerify final result.\n* Other\n** Later\nKeep unrelated work.\n")

;; Original 32x32 blue-and-gold checkerboard, generated from RGB pixels for
;; this test.  No upstream example image or screenshot is redistributed.
(defconst org-mind-map-smoke--png
  "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAAQklEQVR4nGP4uk8XK9JouoQVkaqeYdSCUQuGgAXUMgiX+lELRi0YChZQyyBc6kctGLVgKFhALYNwqR+1YNSCIWABACtCuFsJJ6OEAAAAAElFTkSuQmCC")

(defun org-mind-map-smoke--assert (condition format-string &rest args)
  (unless condition
    (error "org-mind-map smoke: %s" (apply #'format format-string args))))

(defun org-mind-map-smoke--elements (tree tag)
  "Return all elements with TAG, including TREE, in document order."
  (when (consp tree)
    (append (when (eq (car tree) tag) (list tree))
            (cl-mapcan (lambda (child)
                         (org-mind-map-smoke--elements child tag))
                       (cddr tree)))))

(defun org-mind-map-smoke--text (tree)
  (if (stringp tree) tree
    (mapconcat #'org-mind-map-smoke--text (cddr tree) "")))

(defun org-mind-map-smoke--texts (tree)
  (cl-remove-if #'string-empty-p
                (mapcar (lambda (node)
                          (string-trim (org-mind-map-smoke--text node)))
                        (org-mind-map-smoke--elements tree 'text))))

(defun org-mind-map-smoke--title (tree)
  (let ((titles (org-mind-map-smoke--elements tree 'title)))
    (org-mind-map-smoke--assert (= (length titles) 1)
                               "SVG group lacks a unique title: %S" tree)
    (org-mind-map-smoke--text (car titles))))

(defun org-mind-map-smoke--read-svg (file)
  (with-temp-buffer
    (insert-file-contents file)
    (let ((tree (if (fboundp 'libxml-parse-xml-region)
                    (libxml-parse-xml-region (point-min) (point-max))
                  (car (xml-parse-region (point-min) (point-max))))))
      (org-mind-map-smoke--assert (eq (car tree) 'svg)
                                 "%s is not an SVG document" file)
      tree)))

(defun org-mind-map-smoke--check-bounds (tree file)
  "Check Graphviz's transformed graph envelope fits TREE's SVG viewBox."
  (let* ((graphs (cl-remove-if-not
                  (lambda (g) (equal (xml-get-attribute g 'class) "graph"))
                  (org-mind-map-smoke--elements tree 'g)))
         (graph (car graphs))
         ;; Only the graph's direct polygon is its enclosing background;
         ;; descendant polygons are node shapes and edge arrowheads.
         (polygons (cl-remove-if-not
                    (lambda (child) (and (consp child) (eq (car child) 'polygon)))
                    (cddr graph)))
         (view-box (mapcar #'string-to-number
                           (split-string (or (xml-get-attribute tree 'viewBox) "")
                                         "[ ,\t\r\n]+" t)))
         (transform (or (xml-get-attribute graph 'transform) "")))
    (org-mind-map-smoke--assert
     (and (= (length graphs) 1) (= (length polygons) 1)
          (= (length view-box) 4)
          (> (nth 2 view-box) 0) (> (nth 3 view-box) 0)
          (string-match
           (concat "\\`scale(\\([^()]+\\))[[:space:]]*"
                   "rotate(\\([^()]+\\))[[:space:]]*"
                   "translate(\\([^()]+\\))\\'")
           transform))
     "missing graph envelope, viewBox or Graphviz transform in %s" file)
    (let* ((scale-arguments (match-string 1 transform))
           (rotation-argument (match-string 2 transform))
           (translation-arguments (match-string 3 transform))
           (scale (mapcar #'string-to-number
                          (split-string scale-arguments "[ ,]+" t)))
           (rotation (string-to-number rotation-argument))
           (translation (mapcar #'string-to-number
                                (split-string translation-arguments "[ ,]+" t)))
           (points (mapcar
                    (lambda (point)
                      (mapcar #'string-to-number (split-string point "," t)))
                    (split-string (or (xml-get-attribute (car polygons) 'points) "")
                                  "[[:space:]]+" t)))
           (angle (* rotation (/ float-pi 180.0)))
           (cosine (cos angle))
           (sine (sin angle))
           ;; Graphviz rounds viewBox dimensions and transform coefficients.
           (tolerance 0.02))
      (org-mind-map-smoke--assert
       (and (= (length scale) 2) (= (length translation) 2)
            (>= (length points) 4)
            (cl-every (lambda (point) (= (length point) 2)) points))
       "malformed graph envelope or transform in %s" file)
      ;; SVG applies this transform list right-to-left.  The background
      ;; envelope encloses the whole graph, including nodes, edges and images.
      (dolist (point points)
        (let* ((x (+ (car point) (car translation)))
               (y (+ (cadr point) (cadr translation)))
               (svg-x (* (car scale) (- (* cosine x) (* sine y))))
               (svg-y (* (cadr scale) (+ (* sine x) (* cosine y)))))
          (org-mind-map-smoke--assert
           (and (<= (- (nth 0 view-box) tolerance) svg-x
                    (+ (nth 0 view-box) (nth 2 view-box) tolerance))
                (<= (- (nth 1 view-box) tolerance) svg-y
                    (+ (nth 1 view-box) (nth 3 view-box) tolerance)))
           "graph envelope is clipped in %s: transformed point (%g, %g), viewBox %S"
           file svg-x svg-y view-box))))))

(defun org-mind-map-smoke--check-graph (file expected-nodes expected-edges)
  "Check semantic labels and directed topology, ignoring only the Legend.
EXPECTED-NODES maps heading to the complete ordered list of visible text.
SVG IDs identify nodes; their titles resolve the opaque edge endpoint names.
No generated DOT node name or Graphviz node numbering is assumed."
  (let* ((tree (org-mind-map-smoke--read-svg file))
         (groups (org-mind-map-smoke--elements tree 'g))
         (nodes (cl-remove-if-not
                 (lambda (g) (equal (xml-get-attribute g 'class) "node")) groups))
         (edges (cl-remove-if-not
                 (lambda (g) (equal (xml-get-attribute g 'class) "edge")) groups))
         (title-to-id (make-hash-table :test 'equal))
         (heading-to-id (make-hash-table :test 'equal))
         (id-to-title (make-hash-table :test 'equal))
         (id-to-heading (make-hash-table :test 'equal))
         actual-nodes actual-edges)
    (org-mind-map-smoke--check-bounds tree file)
    (dolist (node nodes)
      (let ((title (org-mind-map-smoke--title node))
            (id (xml-get-attribute node 'id))
            (texts (org-mind-map-smoke--texts node)))
        (unless (equal title "Legend")
          (org-mind-map-smoke--assert
           (and id (not (gethash id id-to-title))
                (not (gethash title title-to-id))
                (not (gethash (car texts) heading-to-id)))
           "duplicate or missing SVG node identity in %s" file)
          (puthash title id title-to-id)
          (puthash id title id-to-title)
          (puthash (car texts) id heading-to-id)
          (puthash id (car texts) id-to-heading)
          (push (cons (car texts) texts) actual-nodes))))
    (org-mind-map-smoke--assert
     (equal (sort (copy-tree actual-nodes) (lambda (a b) (string< (car a) (car b))))
            (sort (copy-tree expected-nodes)
                  (lambda (a b) (string< (car a) (car b)))))
     "wrong heading/text semantic set in %s: %S" file actual-nodes)
    ;; Resolve each edge against node titles obtained from XML, then compare
    ;; directed heading pairs.  The polygon proves an arrowhead was rendered.
    (dolist (edge edges)
      (let ((title (org-mind-map-smoke--title edge)) matches)
        (maphash
         (lambda (from from-id)
           (maphash
            (lambda (to to-id)
              (when (equal title (concat from "->" to))
                (push (list (gethash from-id id-to-heading)
                            (gethash to-id id-to-heading)) matches)))
            title-to-id))
         title-to-id)
        (org-mind-map-smoke--assert
         (and (= (length matches) 1)
              (org-mind-map-smoke--elements edge 'path)
              (org-mind-map-smoke--elements edge 'polygon))
         "unresolved or non-directed SVG edge in %s: %S" file title)
        (push (car matches) actual-edges)))
    (org-mind-map-smoke--assert
     (equal (sort (copy-tree actual-edges)
                  (lambda (a b) (string< (prin1-to-string a)
                                        (prin1-to-string b))))
            (sort (copy-tree expected-edges)
                  (lambda (a b) (string< (prin1-to-string a)
                                        (prin1-to-string b)))))
     "wrong directed edges/count in %s: %S" file actual-edges)
    (message "%s: %d semantic nodes, %d directed edges" file
             (length actual-nodes) (length actual-edges))
    tree))

(defun org-mind-map-smoke--render (name)
  "Run the public writer and await its real asynchronous Graphviz process."
  (let* ((output (org-mind-map-write-named name (concat name ".dot") nil))
         (process (get-process "org-mind-map-s"))
         (deadline (+ (float-time) 30)))
    (org-mind-map-smoke--assert process "writer did not start its process")
    (unwind-protect
        (progn
          (while (and (process-live-p process) (< (float-time) deadline))
            (accept-process-output process 0.1))
          ;; Drain output and deliver the upstream sentinel before inspection.
          (accept-process-output process 0.1)
          (org-mind-map-smoke--assert
           (and (eq (process-status process) 'exit)
                (zerop (process-exit-status process)))
           "Graphviz process failed/timed out: %S, exit %s; %s"
           (process-status process) (process-exit-status process)
           (with-current-buffer (process-buffer process) (buffer-string)))
          (let ((diagnostics (with-current-buffer (process-buffer process)
                               (buffer-string))))
            (with-temp-file (concat name ".log") (insert diagnostics))
            ;; Do not suppress harmless upstream/Graphviz warnings, but fail
            ;; diagnostics reporting an error even if the shell pipeline exits 0.
            (org-mind-map-smoke--assert
             (not (string-match-p "\\b[Ee][Rr][Rr][Oo][Rr]\\b" diagnostics))
             "Graphviz reported an error: %s" diagnostics))
          (org-mind-map-smoke--assert (file-exists-p output)
                                     "writer produced no SVG: %s" output)
          output)
      (when (process-live-p process) (delete-process process)))))

(defun org-mind-map-smoke--store-command (command)
  "Require a runnable store program without changing package defaults."
  (let ((program (car (split-string-and-unquote command))))
    (org-mind-map-smoke--assert
     (and (string-prefix-p "/gnu/store/" program) (file-executable-p program))
     "Graphviz default is not a runnable absolute store path: %s" command)))

(defun org-mind-map-smoke-run ()
  (let* ((default-directory
           (file-name-as-directory (getenv "ORG_MIND_MAP_SMOKE_ARTIFACTS")))
         (exec-path nil)
         (org-mind-map-dot-output '("svg"))
         (org-mind-map-display nil)
         (org-mind-map-tag-colors '(("research" . "#b6d9ef")))
         (org-mind-map-include-text t)
         (org-mind-map-include-images t)
         (plain-file (expand-file-name "planning.org"))
         (image-file (expand-file-name "image.org"))
         (asset (expand-file-name "original-checkerboard.png"))
         (all-nodes '(("Plan" "Plan") ("Design" "Design")
                      ("Sketch" "Sketch" "research" "Capture user goals.")
                      ("Build" "Build")
                      ("Assemble" "Assemble" "Connect local parts.")
                      ("Check" "Check" "Verify final result.")
                      ("Other" "Other")
                      ("Later" "Later" "Keep unrelated work."))))
    ;; The Emacs wrapper injects PATH; clear it at the consumer boundary.
    (setenv "PATH" "")
    (org-mind-map-smoke--assert (equal (getenv "PATH") "") "PATH is not empty")
    (org-mind-map-smoke--assert (null exec-path) "exec-path is not nil")
    (org-mind-map-smoke--assert
     (string-prefix-p (file-name-as-directory (getenv "ORG_MIND_MAP_SMOKE_PACKAGE"))
                      (file-truename (locate-library "org-mind-map")))
     "org-mind-map was not loaded from the package under test")
    (org-mind-map-smoke--store-command org-mind-map-dot-command)
    (org-mind-map-smoke--store-command org-mind-map-unflatten-command)
    (with-temp-file plain-file (insert org-mind-map-smoke--plain))
    (let ((buffer (find-file-noselect plain-file)))
      (unwind-protect
          (with-current-buffer buffer
            (org-mind-map-smoke--check-graph
             (org-mind-map-smoke--render (expand-file-name "whole-tree"))
             all-nodes '(("Plan" "Design") ("Plan" "Build")
                         ("Design" "Sketch") ("Build" "Assemble")
                         ("Build" "Check") ("Other" "Later")))
            (goto-char (point-min))
            (re-search-forward "^\\*\\* Build$")
            (beginning-of-line)
            ;; Use Org's real subtree restriction with the public named writer
            ;; so both the exact DOT input and rendered SVG can be retained.
            (save-restriction
              (org-narrow-to-subtree)
              (org-mind-map-smoke--check-graph
               (org-mind-map-smoke--render (expand-file-name "build-subtree"))
               (cl-remove-if-not (lambda (n) (member (car n)
                                                   '("Build" "Assemble" "Check")))
                                 all-nodes)
               '(("Build" "Assemble") ("Build" "Check")))))
        (kill-buffer buffer)))
    (let ((coding-system-for-write 'binary))
      (with-temp-file asset
        (set-buffer-multibyte nil)
        (insert (base64-decode-string org-mind-map-smoke--png))))
    (with-temp-file image-file
      (insert "* Picture\n** Tile\n[[file:" asset "]]\n"))
    ;; Separate image-only fixture avoids upstream's paragraph-to-string
    ;; assumption; both exports otherwise use the same installed behavior.
    (let ((buffer (find-file-noselect image-file))
          (org-mind-map-include-text nil))
      (unwind-protect
          (with-current-buffer buffer
            (dolist (enabled '(t nil))
              (let* ((org-mind-map-include-images enabled)
                     (svg (org-mind-map-smoke--render
                           (expand-file-name (if enabled "image-on" "image-off"))))
                     (tree (org-mind-map-smoke--check-graph
                            svg '(("Picture" "Picture") ("Tile" "Tile"))
                            '(("Picture" "Tile"))))
                     (images (org-mind-map-smoke--elements tree 'image)))
                (org-mind-map-smoke--assert
                 (= (length images) (if enabled 1 0))
                 "image toggle produced %d SVG images, enabled=%S"
                 (length images) enabled)
                (when enabled
                  (let* ((image (car images))
                         (href (or (xml-get-attribute image 'xlink:href)
                                   (xml-get-attribute image 'href)))
                         (tile (cl-find-if
                                (lambda (node)
                                  (equal (org-mind-map-smoke--texts node) '("Tile")))
                                (org-mind-map-smoke--elements tree 'g))))
                    (org-mind-map-smoke--assert
                     (and (equal href asset)
                          (member image (org-mind-map-smoke--elements tile 'image))
                          (> (string-to-number (or (xml-get-attribute image 'width) "0")) 0)
                          (> (string-to-number (or (xml-get-attribute image 'height) "0")) 0))
                     "SVG image is not the local asset on Tile: %S" image))))))
        (kill-buffer buffer)))
    (message "org-mind-map installed offline semantic SVG smoke passed")))

;;; org-mind-map-smoke.el ends here
