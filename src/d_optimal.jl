function build_linear_formula(factors::Int)
    linear_formula = Expr(:call)
    linear_formula.args = vcat(:+, [Symbol("x", i) for i = 1:factors])
    return Formula(:Y, linear_formula)
end

function get_model_variables(formula::DataFrames.Formula)
    variables = Array{Any, 1}()
    push!(variables, DataFrames.Terms(formula).terms...)
    return variables
end

"""
    scale_orthogonal!(design::Array{Float64, 2}, factors::Array{T, 1}) where T <: Any

Orthogonally scale and center factors of a design using design and factor
limits.

# Examples

```jldoctest
julia> using ExperimentalDesign

julia> factors = [[-5., 0., 5.], [1., 2., 3.], [-2., -1., 0.]]
3-element Array{Array{Float64,1},1}:
 [-5.0, 0.0, 5.0]
 [1.0, 2.0, 3.0]
 [-2.0, -1.0, 0.0]

julia> A = [5. 2. -1.; 5. 3. 0.; -5. 1. -2.]
3×3 Array{Float64,2}:
  5.0  2.0  -1.0
  5.0  3.0   0.0
 -5.0  1.0  -2.0

julia> scale_orthogonal!(A, factors)
3×3 Array{Float64,2}:
  1.0   0.0   0.0
  1.0   1.0   1.0
 -1.0  -1.0  -1.0

julia> A
3×3 Array{Float64,2}:
  1.0   0.0   0.0
  1.0   1.0   1.0
 -1.0  -1.0  -1.0
```

# Formula

For a design ``D_{n,p}`` with ``n`` experiments or rows and ``p`` factors
or columns, scale each factor ``\\mathbf{x}_i`` to ``\\mathbf{x}_{i}^{s}``
according to:

```math
\\mathbf{x}_{i}^{s} = \\dfrac{\\mathbf{x}_i - \\bar{M}}{\\bar{M}_{def}}
```

Where ``\\mathbf{x}_{def}`` is the factor defined in the `factors` parameter and:

```math
\\bar{M} = (max(\\mathbf{x}_i) + min(\\mathbf{x}_i)) / 2
```

```math
\\bar{M}_{def} = (max(\\mathbf{x}_{def}) - min(\\mathbf{x}_{def})) / 2
```
"""
function scale_orthogonal!(design::Array{Float64, 2},
                           factors::Array{T, 1}) where T <: Any
    for i = 1:size(design, 2)
        design_range = (max(design[:, i]...) + min(design[:, i]...)) / 2
        factor_range = (max(factors[i]...) - min(factors[i]...)) / 2
        design[:, i] = (design[:, i] .- design_range) ./ factor_range
    end

    return design
end

