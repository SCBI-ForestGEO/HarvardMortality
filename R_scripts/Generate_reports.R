# Generate reports looking at latest mortality census raw data ####
## this script is run automatically when there is a push  

# clear environment ####
rm(list = ls())

# load libraries ####
library(here)
library(readxl)
library(dplyr)
library(readr)
library(stringr)

# load latest mortality data ####

## get the name of latest excel form
latest_FFFs <- list.files(here("raw_data/FFF_excel/"), pattern = ".xlsx", full.names = T)

mort <- as.data.frame(read_xlsx(latest_FFFs, sheet = "subform_1", .name_repair = "minimal" ))
mort_root <- as.data.frame(read_xlsx(latest_FFFs, sheet = "Root", .name_repair = "minimal" ))

# Slightly different than SCBI version b/c of weird renaming of "Percentage of crown intact" to 
# "Percentage.of.crown.intact"
orig.names <- names(mort)
mort <- data.frame(SurveyorID = mort_root$Personnel[match(mort$`Submission Id`, mort_root$`Submission Id`)], mort)
names(mort) <- c("SurveyorID", orig.names)

# Load list of stems to census ####
main_census <- read_tsv("data/HFmort_stemtag.txt") %>% 
  select(quadrat, StemTag = stem.tag) %>% 
  # Ensure all quadrat names are 4 characters long
  mutate(quadrat = str_pad(quadrat, 4, side = "left", pad = "0"))

## TODO: fix once 
# # load species table ####
# 
# spptable <- read.csv("https://raw.githubusercontent.com/SCBI-ForestGEO/SCBI-ForestGEO-Data/master/tree_main_census/data/census-csv-files/scbi.spptable.csv")

# remove empty lines
mort <- mort[!is.na(mort$Quad), ] # fix empty lines

# remove repeated columns
mort <- mort[, unique(names(mort))]

# Convert character vectors to numeric 
mort[, "DBH"] <- as.numeric(mort[, "DBH"])
mort[, "HOM"] <- as.numeric(mort[, "HOM"])
mort[, 'Percentage of crown intact'] <- as.numeric(mort[, 'Percentage of crown intact'])
mort[, 'Percentage of crown living'] <- as.numeric(mort[, 'Percentage of crown living'])

# Add original collection date
mort_info <- as.data.frame(read_xlsx(latest_FFFs, sheet = "Root", .name_repair = "minimal" )) %>% 
  select('Submission Id', 'Orig.collection.date' = 'Date/Time')

mort <- mort %>% 
  left_join(
    mort_root %>% 
      select('Submission Id', 'Orig.collection.date' = 'Date/Time'), 
    by = 'Submission Id') %>% 
  select(SurveyorID, 'Submission Id', 'Orig.collection.date', everything())



# give a % completion status ####
percent_completion <- round(sum(paste(main_census$StemTag) %in% paste(mort$StemTag)) / nrow(main_census) * 100)

png(file.path(here("testthat"), "reports/percent_completion.png"), width = 1, height = 1, units = "in", res = 150)
par(mar = c(0,0,0,0))
plot(0,0, axes = F, xlab = "", ylab = "", type = "n")
text(0,0, paste(percent_completion, "%"))
dev.off()
# write.table(percent_completion, file = file.path(here("testthat"), "reports/percent_completion.txt"),  col.names = F, row.names = F)



# --- PERFORM CHECKS ---- ####

# prepare log files #####
require_field_fix_error_file <- NULL
will_auto_fix_error_file <- NULL
warning_file <- NULL



# for each quadrat censused, check all expected trees were censused ####
filename <- file.path(here("testthat"), "reports/requires_field_fix/quadrat_censused_missing_stems.csv")

idx_quadrat_censused <- main_census$quadrat %in% str_sub(mort$`Quad Sub Quad`, 1, 4)

tag_stem_with_error <- paste(main_census$StemTag)[idx_quadrat_censused] [!paste(main_census$StemTag)[idx_quadrat_censused] %in% mort$StemTag]
# table(main_census[paste(main_census$StemTag) %in% tag_stem_with_error, ]$sp)

if(length(tag_stem_with_error) > 0) {
  write.csv(main_census[paste(main_census$StemTag) %in% tag_stem_with_error, ], file = filename, row.names = F)
} else {
  if(file.exists(filename) ) file.remove(filename)
}



# remove any tree with current status DN as we don't need to check errors on those ####
status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- !mort[, status_column] %in% c("DN")

mort <- mort[idx_trees, ]



# check that personnel/surveyor ID who collected data is entered  ####
error_name <- "personnel_missing"

idx_error <- is.na(mort$SurveyorID)

if(sum(idx_error) != 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[idx_error,], error_name))



