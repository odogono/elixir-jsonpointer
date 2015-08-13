defmodule JSONPointer do


  @doc """
  Looks up a JSON pointer in an object
  """
  def get(object, pointer ) do

  end

  @doc """
  Sets a new value on object at the location described by pointer
  """
  def set(object, pointer, value) do

  end


  @doc """
  Removes an attribute of object referenced by pointer
  """
  def remove(object, pointer) do

  end

  @doc """
    Tests if an object has a value for a JSON pointer
  """
  def has( object, pointer ) do

  end

  @doc """
    Escapes a reference token

    ## Examples

      iex> JSONPointer.escape "hello~bla"
      "hello~0bla"
      iex> JSONPointer.escape "hello/bla"
      "hello~1bla"

  """
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
  def unescape( str ) do
    str
    |> String.replace( "~0", "~" )
    |> String.replace( "~1", "/" )
  end

  @doc """
  Converts a JSON pointer into a list of reference tokens
  """
  def parse( str ) do

  end

end
