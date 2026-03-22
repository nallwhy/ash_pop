defmodule AshPopWeb.LineItemLive do
  use AshPopWeb, :live_view

  alias AshPop.Shop.LineItem

  @impl true
  def mount(_params, _session, socket) do
    form =
      LineItem
      |> AshPhoenix.Form.for_create(:create, forms: [auto?: true])
      |> to_form()

    {:ok, assign(socket, form: form, line_item: nil)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form =
      socket.assigns.form.source
      |> AshPhoenix.Form.validate(params)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, line_item} ->
        form =
          line_item
          |> AshPhoenix.Form.for_update(:update, forms: [auto?: true])
          |> to_form()

        {:noreply,
         socket
         |> assign(form: form, line_item: line_item)
         |> put_flash(:info, "Saved successfully.")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-lg mx-auto">
        <h1 class="text-2xl font-bold mb-6">Line Item Calculator</h1>

        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:unit_price]}
              type="number"
              label="Unit Price"
            />
            <.input
              field={@form[:qty]}
              type="number"
              label="Quantity"
            />
          </div>

          <div class="grid grid-cols-3 gap-4">
            <.input
              field={@form[:subtotal_amt]}
              type="number"
              label="Subtotal"
            />
            <.input
              field={@form[:tax_amt]}
              type="number"
              label="Tax (10%)"
              readonly
            />
            <.input
              field={@form[:total_amt]}
              type="number"
              label="Total"
            />
          </div>

          <div class="flex justify-end">
            <button type="submit" class="btn btn-primary">Save</button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
