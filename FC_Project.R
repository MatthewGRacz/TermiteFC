library("spatstat")
library("tidyverse")
library("seqinr")
library("deldir")
library("ggplot2")
library("rcompanion")
library("jsonlite")
library("pracma")
library("tidyverse")
library("moments")
library("sf")

setwd("/Users/mattracz/Projects/Bonachela_Lab/TermiteFC")

#get areas of FCs identified via coords-----


get_centroid <- function(img_name, xcoords, ycoords){
  
  #for one FC polygon
  
  #load XY coords and duplicate the last row if it's not already duplicated, as sf requires "closed" coords-----
  
  xy_coord_matrix <- cbind(xcoords, ycoords)
  
  if (!all(xy_coord_matrix[1, ] == xy_coord_matrix[nrow(xy_coord_matrix), ])) { 
    #if first row isnt equal to the last
    xy_coord_matrix <- rbind(xy_coord_matrix, xy_coord_matrix[1, ]) 
    #duplicate first XY pair
  }
  
  polygon_centroid_data <- st_centroid(st_polygon(list(xy_coord_matrix)))
  
  centroid_xycoords <- st_coordinates(polygon_centroid_data)
  
  #fc_ppp <- as.ppp(xcoords, ycoords, window=owin(c(0, max(xcoords)), c(0, max(ycoords))))
  
  centroid_xycoords <- list(centroid_xycoords[!(is.infinite(centroid_xycoords) | is.na(centroid_xycoords))])
  
  return(centroid_xycoords)
  
  
}

