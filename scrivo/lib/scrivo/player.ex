defmodule Scrivo.Player do
    @enforce_keys [:ref]
    defstruct [:ref, :name]

    def create(ref) do
        %Scrivo.Player{ref: ref}
    end
end
