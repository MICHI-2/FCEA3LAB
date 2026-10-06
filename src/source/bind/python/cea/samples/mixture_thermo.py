import numpy as np
import cea

"""
This example demonstrates how to compute thermodynamic properties of a reactant
mixture at various conditions without having to first compute the chemical equilibrium.
It uses hydrogen and air as reactants and computes properties at different
pressures, temperatures, and oxidizer-to-fuel ratios, using the resulting values from example1.py.
"""

# Species
reac_names = ["Ar", "CO", "CO2", "H", "H2", "H2O", "HO2", "N", "NO", "N2", "O", "O2", "OH"]

# Thermo states
p = cea.units.atm_to_bar(1.0)
t = 3000.0

# Mixture states
moles = np.array([0.0070982, 0.00017073, 7.1077e-05, 0.040752, 0.067277, 0.2073,
                  1.0257e-05, 1.0577e-05, 0.012303, 0.58568, 0.015397, 0.018761, 0.045174])

# Mixtures
reac = cea.Mixture(reac_names)
weights = reac.moles_to_weights(moles)

# Store the output
T_out = t
P_out = cea.units.bar_to_atm(p)
rho = reac.calc_property(cea.DENSITY, weights, t, pressure=p)
volume = reac.calc_property(cea.VOLUME, weights, t, pressure=p)
enthalpy = reac.calc_property(cea.ENTHALPY, weights, t)*cea.units.joule_to_cal(1.0)*1.e-3
energy = reac.calc_property(cea.ENERGY, weights, t)*cea.units.joule_to_cal(1.0)*1.e-3
gibbs = reac.calc_property(cea.GIBBS_ENERGY, weights, t, pressure=p)*cea.units.joule_to_cal(1.0)*1.e-3
entropy = reac.calc_property(cea.ENTROPY, weights, t, pressure=p)*cea.units.joule_to_cal(1.0)*1.e-3
cp_fr = reac.calc_property(cea.FROZEN_CP, weights, t, pressure=p)*cea.units.joule_to_cal(1.0)*1.e-3
cv_fr = reac.calc_property(cea.FROZEN_CV, weights, t, pressure=p)*cea.units.joule_to_cal(1.0)*1.e-3

print("P, atm          ", end="")
print("{0:10.3f}".format(P_out))

print("T, K            ", end="")
print("{0:10.3f}".format(T_out))

print("Density, g/cc   ", end="")
print("{0:10.3e}".format(rho))

print("Volume, cc/g    ", end="")
print("{0:10.3e}".format(volume))

print("H, cal/g        ", end="")
print("{0:10.3f}".format(enthalpy))

print("U, cal/g        ", end="")
print("{0:10.3f}".format(energy))

print("G, cal/g        ", end="")
print("{0:10.1f}".format(gibbs))

print("S, cal/g-K      ", end="")
print("{0:10.3f}".format(entropy))

print("Cp, cal/g-K     ", end="")
print("{0:10.4f}".format(cp_fr))

print("Cv, cal/g-K     ", end="")
print("{0:10.4f}".format(cv_fr))