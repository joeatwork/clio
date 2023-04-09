(declare-project
 :name "clio"
 :description "remember things at the command line"
 :dependencies [
		"https://github.com/andrewchambers/janet-sh.git"
		"https://github.com/ianthehenry/judge.git"
	       ]
 )

(declare-executable
 :name "clio"
 :entry "main.janet")