# for each quadrat censused, check that there is no duplicated stems ####
# Previously wrote duplicates to reports/will_auto_fix/, now writing to reports/require_field_fix:
# filename <- file.path(here("testthat"), "reports/will_auto_fix/quadrat_censused_duplicated_stems.csv")
#
# if(length(tag_stem_with_error) > 0) {
#   write.csv(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], file = filename, row.names = F)
# } else {
#   if(file.exists(filename) ) file.remove(filename)
# }
error_name <- "duplicated_stem"

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[duplicated(paste(mort$Tag, mort$StemTag))]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that all censused trees have a crown position recorded ####
error_name <- "missing_crown_position"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("A", "AU", "DS")

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[is.na(mort$'Crown position') & idx_trees]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that all censused trees have a percent of crown intact recorded ####
error_name <- "missing_percent_crown_intact"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("A", "AU", "DS")

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[is.na(mort$'Percentage of crown intact') & idx_trees]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that all censused trees have a percent of crown living recorded ####
error_name <- "missing_percent_crown_living"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("A", "AU", "DS")

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[is.na(mort$'Percentage of crown living') & idx_trees]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ] , error_name))



# check percent of crown living <=  percent of crown intact####
error_name <- "crown_living_greater_than_crown_intact"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("A", "AU", "DS")

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[!is.na(mort$'Percentage of crown living') & !is.na(mort$'Percentage of crown intact') & (mort$'Percentage of crown living' > mort$'Percentage of crown intact') & idx_trees]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ] , error_name))



# check percent newly censused trees (DS or DC)	have percentage of crown living = 0####
error_name <- "dead_but_crown_living_not_zero"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("DS", "DC")

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[!is.na(mort$'Percentage of crown living') & mort$'Percentage of crown living'> 0 &  idx_trees]

if(length(tag_stem_with_error) > 0) will_auto_fix_error_file <- rbind(will_auto_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ] , error_name))



# check that newly censused alive trees have no FAD selected; no record of wounded main stem, canker, or rotting trunk; DWR (dead with resprouts) not selected ####
error_name <- "status_A_but_unhealthy"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% "A"
idx_FAD <- !is.na(mort$FAD)
idx_wound <- !is.na(mort$'Wounded main stem')
idx_canker <- !is.na(mort$'Canker; swelling, deformity')
idx_rot <- !is.na(mort$'Rotting trunk')
idx_DWR <- !mort$'DWR' %in% "False"

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & (idx_FAD | idx_wound | idx_wound | idx_canker | idx_rot | idx_DWR)]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



## and vice-versa ####
error_name <- "unhealthy_but_wrong_status"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU", "DC", "DS")
idx_FAD <- !is.na(mort$FAD)
idx_wound <- !is.na(mort$'Wounded main stem')
idx_canker <- !is.na(mort$'Canker; swelling, deformity')
idx_rot <- !is.na(mort$'Rotting trunk')
idx_DWR <- !mort$'DWR' %in% "False"

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[!idx_trees & (idx_FAD | idx_wound | idx_wound | idx_canker | idx_rot | idx_DWR)]

if(length(tag_stem_with_error) > 0) will_auto_fix_error_file <- rbind(will_auto_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that status 'AU' does not have 	DWR (dead with resprouts)  selected ####
error_name <- "status_AU_but_DWR_selected"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% "AU"
idx_DWR <- !mort$'DWR' %in% "False"

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_DWR]

if(length(tag_stem_with_error) > 0) if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that newly censused 'AU', 'DS' or 'DC trees that were alive in previous census have at least one FAD selected ####
error_name <- "status_AU_DS_or_DC_but_no_FAD"

status_column <- rev(grep("Status", names(mort), value = T))[1]
previous_status_column <- rev(grep("Status", names(mort), value = T))[2]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_previously_dead <- idx_previously_dead <- grepl("D", mort[,previous_status_column]) & !is.na(mort[,previous_status_column])

idx_no_FAD <- is.na(mort$FAD)

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_no_FAD & !idx_previously_dead]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that newly censused 'AU', 'DS' or 'DC with "wound" selected as FAD have selected a level for wounded main stem ####
error_name <- "wounded_but_no_level"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_wounded <- !is.na(mort$FAD) & grepl("W", mort$FAD)
idx_wnd_main_stem <- !is.na(mort$'Wounded main stem')


tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_wounded & !idx_wnd_main_stem ]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



## and vice versa ####
error_name <- "wounded_level_but_wrong_status_or_FAD"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_wounded <- !is.na(mort$FAD) & grepl("W", mort$FAD)
idx_wnd_main_stem <- !is.na(mort$'Wounded main stem')

