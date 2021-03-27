using Test, MathJaxRenderer, VisualRegressionTests

# Test cases from Latexify.jl.

keywords = Dict(
    "small" => (
        zoom = 4,
        background_color = :orange,
    ),
    "large" => (
        zoom = 2,
        background_color = :lightblue,
    ),
)

@testset "MathJaxRenderer" begin
    @testset "Integration" begin
        tex = joinpath(@__DIR__, "data", "tex")
        svg = joinpath(@__DIR__, "data", "svg")
        png = joinpath(@__DIR__, "data", "png")
        pdf = joinpath(@__DIR__, "data", "pdf")
        eps = joinpath(@__DIR__, "data", "eps")
        for file in readdir(tex)
            name = first(splitext(file))
            file = joinpath(tex, file)
            math = read(file, Math)
            kws = keywords[name]
            @test write(joinpath(svg, "$name.svg"), math; kws...) > 0
            @test write(joinpath(png, "$name.png"), math; kws...) > 0
            @test write(joinpath(pdf, "$name.pdf"), math; kws...) > 0
            @test write(joinpath(eps, "$name.eps"), math; kws...) > 0
        end
    end
    @testset "Visuals" begin
        testfun = (filename) -> write(filename, Math("\\frac{1}{1 + x}"); zoom = 5)
        @visualtest testfun joinpath(@__DIR__, "data/references/fraction.png") tol = 0.2
        testfun = (filename) -> write(filename, Math("\\begin{align}\n3.29e+07 =& 1.23e+00 =& P_{1} \\\\\n\\frac{x}{y} =& 1.00e+10 =& 1.29e+03\n\\end{align}"); zoom = 5)
        @visualtest testfun joinpath(@__DIR__, "data/references/align.png") tol = 0.2
    end
end
