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

  defp get_sub(obj,[]), do: obj

  defp get_sub(list,[token|tokens]) when is_list(list) do
    case Integer.parse( token ) do
      {number,_rem} ->
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
        {:error, "invalid reference token #{inspect token} #{inspect map}"}
    end
  end




  defp apply_into( list, index, val ) when is_list(list) do
    # IO.puts "   apply_into list #{inspect list}(#{Enum.count(list)}) #{inspect index} = #{inspect val}"
    if index do
      # ensure the list has the capacity for this index
      val = list |> ensure_list_size(index+1) |> List.replace_at(index, val)
    end
    val
  end


  defp apply_into( map, key, val ) when is_map(map) do
    # IO.puts "   apply_into map #{inspect key} #{inspect val}"
    if key do
      val = Map.put(map, key, val)
    end
    val
  end

  @doc """
    Tests if an object has a value for a JSON pointer
  """
  def has( object, pointer ) do
    case walk_container( :has, object, pointer, nil ) do
      {:ok,_obj,_existing} -> true
      {:error,_,_} -> false
      value -> value

    end
  end

  @doc """
  Removes an attribute of object referenced by pointer
  """
  def remove(object, pointer) do
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        # IO.puts "remove #{inspect tokens}"
        [token|tokens] = tokens
        walk_container( :remove, nil, object, token, tokens, nil )
      {:error, reason} ->
        {:error,reason}
    end
  end

  @doc """
  Sets a new value on object at the location described by pointer

    ## Examples

      iex> JSONPointer.set( %{}, "/example/msg", "hello")
      {:ok, %{ "example" => %{ "msg" => "hello" }} }
  """
  def set( object, pointer, value ) do
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        [token|tokens] = tokens
        walk_container( :set, nil, object, token, tokens, value )
      {:error, reason} ->
        {:error,reason}
    end
  end

  defp walk_container(operation, object, pointer, value ) do
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        [token|tokens] = tokens
        walk_container( operation, nil, object, token, tokens, value )
      {:error, reason} ->
        {:error,reason}
    end
  end

  # leaf operation: remove from map
  defp walk_container( operation, parent, map, token, tokens, value ) when operation == :remove and tokens == [] and is_map(map) do
      # IO.puts("removing #{inspect token} #{inspect tokens} from #{inspect map}")
      case Map.fetch( map, token ) do
        {:ok, existing} ->
          {:ok, Map.delete(map, token), existing}
        :error ->
          {:error, "json pointer key not found %{token}"}
      end
  end

  # leaf operation: remove from list
  defp walk_container( operation, parent, list, token, tokens, value ) when operation == :remove and tokens == [] and is_list(list) do
    case Integer.parse(token) do
      {index,_rem} ->
        {:ok, apply_into(list, index, nil), Enum.at(list,index) }
      :error ->
        {:error, "invalid json pointer invalid index #{token} into #{inspect list}"}
    end
  end

  # leaf operation: set token to value on a map
  defp walk_container( operation, parent, map, token, tokens, value ) when operation == :set and tokens == [] and is_map(map) do
      # IO.puts("setting #{inspect token} = #{inspect value} onto #{inspect map}")
      case Integer.parse(token) do
        {index,_rem} ->
            # the token turned out to be an array index, so convert the value into a list
            {:ok, apply_into([],index,value), nil}
        :error ->
          case Map.fetch( map, token ) do
            {:ok, existing} ->
              {:ok, apply_into(map, token,value), existing}
            :error ->
              {:ok, apply_into(map, token,value), nil}
              # {:error, "json pointer key not found %{token}"}
          end
      end
  end

  # leaf operation: set token(index) to value on a list
  defp walk_container( operation, parent, list, token, tokens, value ) when operation == :set and tokens == [] and is_list(list) do
    # IO.puts "list #{operation} #{inspect token} to #{value} on #{inspect list}"
    case Integer.parse(token) do
      {index,_rem} ->
        {:ok, apply_into(list, index, value), Enum.at(list,index) }
      :error ->
        # {:ok, apply_into(list, index, value), nil }
        {:error, "invalid json pointer invalid index #{token} into #{inspect list}"}
    end
  end

  # leaf operation: no value for list, so we determine the container depending on the token
  defp walk_container(operation, parent, list, token, tokens, value ) when operation == :set and tokens == [] and is_list(parent) and list == nil do
    case Integer.parse(token) do
      {index,_rem} ->
        {:ok, apply_into([], index, value), nil }
      :error ->
        {:ok, apply_into(%{}, token, value), nil }
    end
  end

  # leaf operation: does map have token?
  defp walk_container(operation, parent, map, token, tokens, value) when operation == :has and tokens == [] and is_map(map) do
    # IO.puts "does map #{inspect map} have #{token}"
    case Map.fetch(map, token) do
      {:ok,existing} ->
        {:ok, nil, existing}
      :error ->
        {:error,nil,nil}
    end
  end

  # leaf operation: does list have index?
  defp walk_container(operation, parent, list, token, tokens, value) when operation == :has and tokens == [] and is_list(list) do
    case Integer.parse(token) do
      {index, _rem} ->
        #
        if (index < Enum.count(list) && Enum.at(list,index) != nil) do
          {:ok,nil, Enum.at(list,index)}
        else
          {:error,nil,nil}
        end
      :error ->
        false
    end
  end


  defp walk_container( operation, parent, map, token, tokens, value ) when is_map(map) do
    # IO.puts("#{operation} #{inspect token} #{inspect tokens} from map #{inspect map}")

    [sub_token|tokens] = tokens
    # {index,_rem} = Integer.parse(token)
    case Map.fetch(map, token) do
      {:ok, existing} ->
        {res,sub,rem} = walk_container( operation, map, existing, sub_token, tokens, value)
        # re-apply the altered tree back into our map
        {res,apply_into(map, token, sub),rem}
      :error ->
        case operation do
          :set ->
            {res,sub,rem} = walk_container( operation, map, %{}, sub_token, tokens, value)
            {res,apply_into(map, token, sub),rem}
          :has ->
            {res,sub,rem} = walk_container( operation, map, %{}, sub_token, tokens, value)
          _ ->
            {:error, "json pointer key not found #{token} on #{inspect map}"}
        end

        # if operation == :set do
        #
        # else
        #
        # end
    end
  end

  defp walk_container( operation, parent, list, token, tokens, value ) when is_list(list) do
    # IO.puts("#{operation} #{inspect token} #{inspect tokens} from list #{inspect list}")
    [sub_token|tokens] = tokens
    case Integer.parse(token) do
      {index,_rem} ->
        {res,sub,rem} = walk_container( operation, list, Enum.at(list,index), sub_token, tokens, value)
        # re-apply the returned result back into the current list
        {res, apply_into(list,index,sub), rem}
      _ ->
        {:error}
    end
  end

  defp walk_container( operation, parent, container, token, tokens, value ) when operation == :set and container == nil do
    [sub_token|tokens] = tokens
    # IO.puts "/b #{sub_token} #{inspect token} #{inspect tokens}"
    case Integer.parse(token) do
      {index,_rem} ->
        {res,sub,rem} = walk_container( operation, [], [], sub_token, tokens, value)
        # re-apply the returned result back into the current list
        {res, apply_into([],index,sub), rem}
      _ ->
        {res,sub,rem} = walk_container( operation, %{}, %{}, sub_token, tokens, value)
        # re-apply the returned result back into the current list
        {res, apply_into(%{},token,sub), rem}
    end
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


  def ensure_list_size(list, size) do
    diff = size - Enum.count(list)
    # IO.puts "ensure_list_size #{size} #{Enum.count(list)} ~ #{diff}"
    if diff > 0 do
      list = list ++ List.duplicate( nil, diff )
    end
    list
  end

end
