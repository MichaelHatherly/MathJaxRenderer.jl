module MathJaxRenderer

using Artifacts, Librsvg_jll, NodeJS, JSON

export Math

"""
    Math(src::AbstractString)

Wrap a string `src` containing LaTeX math syntax for conversion to one of the
following formats: `svg`, `png`, `pdf`, or `eps`. The MathJax NodeJS library
is used to typeset `src`.

When writing to either a file (via `write(filename, math)`) or an `IO` object
(via `show(io, mime, math)`) the following keyword options are available for
either `show` or `write`:

  - The following apply to the conversion from `tex` to `svg`:

      - `inline = false`, whether to typeset as inline or display math.
      - `em = 16`, a number giving the number of pixels in an `em` for the surrounding font.
      - `ex = 8`, a number giving the number of pixels in an `ex` for the surrounding font.
      - `width = 80em`, a number giving the width of the container, in pixels.

  - and the following apply to conversion from `tex` to `svg`, `png`, `pdf`, and `eps`:

      - `dpi_x = 90`, pixels per inch (horizontal).
      - `dpi_y = 90`, pixels per inch (vertical).
      - `x_zoom = 1.0`, zoom factor (horizontal).
      - `y_zoom = 1.0`, zoom factor (vertical).
      - `zoom = 1.0`, zoom factor (both horizontal and vertical).
      - `keep_aspect_ratio = false`, whether to preserve the aspect ratio.
      - `background_color = :white`, set the background color, CSS color names and syntax.
      - `unlimited = false`, allow for huge SVG files.

When writing to file with `write` the follow extensions are supported:

```julia-repl
julia> m = Math("\\sqrt{x^2 + y^2}");

julia> write("math.svg", m); # MIME("image/svg+xml")

julia> write("math.png", m); # MIME("image/png")

julia> write("math.pdf", m); # MIME("application/pdf")

julia> write("math.eps", m); # MIME("application/postscript")

```

and when using `show` use the noted `MIME` types for each extension.
"""
struct Math
    src::String
end

Base.read(fn::String, ::Type{Math}) = Math(read(fn, String))
Base.write(fn::String, d::Math; kws...) = open(io -> show(io, mimetype(fn)(), d; kws...), fn, "w")

Base.show(io::IO, d::Math) = print(io, "$Math(...)")

### Keep next section in sync.

const SVG = MIME"image/svg+xml"
const PNG = MIME"image/png"
const PDF = MIME"application/pdf"
const EPS = MIME"application/postscript"

const SUPPORTED_MIMES = Union{SVG,PNG,PDF,EPS}

extension(::SVG) = "svg"
extension(::PNG) = "png"
extension(::PDF) = "pdf"
extension(::EPS) = "eps"
extension(other) = error("unknown extension '$other'.")

function mimetype(filename::AbstractString)
    _, ext = splitext(filename)
    return mimetype(Val{Symbol(ext[2:end])}())
end
mimetype(::Val{:svg}) = SVG
mimetype(::Val{:png}) = PNG
mimetype(::Val{:pdf}) = PDF
mimetype(::Val{:eps}) = EPS
mimetype(::Val{s}) where s = error("unknown format '$s'.")

###

Base.show(io::IO, mime::SUPPORTED_MIMES, d::Math; kws...) = write(io, converter(d, mime; kws...))

mathjax() = `$(nodejs_cmd()) $(joinpath(artifact"mathjax", "index.js"))`

function exec(cmd::Cmd, input::IOBuffer)
    output, errors = IOBuffer(), IOBuffer()
    yes = success(pipeline(cmd; stdout = output, stdin = input, stderr = errors))
    return (yes = yes, io = yes ? output : errors)
end
exec(cmd::Cmd, input="") = exec(cmd, IOBuffer(input))

function extract_svg(s::String)
    fn(str, a::UnitRange, b::UnitRange) = String(str[a[begin]:b[end]])
    fn(str, ::Any, ::Any) = str
    return fn(s, findfirst("<svg", s), findlast("</svg>", s))
end
extract_svg(vec::Vector{UInt8}) = extract_svg(String(vec))

function svg_converter(
    f::Math;
    inline = false,
    em = 16,
    ex = 8,
    width = 80em,
    kws...,
)
    conf = Dict(
        :src => f.src,
        :config => Dict(
            :display => !inline,
            :em => em,
            :ex => ex,
            :containerWidth => width,
        ),
    )
    str = take!(check(exec(mathjax(), JSON.json(conf))).io)
    return IOBuffer(extract_svg(str))
end

function converter(
    f::Math,
    m::SUPPORTED_MIMES;
    dpi_x = 90,
    dpi_y = 90,
    x_zoom = 1.0,
    y_zoom = 1.0,
    zoom = 1.0,
    keep_aspect_ratio = false,
    background_color = :white,
    unlimited = false,
    kws...,
)
    Librsvg_jll.rsvg_convert() do bin
        ext = extension(m)
        cmd = [
            bin,
            "--format=$(extension(m))",
            "--dpi-x=$dpi_x",
            "--dpi-y=$dpi_y",
            "--x-zoom=$x_zoom",
            "--y-zoom=$y_zoom",
            "--zoom=$zoom",
            "--background-color=$background_color",
        ]
        keep_aspect_ratio && push!(cmd, "--keep-aspect-ratio")
        unlimited && push!(cmd, "--unlimited")
        take!(check(exec(Cmd(cmd), svg_converter(f; kws...))).io)
    end
end
check(result) = result.yes ? result : error(String(take!(result.io)))

end # module
