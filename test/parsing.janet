(use /src/clio)
(use judge)

(def some-note
  {:text "---\ntags: test, new\ntimestamp: 2023-02-03T04:42:32\n---\nHere is some note\nIt is a quality note\n"
   :previous {:text "---\ntags: test, old\ntimestamp: 2023-01-01\n---\nThis is an old version of the note\n"
              :previous :empty-note}})

(test (to-text :empty-note)
      `
---
tags:
---
Put the body of your note here

`)

(test (to-text some-note)
      `
---
tags: test, new
timestamp: 2023-02-03T04:42:32
---
Here is some note
It is a quality note

`)

(test (peg/match note-metas-peg "---\nm1: a, b\nm2 ::: \n---\nl1\nl2\n")
      @["m1" " a, b" "m2 " ":: "])

(test (parse-metas "---\ntags: test, good times\ntimestamp: 2023-02-03T04:42:32\n---\nSome good stuff")
      {:tags ["test" "good times"] :timestamp 1675399352})

(def updated
  (reserialize-metas
    {:tags ["up" "down"]
     :title "newt"
     :timestamp 1681689107
     :useless "unchanged"}
    "---\ntitle: oldt\ntags: a, b\ntimestamp: 2023-02-03T04:42:32\n---\nSome good stuff"))

(test updated
      "---\ntitle: newt\ntags: up, down\ntimestamp: 2023-04-16T23:51:47\n---\nSome good stuff")
