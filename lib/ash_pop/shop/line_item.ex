defmodule AshPop.Shop.LineItem do
  use Ash.Resource,
    domain: AshPop.Shop,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "line_items"
    repo AshPop.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:unit_price, :qty]
      change AshPop.Shop.LineItem.Changes.UpdateCalcedFields
    end

    update :update do
      accept [:unit_price, :qty, :subtotal_amt, :total_amt]
      argument :target, :atom, allow_nil?: true
      require_atomic? false
      change AshPop.Shop.LineItem.Changes.UpdateCalcedFields
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :unit_price, :decimal, allow_nil?: true
    attribute :qty, :decimal, allow_nil?: true
    attribute :subtotal_amt, :decimal, allow_nil?: true
    attribute :tax_amt, :decimal, allow_nil?: true, default: Decimal.new("0")
    attribute :total_amt, :decimal, allow_nil?: true

    timestamps()
  end
end
