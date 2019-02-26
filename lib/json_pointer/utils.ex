defmodule JSONPointer.Utils do
  @moduledoc false

  @type pointer :: String.t() | [String.t()]
  @type msg :: String.t()

  @doc """
  Escapes a reference token

  ## Examples

      iex> JSONPointer.escape "hello~bla"
      "hello~0bla"
      iex> JSONPointer.escape "hello/bla"
      "hello~1bla"

  """
  @spec escape(String.t()) :: String.t()
  def escape(str) do
    str
    |> String.replace("~", "~0")
    |> String.replace("/", "~1")
    |> String.replace("**", "~2")
  end

  @doc """
  Unescapes a reference token

  ## Examples

      iex> JSONPointer.unescape "hello~0bla"
      "hello~bla"
      iex> JSONPointer.unescape "hello~1bla"
      "hello/bla"
  """
  @spec unescape(String.t()) :: String.t()
  def unescape(str) do
    str
    |> String.replace("~0", "~")
    |> String.replace("~1", "/")
    |> String.replace("~2", "**")
  end

  @doc """
  Converts a JSON pointer into a list of reference tokens

  ## Examples
      iex> JSONPointer.parse("/fridge/butter")
      {:ok, [ "fridge", "butter"] }
  """
  def parse(""), do: {:ok, []}

  def parse(pointer) when is_list(pointer), do: {:ok, pointer}

  @spec parse(pointer) :: {:ok, [String.t()]} | {:error, msg, pointer}
  def parse(pointer) do
    # handle a URI Fragment
    pointer = String.trim_leading(pointer, "#")

    case String.first(pointer) do
      "/" ->
        {:ok,
         pointer
         |> String.trim_leading("/")
         |> String.split("/")
         #  |> Enum.map(&URI.decode/1) # NOTE - decoding uri parts is not spec compliant (and not needed) - so removed
         |> Enum.map(&unescape/1)}

      _ ->
        {:error, "invalid json pointer", pointer}
    end
  end

  # @doc """
  # Ensures that the given list has size number of elements

  # ## Examples
  #     iex> JSONPointer.ensure_list_size( [], 2 )
  #     [nil, nil]
  # """
  @spec ensure_list_size(list, non_neg_integer()) :: list
  def ensure_list_size(list, size) do
    diff = size - Enum.count(list)

    if diff > 0 do
      list ++ List.duplicate(nil, diff)
    else
      list
    end
  end

  @doc """
  Attempts to converts a value into an integer

  ## Examples
      iex> parse_index 10
      10
      iex> parse_index "100"
      100
      iex> parse_index "92.4"
      {:error, "invalid index: 92.4"}
  """
  def parse_index("0"), do: 0
  def parse_index(<<"0", rest::binary>>), do: "0" <> rest
  def parse_index(val) when is_integer(val), do: val
  # defp parse_index(val) when is_float(val), do: {Kernel.trunc(val), 0}

  def parse_index(val) do
    case Integer.parse(val) do
      {int, rem} ->
        if rem != "", do: {:error, "invalid index: #{val}"}, else: int

      :error ->
        {:error, "invalid index: #{val}"}
    end
  end
end
