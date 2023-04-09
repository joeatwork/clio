#!/usr/bin/env jane#!/usr/bin/env janet

# Simple user story
# I type some bullshit command
# I then type coach n --tags="databases,yugabyte,whatnot" "bullshit command"

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

# TODO remove
(defn cat
  [filename]
  (let [book (read-notebook filename)]
    (each note (book :notes) (printf "%p" note))))

(def empty-note-text
    "---\ntags:\ntimestamp: auto\n---\nPut the body of your note here\n")

(defn to-text
  [note]
  (if (= note :empty-note)
    empty-note-text
    (note :text)))

(defn parsed-timestamp-to-time
  "takes strings pulled from a timestamp-peg style timestamp and returns unixtime"
  [year month day &opt hour minute second]
  (os/mktime {:year (scan-number year)
	      :month (- (scan-number month) 1)
	      :month-day (- (scan-number day) 1)
	      :hours (when hour (scan-number hour))
	      :minutes (when minute (scan-number minute))
	      :seconds (when second (scan-number second))}))

# A likely buggy local ISO 8601 timestamp
(def timestamp-peg
  (peg/compile ~{
		:time (* (<- (2 :d)) ":" (<- (2 :d)) (? (* ":" (<- (2 :d)))))
		:date (* (<- (4 :d)) "-" (<- (2 :d)) "-" (<- (2 :d)))
		:main (* :date (? (* "T" :time)) -1)
		}))

(defn format-timestamp
  [unixtime]
  (let [date (os/date unixtime)]
    (string/format "%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2d"
		   (date :year)
		   (+ (date :month) 1)

		   (+ (date :month-day) 1)
		   (date :hours)
		   (date :minutes)
		   (date :seconds))))


(def note-metas-peg
  (peg/compile ~{
		:meta-key (some (if-not (+ ":" "\n") 1))
		:meta-val (any (if-not "\n" 1))
		:meta-line (* (<- :meta-key) ":" (<- :meta-val) "\n")
		:metas (+ "---\n" (* :meta-line :metas))
		:main (* "---\n" :metas)
		}))

(defn parse-metas
  [note-text]
  (let [raw-metas (peg/match note-metas-peg note-text)
	cleaned (map string/trim raw-metas)
	metas (struct ;cleaned)
	mts (metas "timestamp")
	mtags (metas "tags")
	timestamp (or
		    (when mts (parsed-timestamp-to-time
			       ;(peg/match timestamp-peg mts)))
		    (os/time))
	tags (or
	       (when mtags (map string/trim (string/split "," mtags)))
	       [])
       ]
    {:timestamp timestamp :tags (tuple ;tags)}))
    
