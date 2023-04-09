(use /src/clio)

(use judge)

(def some-note {:body "This is the body\nit has multiple\nlines"
		 :tags [:test :new]
		 :timestamp 1680991299
		 :versions {:body "This is an old version"
			    :timestamp 1680905000
			    :versions :empty-note
			    :tags [:test :old]
			  }
		 })

(test (to-text :empty-note)
      "---\ntags:\n---\nPut the body of your note here\n")

(test (to-text some-note)
 "---\ntags: test, new\n---\nThis is the body\nit has multiple\nlines\n")
