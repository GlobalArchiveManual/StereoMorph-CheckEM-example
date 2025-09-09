# How to format StereoMorph data for CheckEM

StereoMorph is an open source R package, allowing image annotation through R.
There is not a defined format for the output file, it is up to the user to define how they export the data after the images are annotated. 
Here, we put forward a workflow to use StereoMorph with the CheckEM shiny app.

# Instructions
1. In the r folder, there is a R script named 01_Open StereoMorph and save data.R, open the script in R.
2. Follow the instructions in the script to launch StereoMorph using the example imagery.
3. Annotate imagery using StereoMorph.
4. Follow the instructions in the script to save data into a format ready to use by CheckEM
5. Upload to CheckEM

# Acknowledgements
We would like to thank Alberto Garcia Baciero for providing example imagery, R scripts, and landmarks.

# The data used in this workflow is from the following paper:
García-Baciero, A., Robalino-Mejía, C., Peñaherrera-Palma, C. et al. Comparing the performance of two scientific tools for obtaining fish length measurements. Mar Biol 172, 125 (2025). https://doi.org/10.1007/s00227-025-04682-9

# For more explanation on the methods used please see this paper:
García-Baciero, A., Borges-Souza, J. M., Palomares-García, J. R., Rodríguez-Sánchez, R., Rubio-Rodríguez, U., & Villalobos, H. (2025). Monitoring fish populations using stereo-DOV-based surveys and open-access tools in the Gulf of California. Regional Studies in Marine Science, 81, 103926. https://doi.org/10.1016/j.rsma.2024.103926
