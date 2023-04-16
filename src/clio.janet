(import sqlite3)
(import musty)

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
        timestamp (or (when mts
                        (when-let
                          [parse (peg/match timestamp-peg mts)]
                          (parsed-timestamp-to-time ;parse)))
                      (os/time))
        tags (or
               (when mtags (map string/trim (string/split "," mtags)))
               [])]
    {:timestamp timestamp :tags (tuple ;tags)}))

(defn- note-defaults
  "Assumes {:id :text} from table"
  [result]
  (let [now (os/time)]
    (table/to-struct (merge {:previous :empty-note :timestamp now} result))))

(defn initialize-notebook
  "creates or updates a SQLite file containing a notebook schema"
  [filename]
  (def db (sqlite3/open filename))
  (def version_exists (sqlite3/eval db `
     SELECT TRUE FROM sqlite_master
     WHERE name='schema_version'
       AND type='table'`))

  (when (not (any? version_exists))
    (sqlite3/eval db `
       CREATE TABLE IF NOT EXISTS notes (
          timestamp INTEGER,
          text TEXT,
          previous INTEGER NULL -- notes.rowid
       )`)
    (sqlite3/eval db `CREATE INDEX IF NOT EXISTS notes_timestamp_ix ON notes (timestamp)`)
    (sqlite3/eval db `
       CREATE TABLE IF NOT EXISTS tags (
          tag TEXT,
          note INTEGER -- notes.rowid
       )`)
    (sqlite3/eval db `CREATE INDEX IF NOT EXISTS tags_tag_ix ON tags (tag)`)
    (sqlite3/eval db `
       CREATE TABLE IF NOT EXISTS schema_version (
          version INTEGER
       )`)
    (sqlite3/eval db `
      INSERT INTO schema_version (version) VALUES (1)
      `))

  (let [version (sqlite3/eval db "SELECT MAX(version) FROM schema_version")]
    (cond
      (= version 1)
      (do
        (sqlite3/eval db `BEGIN TRANSACTION`)
        (sqlite3/eval db `ALTER TABLE schema_version ADD COLUMN k INTEGER`)
        (sqlite3/eval db `UPDATE schema_version SET k=1`)
        (sqlite3/eval db `
           CREATE UNIQUE INDEX schema_version_k_ix
           ON schema_version (k)`)
        (sqlite3/eval db `UPDATE schema_version SET version=2 WHERE k=1`)
        (sqlite3/eval db `COMMIT`)
        (initialize-notebook db))
      (= version 2)
      (do
        (sqlite3/eval db `BEGIN TRANSACTION`)
        (sqlite3/eval db `ALTER TABLE notes ADD COLUMN title TEXT NULL`)
        (sqlite3/eval db `
         CREATE UNIQUE INDEX notes_title_ix
         ON notes (title)
         WHERE title IS NOT NULL`)
        (sqlite3/eval db `UPDATE schema_version SET version=3 WHERE k=1`)
        (sqlite3/eval db `COMMIT`)
        (initialize-notebook db)))))

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
       INSERT INTO notes (timestamp, text, previous)
         VALUES (:timestamp, :text, :previous)
       ` {:timestamp (metas :timestamp)
          :text text
          :previous previous})

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
        SELECT n.rowid AS id, n.text, n.previous, n.timestamp
        FROM notes AS n
          LEFT JOIN notes AS edits ON n.rowid=edits.previous
        WHERE edits.previous IS NULL
        ORDER BY n.timestamp DESC`))
  (map note-defaults results))

(defn note-by-id
  "gets the note for the given id"
  [file id]
  (def db (sqlite3/open file))
  (def results
    (sqlite3/eval db `
        SELECT rowid AS id, text, previous, timestamp
        FROM notes
        WHERE rowid = :id` {:id id}))
  (note-defaults (first results)))

(defn note-from-template
  "uses a given id as a template to create and insert a new note"
  [file template-id env]
  (let [templ (note-by-id file template-id)
        new-text (musty/render (templ :text) env)]
    (insert-note file {:text new-text :previous :empty-note})
    (print new-text)))
