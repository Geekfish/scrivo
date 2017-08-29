defmodule Scrivo.TextUtils do
  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")

  def code_of_length(length) do
    Enum.reduce((1..length), [], fn (_i, acc) ->
      [Enum.random(@chars) | acc]
    end) |> Enum.join("")
  end

  def word_count(text) do
      text
        |> String.split
        |> length
  end
end
