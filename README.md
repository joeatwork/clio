Clio

A rudimentary note-taking tool for the command line.

To build and run:
```console
$ jpm deps --local
$ ./jpm_tree/bin/judge # to run tests
$ jpm build --local
$ ./build/clio
```

To format the source files, run
```console
$ find . \( -name jpm_tree -prune \) -o \( -name \*.janet -print \) | \
    xargs janet ./jpm_tree/bin/janet-format
```
