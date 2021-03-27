using Pkg.Artifacts
using JSON
using NodeJS
using URIs

function build()
    package_dict = JSON.parsefile(joinpath(@__DIR__, "package.json"))
    pkgname = package_dict["name"]
    version = VersionNumber(package_dict["version"])
    host = "https://github.com/MichaelHatherly/MathJaxRenderer.jl/releases/download"

    build_path = joinpath(@__DIR__, "build")

    if ispath(build_path)
        rm(build_path, force=true, recursive=true)
    end

    mkpath(build_path)

    artifact_toml = joinpath(build_path, "..", "Artifacts.toml")

    npm = NodeJS.npm_cmd()

    product_hash = create_artifact() do artifact_dir
        cp(joinpath(@__DIR__, "index.js"), joinpath(artifact_dir, "index.js"))
        cp(joinpath(@__DIR__, "package.json"), joinpath(artifact_dir, "package.json"))
        cp(joinpath(@__DIR__, "package-lock.json"), joinpath(artifact_dir, "package-lock.json"))

        run(Cmd(`$npm install`, dir = artifact_dir))
    end

    archive_filename = "$pkgname-$version.tar.gz"

    download_hash = archive_artifact(product_hash, joinpath(build_path, archive_filename))

    bind_artifact!(
        artifact_toml,
        "mathjax",
        product_hash,
        force = true,
        download_info = Tuple[
            (
                "$host/$(escapeuri(string(version)))/$archive_filename",
                download_hash,
            ),
        ],
    )
end

build()
