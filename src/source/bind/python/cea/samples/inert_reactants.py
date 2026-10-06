import numpy as np
import cea

# Thermo states
p0 = cea.units.atm_to_bar(1.0)  # Fixed-pressure state (bar)
T0 = 2000.0   # Initial reactant temperature (K)

# Mixtures
reac = cea.Mixture(["H2", "O2", "InertH2"])
prod = cea.Mixture(["H", "H2", "H2O", "O", "O2", "OH", "InertH2"])

# Solver
solver = cea.EqSolver(prod, reactants=reac)
solution = cea.EqSolution(solver)

# Get the weights for one mole of each species
weights = reac.moles_to_weights(np.array([0.45, 0.5, 0.05]))

# Get the fixed-enthalpy
h0 = reac.calc_property(cea.ENTHALPY, weights, T0)/cea.R

# Equilibrium solve
solver.solve(solution, cea.HP, p0, h0, weights)

print("T = ", solution.T, " K")
print("nj = ", solution.nj)
print("ln_nj = ", solution.ln_nj)
print("n = ", solution.n)
print("converged?", solution.converged)
print()
print("mole fractions:")
for name in solution.mole_fractions:
    print(name, 100*solution.mole_fractions[name],"%")
print()
print("mass fractions:")
for name in solution.mass_fractions:
    print(name, 100*solution.mass_fractions[name],"%")