"""
    scale_boxdraper_encoding!(design::Array{Float64, 2},
                              factors::Array{T, 1};
                              scale_denominator = false) where T <: Any

Scale factors of a design using the Box and Draper's coding convention from
"Response Surfaces, Mixtures, and Ridge Analyses".

# Examples

Without denominator scaling:

```jldoctest
julia> using ExperimentalDesign

julia> factors = [[-5., 0., 5.], [1., 2., 3.], [-2., -1., 0.], [2., 3., 4.]]
4-element Array{Array{Float64,1},1}:
 [-5.0, 0.0, 5.0]
 [1.0, 2.0, 3.0]
 [-2.0, -1.0, 0.0]
 [2.0, 3.0, 4.0]

julia> A = [5. 2. -1. 2.; 5. 3. 0. 4.; -5. 1. -2. 3.; 0. 2. -1. 3.]
4×4 Array{Float64,2}:
  5.0  2.0  -1.0  2.0
  5.0  3.0   0.0  4.0
 -5.0  1.0  -2.0  3.0
  0.0  2.0  -1.0  3.0

julia> scale_boxdraper_encoding!(A, factors)
4×4 Array{Float64,2}:
  0.57735   0.0        0.0       -0.707107
  0.57735   0.707107   0.707107   0.707107
 -0.57735  -0.707107  -0.707107   0.0
  0.0       0.0        0.0        0.0

julia> A
4×4 Array{Float64,2}:
  0.57735   0.0        0.0       -0.707107
  0.57735   0.707107   0.707107   0.707107
 -0.57735  -0.707107  -0.707107   0.0
  0.0       0.0        0.0        0.0

julia> all([isapprox(1.0, sqrt(sum(A[:, i] .^ 2.0))) for i in 1:4])
true
```

With denominator scaling:

```jldoctest
julia> using ExperimentalDesign

julia> factors = [[-5., 0., 5.], [1., 2., 3.], [-2., -1., 0.], [2., 3., 4.]]
4-element Array{Array{Float64,1},1}:
 [-5.0, 0.0, 5.0]
 [1.0, 2.0, 3.0]
 [-2.0, -1.0, 0.0]
 [2.0, 3.0, 4.0]

julia> A = [5. 2. -1. 2.; 5. 3. 0. 4.; -5. 1. -2. 3.; 0. 2. -1. 3.]
4×4 Array{Float64,2}:
  5.0  2.0  -1.0  2.0
  5.0  3.0   0.0  4.0
 -5.0  1.0  -2.0  3.0
  0.0  2.0  -1.0  3.0

julia> scale_boxdraper_encoding!(A, factors, scale_denominator = true)
4×4 Array{Float64,2}:
  1.1547   0.0       0.0      -1.41421
  1.1547   1.41421   1.41421   1.41421
 -1.1547  -1.41421  -1.41421   0.0
  0.0      0.0       0.0       0.0

julia> A
4×4 Array{Float64,2}:
  1.1547   0.0       0.0      -1.41421
  1.1547   1.41421   1.41421   1.41421
 -1.1547  -1.41421  -1.41421   0.0
  0.0      0.0       0.0       0.0

julia> all([isapprox(1.0, sqrt(sum((A[:, i].^2.0) / 4))) for i in 1:4])
true
```

# Formula

For a design ``D_{n,p}`` with ``n`` experiments or rows and ``p`` factors
or columns, scale each factor ``\\mathbf{x}_i`` to ``\\mathbf{x}_{i}^{s}``
according to:

```math
\\mathbf{x}_{i}^{s} = \\dfrac{\\mathbf{x}_i - \\bar{\\mathbf{x}}_i}{S_i}
```

Where ``\\bar{\\mathbf{x}}_i`` is mean of factor definition values in the
`factors` parameter and:

```math
S_{i}^{2} = \\sum\\limits_{j = 1}^{n}{(x_{ij} - \\bar{\\mathbf{x}}_i)^{2}}
```

If we pass `scale_denominator = true`, ``S_i`` becomes:

```math
S_{i}^{2} = \\dfrac{1}{n} \\sum\\limits_{j = 1}^{n}{(x_{ij} - \\bar{\\mathbf{x}}_i)^{2}}
```
"""
function scale_boxdraper_encoding!(design::Array{Float64, 2},
                                   factors::Array{T, 1};
                                   scale_denominator = false) where T <: Any
    for i = 1:size(design, 2)
        factor_mean = mean(factors[i])
        denominator = sum((design[:, i] .- factor_mean) .^ 2.0)

        if scale_denominator
            denominator /= size(design, 1)
        end

        denominator = sqrt(denominator)

        numerator = design[:, i] .- factor_mean

        if !iszero(denominator) && !iszero(numerator)
            numerator ./= denominator
        end

        design[:, i] = numerator
    end

    return design
end

