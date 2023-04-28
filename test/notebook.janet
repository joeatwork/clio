(use /src/clio)
(use judge)
(import sh)

(try (sh/$ rm "test-notebook.sqlite") ([_err] "do nothing on err"))

(initialize-notebook "test-notebook.sqlite")

(insert-note "test-notebook.sqlite"
             {:text "---\ntimestamp: 2023-01-14\n---\nhello\n"})

(insert-note "test-notebook.sqlite"
             {:text "---\ntags: good, bad\ntimestamp: 2023-01-13\ntitle: test title\n---\nbenvenuti a tutti\n"})

(insert-note "test-notebook.sqlite"
             {:text "---\ntags: good, bad\ntimestamp: 2023-01-13\ntitle: test title\n---\nbenvenuti\n" :previous 2})

(test (all-notes "test-notebook.sqlite")
      @[{:id 1
         :previous :empty-note
         :text "---\ntimestamp: 2023-01-14\n---\nhello\n"
         :timestamp 1673654400}
        {:id 3
         :previous 2
         :text "---\ntags: good, bad\ntimestamp: 2023-01-13\ntitle: test title\n---\nbenvenuti\n"
         :timestamp 1673568000
         :title "test title"}])

(test (one-note "test-notebook.sqlite" 1)
      {:id 1
       :previous :empty-note
       :text "---\ntimestamp: 2023-01-14\n---\nhello\n"
       :timestamp 1673654400})

(test (one-note "test-notebook.sqlite" "test title")
      {:id 3
       :previous 2
       :text "---\ntags: good, bad\ntimestamp: 2023-01-13\ntitle: test title\n---\nbenvenuti\n"
       :timestamp 1673568000
       :title "test title"})
