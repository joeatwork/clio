(import sh)
(import spork/argparse)
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

(defn note [opts]
  (let [notebook-name (opts "file")
        book (try
               (clio/read-notebook notebook-name)
               ([err]
                 (do
                   (eprintf "can't find %s: creating" notebook-name)
                   (clio/empty-notebook))))
        tmpl (clio/to-text :empty-note)
        new-text (edit-string tmpl)
        new-book (clio/add-note! book new-text)]
    (clio/write-notebook notebook-name new-book)))

(defn init [opts]
  (let [notebook-name (opts "file")]
    (clio/write-notebook notebook-name (clio/empty-notebook))))

(defn cat [opts]
  (let [notebook-name (opts "file")]
    (clio/cat notebook-name)))

(defn main [&]
  (def opts (argparse/argparse
              "a note-taking tool for the command line"
              "note"
              {:kind :flag
               :help "create a new note"}
              "cat"
              {:kind :flag
               :help "dump all notes to standard output"}
              "init"
              {:kind :flag
               :help "create a new notebook file"}
              "file"
              {:kind :option
               :help "name of notebook file"
               :default "notes.jimage"}))

  (cond
    (opts "note") (note opts)
    (opts "cat") (cat opts)
    (opts "init") (init opts)
    (print "call with --cat, --note, or --init")))