"""
    generate_model_matrix(formula::DataFrames.Formula,
                          design::Array{Float64, 2},
                          factors::Array{T, 1};
                          scale::Function = scale_orthogonal!) where T <: Any

Generate a `DataFrame` with a scaled model matrix for a given formula, design and factors.

Assumes that `formula` is a linear relationship between all the factors in `factors`.

# Examples

```jldoctest
julia> using ExperimentalDesign, DataFrames

julia> A = [5. 2. -1. 2.; 5. 3. 0. 4.; -5. 1. -2. 3.; 0. 2. -1. 3.]
4×4 Array{Float64,2}:
  5.0  2.0  -1.0  2.0
  5.0  3.0   0.0  4.0
 -5.0  1.0  -2.0  3.0
  0.0  2.0  -1.0  3.0

julia> factors = [[-5., 0., 5.], [1., 2., 3.], [-2., -1., 0.], [2., 3., 4.]]
4-element Array{Array{Float64,1},1}:
 [-5.0, 0.0, 5.0]
 [1.0, 2.0, 3.0]
 [-2.0, -1.0, 0.0]
 [2.0, 3.0, 4.0]

julia> M = generate_model_matrix(@formula(y ~ x1 + x2 + x3 + x4), A, factors)
4×5 DataFrames.DataFrame
│ Row │ I   │ x1   │ x2   │ x3   │ x4   │
├─────┼─────┼──────┼──────┼──────┼──────┤
│ 1   │ 1.0 │ 1.0  │ 0.0  │ 0.0  │ -1.0 │
│ 2   │ 1.0 │ 1.0  │ 1.0  │ 1.0  │ 1.0  │
│ 3   │ 1.0 │ -1.0 │ -1.0 │ -1.0 │ 0.0  │
│ 4   │ 1.0 │ 0.0  │ 0.0  │ 0.0  │ 0.0  │

julia> M = generate_model_matrix(@formula(y ~ x1 + x2 + x3 + x4), A, factors, scale = scale_boxdraper_encoding!)
4×5 DataFrames.DataFrame
│ Row │ I   │ x1       │ x2        │ x3       │ x4        │
├─────┼─────┼──────────┼───────────┼──────────┼───────────┤
│ 1   │ 1.0 │ 0.57735  │ -0.471405 │ 0.408248 │ -0.648886 │
│ 2   │ 1.0 │ 0.57735  │ -0.235702 │ 0.816497 │ -0.324443 │
│ 3   │ 1.0 │ -0.57735 │ -0.707107 │ 0.0      │ -0.486664 │
│ 4   │ 1.0 │ 0.0      │ -0.471405 │ 0.408248 │ -0.486664 │

```
"""
function generate_model_matrix(formula::DataFrames.Formula,
                               design::Array{Float64, 2},
                               factors::Array{T, 1};
                               scale::Function = scale_orthogonal!) where T <: Any
    variables  = get_model_variables(formula)

    # We are assuming a linear formula, a non-linear formula would mess scaling
    design     = DataFrame(scale(design, factors))
    new_design = DataFrame(I = ones(size(design, 1)))

    for variable in variables
        if typeof(variable) == Expr && variable.args[1] == :&
            interaction             = Symbol(variable.args[2:end]...)
            new_design[interaction] = ones(size(design, 1))

            for s in variable.args[2:end]
                new_design[interaction] .*= design[s]
            end
        else
            new_design[variable] = float(design[variable])
        end
    end

    return new_design
end

function get_prediction_variances(model_matrix::Array{Float64, 2})
    information_matrix = model_matrix' * model_matrix

    if det(information_matrix) != 0.0
        dispersion_matrix = inv(information_matrix)
        rows              = size(dispersion_matrix, 1)

        prediction_variances = [dispersion_matrix[i, :]' * dispersion_matrix *
                                dispersion_matrix[i, :] for i = 1:rows]

        return prediction_variances
    else
        return 0.0
    end
end

