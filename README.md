# Xfile

[![Module Version](https://img.shields.io/hexpm/v/xfile.svg)](https://hex.pm/packages/xfile)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/xfile/)
[![Total Download](https://img.shields.io/hexpm/dt/xfile.svg)](https://hex.pm/packages/xfile)
[![License](https://img.shields.io/hexpm/l/xfile.svg)](https://hex.pm/packages/xfile)
[![Last Updated](https://img.shields.io/github/last-commit/fireproofsocks/xfile.svg)](https://github.com/fireproofsocks/xfile/commits/master)

`Xfile` is a utility module providing augmentations to the functions in the built-in `File` module, specifically adding useful functionality to the `ls` function.

## Examples

Use a regular expression to return only `.txt` files:

      iex> {:ok, stream} = Xfile.ls("path/to/files", filter: ~r/\\.txt$/)
      {:ok, #Function<59.58486609/2 in Stream.transform/3>}
      iex> Enum.to_list(stream)
      [
        "path/to/files/a.txt",
        "path/to/files/b.txt",
        "path/to/files/subdir/c.txt"
      ]

Use a function to apply more complex logic to filter the results:

      iex> {:ok, stream} = Xfile.ls("mydir", filter: fn x ->
        stat = File.stat!(x)
        stat.size > 1024
      end)
      {:ok, #Function<59.58486609/2 in Stream.transform/3>}
      iex> Enum.to_list(stream)
      [
        "mydir/big-file",
        "mydir/big-file2",
        # ...
      ]

Limit the depth of the recursion to the given directory and its subdirectories, but no further:

      iex> {:ok, stream} = Xfile.ls("top/dir", recursive: 1)
      {:ok, #Function<59.58486609/2 in Stream.transform/3>}
      iex> Enum.to_list(stream)
      [
        "top/dir/a",
        "top/dir/b",
        # ...
        "top/dir/sub1/x",
        "top/dir/sub1/y"
      ]

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `xfile` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:xfile, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/xfile>.

## Image Attribution

Alien by Martin Smith from [NounProject.com](https://thenounproject.com/icon/alien-26233/)
