(use /src/clio)
(use judge)
(import sh)

(try (sh/$ rm "test-notebook.sqlite") ([_err] "do nothing on err"))

(initialize-notebook "test-notebook.sqlite")

(insert-note "test-notebook.sqlite"
             {:text "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n"})

(test (all-notes "test-notebook.sqlite")
      @[{:id 1 :previous :empty-note :text "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n" :timestamp 1673654400}])

(test (note-by-id "test-notebook.sqlite" 1)
      {:id 1 :previous :empty-note :text "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n" :timestamp 1673654400})
