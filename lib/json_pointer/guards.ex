defmodule JSONPointer.Guards do
  @moduledoc false

  defguard is_remove_from_map(operation, map, tokens)
           when operation == :remove and tokens == [] and is_map(map)

  defguard is_remove_from_list(operation, list, tokens)
           when operation == :remove and tokens == [] and is_list(list)

  defguard is_add_list(operation, list, tokens)
           when operation == :add and tokens == [] and is_list(list)

  defguard is_add_set_map(operation, map, tokens)
           when (operation == :add or operation == :set) and tokens == [] and is_map(map)

  defguard is_add_set_empty_map(operation, map, tokens)
           when (operation == :add or operation == :set) and tokens == [] and map == %{}

  defguard is_set_map(operation, map, tokens)
           when operation == :set and tokens == [] and is_map(map)

  defguard is_add_set_list(operation, list, tokens)
           when (operation == :set or operation == :add) and tokens == [] and is_list(list)

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

  defguard is_add_set_remove_map(operation, map)
           when (operation == :add or operation == :set or operation == :remove) and is_map(map)

  defguard is_set_remove_list(operation, list)
           when (operation == :set or operation == :remove) and is_list(list)

  defguard is_set_nil_container(operation, container)
           when operation == :set and container == nil

  defguard is_empty_map(value) when value == %{}

  defguard is_empty_list(value) when value == []
end
