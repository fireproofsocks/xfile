defmodule Xfile do
  @moduledoc """
  `Xfile` contains augmentations of the built-in `File` module, such as supporting
  streams, recursive listing of files, counting lines, grep, and programmatic filtering.
  """

  @doc """
  Like the venerable command-line utility, `grep` searches lines in the given file
  using the given pattern, returning only the matching lines as a stream.

  The given pattern can be one of the following:

  - an arity 1 function which returns a boolean; `true` indicates a match.
  - a pattern compatible with `String.contains?/2`, i.e. a string, a list of strings,
  or a regular expression.

  > #### Stream {: .info}
  >
  > `Xfile.grep/2` returns its result as a `Stream`, so you must remember to convert
  > it to a list via `Enum.to_list/1` if you are not lazily evaluating its result.

  ## Examples

      iex> Xfile.grep(~r/needle/, "path/to/file")
      #Function<59.58486609/2 in Stream.transform/3>

      iex> Xfile.grep("dir", ".gitignore") |> Enum.to_list()
      ["# The directory Mix will write compiled artifacts to.\\n",
      "# The directory Mix downloads your dependencies sources to.\\n"]

  Using a function to evaluate file lines:

      iex> f = fn line ->
        [serial_number, _] = String.split(line, " ")
        String.to_integer(num) > 214
      end
      iex> Xfile.grep(f, "store/products.csv") |> Enum.to_list()
      ["215,Sprocket,9.99\\n", "216,Gear,5.00\\n", ...]
  """
  @spec grep(pattern :: String.pattern() | (String.t() -> boolean()), file :: Path.t()) ::
          Enumerable.t()
  def grep(pattern, file) when is_function(pattern, 1) do
    file
    |> File.stream!()
    |> Stream.filter(fn line -> pattern.(line) end)
  end

  def grep(pattern, file) do
    file
    |> File.stream!()
    |> Stream.filter(fn line -> String.contains?(line, pattern) end)
  end

  @doc """
  Displays first `n` lines of the file, returned as an enumerable stream.

  ## Examples

      iex> Xfile.head(".gitignore", 3) |> Enum.to_list()
      [
        "# The directory Mix will write compiled artifacts to.\\n",
        "/_build/\\n",
        "\\n"
      ]
  """
  @spec head(file :: Path.t(), n :: non_neg_integer()) :: Enumerable.t()
  def head(file, n) when is_binary(file) and is_integer(n) and n > 0 do
    file
    |> File.stream!()
    |> Stream.transform(0, fn line, acc ->
      if acc < n, do: {[line], acc + 1}, else: {:halt, acc}
    end)
  end

  @doc """
  This function mimics the functionality of `grep -rl`: it recursively searches
  all files in the given path, returning only a list of file names (i.e. paths)
  whose contents have one or more lines that match the pattern.

  Internally, this relies on `grep/2`.

  > #### Stream {: .info}
  >
  > `Xfile.grep_rl/3` returns its result as a `Stream`, so you must
  > remember to convert it to a list via `Enum.to_list/1` if you are not lazily
  > evaluating its result.

  ## Examples

      iex> Xfile.grep_rl("[error]", "tmp/logs") |> Enum.to_list()
      [
        "tmp/logs/server.1.log",
        "tmp/logs/cache.log",
        "tmp/logs/server.2.log"
      ]

  ## See Also

  - `grep/2` for searching a single file and returning the matching lines
  - `ls/2` using the `:filter` option to evaluate only the _names_ of the files.
  """
  @spec grep_rl(pattern :: String.pattern(), path :: Path.t(), opts :: Keyword.t()) ::
          Enumerable.t()
  def grep_rl(pattern, path, _opts \\ []) do
    path
    |> ls!()
    |> Stream.filter(fn file ->
      pattern
      |> grep(file)
      |> Enum.count()
      |> Kernel.>(0)
    end)
  end

  @doc """
  Counts the number of lines in the given file, offering functionality similar to `wc -l`.
  Directories are not allowed. This is just some sugar around `File.stream!/1`.

  > #### Newlines {: .info}
  >
  > This function technically counts new lines, which may result in "off-by-one"
  > errors when the last line of a file is not terminated with a newline.

  ## Examples

      iex> Xfile.line_count(".gitignore")
      {:ok, 27}
      iex> Xfile.line_count("/tmp"}
      {:error, :directory}
  """
  @spec(line_count(file :: Path.t()) :: {:ok, non_neg_integer()}, {:error, any()})
  def line_count(file) when is_binary(file) do
    file
    |> File.dir?()
    |> case do
      true ->
        {:error, "Invalid input"}

      false ->
        {:ok,
         file
         |> File.stream!()
         |> Enum.count()}
    end
  end

  @doc """
  As `Xfile.line_count/1`, but returns raw results on success or raises on `:error`.

  ## Examples

      iex> Xfile.line_count!(".gitignore")
      27
  """
  @spec line_count!(file :: Path.t()) :: non_neg_integer() | none()
  def line_count!(file) when is_binary(file) do
    file
    |> File.stream!()
    |> Enum.count()
  end

  @doc """
  Like `File.ls/1`, this returns the list of _files_ in the given directory, but it
  makes available some useful options to support recursive listing and filtering
  results programmatically.

  > #### Stream {: .info}
  >
  > Unlike `File.ls/1`, `Xfile.ls/2` returns its result as a `Stream`, so you must
  > remember to convert it to a list via `Enum.to_list/1` if you are not lazily
  > evaluating its result.

  ## Differences between `File.ls/1`

  - `Xfile.ls/2` returns results as a `Stream`
  - `Xfile.ls/2` returns full paths (relative or absolute) instead of just basenames.

  ## Options

  - `:recursive` indicates whether the directory and its subdirectories should be
    recursively searched. This can be expressed either as a simple boolean or as a
    positive integer indicating the maximum depth (where `false` is equivalent to `0`
    and would list only the contents of the given directory). Default: `true`

  - `:filter` can be either a regular expression to be used with `String.match?/2`
    OR an arity 1 function that receives the full file path and returns a boolean value.
    If the filter operation returns `true`, the file will be included in the
    output. Any other output will cause the file to be filtered from the output. Optional.

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

  Limit the depth of the recursion to the given directory and its subdirectories,
  but no further:

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

  """
  @spec ls(directory :: Path.t(), opts :: Keyword.t()) :: {:ok, Enumerable.t()} | {:error, any()}
  def ls(directory, opts \\ []) when is_binary(directory) do
    max_depth =
      opts
      |> Keyword.get(:recursive, true)
      |> case do
        false -> 0
        other -> other
      end

    case File.dir?(directory) do
      true -> {:ok, directory |> File.ls() |> traverse(directory, opts, 0, max_depth)}
      false -> {:error, "#{directory} is not a directory"}
    end
  end

  @doc """
  As `Xfile.ls/2`, but returns raw results on success or raises on `:error`.
  """
  @spec ls!(directory :: Path.t(), opts :: Keyword.t()) :: Enumerable.t() | none()
  def ls!(directory, opts \\ []) when is_binary(directory) do
    case ls(directory, opts) do
      {:ok, results} -> results
      {:error, error} -> raise error
    end
  end

  @doc """
  Displays the last `n` lines of the file, returned as an enumerable stream.

  ## Examples

      iex> Xfile.tail(".gitignore", 3) |> Enum.to_list()
      [
        "\\n",
        "# Temporary files for e.g. tests\\n",
        "/tmp\\n"
      ]
  """
  @spec tail(file :: Path.t(), n :: non_neg_integer()) :: Enumerable.t()
  def tail(file, n) when is_binary(file) and is_integer(n) and n > 0 do
    start_line = line_count!(file) - n

    file
    |> File.stream!()
    |> Stream.transform(0, fn line, acc ->
      if acc >= start_line, do: {[line], acc + 1}, else: {[], acc + 1}
    end)
  end

  # `traverse/2` receives the result of `File.ls/1`, which acts as like `File.dir?/2`.
  # If the result is `:ok`, we proceed deeper into the directory structure.
  # If the result is an `:error`, then the path being evaluated is accumulated as a file.
  defp traverse({:ok, files}, path, opts, current_depth, max_depth)
       when max_depth == true or current_depth < max_depth do
    files
    |> Stream.flat_map(fn f ->
      "#{path}/#{f}" |> File.ls() |> traverse("#{path}/#{f}", opts, current_depth + 1, max_depth)
    end)
  end

  # at max depth
  defp traverse({:ok, files}, path, opts, _current_depth, _max_depth) do
    files
    |> Stream.flat_map(fn f ->
      case !File.dir?("#{path}/#{f}") && filter_file("#{path}/#{f}", Keyword.get(opts, :filter)) do
        true -> ["#{path}/#{f}"]
        _ -> []
      end
    end)
  end

  defp traverse({:error, _}, file, opts, _, _) do
    case filter_file(file, Keyword.get(opts, :filter)) do
      true -> [file]
      _ -> []
    end
  end

  defp filter_file(file, function) when is_function(function, 1), do: function.(file)

  defp filter_file(file, %Regex{} = regex), do: String.match?(file, regex)

  defp filter_file(_, _), do: true
end
