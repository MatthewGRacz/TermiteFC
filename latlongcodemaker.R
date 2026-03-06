library("tidyverse")
library("strex")

#user enters multiple lat,long coords

coordstext <- "-23.3786575,119.8573823 -23.3781283,119.8647237 -23.3925888,119.8646868 -23.3922077,119.8515489

-23.4145417,119.8337051 -23.4147296,119.845277
-23.4269184,119.8323059 -23.4275738,119.8537651

-23.4305896,119.8325822 -23.4305508,119.8475589
-23.4516285,119.8493022 -23.4517085,119.8385454

-23.5277143,119.8264414 -23.5283875,119.825513
-23.5541541,119.8162923 -23.5489272,119.8257605

-23.3784316,119.8574635 -23.3798484,119.8609763
-23.4049051,119.8615924 -23.4084446,119.845858

-23.4101914,119.8366515 -23.4096881,119.8613922
-23.5280432,119.8561199 -23.5279969,119.8467672

-23.5303654,119.8295635 -23.5302543,119.8556264 -23.5427959,119.8532649 -23.5445339,119.8320526

-23.5494004,119.8321954 -23.5502753,119.8503974 -23.5629159,119.8427142 -23.5631848,119.8316827

-23.3448362,120.4016386 -23.3446555,120.405368
-23.3710137,120.3992745 -23.3681556,120.4169758

-23.4180206,120.6219269 -23.415191,120.6391286
-23.4197567,120.6262172 -23.4179265,120.638255

-23.4465787,120.6698881 -23.4467982,120.6932027
-23.454137,120.6941734 -23.4541542,120.6700507

-22.775067,120.4276478 -22.7755833,120.4342283,
-22.7770579,120.4264746 -22.7768632,120.4291902"
quotedcoords <- paste0('"', gsub(" ", '", "', coordstext), '"')
cat(quotedcoords)

#paste result into list function on allcoords <- list()

allcoords <- list("-23.3786575,119.8573823", "-23.3781283,119.8647237", "-23.3925888,119.8646868", "-23.3922077,119.8515489 -23.4145417,119.8337051", "-23.4147296,119.845277 -23.4269184,119.8323059", "-23.4275738,119.8537651 -23.4305896,119.8325822", "-23.4305508,119.8475589 -23.4516285,119.8493022", "-23.4517085,119.8385454 -23.5277143,119.8264414", "-23.5283875,119.825513 -23.5541541,119.8162923", "-23.5489272,119.8257605 -23.3784316,119.8574635", "-23.3798484,119.8609763 -23.4049051,119.8615924", "-23.4084446,119.845858 -23.4101914,119.8366515", "-23.4096881,119.8613922 -23.5280432,119.8561199", "-23.5279969,119.8467672 -23.5303654,119.8295635", "-23.5302543,119.8556264", "-23.5427959,119.8532649", "-23.5445339,119.8320526 -23.5494004,119.8321954", "-23.5502753,119.8503974", "-23.5629159,119.8427142", "-23.5631848,119.8316827 -23.3448362,120.4016386", "-23.3446555,120.405368 -23.3710137,120.3992745", "-23.3681556,120.4169758 -23.4180206,120.6219269", "-23.415191,120.6391286 -23.4197567,120.6262172", "-23.4179265,120.638255 -23.4465787,120.6698881", "-23.4467982,120.6932027 -23.454137,120.6941734", "-23.4541542,120.6700507 -22.775067,120.4276478", "-22.7755833,120.4342283, -22.7770579,120.4264746", "-22.7768632,120.4291902")

lat1 <- strex::str_nth_number(allcoords[((0)*4)+1][[1]], n=1, decimals = TRUE, negs=TRUE)
lat2 <- strex::str_nth_number(allcoords[((0)*4)+2][[1]], n=1, decimals = TRUE, negs=TRUE)
lat3 <- strex::str_nth_number(allcoords[((0)*4)+3][[1]], n=1, decimals = TRUE, negs=TRUE)
lat4 <- strex::str_nth_number(allcoords[((1)*4)][[1]], n=1, decimals = TRUE, negs=TRUE)

if(length(allcoords) %% 4 == 0){ # only run if four corners given
  
  # FIX 1: Divide by 4 so it only loops once per square
  for(i in 1:(length(allcoords) / 4)){
    
    minlats <- c()
    minlongs <- c()
    maxlats <- c()
    maxlongs <- c()
    
    lat1 <- strex::str_nth_number(allcoords[[((i-1)*4)+1]][[1]], n=1, decimals = TRUE, negs=TRUE)
    lat2 <- strex::str_nth_number(allcoords[[((i-1)*4)+2]][[1]], n=1, decimals = TRUE, negs=TRUE)
    lat3 <- strex::str_nth_number(allcoords[[((i-1)*4)+3]][[1]], n=1, decimals = TRUE, negs=TRUE)
    lat4 <- strex::str_nth_number(allcoords[[(i*4)]][[1]],       n=1, decimals = TRUE, negs=TRUE)
    
    long1 <- strex::str_nth_number(allcoords[[((i-1)*4)+1]][[1]], n=2, decimals = TRUE, negs=TRUE)
    long2 <- strex::str_nth_number(allcoords[[((i-1)*4)+2]][[1]], n=2, decimals = TRUE, negs=TRUE)
    long3 <- strex::str_nth_number(allcoords[[((i-1)*4)+3]][[1]], n=2, decimals = TRUE, negs=TRUE)
    long4 <- strex::str_nth_number(allcoords[[(i*4)]][[1]],       n=2, decimals = TRUE, negs=TRUE)
    
    maxlat <- max(lat1, lat2, lat3, lat4)
    minlat <- min(lat1, lat2, lat3, lat4)
    
    maxlong <- max(long1, long2, long3, long4)
    minlong <- min(long1, long2, long3, long4)
    
    # Keeping your tracking vectors just in case you need them later
    maxlongs <- c(maxlongs, maxlong)
    minlongs <- c(minlongs, minlong)
    maxlats <- c(maxlats, maxlat)
    minlats <- c(minlats, minlat)
    
    # FIX 2: Using sprintf() to inject the variables into the string
    cat(sprintf('
        {
            "name": "FC_",
            "min_lat": %f, "max_lat": %f,
            "min_long": %f, "max_long": %f
        },\n', minlat, maxlat, minlong, maxlong))
    
  }
} else{
  
  cat("The number of lat,long coords is not divisible by 4; please re-enter")
  
}


#for every 4 coords, representing 4 corners of the area, grabs all lats and all longs
#then gets smallest of the four lats, smallest long, largest lat, largest long
#outputs a python code block with the selected lats and longs

