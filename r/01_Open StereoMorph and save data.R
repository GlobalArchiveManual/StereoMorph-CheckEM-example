# Load the StereoMorph library
library(StereoMorph)
library(openxlsx)
library(dplyr)
library(CheckEM)
library(tidyr)
library(stringr)
library(readr)

# Function to calculate distances for each image and pair of landmarks ----
estimate_lengths <- function(landmarks_array, pairs_df) {
  image_names <- dimnames(landmarks_array)[[3]]   # Get image names from array
  results <- data.frame()  # Store results in a data.frame
  
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
digitizeImages(image.file='data/stereomorph files/H7_Images', 
               shapes.file='data/stereomorph files/H7_Shapes_2D', 
               landmarks.ref='data/raw/landmarks.txt', 
               cal.file='data/stereomorph files/H7_cal.txt')

# Reconstruct all digitized landmarks in Shapes 2D folder ----
reconstructStereoSets(shapes.2d='data/stereomorph files/H7_Shapes_2D', 
                      shapes.3d='data/stereomorph files/H7_Shapes_3D', 
                      cal.file='data/stereomorph files/H7_cal.txt')

# Read all 3D shapes ----
shapes <- readShapes(file = "data/stereomorph files/H7_Shapes_3D")

# Print all the reconstructed landmarks as an array ----
landmarks <- shapes$landmarks # 3D array: landmark x coords x image

# Read landmark pairs from file ----
landmark_pairs <- read.csv("data/raw/landmarks2.txt", header = FALSE, stringsAsFactors = FALSE)
colnames(landmark_pairs) <- c("landmark1", "landmark2")

# Run the function to calculate distances for each image and pair of landmarks----
lengths_df <- estimate_lengths(landmarks, landmark_pairs)

# Delete missing values from the frames ----
lengths_df <- na.omit(lengths_df) %>%
  dplyr::glimpse()

# Load metadata linking image name to species ----
# TODO will need to move species names into count/length data frame
# TODO add text for adding in CheckEM metadata names
fish_metadata <- read.xlsx("data/raw/species.xlsx") %>%
  dplyr::glimpse()

sample_metadata <- tibble::tibble(
  opcode = c("Deployment1", "Deployment2"),
  date_time = "2022-12-12T10:00:00-07:00",
  latitude_dd = c(24.250865, 24.25),
  longitude_dd = c(-110.151576, -110.15),
  depth_m = 2,
  status = "Fished",
  observer_count = "Alberto Garcia Baciero",
  observer_length = "Alberto Garcia Baciero",
  successful_count = "Yes",
  successful_length = "Yes",
  site = "Baja California Sur",
  location = "Mexico") %>%
  dplyr::glimpse()

# Merge with the fish length estimates
fishdf <- merge(lengths_df, fish_metadata, by = "image", all.x = TRUE) %>%
  dplyr::mutate(opcode = "Deployment1") %>%
  dplyr::rename(length_mm = distance) %>%
  CheckEM::clean_names() %>%
  dplyr::select(-common_name) %>%
  tidyr::separate(species, into = c("genus", "species"), sep = " ") %>%
  dplyr::mutate(species = str_replace_all(.$species, c("lucassanum" = "lucasanum",
                                                     "troscheli" = "troschelii"))) %>% # Fix spelling mistakes in annotation
  dplyr::left_join(CheckEM::global_life_history) %>% # Join with life history information to get the Family name
  dplyr::select(image, opcode, length_mm, family, genus, species) %>%
  glimpse()

# Create count data frame (the MaxN per species) ----
count <- fishdf %>%
  dplyr::mutate(count = 1) %>%
  dplyr::group_by(image, opcode, family, genus, species) %>%
  dplyr::summarise(count = sum(count)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(opcode, family, genus, species) %>%
  dplyr::slice(which.max(count)) %>%
  ungroup() %>%
  # dplyr::select(-image) %>%
  glimpse()

# Create a length data frame ----
length <- fishdf %>%
  dplyr::mutate(count = 1) %>%
  semi_join()# choose only the length measurements that are at MaxN

# Save final data ----
campaignid <- "2022-12_Baha_stereoRUVs"

write_csv(sample_metadata, paste0("data/tidy/", campaignid, "_Metadata.csv"))
write_csv(count, paste0("data/tidy/", campaignid, "_Count.csv"))
write_csv(length, paste0("data/tidy/", campaignid, "_Length.csv"))