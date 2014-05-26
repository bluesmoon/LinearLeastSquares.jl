export Value, AbstractExpr, Constant, AffineExpr, Variable, SumSquaresExpr

abstract AbstractExpr
signs = [:pos, :neg, :any]
Value = Union(Number,AbstractArray)
ValueOrNothing = Union(Value, Nothing)

type Constant <: AbstractExpr
  head::Symbol
  value::ValueOrNothing
  sign::Symbol
  size::(Int64, Int64)
  uid::Uint64
  evaluate::Function

  function Constant(value::Value, sign::Symbol)
    if !(sign in signs)
      error("sign must be one of :pos, :neg, :any; got $sign")
    else
      this = new(:Constant, value, sign, (size(value, 1), size(value, 2)))
      this.uid = object_id(this)
      this.evaluate = ()->this.value
      return this
    end
  end
end

function Constant(x::Value)
  if all(x .>= 0)
    return Constant(x, :pos)
  elseif all(x .<= 0)
    return Constant(x, :neg)
  end
  return Constant(x, :any)
end

type AffineExpr <: AbstractExpr
  head::Symbol
  value::ValueOrNothing
  varsToCoeffsMap::Dict{Uint64, Constant}
  constant::Constant
  sign::Symbol
  size::(Int64, Int64)
  uid::Uint64
  evaluate::Function

  function AffineExpr(head::Symbol, varsToCoeffsMap::Dict{Uint64, Constant}, constant::Constant, sign::Symbol, size::(Int64, Int64))
    if !(sign in signs)
      error("sign must be one of :pos, :neg, :any; got $sign")
    else
      this = new(head, nothing, varsToCoeffsMap, constant, sign, size)
      this.uid = object_id(this)
      return this
    end
  end
end

function Variable(size::(Int64, Int64)) 
  this = AffineExpr(:variable, Dict{Uint64, Constant}(), Constant(spzeros(size...)), :any, size)
  vec_sz = size[1]*size[2]
  this.varsToCoeffsMap[this.uid] = Constant(speye(vec_sz))
  this.evaluate = ()->this.value == nothing ? error("value of the variable is yet to be calculated") : this.value
  return this
end

Variable(size...) = Variable(size)
Variable() = Variable((1, 1))
Variable(size::Integer) = Variable((size, 1))

type SumSquaresExpr <: AbstractExpr
  head::Symbol
  value::ValueOrNothing
  arg::AffineExpr
  sign::Symbol
  size::(Int64, Int64)
  uid::Uint64
  evaluate::Function

  function SumSquaresExpr(head::Symbol, arg::AffineExpr)
    this = new(head, nothing, arg, :pos, (1, 1))
    this.uid = object_id(this)
    return this
  end
end
