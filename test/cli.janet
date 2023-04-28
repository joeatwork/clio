(import sh)

(use judge)

(try (sh/$ rm "test-cli.sqlite") ([_err] "do nothing on err"))

(def ts-peg
  (peg/compile '(* "\ntimestamp: " (some (if-not "\n" 1)))))

(defn unts
  [s]
  (string (peg/replace ts-peg "\nTIMESTAMP" s)))

(test (sh/run janet -m ./jpm_tree/lib main.janet init --file "test-cli.sqlite") @[0])

(test (sh/run janet -m ./jpm_tree/lib main.janet edit --file "test-cli.sqlite" --stdin < ,"this is a {{great}} note") @[0])

(test (unts (sh/$< janet -m ./jpm_tree/lib main.janet cat --file "test-cli.sqlite" --id 1))
      "id: 1\n---\nTIMESTAMP\n---\nthis is a {{great}} note\n")

(test (sh/$< janet -m ./jpm_tree/lib main.janet cat --file "test-cli.sqlite" --id 1 --body)
      "this is a {{great}} note\n")

(test (unts (sh/$< janet -m ./jpm_tree/lib main.janet templ --file "test-cli.sqlite" 1 great "super"))
      "---\ntags: \nTIMESTAMP\n---\nthis is a super note\n")
