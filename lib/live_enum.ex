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

  def append(live_enum, item) do
    %LiveEnum{live_enum | appends: live_enum.appends ++ [item]}
  end

  def prepend(live_enum, item) do
    %LiveEnum{live_enum | prepends: live_enum.prepends ++ [item]}
  end

  def remove(live_enum, item) do
    # TODO: Remove vs delete naming?
    %LiveEnum{live_enum | deletes: [item | live_enum.deletes]}
  end

  def update(live_enum, item) do
    # TODO: handle update & prepend in same operation
    %LiveEnum{live_enum | appends: live_enum.appends ++ [item]}
  end

  # """
  # <%= LiveEnum.cointainer_for message <- @messages, id: "messages", class: "styling classes go here" do %>
  #      <div id="<%= LiveEnum.dom_id(@messages, message) %>"><%= message.text %>
  #     <button phx-click="delete_messsage" phx-value-id="<%= message.id %>">delete</button>
  #    <form phx-change="edit_message"><input type=hidden name="id" value="<%= message.id %>"><input type="text" name="text">
  #   </div>
  # <% end %>

  # """
  # defmacro container_for({:<-, _, [varname, live_enum]}, container_id: container_id, do: block) do # do_container_for(live_enum, container_id, varname, block)
  defmacro container_for({:<-, _, [varname, live_enum]}, [container_id: container_id], do: block) do
    # quote bind_quoted:[operator:operator,lhs:lhs,rhs:rhs]do
    #   Assertion.Test.assert(operator,lhs,rhs)
    # end

    # quote do
    #   Assertion.Test.assert(unquote(operator),unquote(lhs),unquote(rhs))
    # end
    IO.puts("BLOck")
    IO.inspect(Macro.to_string(block))

    quote do
      var!(container_id) = unquote(container_id)
      var!(live_enum) = unquote(live_enum)
      var!(block) = unquote(block)

      unquote do
        var!(block)|> IO.inspect
        foo = EEx.compile_string(
          """
          <div id="<%= var!(container_id) %>" phx-update="<%= LiveEnum.get_update_mode(var!(live_enum)) %>">
            <%= for item <- LiveEnum.get_additions(var!(live_enum)) do %>
              <%= #{block |> Macro.to_string() } %>
            <% end %>
          </div>
          """,
          engine: Phoenix.LiveView.Engine,
          file: __CALLER__.file,
          line: __CALLER__.line + 1,
          indentation: 0
        )

        foo |> Macro.to_string() |> IO.puts()
        foo
      end

    end
  end

  #   quote do
  #     live_enum = unquote(live_enum)
  #     update_mode = LiveEnum.get_update_mode(live_enum)
  #     additions = LiveEnum.get_additions(live_enum)

  #     additions = for unquote(varname) <- additions, do: unquote(block)

  #     deletes =
  #       for deleted <- live_enum.deletes,
  #           do:
  #             Phoenix.HTML.Tag.tag(:div, id: __MODULE__.dom_id(live_enum, deleted), phx_delete: true)

  #     comprehension = %Phoenix.LiveView.Comprehension{}
  #     # additions ++ deletes
  #     Phoenix.HTML.Tag.content_tag(:div, comprehension,
  #       id: unquote(container_id),
  #       phx_update: update_mode
  #     )

  #     # %Phoenix.LiveView.Comprehension{
  #     #  static: ["<div id=", "\">", "</div>\n"],
  #     #  dynamics: for x <- additions do [x, x] end
  #     # }
  #     # container_id = unquote(container_id)

  #     # # EEx.compile_string(expr, options)
  #     # EEx.compile_string("""
  #     # <div id="container_id" phx-update="<%= #{update_mode} %>">
  #     #   <%= for item <- ["a", "b", "c"] do %>
  #     #     <%= item %>
  #     #   <% end %>
  #     # </div>
  #     # """, options = [
  #     #   engine: Phoenix.LiveView.Engine,
  #     #   file: unquote(__CALLER__.file),
  #     #   line: unquote(__CALLER__.line + 1),
  #     #   indentation: 0
  #     # ])

  #     # EEx.eval_string("""
  #     # <div id="container_id" phx-update="#{update_mode}">
  #     #   <%= for item <- ["a", "b", "c"] do %>
  #     #     <%= item %>
  #     #   <% end %>
  #     # </div>
  #     # """, options = [engine: Phoenix.LiveView.Engine])
  #   end

  #   # ~L"""
  #   #   <div id="container_id" phx-update="append">
  #   #     <%= for item <- ["a", "b", "c"] do %>
  #   #       <%= item %>
  #   #     <% end %>
  #   #   </div>
  #   # """
  # end

  # defmacro foo(assigns \\ %{}, do: block) do
  #   # quote do
  #   #   [~s(<div id="container_id" phx-update="hiii">Hi!!!!</div>),
  #   #   unquote(block)]
  #   #   |> Phoenix.HTML.raw
  #   # end
  # end

  def dom_id(live_enum, message) do
    live_enum.dom_id_callback.(message)
  end

  def get_update_mode(%LiveEnum{appends: appends, prepends: []}), do: :append
  def get_update_mode(%LiveEnum{appends: [], prepends: prepends}), do: :prepend

  # TODO handle both append and prepend in same operation
  def get_additions(%LiveEnum{appends: appends, prepends: []}), do: appends
  def get_additions(%LiveEnum{appends: [], prepends: prepends}), do: prepends
end