if(length(tag_stem_with_error) > 0) {
  tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[(!idx_trees | !idx_wounded) & idx_wnd_main_stem ]
  will_auto_fix_error_file <- rbind(will_auto_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))
}


# check that newly censused 'AU', 'DS' or 'DC with "canker" selected as FAD have selected a level for canker,swelling,deformity ####
error_name <- "canker_but_no_level"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_canker <- !is.na(mort$FAD) & grepl("K", mort$FAD)
idx_ckr_level <- !is.na(mort$'canker,swelling,deformity')

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_canker & !idx_ckr_level ]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



## and vice versa ####
error_name <- "canker_level_but_wrong_status_or_FAD"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_canker <- !is.na(mort$FAD) & grepl("K", mort$FAD)
idx_ckr_level <- !is.na(mort$'canker,swelling,deformity')

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[(!idx_trees & !idx_canker) & idx_ckr_level ]

if(length(tag_stem_with_error) > 0) will_auto_fix_error_file <- rbind(will_auto_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that newly censused 'AU', 'DS' or 'DC with "rotting stem" selected as FAD have selected a level for rotting main stem ####
error_name <- "rot_but_no_level"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_rot <- !is.na(mort$FAD) & grepl("R\\>", mort$FAD)
idx_rot_level <- !is.na(mort$'rotting main stem')

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_rot & !idx_rot_level ]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



## and vice versa ####
error_name <- "rot_level_but_wrong_status_or_FAD"

status_column <- rev(grep("Status", names(mort), value = T))[1]

idx_trees <- mort[, status_column] %in% c("AU","DS", "DC")
idx_rot <- !is.na(mort$FAD) & grepl("R\\>", mort$FAD)
idx_rot_level <- !is.na(mort$'rotting main stem')


tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[(!idx_trees & !idx_rot) & idx_rot_level ]


if(length(tag_stem_with_error) > 0) will_auto_fix_error_file <- rbind(will_auto_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name))



# check that newly censused 'A' or 'AU', were A or AU in previous year ####
# 
# As noted here https://github.com/SCBI-ForestGEO/HarvardMortality/issues/16
# in some rare instances, we can have a newly censused 'A' or 'AU' that were dead previously
# because stem was previously misclassified. i.e. they are "brought back to life"
# For such stems we expect a note. If there is no note, issue error below.
# See "Dead_but_now_alive_with_note" for opposite case. 
error_name <- "Dead_but_now_alive_no_note"

status_column <- rev(grep("Status", names(mort), value = T))[1]
previous_status_column <- rev(grep("Status", names(mort), value = T))[2]

idx_trees <- mort[, status_column] %in% c("AU","A")
idx_previously_dead_no_note <- !mort[,previous_status_column] %in% c("AU","A") & !is.na(mort[,previous_status_column]) & is.na(mort$`Notes 2021`)

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_previously_dead_no_note ]

if(length(tag_stem_with_error) > 0) require_field_fix_error_file <- rbind(require_field_fix_error_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], error_name)) 



# check that newly censused 'A' or 'AU', were A or AU in previous year ####
# 
# As noted here https://github.com/SCBI-ForestGEO/HarvardMortality/issues/16
# in some rare instances, we can have a newly censused 'A' or 'AU' that were dead previously
# because stem was previously misclassified. i.e. they are "brought back to life"
# For such stems we expect a note. If there is a note, issue warning below
# See "Dead_but_now_alive_no_note" for opposite case. 
warning_name <- "Dead_but_now_alive_with_note"

status_column <- rev(grep("Status", names(mort), value = T))[1]
previous_status_column <- rev(grep("Status", names(mort), value = T))[2]

idx_trees <- mort[, status_column] %in% c("AU","A")
idx_previously_dead_with_note <- !mort[,previous_status_column] %in% c("AU","A") & !is.na(mort[,previous_status_column]) & !is.na(mort$`Notes 2021`)

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_previously_dead_with_note ]

if(length(tag_stem_with_error) > 0) warning_file <- rbind(warning_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], warning_name)) 



# check that newly censused 'A' or 'AU' or 'DS', were not 'DC' in previous year ####
warning_name <- "DC_but_now_A_AU_or_DS"

status_column <- rev(grep("Status", names(mort), value = T))[1]
previous_status_column <- rev(grep("Status", names(mort), value = T))[2]

idx_trees <- mort[, status_column] %in% c("AU","A", "DS")
idx_previously_dead <- mort[,previous_status_column] %in% c("DC") & !is.na(mort[,previous_status_column])

tag_stem_with_error <- paste(mort$Tag, mort$StemTag)[idx_trees & idx_previously_dead ]

