defmodule LiveEnum do
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  @doc """

  # `LiveEnum`

  `LiveEnum` wraps a List/Enumerable in a way that lets us do append/prepend/removes efficiently on the DOM, without storing the whole list in LiveView memory.

  It has the following functions:

  ## Manipulating `LiveEnums`

  `create(enumerable, dom_id_callback)`
  Creates a LiveEnum. `dom_id_callback` is a anonymous function that creates a unique DOM-id for any member of the enum.

  `append(live_enum, item)`
  `item` will be s at the end of the list

  `prepend(live_enum, item)`
  `item` will be rendered at the beginning of the list

  `delete(live_enum, item)`
  `item` will be removed from the rendered list

  `update(live_enum, item)`
  `item` will be re-rendered with new contents. `dom_id_callback` must return the same id for both the new and the old item.

  # Rendering LiveEnums
  `container_for(item <- live_enum, options \\ [], do: block)`
  Render a DIV container to hold the LiveEnum. Execute `block` to render each item.

  Note that since LiveView can't compute diffs inside of anonymous functions this has to be implemented as a macro
  or we need to do something like https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#module-phoenix-liveview-integration

  `dom_id(live_enum, item)`
  Generates a unique DOM id for the item (provided as a callback when the LiveEnum is created)

  # Callbacks
  `after_render(socket, live_enum)`
  This callback *MUST* be called in the `after_render` callback of the LiveView for rendering to work.

  Note that we may be able to call this automatically as part of the implementation of `after_render`, but I wanted to be explicit about it in this sketch.
  """

  defmodule Container do
    defstruct [:live_enum, :tag, :id, :update_mode, :deleted_ids, attrs: []]

    defimpl Phoenix.HTML.Safe do
      @impl Phoenix.HTML.Safe
      def to_iodata(
            %Container{
              tag: tag,
              id: id,
              update_mode: update_mode,
              deleted_ids: deleted_ids,
              attrs: attrs
            } = container
          ) do
        attrs =
          attrs
          |> Keyword.put(:id, id)
          |> Keyword.put(:phx_update, update_mode)

        [
          Phoenix.HTML.Safe.to_iodata(Phoenix.HTML.Tag.tag(tag, attrs)),
          for {item_id, generation} <- deleted_ids do
            Phoenix.HTML.Safe.to_iodata(
              Phoenix.HTML.Tag.content_tag(:div, [],
                id: LiveEnum.item_id(container, item_id, generation),
                phx_remove: true
              )
            )
          end
        ]
      end
    end
  end

  defstruct appends: [], prepends: [], deletes: [], foo: %{}

  def create(pairs) do
    appends = for {id, item} <- pairs, do: {id, 0, item}
    foo = for {id, _} <- pairs, into: %{}, do: {id, 0}

    %LiveEnum{
      appends: appends,
      foo: foo
    }
  end

  def append(live_enum, id, item) do
    case Map.fetch(live_enum.foo, id) do
      {:ok, generation} ->
        %LiveEnum{
          live_enum
          | appends: live_enum.appends ++ [{id, generation + 1, item}],
            foo: %{live_enum.foo | id => generation + 1},
            deletes: live_enum.deletes ++ [{id, generation}]
        }

      :error ->
        %LiveEnum{
          live_enum
          | appends: live_enum.appends ++ [{id, 0, item}], foo: Map.put(live_enum.foo, id, 0)
        }
    end
  end

  def prepend(live_enum, id, item) do
    case Map.fetch(live_enum.foo, id) do
      {:ok, generation} ->
        %LiveEnum{
          live_enum
          | prepends: live_enum.prepends ++ [{id, generation + 1, item}],
            foo: %{live_enum.foo | id => generation + 1},
            deletes: live_enum.deletes ++ [{id, generation}]
        }

      :error ->
        %LiveEnum{
          live_enum
          | prepends: live_enum.prepends ++ [{id, 0, item}, foo: %{live_enum.foo | id => 0}]
        }
    end
  end

  def prepend_list(live_enum, items) do
    %LiveEnum{live_enum | prepends: items ++ live_enum.prepends}
  end

  def delete(live_enum, id) do
    # TODO: Remove vs delete naming?
    case Map.fetch(live_enum.foo, id) do
      {:ok, generation} -> %LiveEnum{live_enum | deletes: [{id, generation} | live_enum.deletes]}
      :error -> live_enum
    end
  end

  def update(live_enum, id, item) do
    # TODO: handle update &  prepend in same operation
    case Map.fetch(live_enum.foo, id) do
      {:ok, generation} ->
        %LiveEnum{
          live_enum
          | appends: live_enum.appends ++ [{id, generation, item}],
            foo: %{live_enum.foo | id => generation}
        }

      # %LiveEnum{live_enum | appends: live_enum.appends ++ [{id, generation + 1, item}, foo: %{foo | id => generation + 1}]}
      :error ->
        live_enum
    end
  end

  def reset(live_enum) do
    %LiveEnum{foo: live_enum.foo}
  end

  def container_tag(live_enum, tag, id, attrs \\ []) when is_list(attrs) do
    update_mode = get_update_mode(live_enum)
    deletes = get_deletes(live_enum)
    %Container{
      live_enum: live_enum,
      tag: tag,
      id: id,
      deleted_ids: deletes,
      update_mode: update_mode,
      attrs: attrs
    }
  end

  def item_id(container, id) do
    # losing foo here???
    generation = container.live_enum.foo[id]
    item_id(container, id, generation)
  end

  def item_id(container, id, generation) do
    "#{container.id}-#{id}-#{generation}"
  end

  defp get_update_mode(%LiveEnum{appends: appends, prepends: []}), do: "append"
  defp get_update_mode(%LiveEnum{appends: [], prepends: prepends}), do: "prepend"

  defp get_deletes(%LiveEnum{deletes: deletes}), do: deletes

  defimpl Enumerable do
    # TODO handle both append and prepend in same operation
    defp get_additions(%LiveEnum{appends: appends, prepends: []}), do: dedup(appends)
    defp get_additions(%LiveEnum{appends: [], prepends: prepends}), do: dedup(prepends)


    #{1, 0, a}, {2, 0, 5}, {2,0,1}, {1,1,b} => {2,0,1}, {1,1,b}
    defp dedup(enum) do
      Enum.reverse(enum)
      |> Enum.uniq_by(fn {id, _, _} -> id end)
      |> Enum.reverse()
    end

    @impl Enumerable
    def count(live_enum) do
      {:error, Enumerable.LiveEnum}
    end

    @impl Enumerable
    def member?(live_enum, element) do
      {:error, Enumerable.LiveEnum}
    end

    @impl Enumerable
    def reduce(live_enum, acc, fun) do
      get_additions(live_enum)
      |> Enumerable.List.reduce(acc, fun)
    end

    @impl Enumerable
    def slice(live_enum) do
      {:error, Enumerable.LiveEnum}
    end
  end
end
