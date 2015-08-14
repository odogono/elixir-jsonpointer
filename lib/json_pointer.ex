defmodule JSONPointer do

  @doc """
    Looks up a JSON pointer in an object

    ## Examples
      iex> JSONPointer.get( %{ "example" => %{ "bla" => "hello" } }, "/example/bla" )
      {:ok, "hello"}
  """
  def get(obj, pointer) do

    # parse the incoming string pointer out into a list of tokens
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        case get_sub(obj, tokens) do
          {:error,reason} ->
            {:error,reason}
          value ->
            {:ok, value}
        end
      {:error, reason} ->
        {:error,reason}
    end

  end

  # defp get_sub(obj,nil), do: obj
  # defp get_sub(obj,value), do: value
  defp get_sub(obj,[]), do: obj

  defp get_sub(list,[token|tokens]) when is_list(list) do
    case Integer.parse( token ) do
      {number,_} ->
        if number >= Enum.count(list) do
          {:error, "index #{number} out of bounds in #{inspect list}" }
        else
          list |> Enum.at( number ) |> get_sub( tokens )
        end
      :error ->
        {:error, "invalid reference token for list: #{token}"}
    end
  end

  defp get_sub(map,[token|tokens]) do
    case Map.fetch(map, token) do
      {:ok, subObj} ->
        get_sub( subObj, tokens )
      {:error,reason} ->
        {:error, reason}
      :error ->
        # IO.inspect( Map.fetch(map,token) )
        {:error, "invalid reference token #{Poison.Encoder.encode(token,[])} #{Poison.Encoder.encode(map,[])}"}
    end
  end


  @doc """
  Sets a new value on object at the location described by pointer

    ## Examples

      iex> JSONPointer.set( %{}, "/example/msg", "hello")
      {:ok, %{ "example" => %{ "msg" => "hello" }} }
  """
  def set(object, pointer, value) do
    {:error, "not implemented"}
  end


  @doc """
  Removes an attribute of object referenced by pointer
  """
  def remove(object, pointer) do
    {:error, "not implemented"}
  end

  @doc """
    Tests if an object has a value for a JSON pointer
  """
  def has( object, pointer ) do
    false
  end

  @doc """
    Escapes a reference token

    ## Examples

      iex> JSONPointer.escape "hello~bla"
      "hello~0bla"
      iex> JSONPointer.escape "hello/bla"
      "hello~1bla"

  """
  @spec escape(String.t) :: String.t
  def escape( str ) do
    str
    |> String.replace( "~", "~0" )
    |> String.replace( "/", "~1" )
  end

  @doc """
  Unescapes a reference token

    ## Examples

      iex> JSONPointer.unescape "hello~0bla"
      "hello~bla"
      iex> JSONPointer.unescape "hello~1bla"
      "hello/bla"
  """
  @spec unescape(String.t) :: String.t
  def unescape( str ) do
    str
    |> String.replace( "~0", "~" )
    |> String.replace( "~1", "/" )
  end


  @doc """
  Converts a JSON pointer into a list of reference tokens
  """

  def parse(""), do: {:ok,[]}

  def parse( pointer ) do
    case String.first(pointer) do
      "/" ->
        {:ok,
          pointer
          |> String.lstrip(?/)
          |> String.split("/")
          |> Enum.map( &JSONPointer.unescape/1) }

      _ ->
        {:error, "invalid json pointer: #{pointer}"}
    end


  end



end
