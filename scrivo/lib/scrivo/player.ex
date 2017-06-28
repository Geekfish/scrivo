defmodule Scrivo.Player do
    @derive [Poison.Encoder]
    @enforce_keys [:ref]
    defstruct [:ref, :name]

    def create(ref) do
        %Scrivo.Player{ref: ref}
    end
end
