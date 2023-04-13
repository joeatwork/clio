(use /src/clio)
(use judge)
(import sh)

(try (sh/$ rm "test-notebook.sqlite") ([_err] "do nothing on err"))

(initialize-notebook "test-notebook.sqlite")

(insert-note "test-notebook.sqlite"
             {:text "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n" :previous :empty-note})

(test (all-notes "test-notebook.sqlite") @[{:id 1 :previous :empty-note :text "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n"}])
