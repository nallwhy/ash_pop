defmodule AshPop.Shop do
  use Ash.Domain

  resources do
    resource AshPop.Shop.LineItem
  end
end
