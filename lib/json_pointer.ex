defmodule JSONPointer do
  @type input :: map()
  @type pointer :: String.t() | [String.t()]
  @type t :: nil | true | false | list | float | integer | String.t() | map
  @type msg :: String.t()
  @type existing :: t
  @type removed :: t
  @type pointer_list :: [String.t()]
  @type container :: map | list

  defguard is_remove_from_map(operation, map, tokens)
           when operation == :remove and tokens == [] and is_map(map)

  defguard is_remove_from_list(operation, list, tokens)
           when operation == :remove and tokens == [] and is_list(list)

  defguard is_set_map(operation, map, tokens)
           when operation == :set and tokens == [] and is_map(map)

  defguard is_set_list(operation, list, tokens)
           when operation == :set and tokens == [] and is_list(list)

  defguard is_set_list_nil_child(operation, parent, tokens, child)
           when operation == :set and tokens == [] and is_list(parent) and child == nil

  defguard is_get_map(operation, map, tokens)
           when (operation == :has or operation == :get) and tokens == [] and is_map(map)

  defguard is_get_list(operation, list, tokens)
           when (operation == :has or operation == :get) and tokens == [] and is_list(list)

  defguard is_set_map_no_tokens(operation, map)
           when operation == :set and is_map(map)

  defguard is_set_list_no_tokens(operation, list)
           when operation == :set and is_list(list)

  defguard is_set_remove_map(operation, map)
           when (operation == :set or operation == :remove) and is_map(map)

  defguard is_set_remove_list(operation, list)
           when (operation == :set or operation == :remove) and is_list(list)

  defguard is_set_nil_container(operation, container)
           when operation == :set and container == nil

  @doc """
    Retrieves the value indicated by the pointer from the object

    ## Examples
      iex> JSONPointer.get( %{ "fridge" => %{ "door" => "milk" } }, "/fridge/door" )
      {:ok, "milk"}

      iex> JSONPointer.get( %{ "contents" => [ "milk", "butter", "eggs" ]}, "/contents/2" )
      {:ok, "eggs"} 

      iex> JSONPointer.get( %{ "milk" => true, "butter" => false}, "/cornflakes" )
      {:error, "token not found: cornflakes"}

      iex> JSONPointer.get( %{ "contents" => [ "milk", "butter", "eggs" ]}, "/contents/4" )
      {:error, "list index out of bounds: 4"} 
  """
  @spec get(input, pointer) :: {:ok, t} | {:error, msg}
  def get(obj, pointer) do
    case walk_container(:get, obj, pointer, nil) do
      {:ok, value, _} -> {:ok, value}
      {:error, msg, _} -> {:error, msg}
    end
  end

  @doc """
    Retrieves the value indicated by the pointer from the object

    raises an exception if there is an error

    ## Examples
      iex> JSONPointer.get!( %{}, "/fridge/milk" )
      ** (ArgumentError) json pointer key not found: fridge
  """
  @spec get!(input, pointer) :: {:ok, t} | no_return
  def get!(obj, pointer) do
    case walk_container(:get, obj, pointer, nil) do
      {:ok, value, _} -> value
      {:error, msg, _} -> raise ArgumentError, message: msg
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
  @spec has(input, pointer) :: boolean
  def has(obj, pointer) do
    case walk_container(:has, obj, pointer, nil) do
      {:ok, _obj, _existing} -> true
      {:error, _, _} -> false
    end
  end

  @doc """
    Removes an attribute of object referenced by pointer

    ## Examples
      iex> JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/butter" )
      {:ok, %{"fridge" => %{"milk"=>true}}, true }

      iex> JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/sandwich" )
      {:error, "json pointer key not found: sandwich", %{ "butter" => true, "milk" => true}}
  """
  @spec remove(input, pointer) :: {:ok, t, removed} | {:error, msg}
  def remove(object, pointer) do
    walk_container(:remove, object, pointer, nil)
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
  @spec set(input, pointer, t) :: {:ok, t, existing} | {:error, msg}
  def set(object, pointer, value) do
    case walk_container(:set, object, pointer, value) do
      {:ok, result, existing} -> {:ok, result, existing}
      {:error, msg, _} -> {:error, msg}
    end
  end

  @doc """
  Extracts a list of JSON pointer paths from the given object

    ## Examples
    iex> JSONPointer.extract( %{"a"=>%{"b"=>["c","d"]}} )
    {:ok, [{"/a/b/0", "c"}, {"/a/b/1", "d"}] }

    iex> JSONPointer.extract( %{"a"=>[10, %{"b"=>12.5}], "c"=>99} )
    {:ok, [{"/a/0", 10}, {"/a/1/b", 12.5}, {"/c", 99}] }

  """
  @spec extract(input) :: {:ok, pointer_list}
  def extract(object) do
    {:ok, extract_container(object, [], [])}
  end

  defp extract_container(value, acc, result) when is_list(value) do
    value |> Stream.with_index()
    |> Enum.reduce(result, fn {v, k}, racc ->
      k = Integer.to_string(k)
      racc ++ extract_container(v, [k | acc], result)
    end)
  end

  defp extract_container(value, acc, result) when is_map(value) do
    Enum.reduce(value, result, fn {k, v}, racc ->
      racc ++ extract_container(v, [k | acc], result)
    end)
  end

  defp extract_container(value, acc, result) do
    # join the accumulated keys together into a path, and join it with the result
    parts = Enum.map(acc, fn path -> escape(path) end)
    [{"/" <> Enum.join(Enum.reverse(parts), "/"), value} | result]
  end

  @doc """
  Merges the incoming dst object into src

    ## Examples

    iex> JSONPointer.merge( %{"a"=>1}, %{"b"=>2} )
    {:ok, %{"a"=>1,"b"=>2} }

    iex> JSONPointer.merge( ["foo", "bar"], ["baz"] )
    {:ok, ["baz", "bar"]}

  """
  @spec merge(container, container) :: {:ok, container}
  def merge(src, dst) do
    # extract a list of json paths from the dst
    {:ok, paths} = extract(dst)

    # apply each of those paths to the src
    reduce_result =
      Enum.reduce(paths, src, fn {path, value}, acc ->
        case JSONPointer.set(acc, path, value) do
          {:ok, result, _} -> result
          {:error, reason} -> {:error, reason}
        end
      end)

    case reduce_result do
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  end

  # set the list at index to val
  defp apply_into(list, index, val) when is_list(list) do
    if index do
      # ensure the list has the capacity for this index
      list |> ensure_list_size(index + 1) |> List.replace_at(index, val)
    else
      val
    end
  end

  # set the key to val within a map
  defp apply_into(map, key, val) when is_map(map) do
    if key do
      Map.put(map, key, val)
    else
      val
    end
  end

  # when an empty pointer has been provided, simply return the incoming object
  defp walk_container(_operation, object, "", _value) do
    {:ok, object, nil}
  end

  defp walk_container(_operation, object, "#", _value) do
    {:ok, object, nil}
  end

  # begins the descent into a container using the specified pointer  
  defp walk_container(operation, object, pointer, value) when is_list(pointer) do
    [token | tokens] = pointer
    walk_container(operation, nil, object, token, tokens, value)
  end

  # begins the descent into a container using the specified pointer
  defp walk_container(operation, object, pointer, value) do
    case JSONPointer.parse(pointer) do
      {:ok, tokens} ->
        [token | tokens] = tokens
        walk_container(operation, nil, object, token, tokens, value)

      {:error, reason, value} ->
        {:error, reason, value}
    end
  end

  # leaf operation: remove from map
  defp walk_container(operation, _parent, map, token, tokens, _value)
       when is_remove_from_map(operation, map, tokens) do
    if token == "**" do
      {:ok, nil, map}
    else
      case Map.fetch(map, token) do
        {:ok, existing} ->
          {:ok, Map.delete(map, token), existing}

        :error ->
          {:error, "json pointer key not found: #{token}", map}
      end
    end
  end

  # leaf operation: remove from list
  defp walk_container(operation, _parent, list, token, tokens, _value)
       when is_remove_from_list(operation, list, tokens) do
    case Integer.parse(token) do
      {index, _rem} ->
        {:ok, apply_into(list, index, nil), Enum.at(list, index)}

      :error ->
        {:error, "invalid json pointer invalid index: #{token}", list}
    end
  end

  # leaf operation: set token to value on a map
  defp walk_container(operation, _parent, map, token, tokens, value)
       when is_set_map(operation, map, tokens) do
    case Integer.parse(token) do
      {index, _rem} ->
        # the token turned out to be an array index, so convert the value into a list
        {:ok, apply_into([], index, value), nil}

      :error ->
        case Map.fetch(map, token) do
          {:ok, existing} ->
            {:ok, apply_into(map, token, value), existing}

          :error ->
            {:ok, apply_into(map, token, value), nil}
        end
    end
  end

  # leaf operation: set wildcard to value on a list
  defp walk_container(operation, _parent, list, "**", tokens, value)
       when is_set_list(operation, list, tokens) do
    # replace each entry in the list with the value
    result =
      Enum.reduce(list, [], fn _entry, acc ->
        acc ++ [value]
      end)

    {:ok, result, nil}
  end

  defp walk_container(operation, parent, _map, "**", tokens, value)
       when is_set_map(operation, parent, tokens) do
    {:ok, value, nil}
  end

  # leaf operation: set token(index) to value on a list
  defp walk_container(operation, _parent, list, token, tokens, value)
       when is_set_list(operation, list, tokens) do
    case Integer.parse(token) do
      {index, _rem} ->
        {:ok, apply_into(list, index, value), Enum.at(list, index)}

      :error ->
        {:error, "invalid json pointer invalid index #{token}", list}
    end
  end

  # leaf operation: no value for list, so we determine the container depending on the token
  defp walk_container(operation, parent, list, token, tokens, value)
       when is_set_list_nil_child(operation, parent, tokens, list) do
    case Integer.parse(token) do
      {index, _rem} ->
        {:ok, apply_into([], index, value), nil}

      :error ->
        {:ok, apply_into(%{}, token, value), nil}
    end
  end

  # leaf operation: does map have token?
  defp walk_container(operation, _parent, map, token, tokens, _value)
       when is_get_map(operation, map, tokens) do
    if token == "**" do
      {:ok, map, nil}
    else
      case Map.fetch(map, token) do
        {:ok, existing} ->
          {:ok, existing, nil}

        :error ->
          {:error, "token not found: #{token}", map}
      end
    end
  end

  # leaf operation: does list have index?
  defp walk_container(operation, _parent, list, token, tokens, _value)
       when is_get_list(operation, list, tokens) do
    if token == "**" do
      {:ok, list, nil}
    else
      case Integer.parse(token) do
        {index, _rem} ->
          if index < Enum.count(list) && Enum.at(list, index) != nil do
            {:ok, Enum.at(list, index), nil}
          else
            {:error, "list index out of bounds: #{index}", list}
          end

        :error ->
          {:error, "token not found: #{token}", list}
      end
    end
  end

  #
  defp walk_container(operation, _parent, map, "**", tokens, value)
       when is_set_map_no_tokens(operation, map) do
    [next_token | next_tokens] = tokens

    case Map.fetch(map, next_token) do
      {:ok, _existing} ->
        walk_container(operation, map, map, next_token, next_tokens, value)

      :error ->
        result =
          Enum.reduce(map, %{}, fn {map_key, _map_value}, result ->
            case walk_container(operation, map, Map.fetch!(map, map_key), "**", tokens, value) do
              {:ok, rval, _res} ->
                apply_into(result, map_key, rval)

              {:error, msg, _value} ->
                raise "error applying :set into map: #{msg}"
            end
          end)

        {:ok, result, nil}
    end
  end

  #
  defp walk_container(operation, _parent, map, "**", tokens, value) when is_map(map) do
    [next_token | next_tokens] = tokens

    case Map.fetch(map, next_token) do
      {:ok, _existing} ->
        walk_container(operation, map, map, next_token, next_tokens, value)

      :error ->
        result =
          Enum.reduce(Map.keys(map), [], fn map_key, acc ->
            case walk_container(operation, map, Map.fetch!(map, map_key), "**", tokens, value) do
              {:ok, walk_val, _walk_res} ->
                case walk_val do
                  _walk_result when is_list(walk_val) -> acc ++ walk_val
                  _walk_result -> acc ++ [walk_val]
                end

              {:error, _msg, _value} ->
                acc
            end
          end)

        if List.first(result) == nil do
          {:error, "token not found: #{next_token}", result}
        else
          {:ok, result, nil}
        end
    end
  end

  defp walk_container(operation, _parent, list, "**", tokens, value)
       when is_set_list_no_tokens(operation, list) do
    result =
      Enum.reduce(list, [], fn entry, acc ->
        case walk_container(operation, list, entry, "**", tokens, value) do
          {:ok, walk_val, _original_val} ->
            acc ++ [walk_val]

          {:error, _msg, _value} ->
            acc
        end
      end)

    {:ok, result, nil}
  end

  #
  defp walk_container(operation, _parent, list, "**", tokens, value) when is_list(list) do
    result =
      Enum.reduce(list, [], fn entry, acc ->
        case walk_container(operation, list, entry, "**", tokens, value) do
          {:ok, walk_val, _original_val} ->
            acc ++ [walk_val]

          {:error, _msg, _value} ->
            acc
        end
      end)

    {:ok, result, nil}
  end

  #
  defp walk_container(_operation, _parent, map, "**", tokens, _value) do
    [next_token | _] = tokens
    {:error, "token not found: #{next_token}", map}
  end

  # recursively walk through a map container
  defp walk_container(operation, _parent, map, token, tokens, value)
       when is_set_remove_map(operation, map) do
    [next_token | next_tokens] = tokens

    result =
      case Map.fetch(map, token) do
        {:ok, existing} ->
          # catch the situation where the wildcard is the last token
          {res, sub, rem} =
            walk_container(operation, map, existing, next_token, next_tokens, value)

          # re-apply the altered tree back into our map
          if res == :ok do
            if next_token == "**" do
              {res, apply_into(map, token, sub), rem}
            else
              {res, apply_into(map, token, sub), rem}
            end
          else
            {res, sub, rem}
          end

        :error ->
          {res, sub, rem} = walk_container(operation, map, %{}, next_token, next_tokens, value)
          {res, apply_into(map, token, sub), rem}
      end

    result
  end

  # recursively walk through a map container
  defp walk_container(operation, _parent, map, token, tokens, value) when is_map(map) do
    [next_token | next_tokens] = tokens

    result =
      case Map.fetch(map, token) do
        {:ok, existing} ->
          {res, sub, rem} =
            walk_container(operation, map, existing, next_token, next_tokens, value)

          # re-apply the altered tree back into our map
          if res == :ok do
            if next_token == "**" do
              {res, sub, rem}
            else
              {res, sub, rem}
            end
          else
            {res, sub, rem}
          end

        :error ->
          case operation do
            :has ->
              {_res, _sub, _rem} =
                walk_container(operation, map, %{}, next_token, next_tokens, value)

            _ ->
              {:error, "json pointer key not found: #{token}", map}
          end
      end

    result
  end

  defp walk_container(operation, _parent, list, token, tokens, value)
       when is_set_remove_list(operation, list) do
    [next_token | tokens] = tokens

    result =
      case Integer.parse(token) do
        {index, _rem} ->
          {res, sub, rem} =
            walk_container(operation, list, Enum.at(list, index), next_token, tokens, value)

          # re-apply the returned result back into the current list - WHY!
          {res, apply_into(list, index, sub), rem}

        _ ->
          {:error, "invalid list index: #{token}", list}
      end

    result
  end

  # recursively walk through a list container
  defp walk_container(operation, _parent, list, token, tokens, value) when is_list(list) do
    [next_token | tokens] = tokens

    result =
      case Integer.parse(token) do
        {index, _rem} ->
          if (operation == :get or operation == :has) and index >= Enum.count(list) do
            {:error, "list index out of bounds: #{index}", list}
          else
            {res, sub, rem} =
              walk_container(operation, list, Enum.at(list, index), next_token, tokens, value)

            # re-apply the returned result back into the current list - WHY!
            {res, sub, rem}
          end

        _ ->
          {:error, "invalid list index: #{token}", list}
      end

    result
  end

  # when there is no container defined, use the type of token to decide one
  defp walk_container(operation, _parent, container, token, tokens, value)
       when is_set_nil_container(operation, container) do
    [next_token | tokens] = tokens

    case Integer.parse(token) do
      {index, _rem} ->
        {res, sub, rem} = walk_container(operation, [], [], next_token, tokens, value)
        # re-apply the returned result back into the current list
        {res, apply_into([], index, sub), rem}

      _ ->
        {res, sub, rem} = walk_container(operation, %{}, %{}, next_token, tokens, value)
        # re-apply the returned result back into the current list
        {res, apply_into(%{}, token, sub), rem}
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

  # def parse(pointer) when is_binary(pointer), do: parse(String.to_char_list(pointer))

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
         |> Enum.map(&URI.decode/1)
         |> Enum.map(&JSONPointer.unescape/1)}

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
  @spec ensure_list_size(list, non_neg_integer()) :: list
  def ensure_list_size(list, size) do
    diff = size - Enum.count(list)

    if diff > 0 do
      list ++ List.duplicate(nil, diff)
    else
      list
    end
  end
end
