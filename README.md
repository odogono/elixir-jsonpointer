ODGN JSONPointer
=================
[![Build Status](https://travis-ci.org/odogono/elixir-jsonpointer.svg?branch=master)](https://travis-ci.org/odogono/elixir-jsonpointer)
[![Hex.pm](https://img.shields.io/hexpm/v/odgn_json_pointer.svg?style=flat-square)](https://hex.pm/packages/odgn_json_pointer)


This is an implementation of [JSON Pointer (RFC 6901)](http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-08) for Elixir.


## Installation

Add a dependency to your project `mix.exs`:

```Elixir

def deps do
  [{:odgn_json_pointer, "-> 1.0.0"}]
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


### JSONPointer.set(object, pointer, value)

Sets the value indicated by the pointer in the object

```Elixir
JSONPointer.set( %{}, "/example/msg", "hello")
# => {:ok, %{ "example" => %{ "msg" => "hello" }}, nil }
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


## Ack

inspiration from https://github.com/manuelstofer/json-pointer.git

made without peeking (much) at the source of https://github.com/xavier/json_pointer

Made in Exeter, UK.


## License

This software is licensed under [the MIT license](LICENSE.md).