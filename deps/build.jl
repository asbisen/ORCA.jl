using Conda

env = @__DIR__
Conda.add_channel("plotly", env)
Conda.add("plotly-orca", env)
Conda.update(env)

function _gen_orca_graph_docstring(orca_cmd)
    graph_help = readchomp(`$orca_cmd graph --help`)
    options_start = match(r"^Options.+($)"m, graph_help).offsets[1]
    arg_start = r"\s*--([\w-]+)"m
    args = Set{Symbol}()
    for m in eachmatch(arg_start, graph_help[options_start:end])
        !occursin('-', m[1]) && push!(args, Symbol(strip(m[1])))
    end

    flag_start = r"\s-(\w+)"m
    flags = Set{Symbol}()
    for m in eachmatch(arg_start, graph_help[options_start:end])
        !occursin('-', m[1]) && push!(flags, Symbol(strip(m[1])))
    end

    # remove help
    pop!(flags, :h, nothing)
    pop!(args, :help, nothing)

    after_output = match(r"\s*--output (?>.|\n)+?( *--\w)"m, graph_help).offsets[1]
    savefig_doc_extra = let
        lines = split(graph_help[after_output:end], '\n')
        new_lines = map(lines) do line
            line = line[3:end]
            if line[1:2] == "--"
                line = string("- ", line[3:end])
            end
            line = replace(line, "--" => "")
        end
        join(new_lines, '\n')
    end
    args, flags, savefig_doc_extra
end


open("paths.jl", "w") do f
    orca_cmd = joinpath(@__DIR__, "bin", "orca")
    _ARGS, _FLAGS, _SAVEFIG_DOC_EXTRA = _gen_orca_graph_docstring(orca_cmd)
    println(f, "# This file is automatically generated by build.jl DO NOT EDIT")
    println(f, "const orca_cmd = \"$(orca_cmd)\"")
    println(f, "\n")
    println(f, "const _ARGS = $(_ARGS)")
    println(f, "const _FLAGS = $(_FLAGS)")
    println(f, "const _SAVEFIG_DOC_EXTRA = \"\"\"\\n$_SAVEFIG_DOC_EXTRA\"\"\"")
end
