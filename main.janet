(import sh)
(import ./src/clio)

(defn edit-string
  "dumps a string into an editor, opens $EDITOR"
  [&opt s]
  (let [editor-bin (or ((os/environ) "EDITOR") "vi")
	tfile (sh/$<_ mktemp -t "clio-scratch")]
    (when s (spit tfile s))
    (sh/$ ,editor-bin ,tfile)
    # leaks the tempfile on failures.
    (def result (slurp tfile))
    (sh/$ rm ,tfile)
    result))


(defn main [&]
  (let [tmpl (clio/to-text :empty-note)
	new-text (edit-string tmpl)
	new-meta (clio/parse-metas new-text)]
    (pp new-meta)
    (print new-text)))
	
