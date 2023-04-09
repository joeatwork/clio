(use /src/clio)

(use judge)

(test (peg/match timestamp-peg "2023-01-01") @["2023" "01" "01"])

(test (peg/match timestamp-peg "2023-02-03T04:05") @["2023" "02" "03" "04" "05"])

(test (peg/match timestamp-peg "2023-02-03T04:42:32") @["2023" "02" "03" "04" "42" "32"])

(test (peg/match timestamp-peg "2023-01-01 Not a Date") nil)

(test (parsed-timestamp-to-time "2023" "01" "01") 1672531200)

(test (parsed-timestamp-to-time "2023" "02" "03" "04" "05") 1675397100)

(test (parsed-timestamp-to-time "2023" "02" "03" "04" "42" "32") 1675399352)

(test (format-timestamp 1675399352) "2023-02-03T04:42:32")
