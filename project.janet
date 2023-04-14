(declare-project
  :name "clio"
  :description "remember things at the command line"
  :dependencies
  [{:url "https://github.com/andrewchambers/janet-sh.git"
    :tag "v0.0.1"}
   {:url "https://github.com/ianthehenry/judge.git"
    :tag "v2.3.1"}
   {:url "https://github.com/ianthehenry/cmd.git"
    :tag "v1.0.4"}
   {:url "https://github.com/janet-lang/sqlite3.git"}])


(declare-executable
  :name "clio"
  :entry "main.janet")
