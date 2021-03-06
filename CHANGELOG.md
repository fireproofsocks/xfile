# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.4.0

- `ls`'s filter is now compatible with `grep`'s, namely:
  - `ls/2` now supports simple strings and lists of strings (per `String.contains?/2`) for filtering files.
  - `grep/2` now properly supports `Regex` patterns for filtering lines.
- Adds support of the `:show_dirs?` option to the `ls/2` function. This makes the results
cleave more closely to what `File.ls/1` returns; it can be jarring for `Xfile.ls("deps", recursive: false)` to yield _no results_ when the directory contains only sub-directories,
so using this option can be a useful way to view sub-directories.
- `grep_rl/2` now routes its `opts` arg to `ls!/2` to support pre-filtering of files
subjected to pattern matching.

## v0.3.0

Adds functions for `head/2` and `tail/2`

## v0.2.0

Adds functions for `grep/2`, `grep_rl/3`, and `line_count/1`

## v0.1.0

Initial release.
