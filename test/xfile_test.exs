defmodule XfileTest do
  use ExUnit.Case

  describe "grep/2" do
    test "matches lines using string" do
      assert ["1 duck\n", "2 duck\n", "4 duck\n"] ==
               "duck" |> Xfile.grep("test/support/b") |> Enum.to_list()
    end

    test "matches lines using regex" do
      assert ["1 duck\n", "2 duck\n", "4 duck\n"] ==
               ~r/duck/ |> Xfile.grep("test/support/b") |> Enum.to_list()
    end

    test "matches lines using arity 1 function" do
      f = fn line ->
        [num, _] = String.split(line, " ")
        String.to_integer(num) > 2
      end

      assert ["3 goose\n", "4 duck\n"] ==
               f |> Xfile.grep("test/support/b") |> Enum.to_list()
    end
  end

  describe "grep_rl/3" do
    test "finds matching files" do
      assert ["test/support/d1/d2/c2.txt", "test/support/d1/b1.txt", "test/support/a.txt"] =
               "xyz" |> Xfile.grep_rl("test/support") |> Enum.to_list()
    end
  end

  describe "head/2" do
    test "returns the top n lines" do
      assert ["this\n", "has\n"] == Xfile.head("test/support/a.txt", 2) |> Enum.to_list()
    end
  end

  describe "line_count/1" do
    test ":ok" do
      assert {:ok, 5} == Xfile.line_count("test/support/a.txt")
    end

    test ":error" do
      assert {:error, _} = Xfile.line_count("test/support")
    end
  end

  describe "line_count!/1" do
    test "ok" do
      assert 5 == Xfile.line_count!("test/support/a.txt")
    end

    test "raises error on directory" do
      assert_raise File.Error, fn -> Xfile.line_count!("test/support") end
    end
  end

  describe "ls/2" do
    test "recursively lists directory contents" do
      {:ok, stream} = Xfile.ls("test/support")

      assert [
               "test/support/d1/c1",
               "test/support/d1/d2/b2",
               "test/support/d1/d2/a2",
               "test/support/d1/d2/c2.txt",
               "test/support/d1/b1.txt",
               "test/support/d1/a1",
               "test/support/a.txt",
               "test/support/c",
               "test/support/b"
             ] = Enum.to_list(stream)
    end

    test "recursive false does not traverse subdirectories" do
      {:ok, stream} = Xfile.ls("test/support", recursive: false)

      assert ["test/support/a.txt", "test/support/c", "test/support/b"] = Enum.to_list(stream)
    end

    test "recursive 1 traverses 1 subdirectory" do
      {:ok, stream} = Xfile.ls("test/support", recursive: 1)

      assert [
               "test/support/d1/c1",
               "test/support/d1/b1.txt",
               "test/support/d1/a1",
               "test/support/a.txt",
               "test/support/c",
               "test/support/b"
             ] = Enum.to_list(stream)
    end

    test ":filter by function" do
      {:ok, stream} = Xfile.ls("test/support", filter: fn x -> String.ends_with?(x, ".txt") end)

      assert [
               "test/support/d1/d2/c2.txt",
               "test/support/d1/b1.txt",
               "test/support/a.txt"
             ] = Enum.to_list(stream)
    end

    test ":filter by regex" do
      {:ok, stream} = Xfile.ls("test/support", filter: ~r/\/d1\//)

      assert [
               "test/support/d1/c1",
               "test/support/d1/d2/b2",
               "test/support/d1/d2/a2",
               "test/support/d1/d2/c2.txt",
               "test/support/d1/b1.txt",
               "test/support/d1/a1"
             ] = Enum.to_list(stream)
    end

    test ":filter by simple string" do
      {:ok, stream} = Xfile.ls("test/support", filter: "d2")

      assert [
               "test/support/d1/d2/b2",
               "test/support/d1/d2/a2",
               "test/support/d1/d2/c2.txt"
             ] = Enum.to_list(stream)
    end
  end

  describe "ls!/2" do
    test "recursively lists files" do
      assert [
               "test/support/d1/c1",
               "test/support/d1/d2/b2",
               "test/support/d1/d2/a2",
               "test/support/d1/d2/c2.txt",
               "test/support/d1/b1.txt",
               "test/support/d1/a1",
               "test/support/a.txt",
               "test/support/c",
               "test/support/b"
             ] = "test/support" |> Xfile.ls!() |> Enum.to_list()
    end

    test "raises on error" do
      assert_raise RuntimeError, fn -> Xfile.ls!("does-not-exist") end
    end
  end

  describe "tail/2" do
    test "returns the last n lines" do
      assert ["text\n", "xyz\n"] == Xfile.tail("test/support/a.txt", 2) |> Enum.to_list()
    end
  end
end
