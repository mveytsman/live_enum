defmodule LiveEnum do
  use Phoenix.HTML
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

  `remove(live_enum, item)`
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

  defstruct [:appends, :prepends, :deletes, :dom_id_callback]

  def create(enum, dom_id_callback) do
    %LiveEnum{
      appends: enum,
      prepends: [],
      deletes: [],
      dom_id_callback: dom_id_callback
    }
  end


 """
  <%= LiveEnum.cointainer_for message <- @messages, id: "messages", class: "styling classes go here" do %>
         <div id="<%= LiveEnum.dom_id(@messages, message) %>"><%= message.text %>
         <button phx-click="delete_messsage" phx-value-id="<%= message.id %>">delete</button>
         <form phx-change="edit_message"><input type=hidden name="id" value="<%= message.id %>"><input type="text" name="text">
         </div>
       <% end %>
       """
  defmacro container_for({:<-, _, [varname, live_enum]}, id: container_id, do: block), do: do_container_for(live_enum, container_id, varname, block)

  defp do_container_for(live_enum, container_id, varname, block) do
    quote do

      {items, update_mode} = case unquote(live_enum) do
        %LiveEnum{appends: appends, prepends: []}  -> {appends, "append"}
        %LiveEnum{appends: [], prepends: prepends} -> {prepends, "prepend"}
      end

      additions = for unquote(varname) <- items, do: unquote(block)
      deletes = for deleted <- unquote(live_enum).deletes, do: Phoenix.HTML.Tag.tag(:div, [id: __MODULE__.dom_id(unquote(live_enum), deleted), phx_delete: true])

      Phoenix.HTML.html_escape(
        [Phoenix.HTML.Tag.content_tag(:div, additions ++ deletes, [id: unquote(container_id), phx_update: update_mode])]
      )
    end
  end

  def dom_id(live_enum, message) do
    live_enum.dom_id_callback.(message)
  end

end
