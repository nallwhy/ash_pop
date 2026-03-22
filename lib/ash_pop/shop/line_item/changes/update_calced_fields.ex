defmodule AshPop.Shop.LineItem.Changes.UpdateCalcedFields do
  use Ash.Resource.Change

  @moduledoc """
  필드 변경 시 연쇄적으로 계산 필드를 업데이트한다.

  - unit_price 또는 qty 변경 → subtotal_amt = unit_price * qty
  - subtotal_amt 변경 → tax_amt = subtotal_amt * 0.1, total_amt = subtotal_amt + tax_amt
  - total_amt 변경 → subtotal_amt, tax_amt 역산
  """

  @tax_rate Decimal.new("0.1")

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    target = Ash.Changeset.get_argument(changeset, :target) || :unit_price

    update(changeset, target, target)
  end

  # unit_price 또는 qty 변경 → subtotal 계산
  defp update(cs, field, field) when field in [:unit_price, :qty] do
    update(cs, :subtotal_amt, field)
  end

  defp update(cs, :subtotal_amt, changed) when changed in [:unit_price, :qty] do
    unit_price = get_attr(cs, :unit_price)
    qty = get_attr(cs, :qty)
    subtotal_amt = get_attr(cs, :subtotal_amt)

    new_subtotal_amt =
      if unit_price && qty do
        Decimal.mult(unit_price, qty) |> Decimal.round(0)
      else
        subtotal_amt
      end

    if dec_eq?(new_subtotal_amt, subtotal_amt) do
      cs
    else
      cs
      |> Ash.Changeset.change_attribute(:subtotal_amt, new_subtotal_amt)
      |> update(:subtotal_amt, :subtotal_amt)
    end
  end

  # subtotal_amt 변경 → tax, total 계산 + unit_price 역산
  defp update(cs, :subtotal_amt, :subtotal_amt) do
    cs
    |> update(:unit_price, :subtotal_amt)
    |> update(:tax_amt, :subtotal_amt)
    |> update(:total_amt, :subtotal_amt)
  end

  # subtotal_amt 변경 시 unit_price 역산
  defp update(cs, :unit_price, :subtotal_amt) do
    unit_price = get_attr(cs, :unit_price)
    qty = get_attr(cs, :qty)
    subtotal_amt = get_attr(cs, :subtotal_amt)

    new_unit_price =
      if subtotal_amt && qty && not Decimal.eq?(qty, Decimal.new("0")) do
        Decimal.div(subtotal_amt, qty) |> Decimal.round(0)
      else
        unit_price
      end

    if dec_eq?(new_unit_price, unit_price) do
      cs
    else
      Ash.Changeset.change_attribute(cs, :unit_price, new_unit_price)
    end
  end

  # subtotal_amt 변경 시 tax_amt 계산
  defp update(cs, :tax_amt, :subtotal_amt) do
    subtotal_amt = get_attr(cs, :subtotal_amt)
    tax_amt = get_attr(cs, :tax_amt)

    new_tax_amt =
      if subtotal_amt do
        Decimal.mult(subtotal_amt, @tax_rate) |> Decimal.round(0)
      else
        tax_amt
      end

    if dec_eq?(new_tax_amt, tax_amt) do
      cs
    else
      Ash.Changeset.change_attribute(cs, :tax_amt, new_tax_amt)
    end
  end

  # subtotal_amt 또는 tax_amt 변경 시 total_amt 계산
  defp update(cs, :total_amt, changed) when changed in [:subtotal_amt, :tax_amt] do
    subtotal_amt = get_attr(cs, :subtotal_amt)
    tax_amt = get_attr(cs, :tax_amt)
    total_amt = get_attr(cs, :total_amt)

    new_total_amt =
      if subtotal_amt && tax_amt do
        Decimal.add(subtotal_amt, tax_amt) |> Decimal.round(0)
      else
        total_amt
      end

    if dec_eq?(new_total_amt, total_amt) do
      cs
    else
      Ash.Changeset.change_attribute(cs, :total_amt, new_total_amt)
    end
  end

  # total_amt 직접 변경 → subtotal, tax 역산
  defp update(cs, :total_amt, :total_amt) do
    cs
    |> update(:tax_amt, :total_amt)
    |> update(:subtotal_amt, :total_amt)
  end

  defp update(cs, :tax_amt, :total_amt) do
    total_amt = get_attr(cs, :total_amt)
    tax_amt = get_attr(cs, :tax_amt)

    new_tax_amt =
      if total_amt do
        Decimal.mult(total_amt, Decimal.div(@tax_rate, Decimal.add(Decimal.new("1"), @tax_rate)))
        |> Decimal.round(0)
      else
        tax_amt
      end

    if dec_eq?(new_tax_amt, tax_amt) do
      cs
    else
      Ash.Changeset.change_attribute(cs, :tax_amt, new_tax_amt)
    end
  end

  defp update(cs, :subtotal_amt, :total_amt) do
    subtotal_amt = get_attr(cs, :subtotal_amt)
    tax_amt = get_attr(cs, :tax_amt)
    total_amt = get_attr(cs, :total_amt)

    new_subtotal_amt =
      if tax_amt && total_amt do
        Decimal.sub(total_amt, tax_amt) |> Decimal.round(0)
      else
        subtotal_amt
      end

    if dec_eq?(new_subtotal_amt, subtotal_amt) do
      cs
    else
      cs
      |> Ash.Changeset.change_attribute(:subtotal_amt, new_subtotal_amt)
      |> update(:unit_price, :subtotal_amt)
    end
  end

  defp update(cs, _, _), do: cs

  defp get_attr(cs, field), do: Ash.Changeset.get_attribute(cs, field)

  defp dec_eq?(nil, nil), do: true
  defp dec_eq?(nil, _), do: false
  defp dec_eq?(_, nil), do: false
  defp dec_eq?(a, b), do: Decimal.eq?(a, b)
end
