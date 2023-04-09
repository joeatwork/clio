#!/usr/bin/env janet

# Simple user story
# I type some bullshit command
# I then type coach n --tags="databases,yugabyte,whatnot" "bullshit command"


(defn new-note
  "creates a new note with no ancestors"
  [body & tags]
  {:body body
    :tags tags
    :timestamp (os/time)
    :versions :none
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

# TODO
(defn cat
  [filename]
  (let [book (read-notebook filename)]
    (each note (book :notes) (printf "%p" note))))

(def empty-note-text
    "---\ntags:\n---\nPut the body of your note here\n")

(defn to-text
  [note]
  (if (= note :empty-note)
    empty-note-text
    (let [tag-list (string/join (note :tags) ", ")
	  headers [(string "tags: " tag-list)] ]
      (string
       ;(mapcat |(tuple $ "\n")
		["---" ;headers "---" (note :body)])))))

(defn pair-to-meta
  "parse helper for captured key / value pairs"
  [raw-k raw-v]
  (let [k (string/trim raw-k)
	v (string/trim raw-v)]
  [(keyword k) v]))

# Parses [(k v) (k v) (k v) body] 
(def note-text-peg
  (peg/compile ~{
		:meta-key (some (if-not (+ ":" "\n") 1))
		:meta-val (any (if-not "\n" 1))
		:meta-line (replace (* (<- :meta-key) ":" (<- :meta-val) "\n") ,pair-to-meta)
		:metas (+ "---\n" (* :meta-line :metas))
		:main (* "---\n" :metas (<- (any 1) :body))
		}))

(defn from-text
  [text]
  (let [parsed (peg/match note-text-peg text)
	[body & metas] (reverse! parsed)]
    # TODO parse tags out of metas
    {:body body
     :metas metas }))
