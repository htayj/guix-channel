;; Real consumer of the installed pmatiello/tui jar; no source-tree classpath.
(require '[clojure.java.io :as io]
         '[clojure.string :as string]
         '[me.pmatiello.tui.core :as tui])

(defn tui-smoke-assert [condition message]
  (when-not condition (throw (ex-info message {}))))

(let [esc "\u001b["
      styled (fn [style body] {:style style :body body})]
  (tui-smoke-assert (= "" (tui/render nil) (tui/render [])) "empty page boundary")
  (tui-smoke-assert (= "A café λ" (tui/render [\A " " "café λ"])) "Unicode/character page")
  (tui-smoke-assert (= "a:b" (tui/render ["a" "b"] {:separator ":"})) "plain separator")
  (tui-smoke-assert (= (str "a" esc "4m|" esc "0mb")
             (tui/render ["a" "b"] {:separator (styled [:underline] "|")}))
          "styled separator and reset")
  (tui-smoke-assert (= (str esc "1m" esc "31m" esc "44mX" esc "0mY")
             (tui/render [(styled [:bold :fg-red :bg-blue] "X") "Y"]))
          "ordered styles and reset boundary")
  (tui-smoke-assert (= "a b" (with-out-str (tui/print "a" "b"))) "variadic print")
  (tui-smoke-assert (= "a b\n" (with-out-str (tui/println "a" "b"))) "println newline")
  (tui-smoke-assert (= "\n" (with-out-str (tui/println))) "empty println boundary")
  (tui-smoke-assert (try (tui/render [(styled [:not-a-style] "X")]) false
               (catch AssertionError _ true)) "invalid style rejection"))

(defn row [body styles]
  ;; Fixed text geometry belongs to this consumer, not to a nonexistent Tui
  ;; layout API.  Each row is exactly 40 visible columns including the border.
  (tui-smoke-assert (<= (count body) 36) "row exceeds 40-column geometry")
  (tui/println
   (tui/render ["| " {:style styles :body body}
                (apply str (repeat (- 36 (count body)) " ")) " |"])))

(tui/println "+--------------------------------------+")
(row "TUI installed consumer" [:bold :fg-cyan])
(row "red on blue" [:fg-red :bg-blue])
(row "green underline" [:fg-green :underline])
(row "Unicode: café λ" [])
(tui/println "+--------------------------------------+")
(tui/print "Name> ")
(tui/flush)

(let [name (tui/read-line)]
  (tui-smoke-assert (= name "Alice") "real cooked read-line input")
  (tui/println {:style [:bold :fg-green] :body (str "Hello, " name "!")})
  (tui/print "Lines (EOF to finish)> ")
  (tui/flush)
  (let [lines (vec (tui/read-lines))
        resource (str (io/resource "me/pmatiello/tui/core.clj"))]
    (tui-smoke-assert (= ["first" "second"] lines) "real read-lines/EOF input")
    (tui-smoke-assert (string/starts-with? resource "jar:file:/gnu/store/")
            "library must load from an installed store jar")
    (spit (first *command-line-args*)
          (str "{\"core_resource\":" (pr-str resource)
               ",\"runtime_version\":" (pr-str (clojure-version))
               ",\"name\":" (pr-str name)
               ",\"lines\":[" (string/join "," (map pr-str lines))
               "],\"render_checks\":true}\n"))
    (tui/println (str "LINES=" (string/join "|" lines)))
    (tui/println "TUI_RUNTIME_OK")
    (tui/flush)))
