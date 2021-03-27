# MathJaxRenderer.jl

Wrapper package for rendering LaTeX mathematics using offline MathJax and
`rsvg-convert` to SVG, PNG, PDF, and postscript.

## Usage

Wrap an `AbstractString` in the provided `Math` object:

```julia
julia> using MathJaxRenderer

julia> m = Math("\\frac{1}{1 + x}");

julia> write("fraction.png", m);

```

See `?Math` for the full range of rendering options available.
