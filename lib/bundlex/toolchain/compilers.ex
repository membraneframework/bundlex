defmodule Bundlex.Toolchain.Compilers do
    defstruct [:c, :cpp]

    def resolve_lang(lang) do
        cond do
            lang in ["cpp", "c++", "C++", "CPP", "cplusplus", "CPLUSPLUS"] ->
                :cpp
            lang in ["c", "C"] ->
                :c
            true ->
                :c
        end
    end

    def resolve_compiler(lang, compilers) do
        with :cpp <- resolve_lang(lang) do
            compilers.cpp
        else
            compilers.c
        end
    end
end