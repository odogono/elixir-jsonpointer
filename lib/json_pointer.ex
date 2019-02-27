defmodule JSONPointer do
  @moduledoc """
  An implementation of [JSON Pointer (RFC 6901)](http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-08) for Elixir.
  """

  import JSONPointer.Guards
  import JSONPointer.Serialize
  import JSONPointer.Utils

  @typedoc """
  the item on which the operations are applied
  """
  @type container :: map | list

  @typedoc """
  the JSON Pointer value
  """
  @type pointer :: String.t() | [String.t()]

  @typedoc """
  return type
  """
  @type t :: nil | true | false | list | float | integer | String.t() | map

  @typedoc """
  data that was affected by an operation
  """
  @type existing :: t

  @typedoc """
  data that was removed by an operation
  """
  @type removed :: t

  @typedoc """
  a tuple of JSON Pointer and value
  """
  @type pointer_list :: {String.t(), t}

  @typedoc """
  return error tuple
  """
  @type error_message :: {:error, String.t()}

  @typep transform_fn :: (any() -> any())

  @typedoc """
  argument passed to transform/2 mapping a pointer using a function or
  another pointer
  """
  @type transform_mapping ::
          {pointer, pointer}
          | {pointer, pointer, transform_fn}
          | {pointer, (() -> any())}

  @typep strict :: boolean

  @typedoc """
  options that may be passed to functions to control outcomes
  """
  @type options :: %{
          optional(:strict) => strict
        }

  @default_options %{:strict => false}
  @default_add_options %{:strict => true}

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
      {:error, "index out of bounds: 4"}
  """
  @spec get(container, pointer) :: {:ok, t} | error_message
  def get(obj, pointer, options \\ @default_options) do
    case walk_container(:get, obj, pointer, nil, options) do
      {:ok, value, _} -> {:ok, value}
      {:error, msg, _} -> {:error, msg}
    end
  end

  @doc """
  Retrieves the value indicated by the pointer from the object, raises
  an error on exception

  ## Examples
      iex> JSONPointer.get!( %{ "fridge" => %{ "milk" => true}}, "/fridge/milk" )
      true
      iex> JSONPointer.get!( %{}, "/fridge/milk" )
      ** (ArgumentError) json pointer key not found: fridge
  """
  @spec get!(container, pointer, options) :: t | no_return
  def get!(obj, pointer, options \\ @default_options) do
    case walk_container(:get, obj, pointer, nil, options) do
      {:ok, value, _} -> value
      {:error, msg, _} -> raise ArgumentError, message: msg
    end
  end

  @doc """
  Returns true if the given JSON Pointer resolves to a value

  ## Examples
      iex> JSONPointer.has!( %{ "milk" => true, "butter" => false}, "/butter" )
      true

      iex> JSONPointer.has!( %{ "milk" => true, "butter" => false}, "/cornflakes" )
      false
  """
  @spec has!(container, pointer, options) :: boolean
  def has!(obj, pointer, options \\ @default_options) do
    case walk_container(:has, obj, pointer, nil, options) do
      {:ok, _obj, _existing} -> true
      {:error, _, _} -> false
    end
  end

  @doc """
  Tests whether a JSON Pointer equals the given value

  """
  @spec test(container, pointer, t, options) :: {:ok, t} | error_message
  def test(obj, pointer, value, options \\ @default_options) do
    # with {:ok, result, existing} <- walk_container(:has, obj, pointer, nil, options)
    #   is_equal <- are_equal?
    #   do

    #   else
    #     {:error, msg, _ } -> {:error, msg}
    #   end

    case walk_container(:get, obj, pointer, nil, options) do
      {:ok, result, _} ->
        # IO.puts("are_equal?  #{pointer} => '#{value}' '#{result}'")

        case are_equal?(value, result) do
          {:ok, _} -> {:ok, obj}
          {:error, msg} -> {:error, msg}
        end

      {:error, msg, _} ->
        {:error, msg}
    end
  end

  # defp are_equal?(val1, val2) when is_binary(val1) and is_binary(val2),
  #   do:
  #     if(String.equivalent?(val1, val2), do: {:ok, true}, else: {:error, "string not equivalent"})

  defp are_equal?(val1, val2) when is_binary(val1) and is_number(val2),
    do: {:error, "number is not equal to string"}

  defp are_equal?(val1, val2) when is_number(val1) and is_binary(val2),
    do: {:error, "string is not equal to number"}

  defp are_equal?(val1, val2) do
    if val1 == val2 do
      {:ok, true}
    else
      are_not_equal_error(val1,val2)
    end
  end

  defp are_not_equal_error(val1,val2) when is_binary(val1) and is_binary(val2), do: {:error, "string not equivalent"}
  defp are_not_equal_error(_val1,_val2), do: {:error, "not equal"}

  @doc """
  Removes an attribute of object referenced by pointer

  ## Examples
      iex> JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/butter" )
      {:ok, %{"fridge" => %{"milk"=>true}}, true }

      iex> JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/sandwich" )
      {:error, "json pointer key not found: sandwich", %{ "butter" => true, "milk" => true}}
  """
  @spec remove(container, pointer, options) :: {:ok, t, removed} | error_message
  def remove(object, pointer, options \\ @default_options) do
    walk_container(:remove, object, pointer, nil, options)
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
  @spec set(container, pointer, t, options) :: {:ok, t, existing} | error_message
  def set(obj, pointer, value, options \\ @default_options) do
    case walk_container(:set, obj, pointer, value, options) do
      {:ok, result, existing} -> {:ok, result, existing}
      {:error, msg, _} -> {:error, msg}
    end
  end

  @doc """
  Sets a new value on object at the location described by pointer, raises
  an error on exception

  ## Examples
      iex> JSONPointer.set!( %{}, "/example/msg", "hello")
      %{ "example" => %{ "msg" => "hello" }}

      iex> JSONPointer.set!( %{}, "/fridge/contents/1", "milk" )
      %{"fridge" => %{"contents" => [nil, "milk"]}}

      iex> JSONPointer.set!( %{"milk"=>"full"}, "/milk", "empty")
      %{"milk" => "empty"}
  """
  @spec set!(container, pointer, t, options) :: t | no_return
  def set!(obj, pointer, value, options \\ @default_options) do
    case walk_container(:set, obj, pointer, value, options) do
      {:ok, result, _existing} -> result
      {:error, msg, _} -> raise ArgumentError, message: msg
    end
  end

  @doc """
  Adds a value using the given pointer

  Follows the JSON patch behaviour specified in rfc6902

  ## Examples
      iex> JSONPointer.add( %{ "a" => %{"b" => %{}}}, "/a/b/c", ["foo", "bar"] )
      {:ok, %{"a" => %{"b" => %{"c" => ["foo", "bar"]}}}, nil}
  """
  @spec add(container, pointer, t) :: {:ok, t, existing} | error_message
  def add(obj, pointer, value, options \\ @default_add_options) do
    case walk_container(:add, obj, pointer, value, options) do
      {:ok, result, existing} -> {:ok, result, existing}
      {:error, msg, target} -> {:error, msg, target}
    end
  end

  @doc """
  Adds a value using the given pointer, raises an error on exception

  ## Examples
      iex> JSONPointer.add!( %{ "a" => %{ "foo"  => 1 } }, "/a/b", true )
      %{"a" => %{"foo" => 1, "b" => true}}
  """
  @spec add!(container, pointer, t) :: t | no_return
  def add!(obj, pointer, value, options \\ @default_add_options) do
    case add(obj, pointer, value, options) do
      {:ok, result, _existing} -> result
      {:error, msg, _} -> raise ArgumentError, message: msg
    end
  end

  @doc """
  Extracts a list of JSON pointer paths from the given object

  ## Examples
      iex> JSONPointer.dehydrate( %{"a"=>%{"b"=>["c","d"]}} )
      {:ok, [{"/a/b/0", "c"}, {"/a/b/1", "d"}] }

      iex> JSONPointer.dehydrate( %{"a"=>[10, %{"b"=>12.5}], "c"=>99} )
      {:ok, [{"/a/0", 10}, {"/a/1/b", 12.5}, {"/c", 99}] }

  """
  @spec dehydrate(container) :: {:ok, pointer_list} | error_message
  def dehydrate(object) do
    {:ok, dehydrate_container(object, [], [])}
  end

  @doc """
  Extracts a list of JSON pointer paths from the given object, raises
  an error on exception

  ## Examples
      iex> JSONPointer.dehydrate!( %{"a"=>%{"b"=>["c","d"]}} )
      [{"/a/b/0", "c"}, {"/a/b/1", "d"}]

      iex> JSONPointer.dehydrate!( %{"a"=>[10, %{"b"=>12.5}], "c"=>99} )
      [{"/a/0", 10}, {"/a/1/b", 12.5}, {"/c", 99}]

  """
  @spec dehydrate!(container) :: pointer_list
  def dehydrate!(object) do
    dehydrate_container(object, [], [])
  end

  @doc """
  Applies the given list of paths to the given container

  ## Examples

      iex> JSONPointer.hydrate( %{}, [ {"/a/b/1", "find"} ] )
      {:ok, %{"a"=>%{"b"=>[nil,"find"]} } }

  """
  @spec hydrate(container, pointer_list) :: {:ok, container} | error_message
  def hydrate(obj, pointer_list) do
    reduce_result =
      Enum.reduce(pointer_list, obj, fn {path, value}, acc ->
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

  @doc """
  Applies the given list of paths to the given container, raises an exception
  on error

  ## Examples

      iex> JSONPointer.hydrate!( %{}, [ {"/a/b/1", "find"} ] )
      %{"a"=>%{"b"=>[nil,"find"]} }

  """
  @spec hydrate!(container, pointer_list) :: container | no_return
  def hydrate!(obj, pointer_list) do
    case hydrate(obj, pointer_list) do
      {:ok, result} -> result
      {:error, msg} -> raise ArgumentError, message: msg
    end
  end

  @doc """
  Returns the given list of paths applied to a container

  ## Examples

      iex> JSONPointer.hydrate( [ {"/a/1/b", "single"} ] )
      {:ok, %{"a" => %{"1" => %{"b" => "single"}}}}
  """
  @spec hydrate(pointer_list) :: {:ok, container} | error_message
  def hydrate(pointer_list) do
    hydrate(%{}, pointer_list)
  end

  @doc """
  Returns the given list of paths applied to a container, raises an exception
  on error

  ## Examples

      iex> JSONPointer.hydrate!( [ {"/a/b/1", "find"} ] )
      %{"a"=>%{"b"=>[nil,"find"]} }

  """
  @spec hydrate!(pointer_list) :: container | no_return
  def hydrate!(pointer_list) do
    case hydrate(pointer_list) do
      {:ok, result} -> result
      {:error, msg} -> raise ArgumentError, message: msg
    end
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
    {:ok, paths} = dehydrate(dst)
    hydrate(src, paths)
  end

  @doc """
  Merges the incoming dst object into src, raises
  an error on exception

  ## Examples

      iex> JSONPointer.merge!( %{"a"=>1}, %{"b"=>2} )
      %{"a"=>1,"b"=>2}

      iex> JSONPointer.merge!( ["foo", "bar"], ["baz"] )
      ["baz", "bar"]

  """
  @spec merge!(container, container) :: container | no_return
  def merge!(src, dst) do
    case merge(src, dst) do
      {:ok, result} -> result
      {:error, msg} -> raise ArgumentError, message: msg
    end
  end

  @doc """
  Applies a mapping of source paths to destination paths in the result

  The mapping can optionally include a function which transforms the source
  value before it is applied to the result.

  ## Examples

      iex> JSONPointer.transform( %{ "a"=>4, "b"=>%{ "c" => true }}, [ {"/b/c", "/valid"}, {"/a","/count", fn val -> val*2 end} ] )
      {:ok, %{"count" => 8, "valid" => true}}

  """
  @spec transform(map(), transform_mapping) :: map()
  def transform(src, mapping) do
    result =
      Enum.reduce(mapping, %{}, fn
        {dst_path, transform}, acc when is_function(transform) ->
          set!(acc, dst_path, transform.())

        {src_path, dst_path}, acc ->
          set!(acc, dst_path, get!(src, src_path))

        {src_path, dst_path, transform}, acc ->
          set!(acc, dst_path, transform.(get!(src, src_path)))
      end)

    {:ok, result}
  end

  @doc """
  Applies a mapping of source paths to destination paths in the result, raises an
  error on exception

  The mapping can optionally include a function which transforms the source
  value before it is applied to the result.

  ## Examples

      iex> JSONPointer.transform!( %{ "a"=>5, "b"=>%{ "is_valid" => true }}, [ {"/b/is_valid", "/valid"}, {"/a","/count", fn val -> val*2 end} ] )
      %{"count" => 10, "valid" => true}

  """
  @spec transform!(map(), transform_mapping) :: map()
  def transform!(src, mapping) do
    case transform(src, mapping) do
      {:ok, result} -> result
      {:error, msg} -> raise ArgumentError, message: msg
    end
  end

  defp insert_into(list, index, val) when is_list(list) do
    list |> ensure_list_size(index) |> List.insert_at(index, val)
  end

  defp remove_from(list, index) when is_list(list) do
    list |> List.pop_at(index)
  end

  defp apply_into(list, "-", val) when is_list(list) do
    list ++ [val]
  end

  # set the list at index to val
  defp apply_into(list, index, val) when is_list(list) do
    # ensure the list has the capacity for this index
    list |> ensure_list_size(index + 1) |> List.replace_at(index, val)
  end

  # set the key to val within a map
  defp apply_into(map, key, val) when is_map(map) do
    Map.put(map, key, val)
  end

  # when an empty pointer has been provided and this is an add operation,
  # replace the root
  defp walk_container(:add, object, "", value, _options) do
    {:ok, value, object}
  end

  # when an empty pointer has been provided, simply return the incoming object
  defp walk_container(_operation, object, "", _value, _options) do
    {:ok, object, nil}
  end

  defp walk_container(_operation, object, "#", _value, _options) do
    {:ok, object, nil}
  end

  defp walk_container(_operation, object, _pointer, _value, _options) when is_bitstring(object) do
    raise ArgumentError, message: "invalid object: #{object}"
  end

  # begins the descent into a container using the specified pointer
  defp walk_container(operation, object, pointer, value, options) when is_list(pointer) do
    [token | tokens] = pointer
    walk_container(operation, nil, object, token, tokens, value, options)
  end

  # begins the descent into a container using the specified pointer
  defp walk_container(operation, object, pointer, value, options) do
    case parse(pointer) do
      {:ok, tokens} ->
        [token | tokens] = tokens
        walk_container(operation, nil, object, token, tokens, value, options)

      {:error, reason, value} ->
        {:error, reason, value}
    end
  end

  # leaf operation: remove from map
  defp walk_container(operation, _parent, map, "**", tokens, _value, _options)
       when is_remove_from_map(operation, map, tokens) do
    {:ok, nil, map}
  end

  # leaf operation: remove from map
  defp walk_container(operation, _parent, map, token, tokens, _value, _options)
       when is_remove_from_map(operation, map, tokens) do
    case Map.fetch(map, token) do
      {:ok, existing} ->
        {:ok, Map.delete(map, token), existing}

      :error ->
        {:error, "json pointer key not found: #{token}", map}
    end
  end

  # leaf operation: remove from list
  defp walk_container(operation, _parent, list, token, tokens, _value, _options)
       when is_remove_from_list(operation, list, tokens) do
    case parse_index(token) do
      {:error, msg} ->
        {:error, msg, list}

      index ->
        {removed, list} = remove_from(list, index)
        {:ok, list, removed}
    end
  end

  # leaf operation: set token to value on a map
  defp walk_container(operation, _parent, map, "-", tokens, value, _options)
       when is_set_map(operation, map, tokens) do
    {:ok, apply_into(map, "-", value), nil}
  end

  # leaf operation: set token to value on an empty map
  defp walk_container(operation, _parent, map, token, tokens, value, _options)
       when is_add_set_empty_map(operation, map, tokens) do
    # IO.puts("empty map #{token}")
    # IO.inspect(map)

    case parse_index(token) do
      {:error, _msg} ->
        # this is ok, treat the token just as a string
        {:ok, apply_into(map, token, value), nil}

      index ->
        # the token turned out to be an array index, so convert the value into a list
        {:ok, apply_into([], index, value), nil}
    end
  end

  # leaf operation: set token to value on a map
  defp walk_container(operation, _parent, map, token, tokens, value, _options)
       when is_add_set_map(operation, map, tokens) do
    # IO.puts("uhh #{token}")
    # IO.inspect(map)

    case Map.fetch(map, token) do
      {:ok, existing} ->
        {:ok, apply_into(map, token, value), existing}

      :error ->
        {:ok, apply_into(map, token, value), nil}
    end
  end

  # leaf operation: set wildcard to value on a list
  defp walk_container(operation, _parent, list, "**", tokens, value, _options)
       when is_set_list(operation, list, tokens) do
    # replace each entry in the list with the value
    result =
      Enum.reduce(list, [], fn _entry, acc ->
        acc ++ [value]
      end)

    {:ok, result, nil}
  end

  defp walk_container(operation, parent, _map, "**", tokens, value, _options)
       when is_set_map(operation, parent, tokens) do
    {:ok, value, nil}
  end

  defp walk_container(operation, _parent, list, "-", tokens, value, _options)
       when is_add_set_list(operation, list, tokens) do
    {:ok, apply_into(list, "-", value), nil}
  end

  defp walk_container(operation, _parent, list, token, tokens, value, options)
       when is_add_list(operation, list, tokens) do
    is_strict = Map.get(options, :strict)

    case parse_index(token) do
      {:error, msg} ->
        # {:ok, apply_into( %{}, token, value), nil}
        {:error, msg, list}

      index ->
        if is_strict && (index < 0 || index > Enum.count(list)) do
          {:error, "index out of bounds: #{index}", list}
        else
          {:ok, insert_into(list, index, value), Enum.at(list, index)}
        end
    end
  end

  # leaf operation: set token(index) to value on a list
  defp walk_container(operation, _parent, list, token, tokens, value, _options)
       when is_set_list(operation, list, tokens) do
    case parse_index(token) do
      {:error, msg} ->
        {:error, msg, list}

      index ->
        {:ok, apply_into(list, index, value), Enum.at(list, index)}
    end
  end

  defp walk_container(operation, parent, list, "-", tokens, value, _options)
       when is_set_list_nil_child(operation, parent, tokens, list) do
    {:ok, apply_into([], "-", value), nil}
  end

  # leaf operation: no value for list, so we determine the container depending on the token
  defp walk_container(operation, parent, list, token, tokens, value, _options)
       when is_set_list_nil_child(operation, parent, tokens, list) do
    case parse_index(token) do
      {:error, _msg} ->
        # this is fine, token is a string
        {:ok, apply_into(%{}, token, value), nil}

      index ->
        {:ok, apply_into([], index, value), nil}
    end
  end

  # leaf operation: does map have token?
  defp walk_container(operation, _parent, map, "**", tokens, _value, _options)
       when is_get_map(operation, map, tokens) do
    {:ok, map, nil}
  end

  # leaf operation: does map have token?
  defp walk_container(operation, _parent, map, "", tokens, _value, _options)
       when is_get_map(operation, map, tokens) do
    case Map.fetch(map, "") do
      {:ok, existing} ->
        {:ok, existing, nil}

      :error ->
        {:ok, map, nil}
    end
  end

  # leaf operation: does map have token?
  defp walk_container(operation, _parent, map, token, tokens, _value, _options)
       when is_get_map(operation, map, tokens) do
    case Map.fetch(map, token) do
      {:ok, existing} ->
        {:ok, existing, nil}

      :error ->
        {:error, "token not found: #{token}", map}
    end
  end

  # leaf operation: does list have index?
  defp walk_container(operation, _parent, list, "**", tokens, _value, _options)
       when is_get_list(operation, list, tokens) do
    {:ok, list, nil}
  end

  # leaf operation: does list have index?
  defp walk_container(operation, _parent, list, token, tokens, _value, _options)
       when is_get_list(operation, list, tokens) do
    case parse_index(token) do
      {:error, msg} ->
        {:error, msg, list}

      index when is_binary(index) ->
        {:error, "invalid index: #{token}", list}

      index ->
        if index < Enum.count(list) && Enum.at(list, index) != nil do
          {:ok, Enum.at(list, index), nil}
        else
          {:error, "index out of bounds: #{index}", list}
        end
    end
  end

  #
  defp walk_container(operation, _parent, map, "**", tokens, value, options) when is_map(map) do
    [next_token | next_tokens] = tokens

    next_result(
      Map.fetch(map, next_token),
      operation,
      map,
      "**",
      next_token,
      next_tokens,
      value,
      options
    )
  end

  defp walk_container(operation, _parent, list, "**", tokens, value, options)
       when is_set_list_no_tokens(operation, list) do
    result =
      Enum.reduce(list, [], fn entry, acc ->
        case walk_container(operation, list, entry, "**", tokens, value, options) do
          {:ok, walk_val, _original_val} ->
            acc ++ [walk_val]

          {:error, _msg, _value} ->
            acc
        end
      end)

    {:ok, result, nil}
  end

  #
  defp walk_container(operation, _parent, list, "**", tokens, value, options)
       when is_list(list) do
    result =
      Enum.reduce(list, [], fn entry, acc ->
        case walk_container(operation, list, entry, "**", tokens, value, options) do
          {:ok, walk_val, _original_val} ->
            acc ++ [walk_val]

          {:error, _msg, _value} ->
            acc
        end
      end)

    {:ok, result, nil}
  end

  #
  defp walk_container(_operation, _parent, map, "**", tokens, _value, _options) do
    [next_token | _] = tokens
    {:error, "token not found: #{next_token}", map}
  end

  # recursively walk through a map container
  defp walk_container(operation, _parent, map, token, tokens, value, options)
       when is_add_set_remove_map(operation, map) do
    [next_token | next_tokens] = tokens

    next_result(
      Map.fetch(map, token),
      operation,
      map,
      token,
      next_token,
      next_tokens,
      value,
      options
    )
  end

  # recursively walk through a map container
  defp walk_container(operation, _parent, map, token, tokens, value, options) when is_map(map) do
    [next_token | next_tokens] = tokens

    result =
      case Map.fetch(map, token) do
        {:ok, existing} ->
          {res, sub, rem} =
            walk_container(operation, map, existing, next_token, next_tokens, value, options)

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
                walk_container(operation, map, %{}, next_token, next_tokens, value, options)

            _ ->
              {:error, "json pointer key not found: #{token}", map}
          end
      end

    result
  end

  defp walk_container(operation, _parent, list, token, tokens, value, options)
       when is_set_remove_list(operation, list) do
    [next_token | tokens] = tokens

    result =
      case parse_index(token) do
        {:error, msg} ->
          {:error, msg, list}

        index ->
          {res, sub, rem} =
            walk_container(
              operation,
              list,
              Enum.at(list, index),
              next_token,
              tokens,
              value,
              options
            )

          # re-apply the returned result back into the current list - WHY!
          {res, apply_into(list, index, sub), rem}
      end

    result
  end

  # recursively walk through a list container
  defp walk_container(operation, _parent, list, token, tokens, value, options)
       when is_list(list) do
    [next_token | tokens] = tokens

    result =
      case parse_index(token) do
        {:error, msg} ->
          {:error, msg, list}

        index ->
          if (operation == :get or operation == :has) and index >= Enum.count(list) do
            {:error, "index out of bounds: #{index}", list}
          else

            {res, sub, rem} =
              walk_container(
                operation,
                list,
                Enum.at(list, index),
                next_token,
                tokens,
                value,
                options
              )

            # a sublety of adding over setting
            if operation == :add, do: {res, apply_into( list, index, sub ), list}, else: {res, sub, rem}
            # {res, [sub], list}
          end
      end

    result
  end

  # when there is no container defined, use the type of token to decide one
  defp walk_container(operation, _parent, container, token, tokens, value, options)
       when is_set_nil_container(operation, container) do
    [next_token | tokens] = tokens

    case parse_index(token) do
      index when is_integer(index) ->
        {res, sub, rem} = walk_container(operation, [], [], next_token, tokens, value, options)
        # re-apply the returned result back into the current list
        {res, apply_into([], index, sub), rem}

      _ ->
        {res, sub, rem} = walk_container(operation, %{}, %{}, next_token, tokens, value, options)
        # re-apply the returned result back into the current list
        {res, apply_into(%{}, token, sub), rem}
    end
  end

  defp next_result(:error, operation, map, "**", next_token, next_tokens, value, options)
       when is_set_map_no_tokens(operation, map) do
    result =
      Enum.reduce(map, %{}, fn {map_key, _map_value}, result ->
        case walk_container(
               operation,
               map,
               Map.fetch!(map, map_key),
               "**",
               [next_token] ++ next_tokens,
               value,
               options
             ) do
          {:ok, rval, _res} ->
            apply_into(result, map_key, rval)

          {:error, msg, _value} ->
            raise "error applying :set into map: #{msg}"
        end
      end)

    {:ok, result, nil}
  end

  defp next_result(
         {:ok, _existing},
         operation,
         map,
         "**",
         next_token,
         next_tokens,
         value,
         options
       ) do
    walk_container(operation, map, map, next_token, next_tokens, value, options)
  end

  defp next_result(:error, operation, map, "**", next_token, next_tokens, value, options)
       when is_map(map) do
    result =
      Enum.reduce(Map.keys(map), [], fn map_key, acc ->
        operation
        |> walk_container(
          map,
          Map.fetch!(map, map_key),
          "**",
          [next_token] ++ next_tokens,
          value,
          options
        )
        |> next_result(acc)
      end)

    if List.first(result) == nil do
      {:error, "token not found: #{next_token}", result}
    else
      {:ok, result, nil}
    end
  end

  defp next_result(
         {:ok, existing},
         operation,
         map,
         token,
         next_token,
         next_tokens,
         value,
         options
       ) do
    # catch the situation where the wildcard is the last token
    {res, sub, rem} =
      walk_container(operation, map, existing, next_token, next_tokens, value, options)

    # re-apply the altered tree back into our map
    if res == :ok do
      {res, apply_into(map, token, sub), rem}
    else
      {res, sub, rem}
    end
  end

  defp next_result(:error, operation, map, token, next_token, next_tokens, value, options) do
    case Map.get(options, :strict) do
      true ->
        {:error, "path /#{token} does not exist", map}

      _ ->
        new_container = if next_token == "-", do: [], else: %{}

        {res, sub, rem} =
          walk_container(
            operation,
            map,
            new_container,
            next_token,
            next_tokens,
            value,
            options
          )

        {res, apply_into(map, token, sub), rem}
    end
  end

  defp next_result({:ok, walk_val, _walk_res}, acc) when is_list(walk_val), do: acc ++ walk_val
  defp next_result({:ok, walk_val, _walk_res}, acc), do: acc ++ [walk_val]
  defp next_result({:error, _msg, _value}, acc), do: acc
end
