include("../src/tint.jl")
# include("../src/functor.jl")
using .TINT
# using .FunctorBuilder

TINT.NN = 47
# "triangle" or "object"
TINT.mode = "object"

file = "tint_prj/data/three_metaphor_assoc_data.csv"
out = "tint_prj/out"
F = TINT.main()

println(F)