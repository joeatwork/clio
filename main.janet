(import sh)
(import cmd)
(import ./src/clio)

# Here's a use case I'd like to cover:
#
#     $ missles_away --please
#     $ clio -t command :note "fires the missles" :command "!!"
#     $ clio cat --find "fires"
#     ---
#     tags: command
#     ---
#     # fires the missles
#     missles_away --please
#

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

(defn edit [file id?]
  (let [previous (if id? (clio/note-by-id file id?) :empty-note)
        tmpl (clio/to-text previous)
        prev-id (or id? :empty-note)
        new-text (edit-string tmpl)]
    (clio/insert-note file {:text new-text :previous prev-id})))

(defn cat [file find?]
  (let [filter (if find? |(string/find find? $) |(do $& true))]
    (each n (clio/all-notes file)
      (unless (nil? (filter (n :text)))
        (print "id: " (n :id))
        (if (not= (n :previous) :empty-note)
          (print "previous: " (n :previous)))
        (print (n :text))))))

(cmd/main
  (cmd/group
    "a note-taking tool for the command line"
    edit (cmd/fn "create or edit a note"
                 [--id "id of an existing note" (optional :string)
                  --file "name of a notebook file" (optional :string "notes.sqlite")]
                 (edit file id))
    cat (cmd/fn "print notes to stdout"
                [--find "print only notes containing this text"
                 (optional :string)
                 --file "name of a notebook file" (optional :string "notes.sqlite")]
                (cat file find))
    init (cmd/fn "create a new notebook file"
                 [--file "name of a notebook file" (optional :string "notes.sqlite")]
                 (clio/initialize-notebook file))))
