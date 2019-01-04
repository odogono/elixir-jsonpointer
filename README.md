ODGN JSONPointer
=================
[![Build Status](https://travis-ci.org/odogono/elixir-jsonpointer.svg?branch=master)](https://travis-ci.org/odogono/elixir-jsonpointer)
[![Hex.pm](https://img.shields.io/hexpm/v/odgn_json_pointer.svg?style=flat-square)](https://hex.pm/packages/odgn_json_pointer)


This is an implementation of [JSON Pointer (RFC 6901)](http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-08) for Elixir.


## Installation

Add a dependency to your project `mix.exs`:

```Elixir

def deps do
  [{:odgn_json_pointer, "~> 2.4"}]
end

```

Then update your dependencies:

```sh-session
$ mix deps.get
```


## API

### JSONPointer.get(object, pointer)

Retrieves the value indicated by the pointer from the object

```Elixir
JSONPointer.get( %{ "fridge" => %{ "door" => "milk" } }, "/fridge/door" )
# => {:ok, "milk"}
```

### JSONPointer.get!(object,pointer)

Retrieves the value indicated by the pointer from the object, and raises an error if not found

```Elixir
JSONPointer.get!( %{}, "/fridge/milk" )
** (ArgumentError) json pointer key not found: fridge
```

### JSONPointer.set(object, pointer, value)

Sets the value indicated by the pointer in the object

```Elixir
JSONPointer.set( %{}, "/example/msg", "hello")
# => {:ok, %{ "example" => %{ "msg" => "hello" }}, nil }
```

### JSONPointer.set!(object, pointer, value)

Sets the value indicated by the pointer in the object, raises an exception on error

```Elixir
JSONPointer.set!( %{}, "/example/msg", "hello")
# => %{ "example" => %{ "msg" => "hello" }}
```

### JSONPointer.dehydrate(object)

Returns an array of JSON pointer paths mapped to their values

```Elixir
JSONPointer.dehydrate( %{"a"=>%{"b"=>["c","d"]}} )
# => {:ok, [{"/a/b/0", "c"}, {"/a/b/1", "d"}] }
```

### JSONPointer.dehydrate!(object)

Returns an array of JSON pointer paths mapped to their values, raises an exception on error

```Elixir
JSONPointer.dehydrate!( %{"a"=>%{"b"=>["c","d"]}} )
# => [{"/a/b/0", "c"}, {"/a/b/1", "d"}]
```

### JSONPointer.hydrate(container, paths)

Applies the given list of paths to the given container

```Elixir
iex> JSONPointer.hydrate( [ {"/a/1/b", "single"} ] )
# => {:ok, %{"a" => %{"1" => %{"b" => "single"}}}}
```

### JSONPointer.hydrate!(container, paths)

Applies the given list of paths to the given container, raises an exception on error

```Elixir
iex> JSONPointer.hydrate!( %{}, [ {"/a/b/1", "find"} ] )
# => {:ok, %{"a"=>%{"b"=>[nil,"find"]} } }
```

### JSONPointer.merge(src,dst)

Merges the dst container into src

```Elixir
JSONPointer.merge( %{"a"=>1}, %{"b"=>2} )
# => {:ok, %{"a"=>1,"b"=>2} }
```

### JSONPointer.merge!(src,dst)

Merges the dst container into src, raises an exception on error

```Elixir
JSONPointer.merge!( %{"a"=>1}, %{"b"=>2} )
# => %{"a"=>1,"b"=>2}
```

### JSONPointer.has(object, pointer)

Returns true if the given value exists in the object indicated by the pointer

```Elixir
JSONPointer.has( %{ "milk" => true, "butter" => false}, "/butter" )
# => true
```

### JSONPointer.remove(object, pointer)

Removes the value from the object indicated by the pointer

```Elixir
JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/butter" )
# => {:ok, %{"fridge" => %{"milk"=>true}}, true }
```

### JSONPointer.transform(src,mapping)

Applies a mapping of source paths to destination paths in the result

```Elixir
JSONPointer.transform( %{ "a"=>4, "b"=>%{ "c" => true }}, [ {"/b/c", "/valid"}, {"/a","/count", fn val -> val*2 end} ] )
# => {:ok, %{"count" => 8, "valid" => true}}
```

### JSONPointer.transform!(src,mapping)

Applies a mapping of source paths to destination paths in the result, raises an error on exception

```Elixir
JSONPointer.transform!( %{ "a"=>5, "b"=>%{ "is_valid" => true }}, [ {"/b/is_valid", "/valid"}, {"/a","/count", fn val -> val*2 end} ] )
# => %{"count" => 10, "valid" => true}
```



## Ack

inspiration from https://github.com/manuelstofer/json-pointer

made without peeking (much) at the source of https://github.com/xavier/json_pointer

Made in Exeter, UK.


## License

This software is licensed under [the MIT license](LICENSE.md).
