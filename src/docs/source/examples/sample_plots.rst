Custom Plotting Example
=======================

This example walks through ``source/bind/python/cea/samples/sample_plots.py``, which
sweeps equivalence ratio and initial reactant temperature for an H\ :sub:`2`\/O\ :sub:`2`\ mixture,
solves HP equilibrium at each condition, stores the results, and then produces
summary plots. The emphasis is on setting up the inputs, calling the solver in a
nested loop, and querying values from the solution object.

Imports and constants
---------------------

Start by bringing in NumPy, timing utilities, and the CEA bindings. The script uses
:mod:`cea.units` for unit conversions and normalizes enthalpy inline with :data:`cea.R`.

.. code-block:: python

    import numpy as np
    import matplotlib.pyplot as plt
    from datetime import datetime

    import cea

    start = datetime.now()

Define the sweep and mixtures
-----------------------------

The script defines a fixed pressure, a range of initial temperatures, and a range
of equivalence ratios. It then declares reactant and product mixtures for H\ :sub:`2`\/O\ :sub:`2`\.

.. code-block:: python

    p0 = cea.units.atm_to_bar(1.0)  # Fixed-pressure state (bar)
    n_T0 = 350
    T0 = np.linspace(300.0, 2000.0, n_T0)

    reac = cea.Mixture(["H2", "O2"])
    prod = cea.Mixture(["H", "H2", "H2O", "O", "O2", "OH"])

    n_phi = 310
    phi = np.linspace(0.5, 2.0, n_phi)

Set up the solver and storage arrays
------------------------------------

Create the equilibrium solver and an associated solution object. The results are
stored in pre-allocated arrays so each nested-loop iteration only writes values.

.. code-block:: python

    solver = cea.EqSolver(prod, reactants=reac)
    soln = cea.EqSolution(solver)

    X, Y = np.meshgrid(T0, phi)
    T_vals = np.zeros((n_phi, n_T0))
    H_vals = np.zeros((n_phi, n_T0))
    H2_vals = np.zeros((n_phi, n_T0))
    H2O_vals = np.zeros((n_phi, n_T0))
    O_vals = np.zeros((n_phi, n_T0))
    O2_vals = np.zeros((n_phi, n_T0))
    OH_vals = np.zeros((n_phi, n_T0))
    convg_vals = np.zeros((n_phi, n_T0))

Solve in a nested loop and query values
---------------------------------------

The core of the script is a nested loop: the outer loop sweeps equivalence ratio,
computes a reactant weight vector once per ratio, and the inner loop sweeps the
initial temperature. Inside the inner loop, it computes the fixed enthalpy,
invokes the HP equilibrium solve, and then queries the solution fields.

.. code-block:: python

    for i in range(len(phi)):
        of_ratio = reac.weight_eq_ratio_to_of_ratio(
            np.array([0.0, 1.0]), np.array([1.0, 0.0]), phi[i]
        )
        weights = reac.of_ratio_to_weights(
            np.array([0.0, 1.0]), np.array([1.0, 0.0]), of_ratio
        )
        for j in range(len(T0)):
            h0 = reac.calc_property(cea.ENTHALPY, weights, T0[j]) / cea.R
            solver.solve(soln, cea.HP, p0, h0, weights)

            convg_vals[i, j] = soln.converged
            if soln.converged:
                T_vals[i, j] = soln.T
                H_vals[i, j] = soln.mole_fractions["H"]
                H2_vals[i, j] = soln.mole_fractions["H2"]
                H2O_vals[i, j] = soln.mole_fractions["H2O"]
                O_vals[i, j] = soln.mole_fractions["O"]
                O2_vals[i, j] = soln.mole_fractions["O2"]
                OH_vals[i, j] = soln.mole_fractions["OH"]
            else:
                print("Not converged for phi = ", phi[i], " and T0 = ", T0[j])

This is the pattern to reuse in your own sweeps: set up the arrays, loop over the
state grid, call ``solve``, then read the scalar and dictionary-style fields from
``soln`` and store them for later use.

Plotting summary
----------------

After the arrays are filled, the script uses matplotlib to create contour plots of
reaction temperature and species mole fractions. The plotting code lives at the
end of the script and can be kept as-is or adapted to new data products.
