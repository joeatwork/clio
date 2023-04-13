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

(defn edit [opts]
  (let [file (opts "file")
        id (opts "id")
        previous (if id (clio/note-by-id file id) :empty-note)
        tmpl (clio/to-text previous)
        prev-id (or id :empty-note)
        new-text (edit-string tmpl)]
    (clio/insert-note file {:text new-text :previous prev-id})))

(defn init [opts]
  (let [notebook-name (opts "file")]
    (clio/initialize-notebook notebook-name)))

(defn cat [opts]
  (let [notebook-name (opts "file")
        needle (opts "find")
        filter (if needle |(string/find needle $) |(do $& true))]
    (each n (clio/all-notes notebook-name)
      (unless (nil? (filter (n :text)))
        (print "id: " (n :id))
        (if (not= (n :previous) :empty-note)
          (print "previous: " (n :previous)))
        (print (n :text))))))

(defn main [&]
  (def opts (argparse/argparse
              "a note-taking tool for the command line"
              "edit"
              {:kind :flag
               :help "create or edit a note"}
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
              "id"
              {:kind :option
               :help "for \"edit\", the id of an existing note to edit"}
              "find"
              {:kind :option
               :help "for \"cat\", include only notes containing this string"}))

  (cond
    (opts "edit") (edit opts)
    (opts "cat") (cat opts)
    (opts "init") (init opts)
    (print "call with --cat, --edit, or --init")))
