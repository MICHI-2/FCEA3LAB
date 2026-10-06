Computing Thermodynamic Properties of a Mixture
===============================================

This example walks through ``source/bind/python/cea/samples/mixture_thermo.py``.
It computes thermodynamic properties for a fixed reactant mixture at a specified
pressure and temperature without invoking any equilibrium solver. The focus is
on creating a mixture, converting mole fractions to weights, and querying
properties directly from the mixture object.

Imports
-------

Start by importing NumPy and the CEA Python module.

.. code-block:: python

    import numpy as np
    import cea

Define species and state
------------------------

List the reactant species, set the pressure and temperature, and provide the
mixture composition in moles. This example uses a composition taken from
``example1.py``.

.. code-block:: python

    reac_names = [
        "Ar", "CO", "CO2", "H", "H2", "H2O", "HO2",
        "N", "NO", "N2", "O", "O2", "OH",
    ]

    p = cea.units.atm_to_bar(1.0)
    t = 3000.0

    moles = np.array([
        0.0070982, 0.00017073, 7.1077e-05, 0.040752, 0.067277, 0.2073,
        1.0257e-05, 1.0577e-05, 0.012303, 0.58568, 0.015397, 0.018761, 0.045174,
    ])

Build the mixture
-----------------

Create the mixture object and convert the mole amounts to the weight array
required by the property routines. This step bypasses any equilibrium
calculation and treats the mixture as fixed.

.. code-block:: python

    reac = cea.Mixture(reac_names)
    weights = reac.moles_to_weights(moles)

Query thermodynamic properties
------------------------------

Use ``calc_property`` to extract properties for the mixture at the specified
state. Properties that depend on pressure pass ``pressure=p``; others only need
temperature. The example also converts results into conventional units.

.. code-block:: python

    T_out = t
    P_out = cea.units.bar_to_atm(p)
    rho = reac.calc_property(cea.DENSITY, weights, t, pressure=p)
    volume = reac.calc_property(cea.VOLUME, weights, t, pressure=p)
    enthalpy = reac.calc_property(cea.ENTHALPY, weights, t) * cea.units.joule_to_cal(1.0) * 1.0e-3
    energy = reac.calc_property(cea.ENERGY, weights, t) * cea.units.joule_to_cal(1.0) * 1.0e-3
    gibbs = reac.calc_property(cea.GIBBS_ENERGY, weights, t, pressure=p) * cea.units.joule_to_cal(1.0) * 1.0e-3
    entropy = reac.calc_property(cea.ENTROPY, weights, t, pressure=p) * cea.units.joule_to_cal(1.0) * 1.0e-3
    cp_fr = reac.calc_property(cea.FROZEN_CP, weights, t, pressure=p) * cea.units.joule_to_cal(1.0) * 1.0e-3
    cv_fr = reac.calc_property(cea.FROZEN_CV, weights, t, pressure=p) * cea.units.joule_to_cal(1.0) * 1.0e-3

The key point is that all properties are obtained directly from the mixture
object. No equilibrium solver is called; the mixture is treated as fixed at the
specified composition.

Print the results
-----------------

Finally, format and print each property to the console.

.. code-block:: python

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