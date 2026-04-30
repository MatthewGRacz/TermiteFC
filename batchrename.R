setwd("/Users/mattracz/Projects/Bonachela_Lab/FC_screenshots/Australia/4600_Images")

working_dir <- getwd()

target_dir <- "/Users/mattracz/Projects/Bonachela_Lab/FC_screenshots/Australia/next_segs"

# 1. Grab the list of current files
old_names <- list.files(pattern = "*.png", full.names = TRUE)

# 2. Create the new names (FC_1.png, FC_2.png, etc.) based on their index position
new_names <- paste0("FC_", seq_along(old_names), ".png")

# 3. Actually apply the new names to the files!
file.rename(old_names, new_names)



# 2. Get the full list of your 4600 images
all_images <- list.files(working_dir, full.names = TRUE)

# 3. Randomly select 500 of them 
selected_imgs <- sample(all_images, 250, replace = FALSE)

# 4. Construct the exact new file paths
# This glues your new folder path to the original file names (e.g., .../Train_500/FC_42.png)
new_paths <- file.path(target_dir, basename(selected_imgs))

# 5. Move the files by renaming their directory paths
file.rename(from= selected_imgs, to = new_paths)

length(list.files(target_dir, pattern = "\\.png$"))


