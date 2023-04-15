# Clio

An extremely bare bones note taking tool for use at the command line.

## Usage

The instructions in `Building` below produce an executable file `./build/clio`

You can get usage instructions from that executable with

```
$ ./build/clio --help
```

You can get instructions for individual subcommands with

```
$ ./build/clio edit --help
```

Clio stores notes in a file named ~/notes.sqlite by default.
You can change this by providing a --file argument to the command.

## Building

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

