# Generate map of censused quadrats ####

## this script is run automatically when there is a push 

# clear environment ####
rm(list = ls())

# load libraries ####
library(here)
library(rgdal)
library(readxl)
library(ggplot2)
library(png)
library(grid)

# load map of quadrats ####
#quadrats <- rgdal::readOGR(file.path(here(""),"maps/20m_grid/20m_grid.shp"))
quadrats <- read.table("./data/HFquadrats.txt", header=TRUE, sep = '\t')

# load latest mortality data ####

## get the name of latest excel form
latest_FFFs <- list.files(here("raw_data/FFF_excel/"), pattern = ".xlsx", full.names = T)

# get the census data to find missing swamp quadrats
hf <- read.table("./data/Harvard_Forest_FFF.csv", header=T, sep = ",")
hf_quads <- unique(hf$QuadratName)

swmp <- quadrats[!(quadrats$quadrats %in% hf_quads),]$quadrats

## load the latest mortality survey

mort <- as.data.frame(read_xlsx(latest_FFFs, sheet = "subform_1", .name_repair = "minimal" ))
mort <- mort[, unique(names(mort))]# remove repeated columns
mort$quadrat <- substr(mort$`Quad Sub Quad`, start = 1, stop = 4)
complete_quads <- as.integer(unique(mort$quadrat))


# load all report that need to be fixed ####
all_errors_to_be_fixed <- list.files(file.path(here("testthat"), "reports/requires_field_fix/"), pattern = ".csv", full.names = T)
all_warnings_to_be_fixed <- list.files(file.path(here("testthat"), "reports/warnings/"), pattern = ".csv", full.names = T)

#all_errors_to_be_fixed <- sapply(all_errors_to_be_fixed, read.csv)
all_errors_to_be_fixed <- do.call(rbind, lapply(all_errors_to_be_fixed, read.csv))
all_warnings_to_be_fixed <- do.call(rbind, lapply(all_warnings_to_be_fixed, read.csv))

#quadrats_with_error <- unique(unlist(sapply(all_errors_to_be_fixed, function(x) x[, grepl("quad", names(x), ignore.case = T)])))
quadrats_with_errors <- unique(all_errors_to_be_fixed$Quad.Sub.Quad)
quadrats_with_errors <- as.integer(substr(quadrats_with_errors, start = 1, stop = 4))

quadrats_with_warnings <- unique(all_warnings_to_be_fixed$Quad.Sub.Quad)
quadrats_with_warnings <- as.integer(substr(quadrats_with_warnings, start = 1, stop = 4))

quadrats$checks <- ifelse(quadrats$quadrats %in% quadrats_with_errors, 'error',
                          ifelse(quadrats$quadrats %in% quadrats_with_warnings, 'warning', 
                                 ifelse(quadrats$quadrats %in% complete_quads, 'complete',
                                        ifelse(quadrats$quadrats %in% swmp, "swamp", "incomplete"))))


filename <- file.path(here("testthat"), "reports/map_of_error_and_warnings.pdf")

clrs <- c( "aquamarine1", "coral2", "grey50","antiquewhite", "darkgoldenrod1")
img <- readPNG(source = "./data/dragon.png")
g <- rasterGrob(img, interpolate=TRUE)

pr <- ggplot(quadrats, aes(gx-10, gy-10, fill = checks))+
  geom_tile(color='grey80')+
  scale_fill_manual(values = clrs)+
  annotation_custom(g, xmin=370, xmax = 510, ymin = 240, ymax = 380)+
  annotate(geom=  "text", x = 380, y = 370, label = "Here be\ndragons!" )+
  labs(x="", y="")


ggsave(filename, plot= pr, device = 'pdf', 
       width = 8, height = 6, units = "in",dpi = 300 )

# 
# png(filename, width = 9, height = 8, units = "in", res = 300)
# par(mar = c(0,3,0,0))
# 
# plot(quadrats)
# plot(quadrats[quadrats$PLOT %in% mort$Quad,], col = "grey", add = T)
# plot(quadrats[quadrats$PLOT %in%  quadrats_with_error, ], col = "orange", add = T)
# plot(quadrats[quadrats$PLOT %in%  quadrats_with_warnings, ], col = "yellow", add = T)
# plot(quadrats[quadrats$PLOT %in%  intersect(quadrats_with_warnings, quadrats_with_error), ], col = "red", add = T)
# legend("bottomleft", fill = c("grey", "yellow", "orange", "red"), legend = c("done", "warning pending", "error pending", "warning & error pending"), bty = "n")
# 
# dev.off()
