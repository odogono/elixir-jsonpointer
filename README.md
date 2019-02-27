ODGN JSONPointer
=================
[![Build Status](https://travis-ci.org/odogono/elixir-jsonpointer.svg?branch=master)](https://travis-ci.org/odogono/elixir-jsonpointer)
[![Hex.pm](https://img.shields.io/hexpm/v/odgn_json_pointer.svg?style=flat-square)](https://hex.pm/packages/odgn_json_pointer)


An implementation of [JSON Pointer (RFC 6901)](http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-08) for Elixir.


## Installation

Add a dependency to your project `mix.exs`:

```Elixir
def deps do
  [{:odgn_json_pointer, "~> 2.5"}]
end
```

## Basic Usage

```Elixir
iex> JSONPointer.get( %{ "fridge" => %{ "door" => "milk" } }, "/fridge/door" )
{:ok, "milk"}


iex> JSONPointer.set( %{}, "/example/msg", "hello")
{:ok, %{ "example" => %{ "msg" => "hello" }}, nil }


iex> JSONPointer.add( %{ "fridge" => [ "milk", "cheese" ]}, "/fridge/1", "salad")
{:ok, %{ "fridge" => [ "milk", "salad", "cheese" ]}, [ "milk", "cheese" ] }


iex> JSONPointer.has?( %{ "milk" => true, "butter" => false}, "/butter" )
true


iex> JSONPointer.test( %{ "milk" => "skimmed", "butter" => false}, "/milk", "skimmed" )
{:ok, %{ "milk" => "skimmed", "butter" => false} }


iex> JSONPointer.remove( %{"fridge" => %{ "milk" => true, "butter" => true}}, "/fridge/butter" )
{:ok, %{"fridge" => %{"milk"=>true}}, true }


iex> JSONPointer.dehydrate( %{"a"=>%{"b"=>["c","d"]}} )
{:ok, [{"/a/b/0", "c"}, {"/a/b/1", "d"}] }


iex> iex> JSONPointer.hydrate( [ {"/a/1/b", "single"} ] )
{:ok, %{"a" => %{"1" => %{"b" => "single"}}}}


iex> JSONPointer.merge( %{"a"=>1}, %{"b"=>2} )
{:ok, %{"a"=>1,"b"=>2} }


iex> JSONPointer.transform( %{ "a"=>4, "b"=>%{ "c" => true }}, [ {"/b/c", "/valid"}, {"/a","/count", fn val -> val*2 end} ] )
{:ok, %{"count" => 8, "valid" => true}}

```

Full documentation can be found at https://hexdocs.pm/odgn_json_pointer.



## Ack

inspiration from https://github.com/manuelstofer/json-pointer

made without peeking (much) at the source of https://github.com/xavier/json_pointer

Made in Exeter, UK.


## License

This software is licensed under [the MIT license](LICENSE.md).
