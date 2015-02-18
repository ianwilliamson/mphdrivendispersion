These functions compute dispersion and loss characteristics using a driven 
approach. Two functions are provided: MPH_Driven_Dispersion_Mesh_Grid and 
MPH_Driven_Dispersion_Refine. 

MPH_Driven_Dispersion_Mesh_Grid returns a mesh grid over kx, ky, ki, and
frequency.

MPH_Driven_Dispersion_Refine refines the mesh grid produced by 
MPH_Driven_Dispersion_Mesh_Grid using fminsearch and returns the dispersion
(frequency bands) and loss (total imaginary k in direction of propagation).

These two functions are intended to be used in sequence.

The most recent version of the code can be obtained from:
https://bitbucket.org/ianwilliamson/mphdrivendispersion/

For any questions, contact Ian Williamson <ian.williamson@utexas.edu>