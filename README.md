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

### Some example uses

I take a daily note every morning and tag it with the week number.
At the end of the week, I call back all of the week's notes for a summary.

```console
$ # Keep a collection of notes for this week, to sum up at the end
$ clio cat --find week-15
```

I keep a single note titled "next-actions" and just edit it when I
finish an immediate task or a new immediate task comes up.

```console
$ # Keep a single "next-actions" note for next actions
$ clio edit --id next-actions
```

The `clio templ` command expands a mustache template in an old note into
a new note. I have a template with the title "tc" that looks like this.

```
---
title: tcommand
tags: command
---
# {{ desc }}
{{ command }}
```

I can use to make a quick note when I run a complex command I want to remember:

```console
$ # Make a quick note about the last command
$ clio templ tcommand desc "a description here" command "!!"
```

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

