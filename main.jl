
abstract type AbstractPanel{T, N} <: AbstractArray{T, N} end
struct PanelMatrix{T} <: AbstractPanel{T, 2}
    data::Matrix{T}
    rowidx::Vector{UnitRange{Int64}}
end

struct PanelVector{T} <: AbstractPanel{T, 1}
    data::Vector{T}
    rowidx::Vector{UnitRange{Int64}}
end


"""
    Panelized(a::AbstractPanel{T, N}) where T, N

Create a closure of the observed period t of each observation i.

"""
struct Panelized{T} <: AbstractArray{eltype(T), 1}
    data::T
end


"""
    Panel(a::AbstractVector, rowidx::Vector{UnitRange{Int}})
    Panel(a::AbstractMatrix, rowidx::Vector{UnitRange{Int}})
    Panel(a::AbstractVector; tum::Vector{Int})
    Panel(a::AbstractMatrix; tum::Vector{Int})
    Panel(a::Panelized)
    
Create a `Matrix` or  `Vector` object for the usage in panel model.
There are two acceptable from of `rowidx`:
1. given the `rowidx::Vector{UnitRange{Int64}}`
2. given the each time period of i(keyword argument: `tnum`)

# Examples
```juliadoctest
julia> ivar = [1, 1, 1, 2, 2];

julia> y = [2, 2, 4, 3, 3]; 

julia> X = [3 5; 4 7; 5 9; 8 2; 3 2]
5×2 Matrix{Int64}:
 3  5
 4  7
 5  9
 8  2
 3  2

julia> tnum = [length(findall(x->x==i, ivar)) for i in unique(ivar)]
2-element Vector{Int64}:
 3
 2

julia> data = Panel(X, tnum=tnum)
5×2 Main.SFrontiers.PanelMatrix{Int64}:
 3  5
 4  7
 5  9
 8  2
 3  2

julia> mean_data = mean.(Panelized(data), dims=1)
2-element Vector{Matrix{Float64}}:
 [4.0 7.0]
 [5.5 2.0]

julia> noft = numberoft(data); 

julia> _data = [repeat(i,t) for (i,t) in zip(mean_data, noft)]
2-element Vector{Matrix{Float64}}:
 [4.0 7.0; 4.0 7.0; 4.0 7.0]
 [5.5 2.0; 5.5 2.0]

julia> Panel(reduce(vcat, _data), data.rowidx)
5×2 Main.SFrontiers.PanelMatrix{Float64}:
 4.0  7.0
 4.0  7.0
 4.0  7.0
 5.5  2.0
 5.5  2.0
```

"""
Panel(a::AbstractVector, rowidx) = PanelVector(a, rowidx)
Panel(a::AbstractMatrix, rowidx) = PanelMatrix(a, rowidx)
Panel(a::AbstractVector; tnum)   = PanelVector(a, tnumTorowidx(tnum))
Panel(a::AbstractMatrix; tnum)   = PanelMatrix(a, tnumTorowidx(tnum))
Panel(a::Panelized)              = a.data


# Serve the AbstractArray interface for `Panel` and `Panelized`
Base.size(A::AbstractPanel) = size(A.data)
Base.size(A::Panelized) = (length(A.data.rowidx),)

function Base.getindex(A::AbstractPanel, inds::Vararg{Int, N}) where N
    return A.data[inds...]
end

function Base.getindex(A::Panelized, inds::Vararg{Int, N}) where N
    panel_data = A.data
    rowidx = A.data.rowidx
    return panel_data[rowidx[inds...]]
end


# Serve the Broadcasting interface for `Panel`


# arithmetic rules
Base.:*(a::Number, b::AbstractPanel)        = Panel(a*b.data, b.rowidx)
Base.:*(a::PanelMatrix, b::AbstractVector)  = PanelVector(a.data*b, a.rowidx)
Base.:+(a::AbstractPanel, b::AbstractPanel) = Panel(a.data+b.data, a.rowidx)
Base.:-(a::AbstractPanel, b::AbstractPanel) = Panel(a.data-b.data, a.rowidx)
Broadcast.broadcast(f, a::AbstractPanel)    = Panel(broadcast(f, a.data), a.rowidx)
Broadcast.broadcast(f, a::AbstractPanel, b) = Panel(broadcast(f, a.data, b), a.rowidx)
Broadcast.broadcast(f, a, b::AbstractPanel) = Panel(broadcast(f, a, b.data), b.rowidx)


# some utility function for `Panel` and `Panelized`
numberofi(a::AbstractPanel) = length(a.rowidx)
numberofi(a::Panelized)     = numberofi(a.data)

numberoft(a::AbstractPanel) = length.(a.rowidx)
numberoft(a::Panelized)     = numberoft(a.data)

