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
    %LiveEnum{live_enum | prepends: [item | live_enum.prepends]}
  end

  def delete(live_enum, id) do
    # TODO: Remove vs delete naming?
    %LiveEnum{live_enum | deletes: [id | live_enum.deletes]}
  end

  def update(live_enum, item) do
    # TODO: handle update &  prepend in same operation
    %LiveEnum{live_enum | appends: [item | live_enum.appends]}
  end

  def reset(live_enum) do
    %LiveEnum{live_enum | appends: [], prepends: [], deletes: []}
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

  # TODO FOR NEXT TIME
  # Try to return a comprehension directly, we can look at the error messages that the code below gives for a hint.
  # also see https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_live_view/helpers.ex#L210

  # * (exit) an exception was raised:
  #   ** (ArgumentError) lists in Phoenix.HTML and templates may only contain integers representing bytes, binaries or other lists, got invalid entry: {:do, "(\n  require(Phoenix.LiveView.Engine)\n  (\n    dynamic = fn track_changes? ->\n      changed = case(var!(assigns)) do\n        %{__changed__: changed} when track_changes? ->\n          changed\n        _ ->\n          nil\n      end\n      (\n        arg0 = Phoenix.LiveView.Engine.live_to_iodata(var!(container_id))\n        arg1 = Phoenix.LiveView.Engine.live_to_iodata(LiveEnum.get_update_mode(var!(live_enum)))\n        arg2 = %Phoenix.LiveView.Comprehension{static: [\"\\n    \", \"\\n  \"], dynamics: for(item <- LiveEnum.get_additions(var!(live_enum))) do\n          arg2 = Phoenix.LiveView.Engine.live_to_iodata((\n            arg0 = Phoenix.LiveView.Engine.to_safe(\"1\")\n            {:safe, [\"\\n  <div id=\\\"1\\\">block\", arg0, \"</div>\\n\"]}\n          ))\n          [arg2]\n        end, fingerprint: 63291875570330320727908519787609065383}\n      )\n      [arg0, arg1, arg2]\n    end\n    %Phoenix.LiveView.Rendered{static: [\"<div id=\\\"\", \"\\\" phx-update=\\\"\", \"\\\">\\n  \", \"\\n</div>\\n\"], dynamic: dynamic, fingerprint: 115688999562251107880277147161388062309}\n  )\n)"}
  #       (phoenix_html 2.14.3) lib/phoenix_html/safe.ex:81: Phoenix.HTML.Safe.List.to_iodata/1
  #       (phoenix_html 2.14.3) lib/phoenix_html/safe.ex:49: Phoenix.HTML.Safe.List.to_iodata/1
  #       (demo_app 0.1.0) lib/demo_app_web/live/live_enum_live.ex:17: anonymous fn/2 in DemoAppWeb.LiveEnumLive.render/1
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/diff.ex:353: Phoenix.LiveView.Diff.traverse/6
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/diff.ex:427: anonymous fn/4 in Phoenix.LiveView.Diff.traverse_dynamic/6
  #       (elixir 1.11.2) lib/enum.ex:2181: Enum."-reduce/3-lists^foldl/2-0-"/3
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/diff.ex:353: Phoenix.LiveView.Diff.traverse/6
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/diff.ex:127: Phoenix.LiveView.Diff.render/3
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/static.ex:288: Phoenix.LiveView.Static.to_rendered_content_tag/4
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/static.ex:148: Phoenix.LiveView.Static.render/3
  #       (phoenix_live_view 0.15.0) lib/phoenix_live_view/controller.ex:35: Phoenix.LiveView.Controller.live_render/3
  #       (phoenix 1.5.7) lib/phoenix/router.ex:352: Phoenix.Router.__call__/2
  #       (demo_app 0.1.0) lib/demo_app_web/endpoint.ex:1: DemoAppWeb.Endpoint.plug_builder_call/2
  #       (demo_app 0.1.0) lib/plug/debugger.ex:132: DemoAppWeb.Endpoint."call (overridable 3)"/2
  #       (demo_app 0.1.0) lib/demo_app_web/endpoint.ex:1: DemoAppWeb.Endpoint.call/2
  #       (phoenix 1.5.7) lib/phoenix/endpoint/cowboy2_handler.ex:65: Phoenix.Endpoint.Cowboy2Handler.init/4
  #       (cowboy 2.8.0) /home/maxim/projects/real_world_liveview/demo_app/deps/cowboy/src/cowboy_handler.erl:37: :cowboy_handler.execute/2
  #       (cowboy 2.8.0) /home/maxim/projects/real_world_liveview/demo_app/deps/cowboy/src/cowboy_stream_h.erl:300: :cowboy_stream_h.execute/3
  #       (cowboy 2.8.0) /home/maxim/projects/real_world_liveview/demo_app/deps/cowboy/src/cowboy_stream_h.erl:291: :cowboy_stream_h.request_process/3
  #       (stdlib 3.12) proc_lib.erl:249: :proc_lib.init_p_do_apply/3


