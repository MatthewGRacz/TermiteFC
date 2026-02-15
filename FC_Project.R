library(spatstat)
library(tidyverse)
library(seqinr)
library(deldir)
library(ggplot2)
library(rcompanion)

setwd("/Users/mattracz/Projects/Bonachela_Lab/TermiteProject")

fccoords = na.omit(read.csv("initial_snapshot.csv", header = TRUE, sep=","))

ps <- ppp(fccoords$POINT_X, 
          fccoords$POINT_Y,
          window = owin(
            xrange = c(0, max(fccoords$POINT_X)),
            yrange = c(0, max(fccoords$POINT_Y))
          ))
#creates a rectangle (of size according to range of points) around ppp points

plot.new() #new plot
termite_tess <- dirichlet(ps) #tess is the vornoi of points
plot(termite_tess, main="Vornoi FCs", axes=FALSE) #plot vornoi
plot(ps, add=TRUE, col = "black", pch = 20, cex = 0.7) #add points above vornoi
mtext("Meters", side = 1, line = 0)  #bottom
mtext("Meters", side = 2, line = -3) #left #axes


plot(pcf(ps))

#get maximum non-infinite G(r) value from both curves, then find how much above the expected 1 each curve jumped at its maximum peak, call this value A
pcfinfo <- data.frame(pcf(ps)) #iso = ripley, trans = trans, theo = poisson
sortedpcfinfo <- pcfinfo[order(pcfinfo$iso, decreasing=TRUE), ] #sort by descending ripley values
maxripley <- pcfinfo[order(pcfinfo$iso, decreasing=TRUE), ]$iso[2] #choose 2nd most, as 1st most is infinite
ripleyA <- maxripley - 1 #A is how much above 1 the value jumped at its peak, so subtract 1 from the max peak value

maxtrans <- pcfinfo[order(pcfinfo$trans, decreasing=TRUE), ]$trans[2]
transA <- maxtrans - 1

env <- envelope(ps, pcf, nsim=1000) #runs 1000 random simulations, envelopes are a type of fv so also (should) account for edge detection
plot(env) 
envdata <- data.frame(env)

maxobs <- envdata[order(envdata$obs, decreasing=TRUE), ]$obs[2] #choose 2nd most, as 1st most is infinite; obs for the pcf of the actual points on the plot (the observed points) 
obsA <- maxobs - 1 #A is how much above 1 the value jumped at its peak, so subtract 1 from the max peak value

vadf <- data.frame(area=deldir(fccoords$POINT_X, fccoords$POINT_Y)$summary$dir.area) #data frame of the areas of every voronoi cell, accounts for edge detection

meanarea <- mean(vadf$area)
medianarea <- median(vadf$area)
sdarea <- sd(vadf$area)

plotNormalHistogram(vadf, linecol="red", xlab="Area", main="Voronoi Cell Areas", breaks=15) #create histogram with red curve 
abline(v = meanarea, col = "darkgreen", lwd = 2, lty = 1) #green line at mean of histogram
abline(v = medianarea, col = "hotpink", lwd = 2, lty = 1) #pink line at median of histogram
text(x = meanarea, y = 260, labels = paste0("Mean = ", meanarea), pos = 4, col = "darkgreen") #label for mean line
text(x = meanarea-(0.27*sdarea), y = 260, labels = "Median", pos = 2, col = "hotpink", cex=0.9) #label for median line 
text(x = meanarea-(0.625*sdarea), y = 240, labels = "=", pos = 2, col = "hotpink", cex=0.9) 
text(x = meanarea-(0.27*sdarea), y = 220, labels = round(medianarea, 2), pos = 2, col = "hotpink", cex=0.8) 




