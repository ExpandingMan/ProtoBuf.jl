function encode_tag(io::IO, field_number, wire_type::WireType)
    vbyte_encode(io, (UInt32(field_number) << 3) | UInt32(wire_type))
    return nothing
end

function encode(io::IO, i::UInt, x::Vector{T}) where {T}
    _io = IOBuffer(sizehint=sizeof(T))
    Base.ensureroom(io, length(x) * sizeof(T))
    for el in x
        encode(_io, el)
        encode_tag(io, i, LENGTH_DELIMITED)
        vbyte_encode(io, UInt32(position(_io)))
        write(_io, io)
        seekstart(_io)
    end
    close(_io)
    return nothing
end

function encode(io::IO, i::UInt, x::T) where {T}
    _io = PipeBuffer(Vector{UInt8}(undef, sizeof(T)))
    encode(_io, x)
    encode_tag(io, i, LENGTH_DELIMITED)
    vbyte_encode(io, UInt32(position(_io)))
    write(_io, io)
    close(_io)
    return nothing
end

function encode(io::IO, x::T) where {T<:Union{UInt32,UInt64}}
    vbyte_encode(io, x)
    return nothing
end

@inline function encode(io::IO, x::Int64)
    vbyte_encode(io, reinterpret(UInt64, x))
    return nothing
end

function encode(io::IO, x::Int32)
    x < 0 ? vbyte_encode(io, reinterpret(UInt64, Int64(x))) : vbyte_encode(io, reinterpret(UInt32, x))
    return nothing
end

function encode(io::IO, x::T, ::Type{Val{:fixed}}) where {T<:Union{Int32,Int64,Vector{Int32},Vector{Int64}}}
    write(io, x)
    return nothing
end

function encode(io::IO, x::T, ::Type{Val{:zigzag}}) where {T<:Union{Int32,Int64}}
    vbyte_encode(io, reinterpret(unsigned(T), zigzag_encode(x)))
    return nothing
end

function encode(io::IO, x::Vector{T}, ::Type{Val{:zigzag}}) where {T<:Union{Int32,Int64}}
    Base.ensureroom(io, length(x))
    for el in x
        encode(io, el, Val{:zigzag})
    end
    return nothing
end

function encode(io::IO, x::T) where {T<:Union{Bool,Float32,Float64,String}}
    write(io, x)
    return nothing
end

function encode(io::IO, x::Vector{T}) where {T<:Union{Bool,UInt8,Float32,Float64}}
    write(io, x)
    return nothing
end

function encode(io::IO, x::Vector{T}) where {T<:Union{UInt32,UInt64,Int32,Int64,Base.Enum}}
    Base.ensureroom(io, length(x))
    for el in x
        encode(io, el)
    end
    return nothing
end

function encode(io::IO, x::Dict{K,V}) where {K,V}
    Base.ensureroom(io, 2length(x))
    for (k, v) in x
        encode(io, k)
        encode(io, v)
    end
    nothing
end

function encode(io::IO, x::Dict{K,V}, ::Type{Val{Tuple{Nothing,Nothing}}}) where {K,V}
    Base.ensureroom(io, 2length(x))
    for (k, v) in x
        encode(io, k)
        encode(io, v)
    end
    nothing
end

function encode(io::IO, x::Dict{K,V}, ::Type{Val{Tuple{Nothing,W}}}) where {K,V,W}
    Base.ensureroom(io, 2length(x))
    for (k, v) in x
        encode(io, k)
        encode(io, v, Val{W})
    end
    nothing
end

function encode(io::IO, x::Dict{K,V}, ::Type{Val{Tuple{Q,Nothing}}}) where {K,V,Q}
    Base.ensureroom(io, 2length(x))
    for (k, v) in x
        encode(io, k, Val{Q})
        encode(io, v)
    end
    nothing
end

function encode(io::IO, x::Dict{K,V}, ::Type{Val{Tuple{Q,W}}}) where {K,V,Q,W}
    Base.ensureroom(io, 2length(x))
    for (k, v) in x
        encode(io, k, Val{Q})
        encode(io, v, Val{W})
    end
    nothing
