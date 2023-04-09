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

# TODO this should be an argument or
# env var or whatnot
(def notebook-name "devnotes.jimage")

(defn main [&]
  (let [book (try
	       (clio/read-notebook notebook-name)
	       ([err]
		(do
		  (eprintf "can't find %s: creating" notebook-name)
		  (clio/empty-notebook))))
	tmpl (clio/to-text :empty-note)
	new-text (edit-string tmpl)
	new-book (clio/add-note! book new-text)
       ]
    (clio/write-notebook notebook-name new-book)))
	
