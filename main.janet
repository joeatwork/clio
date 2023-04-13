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
        tmpl (clio/to-text :empty-note)
        new-text (edit-string tmpl)]
    (clio/insert-note notebook-name {:text new-text :previous :empty-note})))

(defn init [opts]
  (let [notebook-name (opts "file")]
    (clio/initialize-notebook notebook-name)))

(defn cat [opts]
  (let [notebook-name (opts "file")
        needle (opts "find")
        filter (if needle |(string/find needle $) |(do $& true))]
    (each n (clio/all-notes notebook-name)
      (unless (nil? (filter (n :text)))
        (print (n :text))))))

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
               :default "notes.sqlite"}
              "find"
              {:kind :option
               :help "for \"cat\", include only notes containing this string"}))

  (cond
    (opts "note") (note opts)
    (opts "cat") (cat opts)
    (opts "init") (init opts)
    (print "call with --cat, --note, or --init")))