"""
    d_optimality(model_matrix::Array{Float64, 2})

Compute the ``D``-optimality of a given design's model matrix.

# Examples

```jldoctest
julia> using ExperimentalDesign, DataFrames

julia> A = [5. 2. -1. 2.; 5. 3. 0. 4.; -5. 1. -2. 3.; 0. 2. -1. 3.]
4×4 Array{Float64,2}:
  5.0  2.0  -1.0  2.0
  5.0  3.0   0.0  4.0
 -5.0  1.0  -2.0  3.0
  0.0  2.0  -1.0  3.0

julia> factors = [[-5., 0., 5.], [1., 2., 3.], [-2., -1., 0.], [2., 3., 4.]]
4-element Array{Array{Float64,1},1}:
 [-5.0, 0.0, 5.0]
 [1.0, 2.0, 3.0]
 [-2.0, -1.0, 0.0]
 [2.0, 3.0, 4.0]

julia> M = generate_model_matrix(@formula(y ~ x1 + x2 + x3 + x4), A, factors, scale = scale_boxdraper_encoding!)
4×5 DataFrames.DataFrame
│ Row │ I   │ x1       │ x2        │ x3        │ x4        │
├─────┼─────┼──────────┼───────────┼───────────┼───────────┤
│ 1   │ 1.0 │ 0.57735  │ 0.0       │ 0.0       │ -0.707107 │
│ 2   │ 1.0 │ 0.57735  │ 0.707107  │ 0.707107  │ 0.707107  │
│ 3   │ 1.0 │ -0.57735 │ -0.707107 │ -0.707107 │ 0.0       │
│ 4   │ 1.0 │ 0.0      │ 0.0       │ 0.0       │ 0.0       │

julia> d_optimality(Array(M))
0.0

```

# Formula

The ``D``-optimality of a design is the determinant of the information matrix
``\\mathbf{X}^{\\prime}\\mathbf{X}``, where ``\\mathbf{X}`` is the model matrix of
a design.

"""
function d_optimality(model_matrix::Array{Float64, 2})
    det_information_matrix = det(model_matrix' * model_matrix)

    return det_information_matrix < 0.0 ? 0.0 : det_information_matrix
end

"""
    d_efficiency_lower_bound(model_matrix::Array{Float64, 2})

Compute a lower bound for the ``D``-efficiency of a given design's model matrix
according to Castillo's "Process Optimization : A Statistical Approach".

```jldoctest
julia> using ExperimentalDesign, DataFrames

julia> A = [5. 2. -1. 2.; 5. 3. 0. 4.; -5. 1. -2. 3.; 0. 2. -1. 3.]
4×4 Array{Float64,2}:
  5.0  2.0  -1.0  2.0
  5.0  3.0   0.0  4.0
 -5.0  1.0  -2.0  3.0
  0.0  2.0  -1.0  3.0

julia> factors = [[-5., 0., 5.], [1., 2., 3.], [-2., -1., 0.], [2., 3., 4.]]
4-element Array{Array{Float64,1},1}:
 [-5.0, 0.0, 5.0]
 [1.0, 2.0, 3.0]
 [-2.0, -1.0, 0.0]
 [2.0, 3.0, 4.0]

julia> M = generate_model_matrix(@formula(y ~ x1 + x2 + x3 + x4), A, factors, scale = scale_boxdraper_encoding!)
4×5 DataFrames.DataFrame
│ Row │ I   │ x1       │ x2        │ x3        │ x4        │
├─────┼─────┼──────────┼───────────┼───────────┼───────────┤
│ 1   │ 1.0 │ 0.57735  │ 0.0       │ 0.0       │ -0.707107 │
│ 2   │ 1.0 │ 0.57735  │ 0.707107  │ 0.707107  │ 0.707107  │
│ 3   │ 1.0 │ -0.57735 │ -0.707107 │ -0.707107 │ 0.0       │
│ 4   │ 1.0 │ 0.0      │ 0.0       │ 0.0       │ 0.0       │

julia> d_efficiency_lower_bound(Array(M))
0.0

```

# Formula

For a design ``A_{n,p}`` with ``n`` experiments or rows, ``p`` factors or
columns, and model matrix ``\\mathbf{X}``, the lower bound for the
``D``-efficiency of ``A`` is:

```math
D_{eff}^{(L)} = \\dfrac{|\\mathbf{X}^{\\prime}\\mathbf{X}|^{1/p}}{n}
```
"""
function d_efficiency_lower_bound(model_matrix::Array{Float64, 2})
    return ^(d_optimality(model_matrix), 1 / size(model_matrix, 2)) /
           size(model_matrix, 1)
end

function a_optimality(model_matrix::Array{Float64, 2})
    information_matrix = model_matrix' * model_matrix

    if det(information_matrix) != 0.0
        return trace(inv(information_matrix)) / size(model_matrix, 2)
    else
        return 0.0
    end

end

function v_optimality(model_matrix::Array{Float64, 2})
    prediction_variances = get_prediction_variances(model_matrix)
    rows                 = size(model_matrix, 1)

    return sum(prediction_variances) / rows
end

function g_optimality(model_matrix::Array{Float64, 2})
    prediction_variances = get_prediction_variances(model_matrix)
    return max(prediction_variances...)
end

function g_efficiency(model_matrix::Array{Float64, 2})
    prediction_variances = get_prediction_variances(model_matrix)
    max_variance         = max(prediction_variances...)

    g_e = size(model_matrix, 2) / max_variance

    if g_e == Inf
        return 0.0
    else
        return g_e
    end
end

function d_efficiency_lower_bound_algdesign(model_matrix::Array{Float64, 2})
    g_e   = g_efficiency(model_matrix)
    d_elb = exp(1 - (1 / g_e))

    if d_elb == Inf
        return 0.0
    else
        return d_elb
    end
end

function condition_number(model_matrix::Array{Float64, 2})
    condition_number = cond(model_matrix)

    if condition_number == Inf
        return 0.0
    else
        return condition_number
    end
end

function sample_full_factorial(factors::Array{T, 1}) where T <: Any
    return Array{Float64, 1}([rand(i) for i in factors])
end

function check_repeated_row(subset::SharedArray{Float64, 2}, row::Array{Float64, 1})
    for j = 1:size(subset, 1)
        if subset[j, :] == row
            return true
        end
    end

    return false
end

function full_factorial_subset(factors::Array{T, 1}, experiments::Int) where T <: Any
    subset = fill!(SharedArray{Float64, 2}(experiments, size(factors, 1)), 0.0)

    @sync @parallel for i = 1:experiments
        sample_row = sample_full_factorial(factors)

        while check_repeated_row(subset, sample_row)
            sample_row = sample_full_factorial(factors)
        end

        subset[i, :] = sample_row
    end

    return subset
end

function generate_designs(factors::Array{T, 1},
                          formula::DataFrames.Formula,
                          sample_range::UnitRange{Int},
                          designs::Int;
                          check_bounds::Bool = true,
                          scale::Function = scale_orthogonal!,
                          compute_all_metrics::Bool = false) where T <: Any
    println("> Factors: ", factors)

    full_factorial_size = prod(length, factors)
    full_factorial_subsets = 2.0 ^ full_factorial_size

    println("> Full Factorial Size: ", full_factorial_size)
    println("> Total Subsets: ", full_factorial_subsets)
    println("> Range of Design Sizes: ", sample_range)
    println("> Number of Designs to Sample: ", designs)

    if check_bounds
        if sample_range.start == sample_range.stop
            restricted_subsets = factorial(float(full_factorial_size)) /
                                 (factorial(float(full_factorial_size - sample_range.start)) *
                                 factorial(float(sample_range.start)))
            println("> Total Subsets for Fixed Size ",
                    sample_range.start, ": ",
                    restricted_subsets)

            if designs > restricted_subsets
                println("> Requested too many designs, using ",
                        restricted_subsets, " instead")
                designs = restricted_subsets
            end
        elseif designs > full_factorial_subsets
            println("> Requested too many designs, using ",
                    full_factorial_subsets, " instead")
            designs = full_factorial_subsets
        end

        if sample_range.stop > full_factorial_size
            println("> Requested too many maximum experiments, using ",
                    full_factorial_size, " instead")
            sample_range = sample_range.start:full_factorial_size
        end

    else
        println("> WARNING: Skipping bounds check!")
    end

    if compute_all_metrics
        evaluation = DataFrame(Length  = [],
                               D       = [],
                               DELB    = [],
                               DELB_ad = [],
                               A       = [],
                               V       = [],
                               G       = [],
                               CN      = [],
                               GE      = [],
                               log2CN  = [],
                               log10D  = [])
    else
        evaluation = DataFrame(Length  = [],
                               D       = [],
                               DELB    = [])
    end


    for i in 1:designs
        samples      = rand(sample_range)
        subset       = full_factorial_subset(factors, samples)
        model_matrix = generate_model_matrix(formula, Array{Float64, 2}(subset), factors,
                                             scale = scale)
        candidate    = Array(model_matrix)

        if compute_all_metrics
            d_opt = d_optimality(candidate)
            c_n   = condition_number(candidate)

            push!(evaluation, [size(candidate, 1),
                               d_opt,
                               d_efficiency_lower_bound(candidate),
                               d_efficiency_lower_bound_algdesign(candidate),
                               a_optimality(candidate),
                               v_optimality(candidate),
                               g_optimality(candidate),
                               c_n,
                               g_efficiency(candidate),
                               log(2, abs(c_n)),
                               log(10, abs(d_opt))])
        else
            push!(evaluation, [size(candidate, 1),
                               d_optimality(candidate),
                               d_efficiency_lower_bound(candidate)])
        end
    end

    return evaluation
end

function sample_subset(factors,
                       sample_range,
                       designs;
                       check_bounds = true,
                       scale = scale_orthogonal!)
    formula = build_linear_formula(length(factors))
    #formula = @formula(y ~ x1 + x2 + x3)

    run_time = @elapsed sampling_subset = generate_designs(factors,
                                                           formula,
                                                           sample_range,
                                                           designs,
                                                           check_bounds = check_bounds,
                                                           scale = scale)
    println("> Elapsed Time: ", run_time, " seconds")

    sort!(sampling_subset, cols = :D, rev = true)

    return sampling_subset
end

function sample_subsets(factors::Array,
                        ranges::Array{UnitRange{Int}, 1},
                        designs::Int;
                        check_bounds::Bool = true,
                        scale::Function = scale_orthogonal!,
                        compute_all_metrics::Bool = false)
    sampled_subsets = []

    for subset = 1:length(ranges)
        label = " "

        if ranges[subset].start == ranges[subset].stop
            label = string(ranges[subset].start, " Experiments")
        else
            label = string(ranges[subset].start, " to ",
                          ranges[subset].stop, " Experiments")
        end

        label = string(label, ", ", length(factors[subset]), " Factors")

        sampled_subset = sample_subset(factors[subset],
                                       ranges[subset],
                                       designs,
                                       check_bounds = check_bounds,
                                       scale = scale)

        push!(
              sampled_subsets,
              (sampled_subset,
              max(sampled_subset[:D]...),
              label)
             )
    end

    return sampled_subsets
end

function check_zero(x, tol = 1e-4)
    return isapprox(x, 0.0, atol = tol) ? 0.0 : x
end

function plot_subsets(sampled_subsets; columns = [:D, :DELB, :Length])
    upscale = 2
    small_font = Plots.font("sans-serif", 10.0 * upscale)
    large_font = Plots.font("sans-serif", 14.0 * upscale)
    default(titlefont  = large_font,
            guidefont  = large_font,
            tickfont   = small_font,
            legendfont = small_font)
    default(size = (896 * upscale, 504 * upscale))
    default(dpi = 300)

    plotly()

    subplots = []

    for subset in sampled_subsets
        for column in columns
            subset[1][column] = check_zero.(subset[1][column])
        end

        push!(subplots,
              histogram(Array(subset[1][:D]), labels = "Designs",
                        title = string("D-Optimality for ", subset[3]),
                        color = :lightblue),
              histogram(Array(subset[1][:DELB]), labels = "Designs",
                        title = string("D-Efficiency for ", subset[3]),
                        color = :darkorange))

        for column in columns
            push!(subplots,
                  plot(Array(subset[1][column]),
                       ylims = (0, max(subset[1][column]...)),
                       labels = reshape(columns, (1, length(columns))),
                       title = subset[3],
                       linestyle = :solid,
                       linealpha=1.0,
                       linewidth=1.5 * upscale))
        end
    end

    plot(subplots...,
         layout = (length(sampled_subsets), 2 + length(columns)))
end