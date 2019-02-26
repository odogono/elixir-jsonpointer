defmodule JSONPointer.Serialize do
  @moduledoc false

  import JSONPointer.Guards
  import JSONPointer.Utils

  def dehydrate_container(value, acc, result) when is_empty_list(value) do
    dehydrate_gather(value, acc, result)
  end

  def dehydrate_container(value, acc, result) when is_list(value) do
    value
    |> Stream.with_index()
    |> Enum.reduce(result, fn {v, k}, racc ->
      k = Integer.to_string(k)
      racc ++ dehydrate_container(v, [k | acc], result)
    end)
  end

  def dehydrate_container(value, acc, result) when is_empty_map(value) do
    dehydrate_gather(value, acc, result)
  end

  def dehydrate_container(value, acc, result) when is_map(value) do
    Enum.reduce(value, result, fn {k, v}, racc ->
      racc ++ dehydrate_container(v, [k | acc], result)
    end)
  end

  def dehydrate_container(value, acc, result) do
    # join the accumulated keys together into a path, and join it with the result
    parts = Enum.map(acc, fn path -> escape(path) end)
    [{"/" <> Enum.join(Enum.reverse(parts), "/"), value} | result]
  end

  defp dehydrate_gather(_value, acc, _result) when is_empty_list(acc) do
    []
  end

  defp dehydrate_gather(value, acc, result) do
    # join the accumulated keys together into a path, and join it with the result
    parts = Enum.map(acc, fn path -> escape(path) end)
    [{"/" <> Enum.join(Enum.reverse(parts), "/"), value} | result]
  end
end
