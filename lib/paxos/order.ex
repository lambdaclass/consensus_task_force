defmodule Order do
  def null() do
    {0, 0}
  end

  def one(id) do
    {0, id}
  end

  def gr({n1, i1}, {n2, i2}) do
    {n1, i1} > {n2, i2}
  end

  def goe({n1, i1}, {n2, i2}) do
    {n1, i1} >= {n2, i2}
  end

  def inc({n, id}) do
    {n + 1, id}
  end
end