get_tess_stats <- function(xcoords, ycoords, img_name, img_width, img_height, min_number_fcs){
  
  if(length(xcoords) >= min_number_fcs){
  
    #for all centroids of an image
    
    fc_centers <- ppp(xcoords, ycoords, window=owin(c(0, img_width), c(0, img_height)))
    
    voronoi_tess <- dirichlet(fc_centers)
      
    #----Get the subfolders for graphs ready-----
    
    plots_base <- "plots"
    sub_folders <- c("PCF", "PCF_envelope", "Jest", "Tesselation", "Centered_Lest", "Centered_Gest")
    
    # Create 'plots' folder (if it doesn't already exist)
    if(!dir.exists(plots_base)) {
      dir.create(plots_base)
    }
    
    # Loop through and create all the subdirectories inside 'plots'
    for(sub in sub_folders){
      target_dir <- file.path(plots_base, sub)
      if(!dir.exists(target_dir)) {
        dir.create(target_dir)
      }
    }
    
    tess_file_path <- file.path("plots", "Tesselation", paste0(img_name, "_Tesselation.png"))
    png(filename = tess_file_path, width = 800, height = 800, res = 120)
    
    #-----Make tesselation, plot it with FC centers------
  
    plot(voronoi_tess, main = paste0("Fairy Circle Centers\n", img_name))
    plot(fc_centers, add = TRUE, col = "black", pch = 20, cex = 0.6)
    axis(1)
    axis(2)
    mtext("Meters", side = 1, line = 2)
    mtext("Meters", side = 2, line = -2)
    
    dev.off() #saves plot as specified PNG at specified filepath
    
    #----run different PCF tests, get envelope for each, get RMI's----
    
    pcf_data <- envelope(fc_centers, 
                                 pcf, 
                                 correction = c("isotropic", "trans"),
                                 nsim=1000) 
    
    pcf_data_df <- data.frame(pcf_data)
    
    #rids of infinite values
    pcf_data_df[sapply(pcf_data_df, is.infinite)] <- NA
    
    A <- max(na.omit(pcf_data_df$obs))-1 
    #1 is the baseline, so this is how much above pure randomness the peak is (also makes 0 baseline)
    
    pcf_envelope_file_path <- file.path("plots", "PCF_envelope", paste0(img_name, "_PCF_envelope.png"))
    png(filename = pcf_envelope_file_path, width = 800, height = 800, res = 120)
    
    plot(pcf_data, main=paste0(img_name, "\ng(r) Envelope"), ylim=c(0, A+1.03))
    
    dev.off()
    
    pcf_file_path <- file.path("plots", "PCF", paste0(img_name, "_PCF.png"))
    png(filename = pcf_file_path, width = 800, height = 800, res = 120)
    
    plot(pcf(fc_centers), main=paste0(img_name, "\ng(r)"))
    
    dev.off()
    
    rmi <- pcf_data_df$r[which.max(pcf_data_df$obs)]
    #RMI (Radius of Maximum Inhibition) is the radius where the peak, A, happens
    
    #----runs Lest, get envelope for each, get MED's----
    
    lest_data <- envelope(fc_centers, 
                                  Lest, 
                                  correction = c("isotropic", "trans"),
                                  nsim=1000) 
    
    lest_data_df <- data.frame(lest_data)
    
    estimates <- (names(lest_data_df) != "r") #obs, theo, hi, low
    
    lest_data_df[estimates] <- lapply(lest_data_df[estimates], function(l){l - lest_data_df$r})
    #subtracts r from each estimate, then nadir is maximum exclusion distance (MED)
    
    med <- lest_data_df$r[which.min(lest_data_df$obs)] #gets the r where the nadir is
    #MED (Maximum Exclusion Distance) is the radius where the nadir happens
    
    centered_lest_file_path <- file.path("plots", "Centered_Lest", paste0(img_name, "_Centered_Lest.png"))
    png(filename = centered_lest_file_path, width = 800, height = 800, res = 120)
    
    plot(lest_data, . - r ~ r, main=paste0(img_name, "\nCentered Lest"))
    
    dev.off()
    
    
    #----runs Fest, Gest, Jest, get envelope for each, get MND's----
    
    fest_data <- envelope(fc_centers, 
                          Fest, 
                          correction = "km",
                          nsim=1000) 
    #KM is the gold standard and the best of the 3 options to use
    
    gest_data <- envelope(fc_centers, 
                          Gest, 
                          correction = "km",
                          nsim=1000) 
    
    jest_data <- envelope(fc_centers, 
                          Jest, 
                          correction = "km",
                          nsim=1000)
    
    fest_data_df <- data.frame(fest_data)
    gest_data_df <- data.frame(gest_data)
    jest_data_df <- data.frame(jest_data)
    
    jest_file_path <- file.path("plots", "Jest", paste0(img_name, "_Jest.png"))
    png(filename = jest_file_path, width = 800, height = 800, res = 120)
    
    plot(jest_data, main=paste0(img_name, "\nKM Jest"))
    
    dev.off()
    
    gest_data_df[sapply(gest_data_df, is.infinite)] <- NA
    gest_data_df <- na.omit(gest_data_df)
    gest_data_df[estimates] <- lapply(gest_data_df[estimates], function(l){l - gest_data_df$theo})
    
    mnd <- gest_data_df$r[which.min(gest_data_df$obs)]
    #r equals MND at the nadir 
    
    centered_gest_file_path <- file.path("plots", "Centered_Gest", paste0(img_name, "_Centered_Gest.png"))
    png(filename = centered_gest_file_path, width = 800, height = 800, res = 120)
    
    plot(gest_data, . - theo ~ r, main=paste0(img_name, "\nCentered Gest")) 
    #r equals MND at the nadir 
    
    dev.off()
    
    esp <- 1/(jest_data_df$obs[which.min(abs(jest_data_df$r - mnd))])
    #A random colony placed into the current ecosystem would have an ESP (Empirical Survival Probability)
    #chance of being in an "allowed" or ecologically favorable area
    
    gs_gamma <- as.numeric(exp(coef(ppm(fc_centers ~ 1, Strauss(r = mnd))))["Interaction"])
    #how likely (0 to 1) the FC centers are to be from one another on a map, spatially (assumes uniform conditions)
    #compared to random chance; similar to Chi-Squared which compares probabilities of distributions
    
    
    #----Calculate NND and get stats from it----
    
    tess_nnd <- nndist(fc_centers)
    mean_nnd <- mean(tess_nnd)
    median_nnd <- median(tess_nnd)
    sd_nnd <- sd(tess_nnd)
    cv_nnd <- sd_nnd / mean_nnd
    min_nnd <- min(tess_nnd)
    max_nnd <- max(tess_nnd)
    skew_nnd <- skewness(tess_nnd)
    ce <- clarkevans(fc_centers, correction = c("Donnelly", "cdf"))
    
    
    #-----Calculate Areas and get stats from it-----
    
    tess_areas <- deldir(xcoords, ycoords)$summary$dir.area
    
    mean_area <- mean(tess_areas)
    median_area <- median(tess_areas)
    sd_area <- sd(tess_areas)
    cv_area <- sd_area / mean_area
    min_area <- min(tess_areas)
    max_area <- max(tess_areas)
    skew_area <- skewness(tess_areas)
    
    #----return everything as DF------
    
    return(data.frame(
      
      NAME = img_name,
      A = A,
      RMI = rmi,
      MED = med,
      MND = mnd,
      ESP = esp,
      GS_GAMMA = gs_gamma,
      CE = ce,
      NND_MEAN = mean_nnd,
      NND_MEDIAN = median_nnd,
      NND_SD = sd_nnd,
      NND_CV = cv_nnd,
      NND_MIN = min_nnd,
      NND_MAX = max_nnd,
      NND_SKEW = skew_nnd,
      THEO_AREA_MEAN = mean_area,
      THEO_AREA_MEDIAN = median_area,
      THEO_AREA_SD = sd_area,
      THEO_AREA_CV = cv_area,
      THEO_AREA_MIN = min_area,
      THEO_AREA_MAX = max_area,
      THEO_AREA_SKEW = skew_area
      
      
    ))
    
  }
    
}



