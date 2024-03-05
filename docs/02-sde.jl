#===

# Stochastic Differential Equations (SDEs)

- [Wikipedia: Stochastic Differential Equations](https://en.wikipedia.org/wiki/Stochastic_differential_equation)
- [SDE example](https://diffeq.sciml.ai/stable/tutorials/sde_example/) in `DifferentialEquations.jl`
- [RODE example](https://diffeq.sciml.ai/stable/tutorials/rode_example/) in `DifferentialEquations.jl`

## Stochastic Differential Equations (SDEs)

- Recommended SDE solvers: https://docs.sciml.ai/DiffEqDocs/stable/solvers/sde_solve/

### Scalar SDEs with one state variable

Solving the equation: $du=f(u,p,t)dt + g(u,p,t)dW$

- $f(u,p,t)$ is the ordinary differential equations (ODEs) part
- $g(u,p,t)$ is the stochastic part, paired with a Brownian motion term $dW$.

===#

using DifferentialEquations
using Plots
using DisplayAs: PNG

# Main ODE function
f = (u, p, t) -> p.α * u

# Noise term
g = (u, p, t) -> p.β * u

# Setup the SDE problem
p = (α=1, β=1)
u₀ = 1/2
dt = 1//2^(4)
tspan = (0.0,1.0)
prob = SDEProblem(f, g, u₀, (0.0, 1.0), p)

# Use the classic Euler-Maruyama algorithm
sol = solve(prob, EM(), dt=dt)
plot(sol) |> PNG

# The analytical solution: If $f(u,p,t) = \alpha u$ and $g(u,p,t) = \beta u$, the analytical solution is $u(t, W_t) = u_0 exp((\alpha - \frac{\beta^2}{2})t + \beta W_t)$
f_analytic = (u₀, p, t, W) -> u₀ * exp((p.α - (p.β^2) / 2) * t + p.β * W)

# Combine model and analytic functions into one object
ff = SDEFunction(f, g, analytic=f_analytic)
prob = SDEProblem(ff, g, u₀, (0.0, 1.0), p)

# Visualize numerical and analytical solutions
sol = solve(prob, EM(), dt=dt)
plot(sol, plot_analytic=true) |> PNG

# Using a higher-order solver get a more accurate result
sol = solve(prob, SRIW1(), dt=dt, adaptive=false)
plot(sol, plot_analytic=true) |> PNG

# The solver is adaptive and can find dt itself
sol = solve(prob, SRIW1())
plot(sol, plot_analytic=true) |> PNG

# ### SDEs with diagonal Noise
# Each state variable are influenced by its own noise. Here we use the Lorenz system with noise as an example.

using DifferentialEquations
using Plots

function lorenz!(du, u, p, t)
    du[1] = 10.0(u[2]-u[1])
    du[2] = u[1]*(28.0-u[3]) - u[2]
    du[3] = u[1]*u[2] - (8/3)*u[3]
end

function σ_lorenz!(du, u, p, t)
    du[1] = 3.0
    du[2] = 3.0
    du[3] = 3.0
end

prob_sde_lorenz = SDEProblem(lorenz!, σ_lorenz!, [1.0, 0.0, 0.0], (0.0, 20.0))
sol = solve(prob_sde_lorenz)

plot(sol, idxs=(1,2,3)) |> PNG

# ### SDEs with scalar Noise
# The same noise process (`W`) is applied to all state variables.

using DifferentialEquations
using Plots

# Exponential growth with noise
f = (du, u, p, t) -> (du .= u)
g = (du, u, p, t) -> (du .= u)

# Problem setup
u0 = rand(4, 2)
W = WienerProcess(0.0, 0.0, 0.0)
prob = SDEProblem(f, g, u0, (0.0,1.0), noise=W)

# Solve and visualize
sol = solve(prob, SRIW1())
plot(sol) |> PNG

#===

### SDEs with Non-Diagonal (matrix) Noise

A more general type of noise allows for the terms to linearly mixed via noise function `g` being a matrix.

$$
\begin{aligned}
du_1 &= f_1(u,p,t)dt + g_{11}(u,p,t)dW_1 + g_{12}(u,p,t)dW_2 + g_{13}(u,p,t)dW_3 + g_{14}(u,p,t)dW_4  \\
du_2 &= f_2(u,p,t)dt + g_{21}(u,p,t)dW_1 + g_{22}(u,p,t)dW_2 + g_{23}(u,p,t)dW_3 + g_{24}(u,p,t)dW_4
\end{aligned}
$$

===#

using DifferentialEquations
using Plots

f = (du, u, p, t) -> du .= 1.01u

g = (du, u, p, t) -> begin
  du[1,1] = 0.3u[1]
  du[1,2] = 0.6u[1]
  du[1,3] = 0.9u[1]
  du[1,4] = 0.12u[1]
  du[2,1] = 1.2u[2]
  du[2,2] = 0.2u[2]
  du[2,3] = 0.3u[2]
  du[2,4] = 1.8u[2]
end

u0 = ones(2)
tspan = (0.0, 1.0)

# The noise matrix itself is determined by the keyword argument noise_rate_prototype
prob = SDEProblem(f, g, u0, tspan, noise_rate_prototype=zeros(2, 4))
sol = solve(prob)
plot(sol) |> PNG

#===
### Random ODEs

https://docs.sciml.ai/DiffEqDocs/stable/tutorials/rode_example/

Random ODEs (RODEs) is a more general form that allows nonlinear mixings of randomness.

$du = f(u, p, t, W) dt$ where $W(t)$ is a Wiener process (Gaussian process).

`RODEProblem(f, u0, tspan [, params])` constructs an RODE problem.

The model function signature is
- `f(u, p, t, W)` (out-of-place form).
- `f(du, u, p, t, W)` (in-place form).

===#

# Scalar RODEs

using DifferentialEquations
using Plots

function f3(u, p, t, W)
    2u * sin(W)
end

u0 = 1.00
tspan = (0.0, 5.0)
prob = RODEProblem(f3, u0, tspan)
sol = solve(prob, RandomEM(), dt = 1 / 100)
plot(sol) |> PNG

# Systems of RODEs

using DifferentialEquations
using Plots

function f4(du, u, p, t, W)
    du[1] = 2u[1] * sin(W[1] - W[2])
    du[2] = -2u[2] * cos(W[1] + W[2])
end

u0 = [1.00; 1.00]
tspan = (0.0, 5.0)

prob = RODEProblem(f4, u0, tspan)
sol = solve(prob, RandomEM(), dt = 1 / 100)
plot(sol) |> PNG

# ## SDEs with ModelingToolkit.jl
# Define a stochastic Lorentz system using `SDESystem(equations, noises, iv, dv, ps)`.

using ModelingToolkit
using DifferentialEquations
using Plots

@parameters σ ρ β
@variables t x(t) y(t) z(t)

D = Differential(t)

eqs = [
    D(x) ~ σ * (y - x),
    D(y) ~ x * (ρ - z) - y,
    D(z) ~ x * y - β * z
]

# Add a diagonal noise with 10% of the magnitude.

noises = [0.1x, 0.1y, 0.1z]
@named sys = SDESystem(eqs, noises, t, [x, y, z], [σ,ρ,β])

u0 = [x => 10.0, y => 10.0, z=> 10.0]
p = [σ => 10.0, ρ => 28.0, β => 8/3]
tspan = (0.0, 200.0)
prob = SDEProblem(sys, u0, tspan, p)
sol = solve(prob)
plot(sol, idxs=(1, 2, 3)) |> PNG

# One can also use a Brownian variable for the noise term

using ModelingToolkit
using DifferentialEquations
using Plots

@parameters σ ρ β
@variables t x(t) y(t) z(t)
@brownian a
D = Differential(t)

eqs = [
    D(x) ~ σ * (y - x) + 0.1a * x,
    D(y) ~ x * (ρ - z) - y + 0.1a * y,
    D(z) ~ x * y - β * z + 0.1a * z
]

@mtkbuild de = System(eqs, t)

u0map = [
    x => 1.0,
    y => 0.0,
    z => 0.0
]

parammap = [
    σ => 10.0,
    β => 26.0,
    ρ => 2.33
]

prob = SDEProblem(de, u0map, (0.0, 100.0), parammap)
sol = solve(prob, LambaEulerHeun())
plot(sol, idxs=(1, 2, 3)) |> PNG
