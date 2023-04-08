#!/usr/bin/env janet

# Simple user story
# I type some bullshit command
# I then type coach n --tags="databases,yugabyte,whatnot" "bullshit command"


(defn new-note
  "creates a new note with no ancestors"
  [body & tags]
  @{:body body
    :date (os/date)
    :edits @[]
    :tags tags
    })

# To make an brand-new notebook file, do
# (write-notebook "your-filename.jimage" (empty-notebook))
(defn empty-notebook
  "produces an empty notebook. Not often needed"
  [] @{:notes @[]})

# We want to keep an image with
(defn write-notebook
  "writes notes as a pickle into the given filename"
  [filename notes]
  (spit filename (marshal notes make-image-dict)))

(defn read-notebook
  "reads notes from the disk"
  [filename]
  (load-image (slurp filename)))

(defn n
  "write a new note into a notebook"
  [filename body & tags]
  # This'll tend to corrupt notebooks
  # if you're very lucky - consider
  # an emacs-like backup scheme or something.
  (let [note (new-note body ;tags)
	book (read-notebook filename)]
    (array/push (book :notes) note)
    (write-notebook filename book)))

# TODO give this a PEG or a predicate or something
(defn match-note
  "simple substring search for a note"
  [filename needle]
  (let [book (read-notebook filename)]
 (find |(string/find needle ($ :body)) (book :notes))))

(defn cat
  [filename]
  (let [book (read-notebook filename)]
    (each note (book :notes) (printf "%p" note))))