#creates dataset with coords, areas info------
get_coords_and_areas <- function(xy_coords, img_name, img_width, img_height){
  
    #for every polygon for this image
    
    xcoords <- c()
    ycoords <- c()
    polygon_areas <- c()
    normalized_polygon_areas <- c()
    xcoords_scaled <- c()
    ycoords_scaled <- c()
    xycoords_scaled <- c()
    
    
    xcoords <- xy_coords[seq(1, length(xy_coords), by=2)]
    ycoords <- xy_coords[seq(2, length(xy_coords), by=2)]
    #xcoords are the odd numbered numbers X1Y1X2Y2...
    #ycoords are the even numbered numbers X1Y1X2Y2...
    
    xcoords_scaled <- xcoords * img_width
    ycoords_scaled <- ycoords * img_height
    
    xycoords_scaled <- rbind(c(xcoords_scaled, ycoords_scaled))
    
    polygon_areas <- abs(polyarea(xcoords_scaled, ycoords_scaled))
    #abs because CCW polygons have a negative area, while CW is positive
    #Polyarea calculates Normalized Area, so proportion of the area occupied
    #(FC Proportion of Screenshot Area)(Width of screenshot px * m/px)(Height of screenshot px * m/px)
    
    centroid <- get_centroid(img_name, xcoords_scaled, ycoords_scaled)
    
    centroid_x <- centroid[[1]][1]
    centroid_y <- centroid[[1]][2]
    
    return(data.frame(
      
      NAME = img_name,
      stringsAsFactors = FALSE,
      XYCOORDS = I(list(xycoords_scaled)),
      XCOORDS = I(list(xcoords_scaled)),
      YCOORDS = I(list(ycoords_scaled)),
      REAL_AREA_M2 = polygon_areas,
      CENTROID_X = centroid_x,
      CENTROID_Y = centroid_y,
      CENTROID = I(list(centroid))
    ))
    
  
}

