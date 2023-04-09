(use /src/clio)
(use judge)

(test (add-note! (empty-notebook) "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n") @{:notes @[{:meta {:tags ["good" "bad"] :timestamp 1673654400} :note {:previous :empty-note :text "---\ntags: good, bad\ntimestamp: 2023-01-14\n---\nhello\n"}}]})
