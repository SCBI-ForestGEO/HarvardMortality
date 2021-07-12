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
library(stringr)
library(dplyr)
library(readr)

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





# Identify quadrats with errors
all_errors_to_be_fixed <- list.files(file.path(here("testthat"), "reports/requires_field_fix"), pattern = ".csv", full.names = T)
quadrats_with_errors <- NULL
for(error_to_be_fixed in all_errors_to_be_fixed){
  # We do file-by-file separately here b/c file formats between the different error
  # reports don't match. In particular quadrat_censused_missing_stems.csv
  if(str_sub(error_to_be_fixed, -34, -5) == "quadrat_censused_missing_stems") {
    quadrats_with_errors <- read_csv(error_to_be_fixed) %>% 
      pull(quadrat) %>% 
      c(quadrats_with_errors)
  } else if (str_sub(error_to_be_fixed, -32, -5) == "require_field_fix_error_file") {
    quadrats_with_errors <- read_csv(error_to_be_fixed) %>% 
      mutate(quadrat = str_sub(Quad.Sub.Quad, 1, 4)) %>% 
      pull(quadrat) %>% 
      c(quadrats_with_errors)
  } 
}
quadrats_with_errors <- unique(quadrats_with_errors) %>% as.numeric()



# Identify quadrats with warnings
all_warnings_to_be_fixed <- list.files(file.path(here("testthat"), "reports/warnings/"), pattern = ".csv", full.names = T)
all_warnings_to_be_fixed <- do.call(rbind, lapply(all_warnings_to_be_fixed, read.csv))
quadrats_with_warnings <- unique(all_warnings_to_be_fixed$Quad.Sub.Quad)
quadrats_with_warnings <- as.integer(substr(quadrats_with_warnings, start = 1, stop = 4))


quadrats$checks <- ifelse(quadrats$quadrats %in% quadrats_with_errors, 'error',
                          ifelse(quadrats$quadrats %in% quadrats_with_warnings, 'no error, only warning', 
                                 ifelse(quadrats$quadrats %in% complete_quads, 'complete',
                                        ifelse(quadrats$quadrats %in% swmp, "swamp", "incomplete"))))


filename <- file.path(here("testthat"), "reports/map_of_error_and_warnings.png")

clrs <- c( "aquamarine1", "coral2", "grey50","antiquewhite", "darkgoldenrod1")
img <- readPNG(source = "./data/dragon.png")
g <- rasterGrob(img, interpolate=TRUE)

pr <- ggplot(quadrats, aes(gx-10, gy-10, fill = checks))+
  geom_tile(color='grey80')+
  scale_fill_manual(values = clrs)+
  annotation_custom(g, xmin=370, xmax = 510, ymin = 240, ymax = 380)+
  annotate(geom=  "text", x = 380, y = 370, label = "Here be\ndragons!" )+
  labs(x="", y="")


ggsave(filename, plot= pr, device = 'png', 
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
