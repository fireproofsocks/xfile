defmodule Xfile do
  @moduledoc """
  `Xfile` contains augmentations of the built-in `File` module, such as supporting
  streams, recursion, and programmatic filtering.
  """

  @doc """
  Like `File.ls/1`, this returns the list of _files_ in the given directory, but it
  makes available some useful options to support recursive listing and filtering
  results programmatically.

  > #### Stream {: .info}
  >
  > Unlike `File.ls/1`, `Xfile.ls/2` returns its result as a `Stream`, so you must
  > remember to convert it to a list via `Enum.to_list/1` if you are not lazily
  > evaluating its result.

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
