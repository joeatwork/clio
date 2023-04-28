(import sh)
(import cmd)
(import ./src/clio)

(defn edit-string
  "dumps a string into an editor, opens $EDITOR"
  [&opt s]
  (let [editor-bin (or ((os/environ) "CLIO_EDITOR") ((os/environ) "EDITOR") "vi")
        tfile (sh/$<_ mktemp -t "clio-scratch")]
    (when s (spit tfile s))
    (sh/$ ,editor-bin ,tfile)
    # leaks the tempfile on failures.
    (def result (slurp tfile))
    (sh/$ rm ,tfile)
    result))

(defn read-stdin
  []
  "slurps stdin into memory and formats it as a note"
  (let [raw (file/read stdin :all)
        headered (if (string/has-prefix? "---\n" raw)
                   raw
                   (clio/reserialize-metas {:timestamp (os/time)} raw))]
    headered))

(defn edit [file id? stdin?]
  (let [previous (if id? (clio/one-note file id?) :empty-note)
        tmpl (clio/to-text previous)
        prev-id (if id? (previous :id) :empty-note)
        new-text (if stdin? (read-stdin) (edit-string tmpl))]
    (clio/insert-note file {:text new-text :previous prev-id})))

(defn cat [file find? id? body-only]
  (let [filter (if find? |(string/find find? $) |(do $& true))
        unfiltered (if id? [(clio/one-note file id?)]
                     (clio/all-notes file))]
    (each n unfiltered
      (def txt (n :text))
      (unless (nil? (filter txt))
        (if body-only
          (print (clio/body txt))
          (do
            (print "id: " (n :id))
            (if (not= (n :previous) :empty-note)
              (print "previous: " (n :previous)))
            (print txt)))))))

(defn or-default-file [f?]
  (or f? (string/format "%s/notes.sqlite" (os/getenv "HOME"))))

(cmd/main
  (cmd/group
    "a note-taking tool for the command line"
    edit (cmd/fn "create or edit a note interactively"
                 [--id "id or title of an existing note" (optional ["ID" :string])
                  --file "name of a notebook file for storing your note" (optional :file)
                  --stdin "read the note from standard input rather than opening an editor" (flag)]
                 (edit (or-default-file file) id stdin))
    cat (cmd/fn "print notes to stdout"
                [--body "omit headers and metadata from output" (flag)
                 --id "id or title of an existing note" (optional ["ID" :string])
                 --find "print only notes containing this text" (optional :string)
                 --file "name of a notebook file to open" (optional :file)]
                (cat (or-default-file file) find id body))
    init (cmd/fn "create or update a notebook file to work with the current version of clio"
                 [--file "name of a notebook file" (optional :file)]
                 (let [f (or-default-file file)]
                   (clio/initialize-notebook (or-default-file file))))
    templ (cmd/fn "create a note by expanding another note as a mustache template"
                  [--file "name of a notebook file" (optional :file)
                   template-id "id or name of a template" (required ["ID" :string])
                   kvs "list of key/value pairs for the template" (escape ["KEY/VALUE" :string])]
                  (let [kwd_kvs (mapcat |[(keyword ($ kvs)) ((+ $ 1) kvs)] (range 0 (length kvs) 2))
                        env (struct ;kwd_kvs)]
                    (clio/note-from-template (or-default-file file) template-id env)))))
