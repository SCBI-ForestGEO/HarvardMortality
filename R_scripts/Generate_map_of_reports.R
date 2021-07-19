# Generate map of censused quadrats ####

## this script is run automatically when there is a push 

# clear environment ####
rm(list = ls())

# load libraries ####
library(here)
library(readxl)
library(ggplot2)
library(png)
library(grid)
library(stringr)
library(gganimate)
library(gifski)
library(dplyr)
library(readr)
library(janitor)
library(lubridate)
library(patchwork)

# load map of quadrats ####
#quadrats <- rgdal::readOGR(file.path(here(""),"maps/20m_grid/20m_grid.shp"))
quadrats <- read.table("./data/HFquadrats.txt", header=TRUE, sep = '\t')
quadrats$quad <- as.character(  quadrats$quadrats)
quadrats$quad <- ifelse(nchar(quadrats$quad) < 4, paste0("0",   quadrats$quad),   quadrats$quad)

# load latest mortality data ####

## get the name of latest excel form
latest_FFFs <- list.files(here("raw_data/FFF_excel/"), pattern = ".xlsx", full.names = T)

# get the census data to find missing swamp quadrats
hf <- read.table("./data/Harvard_Forest_FFF.csv", header=T, sep = ",")
hf_quads <- unique(hf$QuadratName)

# swamp area with no trees over 10 cm
swmp <- quadrats[!(quadrats$quadrats %in% hf_quads),]$quadrats

## load the latest mortality survey

mort <- as.data.frame(read_xlsx(latest_FFFs, sheet = "subform_1", .name_repair = "minimal" ))
mort <- mort[, unique(names(mort))] # remove repeated columns
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

# assign codes for coloring quadrats
quadrats$checks <- ifelse(quadrats$quadrats %in% quadrats_with_errors, 'error',
                          ifelse(quadrats$quadrats %in% quadrats_with_warnings, 'warning', 
                                 ifelse(quadrats$quadrats %in% complete_quads, 'complete',
                                        ifelse(quadrats$quadrats %in% swmp, "swamp", "incomplete"))))


filename <- file.path(here("testthat"), "reports/map_of_error_and_warnings.png")

#assign color palette
clrs <- c( "aquamarine1", "coral2", "grey50","ivory1", "gold")

# dragon flare
img <- readPNG(source = "./data/redeft_2.png")
g <- rasterGrob(img, interpolate=TRUE)

# make plot
pr <- ggplot(quadrats, aes(gx-10, gy-10, fill = checks))+
  geom_tile(color='grey80')+
  scale_fill_manual(values = clrs)+
  annotation_custom(g, xmin=355, xmax = 540, ymin = 210, ymax = 380)+
  annotate(geom=  "text", x = 380, y = 370, label = "Here be\ndragons!" )+
  labs(x="", y="") +
  scale_x_continuous(expand = c(0, 0), limits = c(0, NA)) + 
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA))+
  coord_fixed()


ggsave(filename, plot= pr, device = 'png', 
       width = 8, height = 6, units = "in",dpi = 300 )

#### plot progress map by researcher


# # Get info on all quadrats censused so far
quadrat_info <- read_xlsx(latest_FFFs, sheet = "Root", .name_repair = "minimal" ) %>%
  clean_names() %>%
  select(submission_id, quad, date_time, personnel, quadrat_stem_count) %>%
  mutate(
    quadrat_stem_count = as.numeric(quadrat_stem_count),
    date_time = ymd(date_time)
  )


q2 <- base::merge(quadrats, quadrat_info, by = 'quad')
q2$personnel <- ifelse(q2$checks=='incomplete', NA,
                       ifelse(q2$checks == 'swamp', "swamp", q2$personnel))

cruisers <- unique(q2$personnel)

cruiser.color <- c("red", "forestgreen","salmon1", "blue",
                   "darkorchid3", "purple4", "chartreuse",
                   "antiquewhite", "grey50")

# make plot
cr <- ggplot(q2, aes(gx-10, gy-10, fill = personnel))+
  geom_tile(color='grey80')+
  scale_fill_manual(values=  cruiser.color)+
  labs(x="", y="") +
  coord_fixed()

#### animate collection ####
cr.ani <- cr + transition_manual(date_time, cumulative = TRUE)+
  labs(title = 'Date: {current_frame}')

cr.ani <- animate(cr.ani,duration = 20, end_pause = 5)
anim_save(filename = "Crew_cumulative_quadrats_animated.gif", animation = cr.ani, path = "./testthat/reports/")
