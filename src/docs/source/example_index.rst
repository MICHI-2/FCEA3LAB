
Examples
********

Here we provide 13 example problems using the Python interface. These examples are taken from RP-1311 Part 2, and include various equilibrium, rocket, shock, and detonation problems.
The examples are organized into subdirectories based on the type of problem they demonstrate. The table below indicates the problem type demonstrated by each example.

+-------------+-------------+---------+-------+--------+
|             | Equilibrium | Rocket  | Shock | Deton  |
+=============+=============+=========+=======+========+
| Example1    |   x (TP)    |         |       |        |
+-------------+-------------+---------+-------+--------+
| Example2    |   x (TV)    |         |       |        |
+-------------+-------------+---------+-------+--------+
| Example3    |   x (HP)    |         |       |        |
+-------------+-------------+---------+-------+--------+
| Example4    |   x (UV)    |         |       |        |
+-------------+-------------+---------+-------+--------+
| Example5    |   x (HP)    |         |       |        |
+-------------+-------------+---------+-------+--------+
| Example6    |             |         |       |   x    |
+-------------+-------------+---------+-------+--------+
| Example7    |             |         |   x   |        |
+-------------+-------------+---------+-------+--------+
| Example8    |             | x (IAC) |       |        |
+-------------+-------------+---------+-------+--------+
| Example9    |             | x (FAC) |       |        |
+-------------+-------------+---------+-------+--------+
| Example10   |             | x (FAC) |       |        |
+-------------+-------------+---------+-------+--------+
| Example11   |             | x (IAC) |       |        |
+-------------+-------------+---------+-------+--------+
| Example12   |             | x (IAC) |       |        |
+-------------+-------------+---------+-------+--------+
| Example13   |             | x (IAC) |       |        |
+-------------+-------------+---------+-------+--------+
| Example14   |   x (TP)    |         |       |        |
+-------------+-------------+---------+-------+--------+

The table below indicates which specific features are used in each example. The features include:

- **Transport**: Compute transport properties of the mixture.
- **Ions**: Includes ionized species in the equilibrium calculation.
- **Insert**: Uses the ``insert`` species keyword, which is used to start the calculation considering the specified species; only relevant for condensed species - all gas species are always included in the initial guess.
- **Trace**: Sets the ``trace`` threshold parameter, which determines the level at which species concentrations are assumed to be 0.
- **Condensed**: Resulting equilibrium mixture includes significant condensed species concentrations.
- **Frozen**: Utilizes the frozen mode calculations of the rocket problem.


+-------------+-----------+------+--------+-------+-----------+--------+
|             | Transport | Ions | Insert | Trace | Condensed | Frozen |
+=============+===========+======+========+=======+===========+========+
| Example1    |           |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example2    |     x     |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example3    |           |      |        |   x   |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example4    |           |      |        |   x   |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example5    |           |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example6    |     x     |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example7    |           |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example8    |           |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example9    |           |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example10   |           |      |        |       |           |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example11   |     x     |  x   |        |       |     x     |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example12   |           |      |        |       |           |    x   |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example13   |           |      |   x    |   x   |     x     |        |
+-------------+-----------+------+--------+-------+-----------+--------+
| Example14   |           |      |        |       |     x     |        |
+-------------+-----------+------+--------+-------+-----------+--------+


.. toctree::
   :maxdepth: 2

   examples/equilibrium_examples
   examples/rocket_examples
   examples/shock_examples
   examples/deton_examples
   examples/python_examples
