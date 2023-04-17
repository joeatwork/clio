(import sqlite3)
(import musty)

(import ./schema)

(def empty-note-text
  "---\ntags:\n---\nPut the body of your note here\n")

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
  (peg/compile ~{:time (* (<- (2 :d)) ":" (<- (2 :d)) (? (* ":" (<- (2 :d)))))
                 :date (* (<- (4 :d)) "-" (<- (2 :d)) "-" (<- (2 :d)))
                 :main (* :date (? (* "T" :time)) -1)}))

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
  (peg/compile ~{:meta-key (some (if-not (+ ":" "\n") 1))
                 :meta-val (any (if-not "\n" 1))
                 :meta-line (* (<- :meta-key) ":" (<- :meta-val) "\n")
                 :metas (+ "---\n" (* :meta-line :metas))
                 :main (* "---\n" :metas)}))

(defn parse-metas
  "parses metadata like tags and timestamp out of note text"
  [note-text]
  (let [raw-metas (peg/match note-metas-peg note-text)
        cleaned (map string/trim raw-metas)
        metas (struct ;cleaned)
        mts (metas "timestamp")
        mtags (metas "tags")
        title (metas "title")
        timestamp (or (when mts
                        (when-let
                          [parse (peg/match timestamp-peg mts)]
                          (parsed-timestamp-to-time ;parse)))
                      (os/time))
        tags (or
               (when mtags (map string/trim (string/split "," mtags)))
               [])]
    {:timestamp timestamp :tags (tuple ;tags) :title title}))

(defn- note-defaults
  "Assumes {:id :text} from table"
  [result]
  (let [now (os/time)]
    (table/to-struct (merge {:previous :empty-note :timestamp now} result))))

(defn initialize-notebook
  "creates or updates a SQLite file containing a notebook schema"
  [filename]
  (let [db (sqlite3/open filename)]
    (schema/migrate-schema-forward db)))

(defn insert-note
  "adds a note to a SQLite database file named bookname"
  [bookname note]
  (let [note (note-defaults note)
        previd (note :previous)
        previous (when (not= :empty-note previd) previd)
        text (note :text)
        metas (parse-metas text)
        db (sqlite3/open bookname)]
    (sqlite3/eval db `
       INSERT INTO notes (timestamp, text, title, previous)
         VALUES (:timestamp, :text, :title, :previous)
       ` {:timestamp (metas :timestamp)
          :text text
          :previous previous
          :title (metas :title)})

    (def new_id (sqlite3/last-insert-rowid db))
    (sqlite3/eval db "BEGIN TRANSACTION")
    (each tag (metas :tags)
      (sqlite3/eval db `
         INSERT INTO tags (tag, note)
           VALUES (:tag, :new_id)  
         ` {:tag tag :new_id new_id}))
    (sqlite3/eval db "COMMIT")))

(defn all-notes
  "gets all \"current\" notes from a SQLite database file named bookname"
  [bookname]
  (def db (sqlite3/open bookname))
  (def results
    (sqlite3/eval db `
        SELECT n.rowid AS id, n.text, n.previous, n.title, n.timestamp
        FROM notes AS n
          LEFT JOIN notes AS edits ON n.rowid=edits.previous
        WHERE edits.previous IS NULL
        ORDER BY n.timestamp DESC`))
  (map note-defaults results))

(defn one-note
  "gets the note for the given id or title"
  [file identifier]
  (def db (sqlite3/open file))
  (def results
    # sorting hack also relies on all "previous" ids being
    # smaller than descendant ids, and NULL titles sorting
    # behind non-null titles.
    (sqlite3/eval db `
        SELECT rowid AS id, text, previous, title, timestamp
        FROM notes
        WHERE rowid = :identifier
          OR title = :identifier
        ORDER BY title DESC, rowid DESC
        LIMIT 1` {:identifier identifier}))
  (note-defaults (first results)))

(defn note-from-template
  "uses a given id as a template to create and insert a new note"
  [file template-id env]
  (let [templ (one-note file template-id)
        new-text (musty/render (templ :text) env)]
    (insert-note file {:text new-text :previous :empty-note})
    (print new-text)))
