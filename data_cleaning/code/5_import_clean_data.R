# ---------------------------------------------------------------------------- #
# Import Clean Data
# Authors: Jeremy W. Eberle
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Notes ----
# ---------------------------------------------------------------------------- #

# Before running this script, restart R (CTRL+SHIFT+F10 on Windows) and set your
# working directory to the parent folder. This script will import intermediate
# clean data from "./data/3_intermediate_clean" (outputted by "4_clean_data.R") 
# and show how to convert POSIXct date columns back to POSIXct data types. It 
# outputs no files but serves as a starting point for further cleaning/analysis.

# Note for TET data cleaning: Kaitlyn Petz ran through Calm Thinking cleaning code with R version 4.2.3 to see if 
# the code could be run on a newer version of R. Checks were implemented throughout the code to ensure that the steps were
# all happening correctly. All of Kaitlyn's checks for making sure code works with newer R versions will be denoted 
# by double pound sign plus "Kaitlyn:" Kaitlyn also checked the folders & contents on Desktop at the end of each script 
# and compared them to the folders & content created with version 4.0.3, to ensure all data was exported correctly. Kaitlyn
# will also make notes for any changes made to the Calm Thinking code for cleaning the TET data, and implement checks in
# the same way as outlined above.

# ---------------------------------------------------------------------------- #
# Store working directory, install correct R version, load packages ----
# ---------------------------------------------------------------------------- #

# Store working directory

wd_dir <- getwd()

# Load custom functions

source("./code/2_define_functions_TET_v2.R")

# Check correct R version, load groundhog package, and specify groundhog_day

groundhog_day <- version_control()

# Load packages with groundhog

groundhog.library(dplyr, groundhog_day)

library(dplyr)

# ---------------------------------------------------------------------------- #
# Import intermediate clean data ----
# ---------------------------------------------------------------------------- #

# Obtain file names of intermediate clean CSV data files

cln_data_dir <- paste0(wd_dir, "/data/3_intermediate_clean")

filenames <- list.files(cln_data_dir, pattern = "*.csv", full.names = FALSE)

# Import data files into list

dat <- lapply(paste0(cln_data_dir, "/", filenames), read.csv)

# Name data tables in list

names(dat) <- sub(".csv", "", filenames)

# Report names of imported tables

cat("Imported intermediate clean tables:")
names(dat)

# ---------------------------------------------------------------------------- #
# Convert system-generated time stamps back to POSIXct data type ----
# ---------------------------------------------------------------------------- #

# System-generated time stamps were outputted as characters by "4_clean_data.R". 
# They need to be converted back to POSIXct data types (with "tz = 'UTC'" for 
# user-provided "return_date_as_POSIXct" of "return_intention" table and "tz 
# = 'EST'" for all system-generated timestamps).

for (i in 1:length(dat)) {
  POSIXct_colnames <- c(names(dat[[i]])[grep("as_POSIXct", names(dat[[i]]))],
                        "system_date_time_earliest",
                        "system_date_time_latest")
  
  for (j in 1:length(POSIXct_colnames)) {
    # Strip timezone from character vector
    
    dat[[i]][, POSIXct_colnames[j]] <- sub(" UTC| EST", "", 
                                           dat[[i]][, POSIXct_colnames[j]])
    
    # Convert character vector to POSIXct, specifying timezone
    
    if (names(dat[i]) == "return_intention" & 
        POSIXct_colnames[j] == "return_date_as_POSIXct") {
      dat[[i]][, POSIXct_colnames[j]] <- as.POSIXct(dat[[i]][, POSIXct_colnames[j]],
                                                    format = "%Y-%m-%d %H:%M:%S",
                                                    tz = "UTC")
    } else {
      dat[[i]][, POSIXct_colnames[j]] <- as.POSIXct(dat[[i]][, POSIXct_colnames[j]],
                                                    format = "%Y-%m-%d %H:%M:%S",
                                                    tz = "EST")
    }
  }
}