if(length(tag_stem_with_error) > 0) warning_file <- rbind(warning_file, data.frame(mort[paste(mort$Tag, mort$StemTag) %in% tag_stem_with_error, ], warning_name)) 



# clean and save files ####

## remove empty tags
require_field_fix_error_file <- require_field_fix_error_file[!is.na(require_field_fix_error_file$StemTag),]

will_auto_fix_error_file <- will_auto_fix_error_file[!is.na(will_auto_fix_error_file$StemTag),]

warning_file <- warning_file[!is.na(warning_file$StemTag),]

## order by quadrat and tag
if(!is.null(require_field_fix_error_file))
  require_field_fix_error_file <- require_field_fix_error_file[order(require_field_fix_error_file$Quad, require_field_fix_error_file$StemTag),]

if(!is.null(will_auto_fix_error_file))
  will_auto_fix_error_file <- will_auto_fix_error_file[order(will_auto_fix_error_file$Quad, will_auto_fix_error_file$StemTag),]

if(!is.null(warning_file))
  warning_file <- warning_file[order(warning_file$Quad, warning_file$StemTag),]


# if errors/warnings exist save, else delete
if(!is.null(require_field_fix_error_file)) {
  write.csv(
    require_field_fix_error_file[, c(ncol(require_field_fix_error_file), 1:(ncol(require_field_fix_error_file) -1))], 
    file = file.path(here("testthat"), "reports/requires_field_fix/require_field_fix_error_file.csv"), 
    row.names = F
  )
} else {
  file.remove(file.path(here("testthat"), "reports/requires_field_fix/require_field_fix_error_file.csv"))
}

if(!is.null(will_auto_fix_error_file)) {
  write.csv(
    will_auto_fix_error_file[, c(ncol(will_auto_fix_error_file), 1:(ncol(will_auto_fix_error_file) -1))], 
    file = file.path(here("testthat"), "reports/will_auto_fix/will_auto_fix_error_file.csv"), 
    row.names = F
  )
} else {
  file.remove(file.path(here("testthat"), "reports/will_auto_fix/will_auto_fix_error_file.csv"))
}

if(!is.null(warning_file)) {
  write.csv(
    warning_file[, c(ncol(warning_file), 1:(ncol(warning_file) -1))], 
    file = file.path(here("testthat"), "reports/warnings/warnings_file.csv"), 
    row.names = F
  )
} else {
  file.remove(file.path(here("testthat"), "reports/warnings/warnings_file.csv"))
}


# KEEP TRACK OF ALL THE ISSUES ####
all_reports <- list.files(here("testthat/reports/", c("requires_field_fix", "will_auto_fix", "warnings")), recursive = T, pattern = ".csv", full.names = T)

for(f in all_reports) {
  
  new_f <- gsub("/reports/", "/reports/trace_of_reports/", f)
  new_f <- gsub("/requires_field_fix/|/will_auto_fix/|/warnings/", "",new_f)
  
  if(file.exists(new_f))
    write.csv(unique(rbind(read.csv(new_f), read.csv(f))), file = new_f, row.names = F)
  else 
    write.csv(read.csv(f), file = new_f, row.names = F)
  
}



# TODO: Need quadrats
# # generate a file with summary for each quadrat ####
# quadrat_censused_missing_stems <- read.csv(file.path(here("testthat"), "reports/requires_field_fix/quadrat_censused_missing_stems.csv"))
# quadrat_censused_duplicated_stems <- read.csv(file.path(here("testthat"), "reports/will_auto_fix/quadrat_censused_duplicated_stems.csv"))
# 
# quad_with_any_issue <- sort(unique(c(require_field_fix_error_file$Quad, will_auto_fix_error_file$Quad, warning_file$Quad, quadrat_censused_duplicated_stems$quadrat, quadrat_censused_missing_stems$Quad)))
# 
# quad_summary <- data.frame(Quad = quad_with_any_issue, 
#                            n_tag_error_field_fix = c(table(require_field_fix_error_file$Quad))[as.character(quad_with_any_issue)], 
#                            n_tag_error_auto_fix = c(table(will_auto_fix_error_file$Quad))[as.character(quad_with_any_issue)],
#                            n_tag_warnings = c(table(warning_file$Quad))[as.character(quad_with_any_issue)],
#                            n_missing_tags = c(table(quadrat_censused_missing_stems$quadrat))[as.character(quad_with_any_issue)],
#                            n_duplicated_tags = c(table(quadrat_censused_duplicated_stems$Quad))[as.character(quad_with_any_issue)])
# 
# write.csv(quad_summary[order(quad_summary$n_tag_error_field_fix, decreasing = T), ], file.path(here("testthat"), "reports/quadrat_n_errors_summary.csv"), row.names = F)

