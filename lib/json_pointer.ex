defmodule JSONPointer do

  @doc """
    Looks up a JSON pointer in an object

    ## Examples
      iex> JSONPointer.get( %{ "example" => %{ "bla" => "hello" } }, "/example/bla" )
      {:ok, "hello"}

      iex> JSONPointer.get( %{ "contents" => [ "milk", "butter", "eggs" ]}, "/contents/2" )
      {:ok, "eggs"} 

      iex> JSONPointer.get( %{ "milk" => true, "butter" => false}, "/cornflakes" )
      {:error, "token not found: cornflakes"}
  """
  def get(obj, pointer) do
    case walk_container( :get, obj, pointer, nil ) do
      {:ok,value,_} -> {:ok,value}
      {:error,msg,_} -> {:error,msg}
    end
  end

  @doc """
    Looks up a JSON pointer in an object

    raises an exception if their is an error

    ## Examples
      iex> JSONPointer.get!( %{}, "/example/bla" )
      ** (ArgumentError) json pointer key not found example
  """
  def get!(obj,pointer) do
    case walk_container( :get, obj, pointer, nil ) do
      {:ok,value,_} -> value
      {:error,msg,_} -> raise ArgumentError, message: msg
    end
  end

  @doc """
    Tests if an object has a value for a JSON pointer

    ## Examples
      iex> JSONPointer.has( %{ "milk" => true, "butter" => false}, "/butter" )
      true

      iex> JSONPointer.has( %{ "milk" => true, "butter" => false}, "/cornflakes" )
      false
  """
  def has( object, pointer ) do
    case walk_container( :has, object, pointer, nil ) do
      {:ok,_obj,_existing} -> true
      {:error,_,_} -> false
    end
  end

  @doc """
    Removes an attribute of object referenced by pointer

    ## Examples
      iex> JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/butter" )
      {:ok, %{"fridge" => %{"milk"=>true}}, true }
  """
  def remove(object, pointer) do
    walk_container( :remove, object, pointer, nil )
  end

  @doc """
  Sets a new value on object at the location described by pointer

    ## Examples
      iex> JSONPointer.set( %{}, "/example/msg", "hello")
      {:ok, %{ "example" => %{ "msg" => "hello" }}, nil }

      iex> JSONPointer.set( %{}, "/fridge/contents/1", "milk" )
      {:ok, %{"fridge" => %{"contents" => [nil, "milk"]}}, nil }

      iex> JSONPointer.set( %{"milk"=>"full"}, "/milk", "empty")
      {:ok, %{"milk" => "empty"}, "full"}
  """
  def set( object, pointer, value ) do
    case walk_container( :set, object, pointer, value ) do
      {:ok, result, existing} -> {:ok,result, existing}
      {:error,msg,_} -> {:error,msg}
    end
  end


  # set the list at index to val
  defp apply_into( list, index, val ) when is_list(list) do
    if index do
      # ensure the list has the capacity for this index
      val = list |> ensure_list_size(index+1) |> List.replace_at(index, val)
    end
    val
  end


  # set the key to val within a map
  defp apply_into( map, key, val ) when is_map(map) do
    if key do
      val = Map.put(map, key, val)
    end
    val
  end



  # when an empty pointer has been provided, simply return the incoming object
  # @spec walk_container(atom, map | list, String.t, any ) :: any
  defp walk_container(_operation, object, "", _value ) do
    {:ok, object, nil}
  end

  defp walk_container(_operation, object, "#", _value ) do
    {:ok, object, nil}
  end

  # begins the descent into a container using the specified pointer
  # @spec walk_container( atom, map | list, String.t, any ) :: any
  defp walk_container(operation, object, pointer, value ) do
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        [token|tokens] = tokens
        walk_container( operation, nil, object, token, tokens, value )
      {:error, reason, value} ->
        {:error,reason, value}
    end
  end

  # leaf operation: remove from map
  defp walk_container( operation, _parent, map, token, tokens, _value ) when operation == :remove and tokens == [] and is_map(map) do
      if token == "**" do
        {:ok, nil, map}
      else
        case Map.fetch( map, token ) do
          {:ok, existing} ->
            {:ok, Map.delete(map, token), existing}
          :error ->
            {:error, "json pointer key not found #{token}", map}
        end
      end
  end

  # leaf operation: remove from list
  defp walk_container( operation, _parent, list, token, tokens, _value ) when operation == :remove and tokens == [] and is_list(list) do
    case Integer.parse(token) do
      {index,_rem} ->
        {:ok, apply_into(list, index, nil), Enum.at(list,index) }
      :error ->
        {:error, "invalid json pointer invalid index #{token}", list}
    end
  end

  # leaf operation: set token to value on a map
  defp walk_container( operation, _parent, map, token, tokens, value ) when operation == :set and tokens == [] and is_map(map) do
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
          end
      end
  end

  # leaf operation: set wildcard to value on a list
  defp walk_container( operation, _parent, list, "**", tokens, value ) when operation == :set and tokens == [] and is_list(list) do
    # replace each entry in the list with the value
    result = Enum.reduce(list, [], fn(_entry, acc) ->
      acc ++ [value]
      end)
    {:ok, result, nil}
  end


  defp walk_container( operation, parent, map, "**", tokens, value ) when operation == :set and tokens == [] and is_map(parent) do
      {:ok, value, nil}
  end


  # leaf operation: set token(index) to value on a list
  defp walk_container( operation, _parent, list, token, tokens, value ) when operation == :set and tokens == [] and is_list(list) do
    case Integer.parse(token) do
      {index,_rem} ->
        {:ok, apply_into(list, index, value), Enum.at(list,index) }
      :error ->
        {:error, "invalid json pointer invalid index #{token}", list}
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
  defp walk_container(operation, _parent, map, token, tokens, _value) when (operation == :has or operation == :get) and tokens == [] and is_map(map) do
    if token == "**" do
      {:ok, map, nil}
    else
      case Map.fetch(map, token) do
        {:ok,existing} ->
          {:ok, existing, nil}
        :error ->
          {:error,"token not found: #{token}", map}
      end
    end

  end

  # leaf operation: does list have index?
  defp walk_container(operation, _parent, list, token, tokens, _value) when (operation == :has or operation == :get) and tokens == [] and is_list(list) do
    if token == "**" do
      {:ok, list, nil}
    else
      case Integer.parse(token) do
        {index, _rem} ->
          if (index < Enum.count(list) && Enum.at(list,index) != nil) do
            {:ok,Enum.at(list,index),nil}
          else
            {:error,"list index out of bounds: #{index}", list}
          end
        :error ->
          {:error,"token not found: #{token}", list}
      end
    end
  end


  #
  defp walk_container( operation, parent, map, "**", tokens, value ) when operation == :set and is_map(map) do
    [next_token|next_tokens] = tokens
    case Map.fetch(map, next_token) do
      {:ok, existing} ->
        walk_container( operation, map, map, next_token, next_tokens, value)
      :error ->
        result = Enum.reduce( map, %{}, fn({map_key,map_value}, result) ->
          case walk_container( operation, map, Map.fetch!(map, map_key), "**", tokens, value) do
            {:ok,rval,res} ->
              apply_into( result, map_key, rval )
            {:error, msg, _value} ->
              raise "error applying :set into map: #{msg}"
          end
        end)

        {:ok, result, nil}
    end
  end

  #
  defp walk_container( operation, parent, map, "**", tokens, value ) when is_map(map) do
    [next_token|next_tokens] = tokens
    case Map.fetch(map, next_token) do
      {:ok, existing} ->
        walk_container( operation, map, map, next_token, next_tokens, value)
      :error ->
        result = Enum.reduce( Dict.keys(map), [], fn(map_key, acc) ->
          case walk_container( operation, map, Map.fetch!(map, map_key), "**", tokens, value) do
              {:ok, walk_val, walk_res} ->
                case walk_val do
                    r when is_list( walk_val ) -> acc ++ walk_val
                    r -> acc ++ [walk_val]
                end
              {:error, msg, _value} -> acc
          end
        end)
        if List.first(result) == nil do
          {:error, "token not found: #{next_token}", result}
        else
          {:ok, result, nil}
        end
    end
  end



  defp walk_container( operation, _parent, list, "**", tokens, value ) when operation == :set and is_list(list) do
    [next_token|next_tokens] = tokens
    result = Enum.reduce(list, [], fn(entry, acc) ->
      case walk_container( operation, list, entry, "**", tokens, value) do
        {:ok, walk_val, original_val } ->
          acc ++ [ walk_val ]
        {:error, msg, _value} ->
          acc
      end
      end)

    {:ok, result, nil}
  end


  #
  defp walk_container( operation, _parent, list, "**", tokens, value ) when is_list(list) do
    result = Enum.reduce(list, [], fn(entry, acc) ->
      case walk_container( operation, list, entry, "**", tokens, value) do
        {:ok, walk_val, original_val } ->
          acc ++ [ walk_val ]
        {:error, msg, _value} ->
          acc
      end
      end)
    {:ok, result, nil}
  end


  #
  defp walk_container( operation, _parent, map, "**", tokens, value ) do
    [next_token|_] = tokens
    {:error,"token not found: #{next_token}", map}
  end


  # recursively walk through a map container
  defp walk_container( operation, _parent, map, token, tokens, value ) when (operation == :set or operation == :remove) and is_map(map) do
    [next_token|next_tokens] = tokens

    result = case Map.fetch(map, token) do
      {:ok, existing} ->
        # catch the situation where the wildcard is the last token
        {res,sub,rem} = walk_container( operation, map, existing, next_token, next_tokens, value)
        
        # re-apply the altered tree back into our map
        if res == :ok do
          if next_token == "**" do
            {res,apply_into(map, token, sub),rem}
          else
            {res,apply_into(map, token, sub),rem}
          end
        else
          {res,sub,rem}
        end
      :error ->
          {res,sub,rem} = walk_container( operation, map, %{}, next_token, next_tokens, value)
          {res,apply_into(map, token, sub),rem}
    end
    result
  end

  # recursively walk through a map container
  defp walk_container( operation, _parent, map, token, tokens, value ) when is_map(map) do
    [next_token|next_tokens] = tokens

    result = case Map.fetch(map, token) do
      {:ok, existing} ->
        {res,sub,rem} = walk_container( operation, map, existing, next_token, next_tokens, value)
        # re-apply the altered tree back into our map
        if res == :ok do
          if next_token == "**" do
            {res,sub,rem}
          else
            {res,sub,rem}
          end
        else
          {res,sub,rem}
        end
      :error ->
        case operation do
          :has ->
            {_res,_sub,_rem} = walk_container( operation, map, %{}, next_token, next_tokens, value)
          _ ->
            {:error, "json pointer key not found #{token}", map}
        end
    end
    result
  end

  defp walk_container( operation, _parent, list, token, tokens, value ) when (operation == :set or operation == :remove) and is_list(list) do
    [next_token|tokens] = tokens
    result = case Integer.parse(token) do
      {index,_rem} ->
        if (operation == :get or operation == :has) and index >= Enum.count(list) do
          {:error, "list index out of bounds: #{index}", list}
        else
          {res,sub,rem} = walk_container( operation, list, Enum.at(list,index), next_token, tokens, value)
          # re-apply the returned result back into the current list - WHY!
          {res, apply_into(list,index,sub), rem}
        end
      _ ->
        {:error, "invalid list index: #{token}", list}
    end
    result
  end

  # recursively walk through a list container
  defp walk_container( operation, _parent, list, token, tokens, value ) when is_list(list) do
    [next_token|tokens] = tokens
    result = case Integer.parse(token) do
      {index,_rem} ->
        if (operation == :get or operation == :has) and index >= Enum.count(list) do
          {:error, "list index out of bounds: #{index}", list}
        else
          {res,sub,rem} = walk_container( operation, list, Enum.at(list,index), next_token, tokens, value)
          # re-apply the returned result back into the current list - WHY!
          {res,sub,rem}
        end
      _ ->
        {:error, "invalid list index: #{token}", list}
    end
    result
  end

  # when there is no container defined, use the type of token to decide one
  defp walk_container( operation, _parent, container, token, tokens, value ) when operation == :set and container == nil do
    [next_token|tokens] = tokens
    case Integer.parse(token) do
      {index,_rem} ->
        {res,sub,rem} = walk_container( operation, [], [], next_token, tokens, value)
        # re-apply the returned result back into the current list
        {res, apply_into([],index,sub), rem}
      _ ->
        {res,sub,rem} = walk_container( operation, %{}, %{}, next_token, tokens, value)
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
    |> String.replace( "**", "~2" )
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
    |> String.replace( "~2", "**" )
  end


  @doc """
    Converts a JSON pointer into a list of reference tokens

    ## Examples
      iex> JSONPointer.parse("/fridge/butter")
      {:ok, [ "fridge", "butter"] }
  """

  def parse(""), do: {:ok,[]}

  def parse( pointer ) do

    # handle a URI Fragment
    if String.first(pointer) == "#", do: pointer = pointer |> String.lstrip(?#)

    case String.first(pointer) do

      "/" ->
        {:ok,
          pointer
          |> String.lstrip(?/)
          |> String.split("/")
          |> Enum.map( &URI.decode/1 )
          |> Enum.map( &JSONPointer.unescape/1) }

      _ ->
        {:error, "invalid json pointer", pointer}
    end

  end


  @doc """
    Ensures that the given list has size number of elements

    ## Examples
      iex> JSONPointer.ensure_list_size( [], 2 )
      [nil, nil]
  """
  def ensure_list_size(list, size) do
    diff = size - Enum.count(list)
    if diff > 0 do
      list = list ++ List.duplicate( nil, diff )
    end
    list
  end

end
