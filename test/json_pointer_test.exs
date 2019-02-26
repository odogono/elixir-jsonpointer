defmodule JSONPointerTest do
  use ExUnit.Case
  doctest JSONPointer

  defp rfc_data,
    do: %{
      "foo" => ["bar", "baz"],
      "bar" => %{"baz" => 10},
      "" => 0,
      "a/b" => 1,
      "c%d" => 2,
      "e^f" => 3,
      "g|h" => 4,
      "i\\j" => 5,
      "k\"l" => 6,
      " " => 7,
      "m~n" => 8
    }

  defp nested_data,
    do: %{
      "a" => 1,
      "b" => %{"c" => 2},
      "d" => %{"e" => [%{"a" => 3}, %{"b" => 4}, %{"c" => 5}]},
      "f" => [6, 7],
      "200" => %{"a" => "b"},
      "01" => 8
    }

  defp book_store_data,
    do: %{
      "store" => %{
        "book" => [
          %{
            "category" => "reference",
            "author" => "Nigel Rees",
            "title" => "Sayings of the Century",
            "price" => 8.95
          },
          %{
            "category" => "fiction",
            "author" => "Evelyn Waugh",
            "title" => "Sword of Honour",
            "price" => 12.99
          },
          %{
            "category" => "fiction",
            "author" => "Herman Melville",
            "title" => "Moby Dick",
            "isbn" => "0-553-21311-3",
            "price" => 8.99
          },
          %{
            "category" => "fiction",
            "author" => "J. R. R. Tolkien",
            "title" => "The Lord of the Rings",
            "isbn" => "0-395-19395-8",
            "price" => 22.99
          }
        ],
        "bicycle" => %{
          "color" => "red",
          "price" => 19.95
        }
      }
    }

  describe "get" do
    test "get rfc" do
      assert JSONPointer.get!(rfc_data(), "") == rfc_data()
      assert JSONPointer.get!(rfc_data(), "/foo") == rfc_data()["foo"]
      assert JSONPointer.get!(rfc_data(), "/foo/0") == "bar"
      assert JSONPointer.get!(rfc_data(), "/bar") == rfc_data()["bar"]
      assert JSONPointer.get!(rfc_data(), "/bar/baz") == 10
      assert JSONPointer.get!(rfc_data(), "/") == 0
      assert JSONPointer.get!(rfc_data(), "/a~1b") == 1
      assert JSONPointer.get!(rfc_data(), "/c%d") == 2
      assert JSONPointer.get!(rfc_data(), "/e^f") == 3
      assert JSONPointer.get!(rfc_data(), "/g|h") == 4
      assert JSONPointer.get!(rfc_data(), "/i\\j") == 5
      assert JSONPointer.get!(rfc_data(), "/k\"l") == 6
      assert JSONPointer.get!(rfc_data(), "/ ") == 7
      assert JSONPointer.get!(rfc_data(), "/m~0n") == 8

      # starting with fragments
      assert JSONPointer.get(rfc_data(), "#") == {:ok, rfc_data()}
      assert JSONPointer.get(rfc_data(), "#/foo") == {:ok, ["bar", "baz"]}
      assert JSONPointer.get(rfc_data(), "#/foo/0") == {:ok, "bar"}
      assert JSONPointer.get(rfc_data(), "#/") == {:ok, 0}
      assert JSONPointer.get(rfc_data(), "#/a~1b") == {:ok, 1}

      # this library used to support escaped uri fragments, but this was not spec compliant and so removed
      assert JSONPointer.get(rfc_data(), "#/c%25d") == {:error, "token not found: c%25d"}
    end

    test "get expanded" do
      assert JSONPointer.get(nested_data(), "/a") == {:ok, 1}
      assert JSONPointer.get(nested_data(), "/b/c") == {:ok, 2}

      assert JSONPointer.get(nested_data(), "/d/e/0/a") == {:ok, 3}
      assert JSONPointer.get(nested_data(), "/d/e/1/b") == {:ok, 4}
      assert JSONPointer.get(nested_data(), "/d/e/2/c") == {:ok, 5}
      assert JSONPointer.get(nested_data(), "/f/0") == {:ok, 6}

      assert JSONPointer.get([], "/2") == {:error, "index out of bounds: 2"}
      assert JSONPointer.get([], "/2/3") == {:error, "index out of bounds: 2"}
      assert JSONPointer.get(nested_data(), "/d/e/3") == {:error, "index out of bounds: 3"}

      assert JSONPointer.get(%{}, "") == {:ok, %{}}

      assert JSONPointer.get(nested_data(), "/200") == {:ok, %{"a" => "b"}}

      assert JSONPointer.get(nested_data(), ["d", "e", "1", "b"]) == {:ok, 4}

      # passing a string an the object raises an error
      assert_raise ArgumentError, ~s(invalid object: { "unencoded":"json" }), fn ->
        JSONPointer.get(~s({ "unencoded":"json" }), "/unencoded")
      end
    end

    test "special array rule" do
      assert JSONPointer.get!(nested_data(), "/01") == 8
      assert JSONPointer.get(["zero", "one", "two"], "/01") == {:error, "invalid index: 01"}
    end

    test "get using wildcard" do
      data = book_store_data()
      assert JSONPointer.get(data, "/store/bicycle/color") == {:ok, "red"}
      # "the prices of all books in the store"
      assert JSONPointer.get(data, "/store/book/**/price") == {:ok, [8.95, 12.99, 8.99, 22.99]}
      # "all authors"
      assert JSONPointer.get(data, "/**/author") ==
               {:ok, ["Nigel Rees", "Evelyn Waugh", "Herman Melville", "J. R. R. Tolkien"]}

      # the price of everything in the store.
      assert JSONPointer.get(data, "/store/**/price") == {:ok, [19.95, 8.95, 12.99, 8.99, 22.99]}

      assert JSONPointer.get(data, "/store/bicycle/**") ==
               {:ok, %{"color" => "red", "price" => 19.95}}

      assert JSONPointer.get(data, "/store/**") == {:ok, data["store"]}

      assert JSONPointer.get(data, "/store/**/**") == {:error, "token not found: **"}

      assert JSONPointer.get(data, "/store/book/**") == {:ok, data["store"]["book"]}

      assert JSONPointer.get(data, "/store/book") == {:ok, data["store"]["book"]}

      assert JSONPointer.get(data, "/**/nothing") == {:error, "token not found: nothing"}

      assert_raise ArgumentError, "token not found: newspaper", fn ->
        JSONPointer.get!(data, "/**/newspaper")
      end
    end
  end

  describe "set" do
    test "set" do
      assert JSONPointer.set(%{"a" => 1}, "/a", 2) == {:ok, %{"a" => 2}, 1}
      assert JSONPointer.set(%{"a" => %{"b" => 2}}, "/a/b", 3) == {:ok, %{"a" => %{"b" => 3}}, 2}

      assert JSONPointer.set(%{}, "/a", 1) == {:ok, %{"a" => 1}, nil}
      assert JSONPointer.set(%{"a" => 1}, "/a", 6) == {:ok, %{"a" => 6}, 1}
      assert JSONPointer.set(%{}, "/a/b", 2) == {:ok, %{"a" => %{"b" => 2}}, nil}

      assert JSONPointer.set([], "/0", "first") == {:ok, ["first"], nil}
      assert JSONPointer.set([], "/1", "second") == {:ok, [nil, "second"], nil}
      assert JSONPointer.set([], "/0/test", "prudent") == {:ok, [%{"test" => "prudent"}], nil}
    end

    test "set empty array" do
      assert JSONPointer.set(%{}, "/0/test/0", "expected") ==
               {:ok, %{"0" => %{"test" => ["expected"]}}, nil}

      assert JSONPointer.set([], "/0/test/1", "expected") ==
               {:ok, [%{"test" => [nil, "expected"]}], nil}
    end

    test "set with /-" do
      assert JSONPointer.set([1, 2], "/-", "three") == {:ok, [1, 2, "three"], nil}

      assert JSONPointer.set(%{}, "/f/g/h/foo/-", "four") ==
               {:ok, %{"f" => %{"g" => %{"h" => %{"foo" => ["four"]}}}}, nil}

      assert JSONPointer.set([], "/1/-", "five") == {:ok, [nil, ["five"]], nil}

      assert JSONPointer.set(%{"a" => 1}, "/-", "six") == {:ok, %{"a" => 1, "-" => "six"}, nil}

      assert JSONPointer.set([], "/-", "seven") == {:ok, ["seven"], nil}

      assert JSONPointer.set(%{}, "/-", "eight") == {:ok, %{"-" => "eight"}, nil}

      assert JSONPointer.set(%{"f" => %{}}, "/f/-", "nine") ==
               {:ok, %{"f" => %{"-" => "nine"}}, nil}
    end

    test "set using wildcard" do
      assert JSONPointer.set(book_store_data(), "/store/book/**/author", "unknown") ==
               {:ok,
                %{
                  "store" => %{
                    "bicycle" => %{"color" => "red", "price" => 19.95},
                    "book" => [
                      %{
                        "author" => "unknown",
                        "category" => "reference",
                        "price" => 8.95,
                        "title" => "Sayings of the Century"
                      },
                      %{
                        "author" => "unknown",
                        "category" => "fiction",
                        "price" => 12.99,
                        "title" => "Sword of Honour"
                      },
                      %{
                        "author" => "unknown",
                        "category" => "fiction",
                        "isbn" => "0-553-21311-3",
                        "price" => 8.99,
                        "title" => "Moby Dick"
                      },
                      %{
                        "author" => "unknown",
                        "category" => "fiction",
                        "isbn" => "0-395-19395-8",
                        "price" => 22.99,
                        "title" => "The Lord of the Rings"
                      }
                    ]
                  }
                }, nil}

      # using a wildcard to replace all instances within a list
      assert JSONPointer.set(book_store_data(), "/store/book/**", %{"status" => "recalled"}) ==
               {:ok,
                %{
                  "store" => %{
                    "bicycle" => %{"color" => "red", "price" => 19.95},
                    "book" => [
                      %{"status" => "recalled"},
                      %{"status" => "recalled"},
                      %{"status" => "recalled"},
                      %{"status" => "recalled"}
                    ]
                  }
                }, nil}

      assert JSONPointer.set(book_store_data(), "/store/book/**/price", 5.99) ==
               {:ok,
                %{
                  "store" => %{
                    "bicycle" => %{"color" => "red", "price" => 19.95},
                    "book" => [
                      %{
                        "author" => "Nigel Rees",
                        "category" => "reference",
                        "price" => 5.99,
                        "title" => "Sayings of the Century"
                      },
                      %{
                        "author" => "Evelyn Waugh",
                        "category" => "fiction",
                        "price" => 5.99,
                        "title" => "Sword of Honour"
                      },
                      %{
                        "author" => "Herman Melville",
                        "category" => "fiction",
                        "isbn" => "0-553-21311-3",
                        "price" => 5.99,
                        "title" => "Moby Dick"
                      },
                      %{
                        "author" => "J. R. R. Tolkien",
                        "category" => "fiction",
                        "isbn" => "0-395-19395-8",
                        "price" => 5.99,
                        "title" => "The Lord of the Rings"
                      }
                    ]
                  }
                }, nil}

      assert JSONPointer.set(book_store_data(), "/store/**/price", 34.95) ==
               {:ok,
                %{
                  "store" => %{
                    "bicycle" => %{"color" => "red", "price" => 34.95},
                    "book" => [
                      %{
                        "author" => "Nigel Rees",
                        "category" => "reference",
                        "price" => 34.95,
                        "title" => "Sayings of the Century"
                      },
                      %{
                        "author" => "Evelyn Waugh",
                        "category" => "fiction",
                        "price" => 34.95,
                        "title" => "Sword of Honour"
                      },
                      %{
                        "author" => "Herman Melville",
                        "category" => "fiction",
                        "isbn" => "0-553-21311-3",
                        "price" => 34.95,
                        "title" => "Moby Dick"
                      },
                      %{
                        "author" => "J. R. R. Tolkien",
                        "category" => "fiction",
                        "isbn" => "0-395-19395-8",
                        "price" => 34.95,
                        "title" => "The Lord of the Rings"
                      }
                    ]
                  }
                }, nil}
    end
  end

  describe "add" do
    test "add to list" do
      assert JSONPointer.add(%{"foo" => ["bar", "baz"]}, "/foo/1", "qux") ==
               {:ok, %{"foo" => ["bar", "qux", "baz"]}, "baz"}

      # out of bounds (upper)
      assert JSONPointer.add(%{"bar" => [1, 2]}, "/bar/8", "5") ==
               {:error, "index out of bounds: 8", [1, 2]}

      # out of bounds (lower)
      assert JSONPointer.add(%{"bar" => [1, 2]}, "/bar/-1", "5") ==
               {:error, "index out of bounds: -1", [1, 2]}

      # 0 can be an array index or object element name
      assert JSONPointer.add(%{"foo" => 1}, "/0", "bar") ==
               {:ok, %{"foo" => 1, "0" => "bar"}, nil}

      assert JSONPointer.add(["foo"], "/1", "bar") ==
               {:ok, ["foo", "bar"], nil}

      #  object operation on array target
      assert JSONPointer.add(["foo", "baz"], "/bar", 42) ==
               {:error, "invalid index: bar", ["foo", "baz"]}

      assert JSONPointer.add(["foo", "sil"], "/1", ["bar", "baz"]) ==
               {:ok, ["foo", ["bar", "baz"], "sil"], "sil"}

      # add with bad number
      assert JSONPointer.add(["foo", "sil"], "/1e0", "bar") ==
               {:error, "invalid index: 1e0", ["foo", "sil"]}
    end

    test "add to map" do
      assert JSONPointer.add(%{"foo" => "bar"}, "/baz", "qux") ==
               {:ok, %{"baz" => "qux", "foo" => "bar"}, nil}

      # replaces existing field
      assert JSONPointer.add(%{"foo" => nil}, "/foo", 1) ==
               {:ok, %{"foo" => 1}, nil}

      # top level object
      assert JSONPointer.add(%{}, "/foo", 1) ==
               {:ok, %{"foo" => 1}, nil}

      assert JSONPointer.add(%{}, "/", 1) ==
               {:ok, %{"" => 1}, nil}

      #  add to non-existent target
      assert JSONPointer.add(%{"foo" => "bar"}, "/baz/bat", "qux") ==
               {:error, "key not found on object: baz", %{"foo" => "bar"}}

      # replacing root is possible with add
      assert JSONPointer.add(%{"foo" => "bar"}, "", %{"baz" => "qux"}) ==
               {:ok, %{"baz" => "qux"}, %{"foo" => "bar"}}
    end
  end

  describe "remove" do
    test "remove" do
      assert JSONPointer.remove(%{"example" => "hello"}, "/example") == {:ok, %{}, "hello"}
      assert JSONPointer.remove(%{"a" => %{"b" => 5}}, "/a/b") == {:ok, %{"a" => %{}}, 5}

      assert JSONPointer.remove(%{"a" => %{"b" => %{"c" => "discard"}}}, "/a/b/c") ==
               {:ok, %{"a" => %{"b" => %{}}}, "discard"}

      assert JSONPointer.remove(%{"a" => %{"b" => %{"c" => "discard"}}}, "/a") ==
               {:ok, %{}, %{"b" => %{"c" => "discard"}}}

      assert JSONPointer.remove(["alpha", "beta"], "/0") == {:ok, [nil, "beta"], "alpha"}

      assert JSONPointer.remove(["alpha", %{"beta" => ["c", "d"]}], "/1/beta/0") ==
               {:ok, ["alpha", %{"beta" => [nil, "d"]}], "c"}
    end

    test "remove using wildcard" do
      obj = %{
        "a" => %{"b" => 2},
        "c" => [%{"d" => 3}, %{"e" => 4}],
        "f" => 5,
        "g" => [%{"d" => 6}, %{"e" => 7}]
      }

      assert JSONPointer.remove(obj, "/a/**") ==
               {:ok,
                %{
                  "a" => nil,
                  "c" => [%{"d" => 3}, %{"e" => 4}],
                  "f" => 5,
                  "g" => [%{"d" => 6}, %{"e" => 7}]
                }, %{"b" => 2}}
    end
  end

  describe "de/hydrate" do
    test "dehydrate" do
      tests = [
        {
          %{},
          # empty result
          []
        },
        {
          [],
          # empty result
          []
        },
        {
          %{"a" => 1},
          [{"/a", 1}]
        },
        {
          %{"a" => 1, "b" => true},
          [{"/a", 1}, {"/b", true}]
        },
        {
          %{"a" => 1, "b" => %{"c" => "nice"}},
          [{"/a", 1}, {"/b/c", "nice"}]
        },
        {
          ["alpha", "beta"],
          [{"/0", "alpha"}, {"/1", "beta"}]
        },
        {
          %{"a" => %{"b" => ["c", "d"]}},
          [{"/a/b/0", "c"}, {"/a/b/1", "d"}]
        },
        {
          %{"a" => [10, %{"b" => 12.5}], "c" => 99},
          [{"/a/0", 10}, {"/a/1/b", 12.5}, {"/c", 99}]
        },
        {
          %{"a" => %{}, "b" => [], "c" => nil},
          [{"/a", %{}}, {"/b", []}, {"/c", nil}]
        },
        {
          %{
            "" => 0,
            "a/b" => 1,
            "c%d" => 2,
            "e^f" => 3,
            "g|h" => 4,
            "i\\j" => 5,
            "k\"l" => 6,
            " " => 7,
            "m~n" => 8
          },
          [
            {"/", 0},
            {"/ ", 7},
            {"/a~1b", 1},
            {"/c%d", 2},
            {"/e^f", 3},
            {"/g|h", 4},
            {"/i\\j", 5},
            {"/k\"l", 6},
            {"/m~0n", 8}
          ]
        }
      ]

      Enum.each(tests, fn {obj, expected_paths} ->
        assert JSONPointer.dehydrate(obj) == {:ok, expected_paths}
      end)
    end

    test "hydrate" do
      tests = [
        {
          %{},
          [],
          %{}
        },
        {
          %{},
          [{"/a/b/1", 1}],
          %{"a" => %{"b" => [nil, 1]}}
        },
        {
          [],
          [{"/1/a", true}],
          [nil, %{"a" => true}]
        },
        {
          [],
          [{"/a", 14.5}],
          # because of the attempt to set a key on an array
          {:error, "invalid index: a"}
        },
        {
          %{},
          [{"/4", false}],
          [nil, nil, nil, nil, false]
        }
      ]

      Enum.each(tests, fn {src, paths, expected} ->
        expected =
          case expected do
            {:error, _} -> expected
            _ -> {:ok, expected}
          end

        assert JSONPointer.hydrate(src, paths) == expected
      end)
    end
  end

  describe "merge" do
    test "merge" do
      src = %{
        "bla" => %{"test" => "expected"},
        "foo" => [["hello"]],
        "abc" => "bla"
      }

      assert JSONPointer.merge(["foo", "bar"], %{"a" => false}) ==
               {:error, "invalid index: a"}

      assert JSONPointer.merge(%{"a" => false}, %{"c" => true, "b" => 13}) ==
               {:ok, %{"a" => false, "b" => 13, "c" => true}}

      assert JSONPointer.merge(src, %{"bla" => %{"alpha" => "beta"}}) ==
               {:ok,
                %{
                  "bla" => %{"alpha" => "beta", "test" => "expected"},
                  "foo" => [["hello"]],
                  "abc" => "bla"
                }}

      assert JSONPointer.merge(src, %{"foo" => [10, %{"a" => true, "b" => false}], "abc" => 30}) ==
               {:ok,
                %{
                  "abc" => 30,
                  "bla" => %{"test" => "expected"},
                  "foo" => [10, %{"a" => true, "b" => false}]
                }}

      assert JSONPointer.merge(src, %{"foo" => nil, "bla" => nil}) ==
               {:ok, %{"abc" => "bla", "bla" => nil, "foo" => nil}}
    end
  end

  describe "test" do
    test "test" do
      obj = %{
        "bla" => %{"test" => "expected"},
        "foo" => [["hello"]],
        "abc" => "bla"
      }

      assert JSONPointer.test(obj, "/bla") == true
      assert JSONPointer.test(obj, "/foo/0/0") == true
      assert JSONPointer.test(obj, "/bla/test") == true

      assert JSONPointer.test(obj, "/not-existing") == false
      assert JSONPointer.test(obj, "/not-existing/bla") == false
      assert JSONPointer.test(obj, "/test/1/bla") == false
      assert JSONPointer.test(obj, "/0") == false
      assert JSONPointer.test([], "/2") == false
      assert JSONPointer.test([], "/2/3") == false
    end
  end

  describe "transform" do
    test "transform" do
      input = ~s({
      "dt": 1520942400,
      "temp": {
          "day": 11
      },
      "pressure": 1005.47,
      "humidity": 100,
      "weather": [
          {
              "main": "few clouds"
          }
      ],
      "speed": 3.12,
      "deg": 272,
      "clouds": 12
  }) |> Jason.decode!()

      time = :os.system_time(:seconds)

      result =
        JSONPointer.transform(input, [
          {"/temp/day", "/temp"},
          {"/weather/0/main", "/description"},
          {"/created_at", fn -> time end},
          {"/dt", "/datetime",
           fn val -> val |> DateTime.from_unix!() |> DateTime.to_iso8601() end}
        ])

      assert result ==
               {:ok,
                %{
                  "created_at" => time,
                  "datetime" => "2018-03-13T12:00:00Z",
                  "description" => "few clouds",
                  "temp" => 11
                }}
    end
  end

  describe "utils" do
    test "parse" do
      assert JSONPointer.Utils.parse("") == {:ok, []}
      assert JSONPointer.Utils.parse("invalid") == {:error, "invalid json pointer", "invalid"}
      assert JSONPointer.Utils.parse("/some/where/over") == {:ok, ["some", "where", "over"]}
      assert JSONPointer.Utils.parse("/hello~0bla/test~1bla") == {:ok, ["hello~bla", "test/bla"]}
      assert JSONPointer.Utils.parse("/~2") == {:ok, ["**"]}

      assert JSONPointer.Utils.parse("/initial/**/**") == {:ok, ["initial", "**", "**"]}

      assert JSONPointer.Utils.parse(["some", "where", "over"]) ==
               {:ok, ["some", "where", "over"]}

      assert JSONPointer.Utils.parse("/c%d") == {:ok, ["c%d"]}
    end
  end
end
