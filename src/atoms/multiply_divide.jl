export *

function *(x::Constant, y::Constant)
  if x.size == (1, 1)
    return Constant(x.value[1] * y.value)
  elseif y.size == (1, 1)
    return Constant(x.value * y.value[1])
  else
    return Constant(x.value * y.value)
  end
end

function *(x::Constant, y::AffineExpr)
  children = AffineOrConstant[]
  push!(children, x)
  push!(children, y)
  if x.size[2] == y.size[1]
    x_kron = Constant(kron(speye(y.size[2]), x.value))
    vars_to_coeffs_map = Dict{Uint64, Constant}()
    for (v, c) in y.vars_to_coeffs_map
      vars_to_coeffs_map[v] = x_kron * c
    end
    constant = x_kron * y.constant
    this = AffineExpr(:*, children, vars_to_coeffs_map, constant, (x.size[1], y.size[2]))
  elseif x.size == (1, 1)
    vars_to_coeffs_map = Dict{Uint64, Constant}()
    for (v, c) in y.vars_to_coeffs_map
      vars_to_coeffs_map[v] = x * c
    end
    constant = x * y.constant
    this = AffineExpr(:*, children, vars_to_coeffs_map, constant, y.size)
  elseif y.size == (1, 1)
    vec_sz = x.size[1] * x.size[2]
    vars_to_coeffs_map = Dict{Uint64, Constant}()
    for (v, c) in y.vars_to_coeffs_map
      coeff_rep = repmat([c.value], vec_sz, 1)
      for i in 1:vec_sz
        coeff_rep[i,:] = x.value[i] * coeff_rep[i,:]
      end
      vars_to_coeffs_map[v] = Constant(coeff_rep)
    end
    constant_rep = repmat([y.constant.value], vec_sz, 1)
    for i in 1:vec_sz
      constant_rep[i,:] = x.value[i] * constant_rep[i,:]
    end
    constant = Constant(constant_rep)
    this = AffineExpr(:*, children, vars_to_coeffs_map, constant, x.size)
  else
    error("Cannot multiply two expressions of sizes $(x.size) and $(y.size)")
  end
  # TODO: eval
  return this
end

function *(x::AffineExpr, y::Constant)
  if x.size[2] == y.size[1]
    y_kron = Constant(kron(y.value', speye(x.size[1])))
    vars_to_coeffs_map = Dict{Uint64, Constant}()
    for (v, c) in x.vars_to_coeffs_map
      vars_to_coeffs_map[v] = y_kron * c
    end
    constant = y_kron * x.constant
    children = AffineOrConstant[]
    push!(children, x)
    push!(children, y)
    this = AffineExpr(:*, children, vars_to_coeffs_map, constant, (x.size[1], y.size[2]))
    # TODO: eval
    return this
  elseif y.size == (1, 1) || x.size == (1, 1)
    return y*x
  else
    error("Cannot multiply two expressions of sizes $(x.size) and $(y.size)")
  end
end

*(x::Value, y::AffineExpr) = *(Constant(x), y)
*(x::AffineExpr, y::Value) = *(x, Constant(y))


function *(x::Constant, y::SumSquaresExpr)
  if x.size != (1, 1) || x.value[1] < 0
    error("Sum Squares expressions can only be multiplied by nonegative scalars")
  end
  affines = AffineExpr[]
  for affine in y.affines
    push!(affines, x * affine)
  end
  this = SumSquaresExpr(:*, affines)
  return this
end

*(x::SumSquaresExpr, y::Constant) = *(y, x)
*(x::SumSquaresExpr, y::Value) = *(x, Constant(y))
*(x::Value, y::SumSquaresExpr) = *(Constant(x), y)
