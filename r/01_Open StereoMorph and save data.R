# Load the StereoMorph library
library(StereoMorph)
library(openxlsx)

# Function to calculate distances for each image and pair of landmarks ----
estimate_lengths <- function(landmarks_array, pairs_df) {
  # Get image names from array
  image_names <- dimnames(landmarks_array)[[3]]
  
  # Store results in a data.frame
  results <- data.frame()
  
  for (img in image_names) {
    for (i in seq_len(nrow(pairs_df))) {
      lm1 <- pairs_df$landmark1[i]
      lm2 <- pairs_df$landmark2[i]
      
      # Ensure both landmarks exist in the current image
      if (all(c(lm1, lm2) %in% dimnames(landmarks_array)[[1]])) {
        dist <- distancePointToPoint(landmarks_array[c(lm1, lm2), , img])
        results <- rbind(results, data.frame(
          image = img,
          landmark1 = lm1,
          landmark2 = lm2,
          distance = dist
        ))
      } else {
        warning(paste("Landmark(s) missing in", img, ":", lm1, lm2))
      }
    }
  }
  
  return(results)
}

# TODO ask alberto for the H7_cal.txt
# TODO check that the shiny app works properly

# Launch the digitizing application to select the landmarks ----
digitizeImages(image.file='H7_Images', 
               shapes.file='H7_Shapes_2D', 
               landmarks.ref='landmarks.txt', 
               cal.file='H7_cal.txt')

# Reconstruct all digitized landmarks in Shapes 2D folder ----
reconstructStereoSets(shapes.2d='H7_Shapes_2D', 
                      shapes.3d='H7_Shapes_3D', 
                      cal.file='H7_cal.txt')

# Read all 3D shapes ----
shapes <- readShapes(file = "H7_Shapes_3D")

# Print all the reconstructed landmarks as an array ----
landmarks <- shapes$landmarks # 3D array: landmark x coords x image

# Read landmark pairs from file ----
landmark_pairs <- read.csv("landmarks2.txt", header = FALSE, stringsAsFactors = FALSE)
colnames(landmark_pairs) <- c("landmark1", "landmark2")

# Run the function to calculate distances for each image and pair of landmarks----
lengths_df <- estimate_lengths(landmarks, landmark_pairs)

# Delete missing values from the frames ----
lengths_df <- na.omit(lengths_df) %>%
  glimpse()

# Load metadata linking image name to species
metadata <- read.xlsx("species.xlsx")

# Merge with the fish length estimates
fishdf <- merge(lengths_df, metadata, by = "image", all.x = TRUE) %>%
  glimpse()

# Save final dataset ----
write.xlsx(fishdf, "fish_data.xlsx")