end



function encode(io::IO, i::UInt, x::T) where {T<:Union{Bool,Int32,Int64,UInt32,UInt64}}
    encode_tag(io, i, VARINT)
    encode(io, x)
    return nothing
end

function encode(io::IO, i::UInt, x::T, ::Type{Val{:zigzag}}) where {T<:Union{Int32,Int64}}
    encode_tag(io, i, VARINT)
    encode(io, x, Val{:zigzag})
    return nothing
end

function encode(io::IO, i::UInt, x::Int32, ::Type{Val{:fixed}})
    encode_tag(io, i, FIXED32)
    encode(io, x, Val{:fixed})
    return nothing
end

function encode(io::IO, i::UInt, x::Float32)
    encode_tag(io, i, FIXED32)
    encode(io, x)
    return nothing
end

function encode(io::IO, i::UInt, x::Int64, ::Type{Val{:fixed}})
    encode_tag(io, i, FIXED64)
    encode(io, x, Val{:fixed})
    return nothing
end

function encode(io::IO, i::UInt, x::Float64)
    encode_tag(io, i, FIXED64)
    encode(io, x)
    return nothing
end

function encode(io::IO, i::UInt, x::Vector{T}) where {T<:Union{Bool,UInt8,Float32,Float64}}
    encode_tag(io, i, LENGTH_DELIMITED)
    vbyte_encode(io, UInt32(sizeof(x)))
    encode(io, x)
    return nothing
end

function encode(io::IO, i::UInt, x::Vector{String})
    Base.ensureroom(io, sizeof(x) + length(x))
    for el in x
        encode_tag(io, i, LENGTH_DELIMITED)
        vbyte_encode(io, UInt32(sizeof(el)))
        encode(io, el)
    end
    return nothing
end

function encode(io::IO, i::UInt, x::Vector{Vector{UInt8}})
    Base.ensureroom(io, sizeof(x) + length(x))
    for el in x
        encode_tag(io, i, LENGTH_DELIMITED)
        vbyte_encode(io, UInt32(sizeof(el)))
        encode(io, el)
    end
    return nothing
end

function encode(io::IO, i::UInt, x::String)
    encode_tag(io, i, LENGTH_DELIMITED)
    vbyte_encode(io, UInt32(sizeof(x)))
    encode(io, x)
    return nothing
end

function encode(io::IO, i::UInt, x::Vector{T}, ::Type{Val{:fixed}}) where {T<:Union{Int32,Int64}}
    encode_tag(io, i, LENGTH_DELIMITED)
    vbyte_encode(io, UInt32(sizeof(x)))
    encode(io, x, Val{:fixed})
    return nothing
end

function encode(io::IO, i::UInt, x::Vector{T}) where {T<:Union{UInt32,UInt64,Int32,Int64}}
    _io = PipeBuffer(Vector{UInt8}(undef, length(x)), maxsize=10length(x))
    encode(_io, x)
    encode_tag(io, i, LENGTH_DELIMITED)
    vbyte_encode(io, UInt32(position(_io)))
    write(_io, io)
    close(_io)
    return nothing
end

function encode(io::IO, i::UInt, x::Dict{K,V}) where {K,V}
    encode_tag(io, i, LENGTH_DELIMITED)
    encode(io, x)
    nothing
end

function encode(io::IO, i::UInt, x::Dict{K,V}, ::Type{W}) where {K,V,W}
    encode_tag(io, i, LENGTH_DELIMITED)
    encode(io, x, W)
    nothing
end


function encode(io::IO, i::UInt, x::Vector{T}, ::Type{Val{:zigzag}}) where {T<:Union{Int32,Int64}}
    encode_tag(io, i, LENGTH_DELIMITED)
    _io = IOBuffer(sizehint=cld(sizeof(x), _max_varint_size(T)))
    encode(_io, x)
    vbyte_encode(io, UInt32(position(_io)))
    write(_io, io)
    close(_io)
    return nothing
end
