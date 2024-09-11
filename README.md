# ODGN JSONPointer

[![Build Status](https://travis-ci.org/odogono/elixir-jsonpointer.svg?branch=master)](https://travis-ci.org/odogono/elixir-jsonpointer)
[![Hex.pm](https://img.shields.io/hexpm/v/odgn_json_pointer.svg?style=flat-square)](https://hex.pm/packages/odgn_json_pointer)
[![Module Version](https://img.shields.io/hexpm/v/odgn_json_pointer.svg)](https://hex.pm/packages/odgn_json_pointer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/odgn_json_pointer/)
[![Total Download](https://img.shields.io/hexpm/dt/odgn_json_pointer.svg)](https://hex.pm/packages/odgn_json_pointer)
[![License](https://img.shields.io/hexpm/l/odgn_json_pointer.svg)](https://github.com/odogono/elixir-jsonpointer/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/odogono/elixir-jsonpointer.svg)](https://github.com/odogono/elixir-jsonpointer/commits/master)

An implementation of [JSON Pointer (RFC 6901)](http://tools.ietf.org/html/draft-ietf-appsawg-json-pointer-08) for Elixir.

## Installation

Add a dependency to your project `mix.exs`:

```elixir
def deps do
  [
    {:odgn_json_pointer, "~> 3.1.0"}
  ]
end
```

## Basic Usage

```elixir
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

## Acknowledgement

Inspiration from https://github.com/manuelstofer/json-pointer

Made without peeking (much) at the source of https://github.com/xavier/json_pointer

Made in Exeter, UK.


## Copyright and License

Copyright (c) 2024 Alexander Veenendaal

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
