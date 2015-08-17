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
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        # IO.puts "go #{inspect pointer} #{inspect tokens} = #{inspect value}"
        set_obj( object, object, tokens, nil, value)
        # case get_sub(obj, tokens) do
        #   {:error,reason} ->
        #     {:error,reason}
        #   value ->
        #     {:ok, value}
        # end
      {:error, reason} ->
        {:error,reason}
    end
  end


  defp set_obj(parent, map, [token|tokens], parent_token, value) when is_list(parent) and is_map(map) do
    # IO.puts "is_list/is_map parent: #{inspect parent} map: #{inspect map} token:#{token} tokens:#{tokens} parent_token:#{inspect parent_token} value:#{inspect value}"

    case Integer.parse(token) do
      {index,_rem} ->
        list = [] |> ensure_list_size(index+1) |> List.replace_at(index, nil)
        {res,par,existing} = set_obj( parent, list, tokens, index, value )
        # IO.puts "= is_list/is_map result #{inspect par} maybe into #{inspect token} - #{inspect parent_token} = #{inspect map}?"
        par = apply_into( map, parent_token, par )
        {:ok, par, nil}
      :error ->
        {:ok, map, nil }
    end

  end

  # matching set_obj when we have run out of tokens on a list
  defp set_obj( parent, list, [], parent_token, value ) when is_list(list) do
    # IO.puts "*/is_list EOL parent: #{inspect parent} list: #{inspect list} parent_token:#{inspect parent_token} value:#{inspect value}"
    {:ok, List.replace_at(list, parent_token, value), nil}
  end

  defp set_obj( parent, list, [token|tokens], parent_token, value ) when is_list(parent) and is_list(list) do
    # IO.puts "is_map/is_list parent: #{inspect parent} map: #{inspect list} token:#{token} parent_token:#{inspect parent_token} value:#{inspect value}"
    case Integer.parse(token) do
      {index,_rem} ->
        list = list |> ensure_list_size(index+1) |> List.replace_at(index, nil)
        {res,par,existing} = set_obj( parent, list, tokens, index, value )
        # IO.puts "=/A/1 is_map/is_list (#{token}) apply call #{inspect parent}, #{inspect index} = #{inspect par}"
        # IO.puts "=/A/2 is_map/is_list (#{token}) list result #{inspect par}"
        {:ok, par, nil}
      :error ->
        # we have a string key, so add a new map to this array
        insert_map = Map.put(%{}, token, nil)
        list = list |> ensure_list_size(parent_token+1) |> List.replace_at(parent_token, insert_map)
        {res,par,existing} = set_obj( list, insert_map, tokens, token, value )

        # IO.puts "=/B/1 is_map/is_list map (#{token}) result #{inspect par} #{inspect token} into #{inspect parent}?"
        par = apply_into( list, parent_token, par )
        # IO.puts "=/B/2 is_map/is_list map (#{token}) result #{inspect par}"
        {:ok, par, nil}
    end
  end



  # matching set_obj when we have run out of tokens
  defp set_obj( parent, map, [], parent_token, value ) when is_map(map) do
    {:ok, apply_into( map, parent_token, value), nil}
  end

  defp set_obj( parent, map, [], parent_token, value ) when not is_map(map) and not is_list(map) do
    {:ok, apply_into(parent, parent_token, value), map}
  end

  # defp set_obj( parent, map, [token|tokens], parent_token, value ) when parent == nil and is_map(map) do
  #   case Integer.parse(token) do
  #     {index,_rem} ->
  #       set_obj( [], parent, map)
  #     :error ->
  #
  #   end
  # end

  defp set_obj( parent, map, [token|tokens], parent_token, value ) when is_map(parent) and is_map(map) do
    # IO.puts "is_map/is_map parent: #{inspect parent} map: #{inspect map} token:#{token} parent_token:#{inspect parent_token} value:#{inspect value}"

    case Integer.parse(token) do
      {index,_rem} ->
        {:error, "invalid json pointer token #{token} for map #{inspect map}", nil}
      _ ->
        case Map.fetch( map, token ) do
          {:ok, sub_obj} ->
            {res, par, existing_val} = set_obj( map, sub_obj, tokens, token, value)
            par = apply_into( parent, parent_token, par )
            {:ok, par, existing_val}
          {:error, reason} ->
            {:error, reason}
          :error ->
            # IO.puts "=/1 no token #{inspect token} on #{inspect map}, so adding new"
            # IO.puts "=/2 now have #{inspect map}"
            {res,par,existing} = set_obj( parent, %{}, tokens, token, value )
            # IO.puts "=/3 is_map/is_map call #{inspect parent}, #{inspect parent_token} = #{inspect par}"
            par = apply_into(parent,parent_token,par)
            {res,par,existing}
        end
    end
  end



  defp apply_into( list, index, val ) when is_list(list) do
    # IO.puts "   apply_into list #{inspect list}(#{Enum.count(list)}) #{inspect index} = #{inspect val}"
    if index do
      val = List.replace_at(list,index,val)
      # IO.puts "   !apply_into list #{inspect val}"
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


  def ensure_list_size(list, size) do
    diff = size - Enum.count(list)
    # IO.puts "ensure_list_size #{size} #{Enum.count(list)} ~ #{diff}"
    if diff > 0 do
      list = list ++ List.duplicate( nil, diff )
    end
    list
  end

end
