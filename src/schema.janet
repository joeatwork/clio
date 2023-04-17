(import sqlite3)

(defn- to-version-1
  [db]
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

(defn- to-version-2
  "fix schema version so it's easier to use safely"
  [db]
  (sqlite3/eval db `BEGIN TRANSACTION`)
  (sqlite3/eval db `ALTER TABLE schema_version ADD COLUMN k INTEGER`)
  (sqlite3/eval db `UPDATE schema_version SET k=1`)
  (sqlite3/eval db `
           CREATE UNIQUE INDEX schema_version_k_ix
           ON schema_version (k)`)
  (sqlite3/eval db `UPDATE schema_version SET version=2 WHERE k=1`)
  (sqlite3/eval db `COMMIT`))

(defn- to-version-3
  "add an (optionally) unique title to notes"
  [db]
  (sqlite3/eval db `BEGIN TRANSACTION`)
  (sqlite3/eval db `ALTER TABLE notes ADD COLUMN title TEXT NULL`)
  (sqlite3/eval db `UPDATE schema_version SET version=3 WHERE k=1`)
  (sqlite3/eval db `COMMIT`))

(defn migrate-schema-forward
  "migrates the notebook schema forward one version"
  [db]
  (def version_exists (sqlite3/eval db `
     SELECT TRUE FROM sqlite_master
     WHERE name='schema_version'
       AND type='table'`))

  (when (not (any? version_exists))
    (to-version-1 db))

  (let [vresult (sqlite3/eval db "SELECT MAX(version) AS v FROM schema_version")
        version ((first vresult) :v)]

    (cond
      (= version 1)
      (do
        (to-version-2 db)
        (migrate-schema-forward db))
      (= version 2)
      (do
        (to-version-3 db)
        (migrate-schema-forward db)))))