get_tess_areas <- function(img_df, img_width, img_height, min_number_fcs){
  
  tess_window <- owin(c(0, img_width), c(0, img_height))
  
  if(nrow(img_df) >= min_number_fcs){ 
    #quick quality check: at least min number FCs in an image
    #some images have a few FCs to help the AI recognize FCs, but if there's not many because of
    #terrain edge or any other reasons, then the analysis of tesselation won't be accurate for the
    #larger scale data analysis
    
    fc_centers <- ppp(img_df$CENTROID_X, 
                      img_df$CENTROID_Y, 
                      tess_window)
    
    voronoi_tess <- dirichlet(fc_centers)
    
    tess_areas <- tile.areas(voronoi_tess)
    
    img_df$VORONOI_AREA_M2 <- tess_areas
    
  }
  
  else {
    
    img_df$VORONOI_AREA_M2 <- NA 
    
  }
  
  return(img_df)
  
}

main <- function(NDJSONfile, min_number_fcs){
  
  NDJSONdata <- readLines('fcs-training.ndjson') 
  #first line is dataset info, every other line with image data per image; 
  #sorted unannotated then annotated, both sorted from oldest to most recent
  
  NDJSONdata <- NDJSONdata[-1] #remove first line of dataset info
  
  maps_bar_length <- ((50/3.28084)/226) #units: m per pix; 15.24 m = 50 ft = 226px
  #Google Maps bar is 226 pixels wide for 50ft, negligible mercator (lat/long) distortion
  
  fc_master_list <- list()
  
  fc_master_set <- data.frame() 
  #names of FCs, polygon# (if none, 0), XYcoords/polygon, areas
  
  tess_stats <- data.frame()
  #for stats about the tesselation
  
  for(i in 1:length(NDJSONdata)){
    
    img_data <- fromJSON(NDJSONdata[i]) 
    #get info from NDJSON per image
    
    img_name <- img_data$file
    
    xy_coords <- img_data$annotations$segments
    
    xy_coords <- lapply(xy_coords, function(x) x[-1]) 
    #rid of classID of 0 at start of each coords list; if already empty, nothing happens
    
    xy_coords <- xy_coords[lengths(xy_coords) > 0] 
    #avoid "ghost polygons" where it says annotated but really has 0 annotations
    
    lapply(xy_coords, function(b) if(length(b) %% 2 == 0 && length(b)!=0) {cat("Good to go! \n")} else{cat(img_data[which(b)], "\n")}) 
    #check if even number of XY coords and presence of ghost polygons (no coords but counted as a polygon)
    
    img_width <- img_data$width * maps_bar_length
    img_height <- img_data$height * maps_bar_length
    
    fc_master_list[[i]] <- lapply(xy_coords, 
                                  get_coords_and_areas, 
                                  #run get_coords_and_areas function on a each polygon's XY coords
                                  img_name=img_name, 
                                  img_width=img_width, 
                                  img_height=img_height)
    
    
    img_df <- bind_rows(fc_master_list[[i]])
    
    img_df <- get_tess_areas(img_df, img_width, img_height, min_number_fcs)
    #gets Voronoi tesselation areas of each FC's center
    
    tess_stats <- bind_rows(tess_stats, get_tess_stats(img_df$CENTROID_X, img_df$CENTROID_Y, img_name, img_width, img_height, min_number_fcs))
    #get stats for the tesselation for this img, plus other useful ecological metrics
    
    
    fc_master_set <- bind_rows(img_df, fc_master_set)
    
  }

  return(list(fc_master_set, tess_stats))

}

fc_dfs <- main('fcs-training.ndjson', 17)
fc_master_set <- fc_dfs[[1]]
fc_tess_stats <- fc_dfs[[2]]
View(fc_master_set)
View(fc_tess_stats)