#   ==> demo_app
# Compiling 1 file (.ex)
# BLOck
# "(\n  arg0 = Phoenix.LiveView.Engine.to_safe(\"1\")\n  {:safe, [\"\\n  <div id=\\\"1\\\">block\", arg0, \"</div>\\n\"]}\n)"
# {:__block__, [line: 16, live_rendered: true],
#  [
#    {:=, [line: 16],
#     [
#       {:arg0, [line: 16], Phoenix.LiveView.Engine},
#       {{:., [line: 16], [Phoenix.LiveView.Engine, :to_safe]}, [line: 16], ["1"]}
#     ]},
#    {:safe,
#     [
#       "\n  <div id=\"1\">block",
#       {:arg0, [line: 16], Phoenix.LiveView.Engine},
#       "</div>\n"
#     ]}
#  ]}
# (
#   require(Phoenix.LiveView.Engine)
#   (
#     dynamic = fn track_changes? ->
#       changed = case(var!(assigns)) do
#         %{__changed__: changed} when track_changes? ->
#           changed
#         _ ->
#           nil
#       end
#       (
#         arg0 = Phoenix.LiveView.Engine.live_to_iodata(var!(container_id))
#         arg1 = Phoenix.LiveView.Engine.live_to_iodata(LiveEnum.get_update_mode(var!(live_enum)))
#         arg2 = %Phoenix.LiveView.Comprehension{static: ["\n    ", "\n  "], dynamics: for(item <- LiveEnum.get_additions(var!(live_enum))) do
#           arg2 = Phoenix.LiveView.Engine.live_to_iodata((
#             arg0 = Phoenix.LiveView.Engine.to_safe("1")
#             {:safe, ["\n  <div id=\"1\">block", arg0, "</div>\n"]}
#           ))
#           [arg2]
#         end, fingerprint: 63291875570330320727908519787609065383}
#       )
#       [arg0, arg1, arg2]
#     end
#     %Phoenix.LiveView.Rendered{static: ["<div id=\"", "\" phx-update=\"", "\">\n  ", "\n</div>\n"], dynamic: dynamic, fingerprint: 115688999562251107880277147161388062309}
#   )
# )

def fingerprint(block, static) do
  <<fingerprint::8*16>> =
    [block | static]
    |> :erlang.term_to_binary()
    |> :erlang.md5()

  fingerprint
end

  defmacro container_for({:<-, _, [varname, live_enum]}, [container_id: container_id], do: block) do
    # quote bind_quoted:[operator:operator,lhs:lhs,rhs:rhs]do
    #   Assertion.Test.assert(operator,lhs,rhs)
    # end

    # quote do
    #   Assertion.Test.assert(unquote(operator),unquote(lhs),unquote(rhs))
    # end
    IO.puts("BLOck")
    IO.inspect(Macro.to_string(block))

    fingerprint1 = fingerprint(block, ["",""])
    fingerprint2 = fingerprint(fingerprint1, [~s(<div id="), ~s(" phx-update="), ~s(">), "</div>"])
    quote do
      var!(container_id) = unquote(container_id)
      var!(live_enum) = unquote(live_enum)
      #var!(block) = unquote(block)
      var!(additions) = for(unquote(varname) <- LiveEnum.get_additions(var!(live_enum))) do
        [Phoenix.LiveView.Engine.safe_to_iodata(unquote(block))]
      end
      var!(deletes) = for id <- LiveEnum.get_deletes(var!(live_enum)) do ["<div id=\"#{container_id}-#{id}\" phx-remove>Carl</div>"] end
      comprehension = %Phoenix.LiveView.Comprehension{
        static: ["",""],
        dynamics: var!(additions) ++ var!(deletes),
        fingerprint: unquote(fingerprint1)}

      %Phoenix.LiveView.Rendered{
        static: [~s(<div id="), ~s(" phx-update="), ~s(">), "</div>"],
        dynamic: fn _ -> [var!(container_id), LiveEnum.get_update_mode(var!(live_enum)), comprehension] end,
        fingerprint: unquote(fingerprint2)
      }
      #[~s(<div id="), var!(container_id), ~s(phx-update="), LiveEnum.get_update_mode(var!(live_enum)), ~s(">), comprehension, "</div>"]

          #           arg2 = Phoenix.LiveView.Engine.live_to_iodata((
        #             arg0 = Phoenix.LiveView.Engine.to_safe("1")
        #             {:safe, ["\n  <div id=\"1\">block", arg0, "</div>\n"]}
        #           ))
      # unquote do
      #   var!(block)|> IO.inspect
      #   foo = EEx.compile_string(
      #     """
      #     <div id="<%= var!(container_id) %>" phx-update="<%= LiveEnum.get_update_mode(var!(live_enum)) %>">
      #       <%= for item <- LiveEnum.get_additions(var!(live_enum)) do %>
      #         blokc
      #       <% end %>
      #     </div>
      #     """,
      #     engine: Phoenix.LiveView.Engine,
      #     file: __CALLER__.file,
      #     line: __CALLER__.line + 1,
      #     indentation: 0
      #   )

      #   foo |> Macro.to_string() |> IO.puts()
      #   foo
      # end

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

  def get_update_mode(%LiveEnum{appends: appends, prepends: []}), do: "append"
  def get_update_mode(%LiveEnum{appends: [], prepends: prepends}), do: "prepend"

  # TODO handle both append and prepend in same operation
  def get_additions(%LiveEnum{appends: appends, prepends: []}), do: appends
  def get_additions(%LiveEnum{appends: [], prepends: prepends}), do: prepends

  def get_deletes(%LiveEnum{deletes: deletes}), do: deletes

end
