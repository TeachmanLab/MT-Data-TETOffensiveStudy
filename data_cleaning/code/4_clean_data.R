# ---------------------------------------------------------------------------- #
# Clean Data
# Authors: Jeremy W. Eberle, Sonia Baee, and Kaitlyn Petz (for TET)
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Notes ----
# ---------------------------------------------------------------------------- #

# Before running this script, restart R (CTRL+SHIFT+F10 on Windows) and set your
# working directory to the parent folder. This script will import (a) raw data 
# (outputted by "1_get_raw_data.ipynb") from "./data/1_raw_full" (if available;
# only privately shared) or "./data/1_raw_partial" (otherwise; publicly shared) 
# and (b) redacted data from "./data/2_redacted" (outputted by "3_redact_data.R").

# On redacted tables and raw tables in which no redaction was needed, this script
# (a) performs database-wide cleaning (Part I), (b) filters all data for a given 
# study (in this case Calm Thinking; Part II), and (c) performs study-specific 
# cleaning (in this case for Calm Thinking; Part III).

# The script will output intermediate clean data into "./data/3_intermediate_clean".
# The outputted data are deemed only intermediately cleaned because additional 
# analysis-specific data cleaning will be required for any given analysis.


# Note for TET data cleaning: Kaitlyn Petz ran through Calm Thinking cleaning code with R version 4.2.3 to see if 
# the code could be run on a newer version of R. Checks were implemented throughout the code to ensure that the steps were
# all happening correctly. Kaitlyn also checked the folders & contents on Desktop at the end of each script 
# and compared them to the folders & content created with version 4.0.3, to ensure all data was exported correctly. Kaitlyn
# will also make notes for any changes made to the Calm Thinking code for cleaning the TET data.


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

# Kaitlyn and Max ran into an issue on 12/12/23 where rlang and dplyr won't install, unsure why. 
# We can install those manually below. On 12/19/24, Kaitlyn is no longer having this issue, but
# will keep the code below in the case that others using the script have an issue.

#install.packages("rlang") 
#install.packages("dplyr") 

library(rlang) 
packageVersion("rlang") # Version 1.1.4

library(dplyr) 
packageVersion("dplyr") # Version 1.1.4

# ---------------------------------------------------------------------------- #
# Define functions used throughout script ----
# ---------------------------------------------------------------------------- #

# Define function to identify columns matching a grep pattern in a data frame.
# When used with lapply, function can be applied to all data frames in a list.

identify_columns <- function(df, grep_pattern) {
  df_colnames <- colnames(df)
  
  selected_columns <- grep(grep_pattern, df_colnames)
  if (length(selected_columns) != 0) {
    df_colnames[selected_columns]
  }
}

# ---------------------------------------------------------------------------- #
# Document data file names ----
# ---------------------------------------------------------------------------- #

# Obtain file names of raw and redacted CSV data files

if (dir.exists(paste0(wd_dir, "/data/1_raw_calm_full"))) {
  raw_data_dir_full <- paste0(wd_dir, "/data/1_raw_calm_full")
  raw_full_filenames <- 
    list.files(raw_data_dir_full, pattern = "*.csv", full.names = FALSE)
}

if (dir.exists(paste0(wd_dir, "/data/1_raw_calm_partial"))) {
  raw_data_dir_partial <- paste0(wd_dir, "/data/1_raw_calm_partial")
  raw_partial_filenames <- 
    list.files(raw_data_dir_partial, pattern = "*.csv", full.names = FALSE)
}

red_data_dir <- paste0(wd_dir, "/data/2_redacted")
red_filenames <- list.files(red_data_dir, pattern = "*.csv", full.names = FALSE)

## Check that there are the right number of redacted data files
length(red_filenames)==14

# Output file names to TXT

dir.create("./docs")

sink(file = "./docs/data_filenames.txt")

if (exists("raw_data_dir_full")) {
  cat("In './data/1_raw_calm_full'", "\n")
  cat("\n")
  print(raw_full_filenames, width = 80)
  cat("\n")
}

if (exists("raw_data_dir_partial")) {
  cat("In './data/1_raw_calm_partial'", "\n")
  cat("\n")
  print(raw_partial_filenames, width = 80)
  cat("\n")
}

cat("In './data/2_redacted'", "\n")
cat("\n")
print(red_filenames, width = 80)

sink()

# ---------------------------------------------------------------------------- #
# Import raw and redacted data ----
# ---------------------------------------------------------------------------- #

# Import raw and redacted CSV data files into lists. Obtain the full set of raw 
# data files if available; otherwise, obtain the partial set.

if (exists("raw_data_dir_full")) {
  raw_data_dir <- raw_data_dir_full
  raw_filenames <- raw_full_filenames
} else {
  raw_data_dir <- raw_data_dir_partial
  raw_filenames <- raw_partial_filenames
}

cat('Reading data files...','\n')
raw_dat <- lapply(paste0(raw_data_dir, "/", raw_filenames), read.csv)
red_dat <- lapply(paste0(red_data_dir, "/", red_filenames), read.csv)

## Check that the correct number of data files are imported
length(raw_dat)==67
length(red_dat)==14

# Name data tables in lists

split_char <- "-"
names(raw_dat) <- unlist(lapply(raw_filenames, 
                                function(x) {
                                  unlist(strsplit(x, 
                                                  split = split_char, 
                                                  fixed = FALSE))[1]
                                }))
names(red_dat) <- paste0(unlist(lapply(red_filenames, 
                                       function(x) {
                                         unlist(strsplit(x, 
                                                         split = split_char, 
                                                         fixed = FALSE))[1]
                                       })),
                         "-redacted")

# Report names of imported tables

cat("Imported raw tables:","\n")
names(raw_dat)
cat("Imported redacted tables:","\n")
names(red_dat)

# Create single list with redacted tables (when redacted version is available)
# and raw tables (when redacted version is unavailable). Alphabetize list.

dat <- c(red_dat,
         raw_dat[!(names(raw_dat) %in% sub("-redacted", "", names(red_dat)))])
dat <- dat[order(names(dat))]

cat("Selected tables:","\n")
names(dat)

## Check that the above steps performed correctly, i.e., that we took redacted when available
length(dat)==67

# Remove "-redacted" from table names, which rest of script requires

names(dat) <- sub("-redacted", "", names(dat))

# ---------------------------------------------------------------------------- #
# Part I. Database-Wide Data Cleaning ----
# ---------------------------------------------------------------------------- #

# The following code sections apply to data from every study in the "calm" SQL 
# database (i.e., Calm Thinking, TET, GIDI).

# ---------------------------------------------------------------------------- #
# Recode binary variable cells ----
# ---------------------------------------------------------------------------- #

# When Kaitlyn pulled the data, the binary variables in the dataset, which 
# should be "0" and "1" (for things like "over18", "admin", etc.), exported as "bits",  
# which is how they look in the actual coding of the data, so the zeros are now "b'\\x00'" 
# and the ones are now "b'\\x01'". The tech team told Kaitlyn on 9/27/23 that this can happen
# when pulling data, especially on Macs, and doesn't change anything about the data, just how
# it looks on our end. They said that we can just recode those values to be zeros and ones, 
# and everything will be the same. The code below recodes those values across all 67 dataframes. 

dat <- lapply(dat, function(x) {x[x=="b'\\x01'"] <- 1; return(x)})
dat <- lapply(dat, function(x) {x[x=="b'\\x00'"] <- 0; return(x)})

# ---------------------------------------------------------------------------- #
# Remove irrelevant tables ----
# ---------------------------------------------------------------------------- #

# The following tables are vestiges of earlier studies and not used in the Calm
# Thinking, TET, or GIDI studies and contain no data. They can be removed.

unused_tables <- c("coach_log", "data", "media", "missing_data_log", "stimuli", 
                  "trial", "verification_code")

# The "evaluation_how_learn" table was not used in the Calm Thinking, TET, or GIDI 
# studies because its "how_learn" item was moved to the demographics measure before 
# the Calm Thinking study launch. The item is called "ptp_reason" in the "demographics" 
# table. The "evaluation_how_learn" table contains no data and can be removed.

unused_tables <- c(unused_tables, "evaluation_how_learn")

# The following tables are vestiges of earlier studies and not used in the Calm
# Thinking, TET, or GIDI studies. Although they contain data, after removing admin 
# and test accounts they contain no data corresponding to a "participant_id" (the
# rows that have data have a blank "participant_id"). They can be removed.

unused_tables <- c(unused_tables, "imagery_prime", "impact_anxious_imagery")

# The following tables are used internally by the MindTrails system and contain
# no information relevant to individuals' participation in the Calm Thinking, TET, 
# or GIDI studies. Although they have data, they can be removed.

system_tables <- c("export_log", "id_gen", "import_log", "password_token",
                   "random_condition", "visit")

# Remove tables

dat <- dat[!(names(dat) %in% c(unused_tables, system_tables))]

## Check that the above steps performed correctly and that the new data only contains necessary tables
length(dat)==51

# ---------------------------------------------------------------------------- #
# Rename "id" columns in "participant" and "study" tables ----
# ---------------------------------------------------------------------------- #

# Except where noted below, in the "calm" database each table has an "id" 
# column that identifies the rows in that table. By convention, when a table 
# contains a column that corresponds to the "id" column of another table, the 
# derived column's name starts with the name of the table whose "id" column it 
# refers to and ends with "id". For example, "participant_id" refers to "id" in 
# the "participant" table, and "study_id" refers to "id" in the "study" table.

# Each participant has only one "id" in the "participant" table and only one 
# "id" in the "study" table, but these ids are not always the same. To make 
# indexing tables by participant simpler, we rename "id" in the "participant" 
# table to "participant_id" and rename "id" in the "study" table to "study_id". 
# We treat "participant_id" as the primary identifier for each participant;
# once a table is indexed by "participant_id", "study_id" is superfluous.

# The exception to the naming convention above is that for measures that have
# multiple tables (i.e., one main table and one or more companion tables that
# contain responses to items in which multiple response options were possible),
# the "id" variable in the companion table corresponds to the "id" variable in
# the main table (but is not named "main_table_id" as would be expected by the
# convention). For example, the "id" column in the "demographics_race" table
# corresponds to the "id" column in the "demographics" table.

# Define function to rename "id" in "participant" table to "participant_id"
# and to rename "id" in "study" table to "study_id".

rename_id_columns <- function(dat) {
  dat$participant <- dat$participant%>%select(participant_id = id, everything())
  dat$study <- dat$study%>%select(study_id = id, everything())
  return(dat)
}

# Run function

dat <- rename_id_columns(dat)


# Check that the above steps were executed properly, i.e., we changed those two columns
if("participant_id" %in% colnames(dat$participant)){cat("Yep, it's in there!\n");}
if("study_id" %in% colnames(dat$study)){cat("Yep, it's in there!\n");} 

# ---------------------------------------------------------------------------- #
# Add participant_id to all participant-specific tables ----
# ---------------------------------------------------------------------------- #

# Use function "identify_columns" (defined above) to identify columns containing 
# "id" in each table

lapply(dat, identify_columns, grep_pattern = "id")

# Add participant_id to "study" and "task_log" tables. These are participant-
# specific tables but are currently indexed by study_id, not participant_id.

participant_id_study_id_match <- 
  select(dat$participant, participant_id, study_id)

dat$study <- merge(dat$study,
                   participant_id_study_id_match,
                   by = "study_id", 
                   all.x = TRUE)

dat$task_log <- merge(dat$task_log,
                      participant_id_study_id_match,
                      by = "study_id", 
                      all.x = TRUE)

# Check that the above steps were executed properly, i.e., we added participant_id to study and task_log
if("participant_id" %in% colnames(dat$study)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$task_log)){cat("Yep, it's in there!\n");}

# Add "participant_id" to support tables, which are currently indexed by the 
# "id" column of the main table they support. First, for each main table,
# select its "participant_id" and "id" columns and list its support tables.

participant_id_demographics_id_match <- 
  select(dat$demographics, participant_id, id)

demographics_support_table <- "demographics_race"

participant_id_evaluation_id_match <- 
  select(dat$evaluation, participant_id, id)

evaluation_support_tables <- c("evaluation_coach_help_topics",
                               "evaluation_devices",
                               "evaluation_places",
                               "evaluation_preferred_platform",
                               "evaluation_reasons_control")

participant_id_mental_health_history_id_match <- 
  select(dat$mental_health_history, participant_id, id)

mental_health_history_support_tables <- c("mental_health_change_help",
                                          "mental_health_disorders",
                                          "mental_health_help",
                                          "mental_health_why_no_help")

participant_id_reasons_for_ending_id_match <- 
  select(dat$reasons_for_ending, participant_id, id)

reasons_for_ending_support_tables <- c("reasons_for_ending_change_med",
                                       "reasons_for_ending_device_use",
                                       "reasons_for_ending_location",
                                       "reasons_for_ending_reasons")

participant_id_session_review_id_match <- 
  select(dat$session_review, participant_id, id)

session_review_support_table <- "session_review_distractions"

# Now define a function that uses the selected "participant_id" and "id" 
# columns from each main table and the list of the main table's support 
# tables to add "participant_id" to each support table based on the "id"

add_participant_id <- function(dat, id_match, support_tables) {
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    if (names(dat)[[i]] %in% support_tables) {
      output[[i]] <- merge(dat[[i]], id_match, by = "id", all.x = TRUE)
    } else {
      output[[i]] <- dat[[i]]
    }
  }
  
  names(output) <- names(dat)
  return(output)
}

# Run the function for each set of support tables

dat <- add_participant_id(dat = dat,
                          id_match = participant_id_demographics_id_match,
                          support_tables = demographics_support_table)

dat <- add_participant_id(dat = dat,
                          id_match = participant_id_evaluation_id_match,
                          support_tables = evaluation_support_tables)

dat <- add_participant_id(dat = dat,
                          id_match = participant_id_mental_health_history_id_match,
                          support_tables = mental_health_history_support_tables)

dat <- add_participant_id(dat = dat,
                          id_match = participant_id_reasons_for_ending_id_match,
                          support_tables = reasons_for_ending_support_tables)

dat <- add_participant_id(dat = dat,
                          id_match = participant_id_session_review_id_match,
                          support_tables = session_review_support_table)

# Check that the above steps were executed properly, i.e., we added participant_id to all support tables
if("participant_id" %in% colnames(dat$demographics_race)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$evaluation_coach_help_topics)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$evaluation_devices)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$evaluation_places)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$evaluation_preferred_platform)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$evaluation_reasons_control)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$mental_health_change_help)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$mental_health_disorders)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$mental_health_help)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$mental_health_why_no_help)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$reasons_for_ending_change_med)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$reasons_for_ending_device_use)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$reasons_for_ending_location)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$reasons_for_ending_reasons)){cat("Yep, it's in there!\n");}
if("participant_id" %in% colnames(dat$session_review_distractions)){cat("Yep, it's in there!\n");}

# ---------------------------------------------------------------------------- #
# Correct test accounts ----
# ---------------------------------------------------------------------------- #

# Changes/Issues log on 1/28/21 indicates that participant 1097 should not be a
# test account. Recode "test_account" accordingly.

dat$participant[dat$participant$participant_id == 1097, ]$test_account <- 0

# Changes/Issues log on 4/16/21 indicates that participant 1663 should be a test 
# account. The account was created for participant 1537 because they were having
# technical issues, but the account was never used.

dat$participant[dat$participant$participant_id == 1663, ]$test_account <- 1

# ---------------------------------------------------------------------------- #
# Remove admin and test accounts ----
# ---------------------------------------------------------------------------- #

# Identify participant_ids that are admin or test accounts

admin_test_account_ids <- 
  dat$participant[dat$participant$admin == 1 |
                    dat$participant$test_account == 1, ]$participant_id

# Define function that removes in each table rows indexed by participant_ids of 
# admin and test accounts

remove_admin_test_accounts <- function(dat, admin_test_account_ids) {
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    if ("participant_id" %in% colnames(dat[[i]])) {
      output[[i]] <- subset(dat[[i]], 
                            !(participant_id %in% admin_test_account_ids))
    } else {
      output[[i]] <- dat[[i]]
    }
  }
  
  names(output) <- names(dat)
  return(output)
}

# Run function

dat <- remove_admin_test_accounts(dat, admin_test_account_ids)

## Check that no admin or test accounts remain (if this is the case, the output will read 'TRUE')
nrow(dat$participant[dat$participant$admin == 1 |dat$participant$test_account == 1, ])==0

# ---------------------------------------------------------------------------- #
# Label columns redacted by server ----
# ---------------------------------------------------------------------------- #

# Specify a character vector of columns ("<table_name>$<column_name>") whose values 
# should be labeled as "REDACTED_ON_DATA_SERVER". If no column is to be labeled as 
# such, specify NULL without quotes (i.e., "redacted_columns <- NULL").

# On 1/11/2021, Dan Funk said that the following columns are redacted but should
# not be given that they could be useful for analysis. These logical columns
# have all rows == NA.

unnecessarily_redacted_columns <- c("participant$coached_by_id",
                                    "participant$first_coaching_format")

# On 1/11/2021, Dan Funk said that the following columns are redacted and should 
# be. These character columns have all rows == "".

necessarily_redacted_columns <- c("participant$email", "participant$full_name",
                                  "participant$password")

# On 1/11/2021, Dan Funk said that the following columns are redacted and should 
# be. These numeric columns have all rows == NA.

necessarily_redacted_columns <- c(necessarily_redacted_columns, 
                                  "participant$phone", 
                                  "participant$password_token_id")

# On 1/11/2021, Dan Funk said that the following column is redacted and should 
# be. This logical column has all rows == NA.

necessarily_redacted_columns <- c(necessarily_redacted_columns,
                                  "participant$verification_code_id")

# On 1/13/2021, Dan Funk said that the following column is redacted and should 
# be. This character column has all rows == "US", which is its default value in 
# the Data Server.

necessarily_redacted_columns <- c(necessarily_redacted_columns, 
                                  "participant$award_country_code")

# On 1/13/2021, Dan Funk said that the following column is redacted and should 
# be. This numeric column has all rows == 0, which is its default value in the 
# Data Server.

necessarily_redacted_columns <- c(necessarily_redacted_columns, 
                                  "participant$attrition_risk")

# On 1/13/2021, Dan Funk said that the following columns are redacted and should 
# be. These integer columns have all rows == 0, which is their default value in 
# the Data Server.

necessarily_redacted_columns <- c(necessarily_redacted_columns, 
                                  "participant$blacklist",
                                  "participant$can_text_message", 
                                  "participant$coaching",
                                  "participant$verified", 
                                  "participant$wants_coaching")

# Collect all redacted columns

redacted_columns <- c(unnecessarily_redacted_columns, necessarily_redacted_columns)

## Check that we have the correct number of redacted columns
length(redacted_columns)==15

# Define function to convert redacted columns to characters and label as 
# "REDACTED_ON_DATA_SERVER"

label_redacted_columns <- function(dat, redacted_columns) {
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    output[[i]] <- dat[[i]]
    
    for (j in 1:length(dat[[i]])) {
      table_i_name <- names(dat[i])
      column_j_name <- names(dat[[i]][j])
      table_i_column_j_name <- paste0(table_i_name, "$", column_j_name)
      
      if (table_i_column_j_name %in% redacted_columns) {
        output[[i]][, column_j_name] <- as.character(output[[i]][, column_j_name])
        output[[i]][, column_j_name] <- "REDACTED_ON_DATA_SERVER"
      }
    }
  }
  
  names(output) <- names(dat)
  return(output)
}

# Run function

dat <- label_redacted_columns(dat, redacted_columns)

# Can check that the values in these columns have been replaced by checking the first row in the column, 
# as all values in the column should be changed to REDACTED_ON_DATA_SERVER
redacted_columns
dat$participant$coached_by_id[1]
dat$participant$first_coaching_format[1]
dat$participant$email[1]
dat$participant$full_name[1]
dat$participant$password[1]
dat$participant$phone[1]
dat$participant$password_token_id[1]
dat$participant$verification_code_id[1]
dat$participant$award_country_code[1]
dat$participant$attrition_risk[1]
dat$participant$blacklist[1]
dat$participant$can_text_message[1]
dat$participant$coaching[1]
dat$participant$verified[1]
dat$participant$wants_coaching[1]


# ---------------------------------------------------------------------------- #
# Remove irrelevant columns ----
# ---------------------------------------------------------------------------- #

# The "tag" columns in the following tables are not used in the Calm Thinking, TET, 
# or GIDI studies and contain no data. They can be removed.

unused_columns <- paste0(c("angular_training", "anxiety_identity", 
                           "anxiety_triggers", "assessing_program", 
                           "bbsiq", "cc", "coach_prompt", "comorbid", 
                           "covid19", "credibility", "dass21_as", 
                           "demographics", "evaluation", "gidi", "help_seeking",
                           "js_psych_trial", "mechanisms",
                           "mental_health_history", "oa", 
                           "return_intention", "rr", "session_review", 
                           "technology_use", "wellness"),
                         "$tag")

# The following "how_learn_other" columns in "evaluation" are not used in the 
# Calm Thinking, TET, or GIDI studies because the "how_learn_other" item was 
# moved to the demographics measure before Calm Thinking study launch. The item 
# is called "ptp_reason_other" in the "demographics" table. The two columns 
# below contain no data and can be removed.

unused_columns <- c(unused_columns, "evaluation$how_learn_other",
                    "evaluation$how_learn_other_link")

# The following columns are also not used in the Calm Thinking, TET, or GIDI 
# studies and contain no data. They can be removed.

unused_columns <- c(unused_columns, "action_log$action_value",
                    "angular_training$study",
                    "mental_health_history$other_help_text",
                    "participant$random_token",
                    "participant$return_date",
                    "reasons_for_ending$other_why_in_control",
                    "sms_log$type")

## Check that we have the correct number of unused columns
length(unused_columns)==33

# Define function to remove irrelevant columns

remove_columns <- function(dat, columns_to_remove) {
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    output[[i]] <- dat[[i]]
    
    for (j in 1:length(dat[[i]])) {
      table_i_name <- names(dat[i])
      column_j_name <- names(dat[[i]][j])
      table_i_column_j_name <- paste0(table_i_name, "$", column_j_name)
      
      if (table_i_column_j_name %in% columns_to_remove) {
        output[[i]] <- output[[i]][, !(names(output[[i]]) %in% column_j_name)]
      }
    }
  }
  
  names(output) <- names(dat)
  return(output)
}

# Specify a character vector of columns to be removed, with each column listed
# as "<table_name>$<column_name>" (e.g., "js_psych_trial$tag"). If no column is 
# to be removed, specify NULL without quotes (i.e., "columns_to_remove <- NULL").

# Unused columns defined above can be removed

columns_to_remove <- unused_columns

# Remove "over18" from "participant" table. Dan Funk said that 
# we moved this item to the DASS-21 page (and thus to "dass21_as") 
# and that the "over18" column in the "participant" table should be disregarded.

columns_to_remove <- c(columns_to_remove, "participant$over18")

# Run function

dat <- remove_columns(dat, columns_to_remove)

# Check that columns are successfully removed
columns_to_remove
if(!("tag" %in% colnames(dat$angular_training))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$anxiety_identity))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$anxiety_triggers))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$assessing_program))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$bbsiq))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$cc))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$coach_prompt))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$comorbid))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$covid19))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$credibility))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$dass21_as))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$demographics))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$evaluation))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$gidi))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$help_seeking))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$js_psych_trial))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$mechanisms))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$mental_health_history))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$oa))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$return_intention))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$rr))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$session_review))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$technology_use))){cat("No column found; success!\n");}
if(!("tag" %in% colnames(dat$wellness))){cat("No column found; success!\n");}
if(!("how_learn_other" %in% colnames(dat$evaluation))){cat("No column found; success!\n");}
if(!("how_learn_other_link" %in% colnames(dat$evaluation))){cat("No column found; success!\n");}
if(!("action_value" %in% colnames(dat$action_log))){cat("No column found; success!\n");}
if(!("other_help_text" %in% colnames(dat$mental_health_history))){cat("No column found; success!\n");}
if(!("study" %in% colnames(dat$angular_training))){cat("No column found; success!\n");}
if(!("random_token" %in% colnames(dat$participant))){cat("No column found; success!\n");}
if(!("other_why_in_control" %in% colnames(dat$reasons_for_ending))){cat("No column found; success!\n");}
if(!("return_date" %in% colnames(dat$participant))){cat("No column found; success!\n");}
if(!("type" %in% colnames(dat$sms_log))){cat("No column found; success!\n");}
if(!("over18" %in% colnames(dat$participant))){cat("No column found; success!\n");}

# ---------------------------------------------------------------------------- #
# Identify any remaining blank columns ----
# ---------------------------------------------------------------------------- #

# Define function to identify columns whose rows are all blank (interpreted by 
# R as NA) or, if column is of class type "character", whose rows are all "". 
# Do this after removing admin and test accounts because some columns may have 
# been used during testing but not during the study itself. If no columns are 
# blank besides those that are ignored in the search, nothing will be outputted.

find_blank_columns <- function(dat, ignored_columns) {
  for (i in 1:length(dat)) {
    for (j in 1:length(dat[[i]])) {
      table_i_name <- names(dat[i])
      column_j_name <- names(dat[[i]][j])
      table_i_column_j_name <- paste0(table_i_name, "$", column_j_name)
      
      if (!(table_i_column_j_name %in% ignored_columns)) {
        if (all(is.na(dat[[i]][[j]]))) {
          cat(paste0(table_i_column_j_name,
                     "     , class ", class(dat[[i]][[j]]), ",",
                     "     has all rows == NA", "\n"))
        } else if (all(dat[[i]][[j]] == "")) {
          cat(paste0(table_i_column_j_name,
                     "     , class ", class(dat[[i]][[j]]), ",",
                     '     has all rows == ""', "\n"))
        }
      }
    }
  }
}

# Specify a character vector of columns to be ignored, with each column listed
# as "<table_name>$<column_name>" (e.g., "js_psych_trial$tag"). If no column is 
# to be ignored, specify NULL without quotes (i.e., "ignored_columns <- NULL").

ignored_columns <- NULL

# Run function. If blank columns are identified, consider whether they need to
# be added (a) to the set of columns to be indicated as "REDACTED" (see above)
# or (b) to the set of irrelevant columns to be removed (see above).

find_blank_columns(dat, ignored_columns)

## Check that no blank columns were identified (ignored_columns should still be null if we did not
## identify any additional blank columns, so the output should read TRUE)
is.null(ignored_columns)

# ---------------------------------------------------------------------------- #
# Identify and recode time stamp and date columns ----
# ---------------------------------------------------------------------------- #

# Use function "identify_columns" (defined above) to identify columns containing 
# "date" in each table

lapply(dat, identify_columns, grep_pattern = "date")

# View structure of columns containing "date" in each table

view_date_str <- function(df, df_name) {
  print(paste0("Table: ", df_name))
  cat("\n")
  
  df_colnames <- colnames(df)
  date_columns <- grep("date", df_colnames)
  
  if (length(date_columns) != 0) {
    for (i in date_columns) {
      print(paste0(df_colnames[i]))
      str(df[, i])
      print(paste0("Number NA: ", sum(is.na(df[, i]))))
      print(paste0("Number blank: ", sum(df[, i] == "")))
      print(paste0("Number 555: ", sum(df[, i] == 555, na.rm = TRUE)))
      print("Number of characters: ")
      print(table(nchar(df[, i])))
    }
  } else {
    print('No columns containing "date" found.')
  }
  
  cat("----------")
  cat("\n")
}

invisible(mapply(view_date_str, df = dat, df_name = names(dat)))

# Note: "last_session_date" in "study" table is blank where "current_session" is 
# "preTest". Henry Behan said on 9/17/21 that this is expected.

table(dat$study[dat$study$last_session_date == "", "current_session"], 
      useNA = "always")

# Note: "last_login_date" in "participant" table is blank for participant 3659.
# This participant has no data in any tables besides "participant" and "study".
# Henry Behan said on 9/22/21 that this participant emailed the study team on 
# "2020-11-12 02:25:00 EST" saying they were eligible but had an issue creating 
# an account. An account was made manually by an admin; thus, we presumably have 
# screening data for them (indexed by "session_id") but cannot connect it to their
# "participant_id". The participant is considered officially enrolled in the TET 
# study; thus, this needs to be accounted for in the TET participant flow diagram.

dat$participant[dat$participant$last_login_date == "", "participant_id"]

# The following columns across tables are system-generated date and time stamps.
# Dan Funk said on 10/1/21 that all of these are in EST time zone (note: EST, or
# UTC - 5, all year, not "America/New York", which switches between EST and EDT).

system_date_time_cols <- c("date", "date_created", "date_sent", "date_submitted",
                           "last_login_date", "last_session_date",
                           "date_completed")

## Check that it is the right number of columns
length(system_date_time_cols)==7

# The following column in "return_intention" table is user-provided dates and 
# times. Dan Funk said on 9/24/21 that this data is collected in the user's 
# local time but converted to UTC when stored in the database.

user_date_time_cols <- "return_date"

# Define function to reformat system-generated time stamps and user-provided dates 
# and times and add time zone:

# Note: For the data pulls for TET/GIDI cleaning, the original function from the Calm Thinking cleaning script
# would not run, outputting "Error in as.POSIXlt.character(x, tz, ...) :character string is not in a 
# standard unambiguous format". This error stopped us from being able to convert the date/time columns
# to the correct formats and timezones, so filtering study data would not work properly - a large issue. 
# On 10/2/23, Mark Rucker identified that the issue was due to corrupted data on the first line of 
# js_psych_trial.csv. The new code below has the same functionality as the original code (format & tz), 
# but also automatically handles the problem and lets you know where the problem is. As of 10/4/23 we are
# unsure whether this is an issue we will run into with future data pulls, but the code below should
# address the issue and format dates as needed either way. 

posix_conversion <- function(table_name, target_colname, value) {
  
  #Specify time zone as "UTC" for user-provided "return_date" in 
  #"return_intention" and as "EST" for all system-generated 
  #time stamps. Specify nonstandard format to parse "date_sent" in 
  #"sms_log". Other columns are in standard format.
  
  if (table_name == "return_intention" & target_colname == "return_date") {
    return(as.POSIXct(value, tz = "UTC"))
  } else if (table_name == "sms_log" & target_colname == "date_sent") {
    return(as.POSIXct(value, tz = "EST", format = "%Y-%m-%d %H:%M:%S"))
  } else {
    return(as.POSIXct(value, tz = "EST"))
  }
}

recode_date_time_timezone <- function(dat) {
  for (i in 1:length(dat)) {
    table_name <- names(dat[i])
    colnames <- names(dat[[i]])
    target_colnames <- colnames[colnames %in% c(system_date_time_cols,
                                                user_date_time_cols)]

    if (length(target_colnames) != 0) {
     for (j in 1:length(target_colnames)) {
        #Create new variable for POSIXct values. Recode blanks as NA.

        POSIXct_colname <- paste0(target_colnames[j], "_as_POSIXct")

        dat[[i]][, POSIXct_colname] <- dat[[i]][, target_colnames[j]]
        dat[[i]][dat[[i]][, POSIXct_colname] == "", POSIXct_colname] <- NA

        #Find any corrupted data, let us know where it is, and address it.

        tryCatch({
          dat[[i]][,POSIXct_colname] <- posix_conversion(
            table_name,
            target_colnames[j], 
            dat[[i]][,POSIXct_colname]
          )}, error = function(err) {
            for (r in 1:nrow(dat[[i]])) {
              tryCatch({
                dat[[i]][r,POSIXct_colname] <- posix_conversion(
                  table_name,
                  target_colnames[j], 
                  dat[[i]][r,POSIXct_colname]
                )
              }, error = function(err) {
                dat[[i]][r,POSIXct_colname] <- ''
                cat(table_name,'[',r,',',POSIXct_colname,']',' had an improper date.\n')
              })
            }
        })
     }
    }
  }

 return(dat)
}

# Run function

dat <- recode_date_time_timezone(dat)

# As of 12/19/24 we see the output "js_psych_trial [ 1 , date_as_POSIXct ]  had an improper date." 
# Let's check it out. 

dat[["js_psych_trial"]][["date_as_POSIXct"]][1] #"0000-00-00 00:00:00"
dat[["js_psych_trial"]][1,] # All null/0 data, except we can see that it was participant 639


# We will remove this row, as the data is corrupt and not valid to use: 

nrow(dat[["js_psych_trial"]]) # 111474 rows

dat[["js_psych_trial"]] <- dat[["js_psych_trial"]][-1,]

nrow(dat[["js_psych_trial"]]) # 111473 rows - 1 row successfully removed


# We can now convert the "date_as_POSIXct" column of js_psych_trial to the proper format/timezone:

dat[["js_psych_trial"]][["date_as_POSIXct"]] <- as.POSIXct(dat[["js_psych_trial"]][["date_as_POSIXct"]], tz = "EST")


# We can see that the column was now successfully converted, as the values have "EST" assigned to them: 

dat[["js_psych_trial"]][["date_as_POSIXct"]]


# Create new variables for filtering data based on system-generated time stamps. In 
# most tables, the only system-generated time stamp is "date", but "js_psych_trial" 
# table also has "date_submitted". Other tables do not have "date" but have other 
# system-generated time stamps (i.e., "attrition_prediction" table has "date_created"; 
# "email_log", "error_log", and "sms_log" tables have "date_sent"; "gift_log" table
# has "date_created" and "date_sent"; "participant" table has "last_login_date";
# "study" table has "last_session_date"; "task_log" table has "date_completed"). 
# Given that some tables that have multiple system-generated time stamps, let 
# "system_date_time_earliest" and "system_date_time_latest" represent the earliest
# and latest time stamps, respectively, for each row in the table.

for (i in 1:length(dat)) {
  table_name <- names(dat[i])
  colnames <- names(dat[[i]])
  
  dat[[i]][, "system_date_time_earliest"] <- NA
  dat[[i]][, "system_date_time_latest"] <- NA
  
  if (table_name == "js_psych_trial") {
    dat[[i]][, "system_date_time_earliest"] <- min(dat[[i]][, "date_as_POSIXct"], 
                                                    dat[[i]][, "date_submitted_as_POSIXct"],
                                                    na.rm = TRUE)
    dat[[i]][, "system_date_time_latest"] <-   max(dat[[i]][, "date_as_POSIXct"], 
                                                    dat[[i]][, "date_submitted_as_POSIXct"],
                                                    na.rm = TRUE)
  } else if (table_name == "attrition_prediction") {
    dat[[i]][, "system_date_time_earliest"] <- dat[[i]][, "date_created_as_POSIXct"]
    dat[[i]][, "system_date_time_latest"] <-   dat[[i]][, "date_created_as_POSIXct"]
  } else if (table_name %in% c("email_log", "error_log", "sms_log")) {
    dat[[i]][, "system_date_time_earliest"] <- dat[[i]][, "date_sent_as_POSIXct"]
    dat[[i]][, "system_date_time_latest"] <-   dat[[i]][, "date_sent_as_POSIXct"]
  } else if (table_name == "gift_log") {
    dat[[i]][, "system_date_time_earliest"] <- min(dat[[i]][, "date_created_as_POSIXct"], 
                                                    dat[[i]][, "date_sent_as_POSIXct"],
                                                    na.rm = TRUE)
    dat[[i]][, "system_date_time_latest"] <-   max(dat[[i]][, "date_created_as_POSIXct"], 
                                                    dat[[i]][, "date_sent_as_POSIXct"],
                                                    na.rm = TRUE)
  } else if (table_name == "participant") {
    dat[[i]][, "system_date_time_earliest"] <- dat[[i]][, "last_login_date_as_POSIXct"]
    dat[[i]][, "system_date_time_latest"] <-   dat[[i]][, "last_login_date_as_POSIXct"]
  } else if (table_name == "study") {
    dat[[i]][, "system_date_time_earliest"] <- dat[[i]][, "last_session_date_as_POSIXct"]
    dat[[i]][, "system_date_time_latest"] <-   dat[[i]][, "last_session_date_as_POSIXct"]
  } else if (table_name == "task_log") {
    dat[[i]][, "system_date_time_earliest"] <- dat[[i]][, "date_completed_as_POSIXct"]
    dat[[i]][, "system_date_time_latest"] <-   dat[[i]][, "date_completed_as_POSIXct"]
  } else if ("date" %in% colnames) {
    dat[[i]][, "system_date_time_earliest"] <- dat[[i]][, "date_as_POSIXct"]
    dat[[i]][, "system_date_time_latest"] <-   dat[[i]][, "date_as_POSIXct"]
  }
}

# Check that the new columns have been created in the necessary tables and that the values of 
# the rows looks like the correct date/time format (YYY-MM-DD HH:MM:SS TZ).
dat$js_psych_trial$system_date_time_earliest[1:5]
dat$js_psych_trial$system_date_time_latest[1:5]
dat$attrition_prediction$system_date_time_earliest[1:5]
dat$attrition_prediction$system_date_time_latest[1:5]
dat$email_log$system_date_time_earliest[1:5]
dat$email_log$system_date_time_latest[1:5]
dat$error_log$system_date_time_earliest[1:5]
dat$error_log$system_date_time_latest[1:5]
dat$sms_log$system_date_time_earliest[1:5]
dat$sms_log$system_date_time_latest[1:5]
dat$gift_log$system_date_time_earliest[1:5]
dat$gift_log$system_date_time_latest[1:5]
dat$participant$system_date_time_earliest[1:5]
dat$participant$system_date_time_latest[1:5]  
dat$study$system_date_time_earliest[1:5] 
dat$study$system_date_time_latest[1:5] 
dat$task_log$system_date_time_earliest[1:5]
dat$task_log$system_date_time_latest[1:5]
# Just a note: NAs in these new columns are there because the original date/time
  # wasn't recorded - I'm not sure why, but that is how the raw data is so probably 
  # just not recorded on the site for some reason, but again not a cause for concern. 


# The following columns in the "covid19" table are participant-provided dates

user_date_cols <- c("symptoms_date", "test_antibody_date", "test_covid_date")

# Reformat these participant-provided dates so that they do not
# contain empty times, which were not assessed

dat$covid19$symptoms_date[dat$covid19$symptoms_date == ''] <- NA # Recode blanks as NA
dat[["covid19"]][["symptoms_date"]]=as.Date(dat$covid19$symptoms_date) 

dat$covid19$test_antibody_date[dat$covid19$test_antibody_date == ''] <- NA # Recode blanks as NA
dat[["covid19"]][["test_antibody_date"]]=as.Date(dat$covid19$test_antibody_date)

dat$covid19$test_covid_date[dat$covid19$test_covid_date == ''] <- NA # Recode blanks as NA
dat[["covid19"]][["test_covid_date"]]=as.Date(dat$covid19$test_covid_date)

# Manually check that the columns look like they have been correctly changed. This would mean
# that all entries in these columns are either NA, because we changed all blank entries
# to be NAs, or are DATES ONLY formatted as YYYY/MM/DD, because we removed the TIMESTAMP from 
# these entries and thus they should only have date. 
dat[["covid19"]][["symptoms_date"]]
dat[["covid19"]][["test_antibody_date"]]
dat[["covid19"]][["test_covid_date"]]


# The following "covid19" columns indicate whether the participant preferred not 
# to provide a date. Do not reformat these as dates.

covid19_user_date_pna_cols <- c("symptoms_date_no_answer", 
                                "test_antibody_date_no_answer",
                                "test_covid_date_no_answer")

# ---------------------------------------------------------------------------- #
# Identify and rename session-related columns ----
# ---------------------------------------------------------------------------- #

# Use function "identify_columns" (defined above) to identify columns containing 
# "session" in each table

lapply(dat, identify_columns, grep_pattern = "session")

# View structure of columns containing "session" in each table

view_session_str <- function(dat) {
  for (i in 1:length(dat)) {
    print(paste0("Table: ", names(dat[i])))
    cat("\n")
    
    colnames <- names(dat[[i]])
    session_colnames <- colnames[grep("session", colnames)]
    
    if (length(session_colnames) != 0) {
      for (j in 1:length(session_colnames)) {
        session_colname <- session_colnames[j]
        session_colname_class <- class(dat[[i]][, session_colname])
        
        print(paste0(session_colname))
        print(paste0("Class: ", session_colname_class))
        
        if (length(unique(dat[[i]][, session_colname])) > 20) {
          print("First 20 unique levels: ")
          print(unique(dat[[i]][, session_colname])[1:20])
        } else {
          print("All unique levels: ")
          print(unique(dat[[i]][, session_colname]))
        }
        
        print(paste0("Number NA: ", sum(is.na(dat[[i]][, session_colname]))))
        
        if (!("POSIXct" %in% session_colname_class)) {
          print(paste0("Number blank: ", sum(dat[[i]][, session_colname] == "")))
          print(paste0("Number 555: ", sum(dat[[i]][, session_colname] == 555,
                                           na.rm = TRUE)))
        }
        
        cat("\n")
      }
    } else {
      print('No columns containing "session" found.')
      cat("\n")
    }
    
    cat("----------")
    cat("\n", "\n")
  }
}

view_session_str(dat)

# Rename selected session-related columns to clarify conflated content of some
# columns and to enable consistent naming (i.e., "session_only") across tables
# for columns that contain only session information

  # Given that "session" column in "dass21_as" and "oa" tables contains both
  # session information and eligibility status, rename column to reflect this.
  # Also create new column "session_only" with "ELIGIBLE" and "" entries of
  # original "session" column recoded as "Eligibility" (to reflect that these
  # entries were collected at the eligibility screener time point.

  table(dat$dass21_as$session)
  table(dat$oa$session)

  # Given that "session" column in "angular_training" table contains both
  # session information and task-related information (i.e., "flexible_thinking",
  # "Recognition Ratings"), rename column to reflect this.

  table(dat$angular_training$session)

  # Given that "session_name" column in "gift_log" table contains both session
  # information and an indicator of whether an admin awarded the gift card (i.e.,
  # "AdminAwarded"), rename column to reflect this.

  table(dat$gift_log$session_name)
  
  # Rename remaining "session_name" columns (in "action_log" and "task_log"
  # tables) and remaining "session" columns to "session_only" to reflect that
  # they contain only session information. Do not rename "current_session"
  # column of "study" table because "current_session" does not index entries
  # within participants; rather, it reflects participants' current sessions.
  
  # Note: The resulting "session_only" column contains values of "COMPLETE" in
  # some tables (i.e., "action_log", "email_log") but not others (Henry Behan 
  # said on 9/14/21 that the "task_log" table was not designed to record values 
  # of "COMPLETE" in the original "session" column). Also, although "task_log"
  # table contains entries at Eligibility, "action_log" table does not; Henry 
  # Behan said on 9/13/21 said that "action_log" table does not record data 
  # until the participant has created an account.
  
for (i in 1:length(dat)) {
  if (names(dat[i]) %in% c("dass21_as", "oa")) {
    names(dat[[i]])[names(dat[[i]]) == "session"] <- "session_and_eligibility_status"
    
    dat[[i]][, "session_only"] <- dat[[i]][, "session_and_eligibility_status"]
    dat[[i]][dat[[i]][, "session_only"] %in% c("ELIGIBLE", ""), 
                "session_only"] <- "Eligibility"
  } else if (names(dat[i]) == "angular_training") {
    names(dat[[i]])[names(dat[[i]]) == "session"] <- "session_and_task_info"
  } else if (names(dat[i]) == "gift_log") {
    names(dat[[i]])[names(dat[[i]]) == "session_name"] <- "session_and_admin_awarded_info"
  } else if (names(dat[i]) %in% c("action_log", "task_log")) {
    names(dat[[i]])[names(dat[[i]]) == "session_name"] <- "session_only"
  } else if ("session" %in% names(dat[[i]])) {
    names(dat[[i]])[names(dat[[i]]) == "session"] <- "session_only"
  }
}
  
# Check that the above columns were created or renamed. 
if("session_and_eligibility_status" %in% colnames(dat$dass21_as)){cat("Yep, it's in there!\n");}
if("session_and_eligibility_status" %in% colnames(dat$oa)){cat("Yep, it's in there!\n");}
if("session_only" %in% colnames(dat$oa)){cat("Yep, it's in there!\n");}
if("session_and_task_info" %in% colnames(dat$angular_training)){cat("Yep, it's in there!\n");}
if("session_and_admin_awarded_info" %in% colnames(dat$gift_log)){cat("Yep, it's in there!\n");}
if("session_only" %in% colnames(dat$action_log)){cat("Yep, it's in there!\n");}
if("session_only" %in% colnames(dat$task_log)){cat("Yep, it's in there!\n");}


# ---------------------------------------------------------------------------- #
# Check for repeated columns across tables ----
# ---------------------------------------------------------------------------- #

# Define function that identifies column names that are repeated across tables.
# This is used to identify potential columns to check as to whether their values
# are the same for a given "participant_id" across tables.

find_repeated_column_names <- function(dat, ignored_columns) {
  for (i in 1:length(dat)) {
    for (j in 1:length(dat[[i]])) {
      if (!(names(dat[[i]][j]) %in% ignored_columns)) {
        for (k in 1:length(dat)) {
          if ((i != k) &
              names(dat[[i]][j]) %in% names(dat[[k]])) {
            print(paste0(names(dat[i]), "$", names(dat[[i]][j]),
                         "     is also in     ", names(dat[k])))
          }
        }
      }
    }
  }
}

# Define system-related columns to be ignored. Note: The meanings and possible 
# values of some of these columns differ across tables.

key_columns <- c("participant_id", "study_id", "session_id", "id", "X")
raw_timepoint_columns <- c("session", "session_name", "tag")
computed_timepoint_columns <- c("session_and_eligibility_status", "session_only")
raw_date_columns <- c("date", "date_created", "date_sent")
computed_date_columns <- c("date_as_POSIXct", "date_created_as_POSIXct",
                           "date_sent_as_POSIXct",
                           "system_date_time_earliest", "system_date_time_latest")
duration_columns <- c("time_on_page")
log_columns <- c("device", "exception", "successful", "task_name")

# Define other columns that have the same names across the indicated tables but 
# that have different meanings or possible values

# "receive_gift_cards" in "participant" means that the participant is eligible
# to receive gift cards (i.e., has supplied and verified their phone number),
# whereas the same column in "study" means that the participant is assigned to
# a study condition that will be awarded gift cards.

participant_study_columns <- "receive_gift_cards"

# "conditioning" in "angular_training" table may not always correspond with 
# "conditioning" in "study" table where "session" in "angular_training" table
# matches "current_session" in "study" table due to how "current_session" is
# defined in "study" table. See the study-specific data cleaning section "Check 
# 'conditioning' values in 'angular_training' and 'study' tables" below for
# more information about this and related issues.

angular_training_study_columns <- "conditioning"

# "js_psych_trial" contains user activity for the Recognition Ratings measure
# until early July 2020, whereas "angular_training" contains user activity for 
# the Recognition Ratings measure after that. In addition, "angular_training" 
# contains all user activity for training. Because the "js_psych_trial" and
# "angular_training" tables represent different ways of tracking user activity, 
# their shared column names are not necessarily comparable.

js_psych_trial_angular_training_columns <- c("button_pressed", "correct", "rt", 
                                             "rt_first_react", "stimulus", 
                                             "time_elapsed", "trial_type")

# The following shared column names represent different items across tables.

session_review_evaluation_columns <- "distracted"

session_review_reasons_for_ending_columns <- "location"

evaluation_reasons_for_ending_columns <- c("easy", "focused", "helpful", 
                                           "interest", "privacy",
                                           "understand_training")

reasons_for_ending_covid19_columns <- "work"

anxiety_triggers_covid19_columns <- "thoughts"

# "timezone" in "participant" is the timezone gleaned from the participant's web
# browser and serves as the default timezone presented in the "return_intention"
# measure. However, in the "return_intention" measure participants can change the
# default timezone, giving "timezone" in "return_intention" a different meaning.

participant_return_intention_columns <- "timezone"

# Collect all columns to be ignored

ignored_columns <- c(key_columns, 
                     raw_timepoint_columns, computed_timepoint_columns,
                     raw_date_columns, computed_date_columns,
                     duration_columns, log_columns,
                     participant_study_columns,
                     angular_training_study_columns,
                     js_psych_trial_angular_training_columns,
                     session_review_evaluation_columns,
                     session_review_reasons_for_ending_columns,
                     evaluation_reasons_for_ending_columns,
                     reasons_for_ending_covid19_columns,
                     anxiety_triggers_covid19_columns,
                     participant_return_intention_columns)

## Check that we have the correct number of columns 
length(ignored_columns)==43

# Run function

find_repeated_column_names(dat, ignored_columns)

# As long as the function ran above has no output, this means that there are no repeated columns. 

# ---------------------------------------------------------------------------- #
# Correct study extensions ----
# ---------------------------------------------------------------------------- #

# Participants 2004 and 2005 enrolled in the Calm Thinking study and were assigned 
# to a Calm Thinking condition but were given a TET study extension due to a bug at 
# launch of the TET study. According to Dan Funk, the "study_extension" field was 
# not properly being passed through to the Data Server. This was fixed on 4/7/2020, 
# but the "study_extension" for these participants needs to be changed back to "".

specialIDs <- c(2004, 2005)

if (all(dat$study[dat$study$participant_id %in% 
                    specialIDs, ]$study_extension == "")) {
  print("Study extension for special IDs already corrected in server.")
} else {
  dat$study[dat$study$participant_id %in%
              specialIDs, ]$study_extension <- ""
}

# Check that participant's study extensions are ""
dat$study$study_extension[dat$study$participant_id == 2004]
dat$study$study_extension[dat$study$participant_id == 2005]

# note that can also check this by viewing the dataframe (View(dat$study))

# ---------------------------------------------------------------------------- #
# Part II. Filter Data for Desired Study ----
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Specify desired study ----
# ---------------------------------------------------------------------------- #

# Specify desired study ("Calm" for Calm Thinking study, "TET" for TET study,
# "GIDI" for GIDI study)

# If looking exclusively at TET participants, use the variable below: 
#study_name <- "TET"

# If looking exclusively at GIDI participants, use the variable below: 
#study_name <- "GIDI"

# If looking at both TET and GIDI participants, use the variable below: 
study_name <- "TET & GIDI"

# ---------------------------------------------------------------------------- #
# Define enrollment period and participant_ids ----
# ---------------------------------------------------------------------------- #

# Define function that gets open/close dates for official enrollment period for 
# desired study. The enrollment period is needed to filter eligibility screenings, 
# which are not indexed by "participant_id" (participant_ids are created only for 
# eligible participants who create an account).

# Specify enrollment open/close dates using "YYYY-MM-DD HH:MM:SS". When exact time 
# is unknown, use "00:00:00" for the time to specify midnight.

# Specify timezone for study team's location based on the IANA Time Zone database 
# (i.e., "America/New_York", not "EDT" or "EST", which can be ambiguous). See 
# https://www.iana.org/time-zones, https://data.iana.org/time-zones/tz-link.html, 
# and timezones() in R documentation for more details.

# Note: the MT wiki lists 4/2/2020 as the TET start date, which is different from what's listed earlier in the 
# cleaning scripts, 4/7/2020. We're using the earlier start date to capture as many participants as possible. 

# TET Study End: Importantly, we only have reliably protected and cleaned data up to October 4, 2023, the last 
    # time the data was pulled from the server before things started shutting down. In this script, we will set
    # the TET close date as this date, the date of the last reliable TET data pull, as no data past this date will 
    # exist in the reliable dataset and these scripts should likely not be run on the data collected past October 2023. 

get_enroll_dates <- function(study_name) {
  if (study_name == "Calm") {
    official_enroll_open_date <-  as.POSIXct("2019-03-18 17:00:00", tz = "America/New_York")
    official_enroll_close_date <- as.POSIXct("2020-04-06 23:59:00", tz = "America/New_York")
  } else if (study_name == "TET") {
    official_enroll_open_date <-  as.POSIXct("2020-04-02 00:00:00", tz = "America/New_York")
    official_enroll_close_date <- as.POSIXct("2023-10-04 00:00:00", tz = "America/New_York")
  } else if (study_name == "GIDI") {
    official_enroll_open_date <-  as.POSIXct("2020-07-10 13:00:00", tz = "America/New_York")
    official_enroll_close_date <- as.POSIXct("2020-12-12 23:59:00", tz = "America/New_York")
  } else if (study_name == "TET & GIDI") {
    official_enroll_open_date <-  as.POSIXct("2020-04-02 00:00:00", tz = "America/New_York")
    official_enroll_close_date <- as.POSIXct("2025-02-08 00:00:00", tz = "America/New_York")
  }
  official_enroll_dates <- list(open = official_enroll_open_date,
                                close = official_enroll_close_date)
  return(official_enroll_dates)
}

# Define function that gets participant_ids for desired study

get_participant_ids <- function(dat, study_name) {
  if (study_name == "Calm") {
    participant_ids <- dat$study[dat$study$study_extension == "", "participant_id"]
  } else if (study_name == "TET") {
    participant_ids <- dat$study[dat$study$study_extension == "TET", "participant_id"]
  } else if (study_name == "GIDI") {
    participant_ids <- dat$study[dat$study$study_extension == "GIDI", "participant_id"]
  } else if (study_name == "TET & GIDI") {
    participant_ids <- dat$study[dat$study$study_extension == "GIDI" | dat$study$study_extension == "TET", "participant_id"]
  }
  return(participant_ids)
}

# ---------------------------------------------------------------------------- #
# Filter all data ----
# ---------------------------------------------------------------------------- #

# Define function that filters all data for desired study. Use official enrollment
# period to filter eligibility screenings (which excludes screenings during any soft
# launch period). Use participant_ids to filter other tables. Note that "gidi" table
# was not used in Calm Thinking study and that "condition_assignment_settings" table, 
# for which "participant_id" is irrelevant, is retained only for Calm Thinking study; 
# it is not used in TET or GIDI studies.

filter_all_data <- function(dat, study_name) {
  official_enroll_dates <- get_enroll_dates(study_name)
  participant_ids <- get_participant_ids(dat, study_name)
  
  if (study_name == "Calm") {
    screening_tbls <- "dass21_as"
    irrelevant_tbls <- "gidi"
  } else if (study_name %in% c("TET", "GIDI", "TET & GIDI")) {
    screening_tbls <- c("dass21_as", "oa")
    irrelevant_tbls <- "condition_assignment_settings"
  }
  
  dat <- dat[!(names(dat) %in% irrelevant_tbls)]
  
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    if (names(dat[i]) %in% screening_tbls) {
      if (!is.na(official_enroll_dates$close)) {
        output[[i]] <- 
          dat[[i]][(dat[[i]][, "session_only"] == "Eligibility" &
                      dat[[i]][, "date_as_POSIXct"] >= official_enroll_dates$open &
                      dat[[i]][, "date_as_POSIXct"] <= official_enroll_dates$close) |
                     dat[[i]][, "participant_id"] %in% participant_ids, ]
      } else if (is.na(official_enroll_dates$close)) {
        output[[i]] <- 
          dat[[i]][(dat[[i]][, "session_only"] == "Eligibility" &
                      dat[[i]][, "date_as_POSIXct"] >= official_enroll_dates$open) |
                     dat[[i]][, "participant_id"] %in% participant_ids, ]
      }
    } else if ("participant_id" %in% names(dat[[i]])) {
      output[[i]] <- dat[[i]][dat[[i]][, "participant_id"] %in% participant_ids, ]
    } else {
      output[[i]] <- dat[[i]]
    }
  }

  names(output) <- names(dat)
  return(output)
}

# Run function

dat <- filter_all_data(dat, study_name)

# Note: Warnings "In check_tzones(e1, e2) : 'tzone' attributes are inconsistent" 
# are expected and OK because timezone was specified as "America/New_York" for 
# enrollment open/close dates but as "EST" for system-generated timestamps

attr(get_enroll_dates(study_name)$open, "tzone") # Should be America/New_York
attr(get_enroll_dates(study_name)$close, "tzone") # Should be NULL if you list the TET close date as NA (since study is
                                                  # still running as of writing this script); Should be America/New_York
                                                  # if you set the close date as the date on which data was pulled
attr(dat$dass21_as$date_as_POSIXct, "tzone") # Should be EST


# ---------------------------------------------------------------------------- #
# Part III. TET/GIDI Study-Specific Data Cleaning ----
# ---------------------------------------------------------------------------- #

# The following code sections are specific to data for the TET/GIDI studies. 

# ---------------------------------------------------------------------------- #
# Notes ----
# ---------------------------------------------------------------------------- #

# "action_log" table has no data prior to 9/10/2020 because during the period it
# was implemented (8/28/2019 to 10/18/2019) it had been collecting more data than 
# intended; therefore, the data were deleted (see entries in Changes/Issues log on 
# 8/28/2019, 10/18/2019). Data collection seems to have resumed on 9/8/2020 (see 
# entry in Changes/Issues log on 9/8/2020).

# "covid19" table has no data prior to 4/23/2020. Some participants may not have completed
# this questionnaire being that launch was early April 2020. 

# ---------------------------------------------------------------------------- #
# Recode "coronavirus" column of "anxiety_triggers" table ----
# ---------------------------------------------------------------------------- #

# "coronavirus" column of "anxiety_triggers" table indicates an item that launched on 
# 4/4/2020 just for TET participants. If TET launched on 4/2/2020, some participants may not have 
# completed this item. Recode the 0 and 999 values (which indicate the item was not assessed) as NA.

dat$anxiety_triggers[dat$anxiety_triggers$coronavirus %in% c(0, 999), 
                     "coronavirus"] <- NA


# ---------------------------------------------------------------------------- #
# Exclude participants from other studies ----
# ---------------------------------------------------------------------------- #

# Though we have already filtered for just TET study participants, some participants may be
# mis-labeled as TET, so we will also be sure to remove the participants from other studies by ID number.

# Remove all early MT Movement participants - ID numbers were provided by Dr. Jessie Gibson on 9/6/23

# Define function that removes in each table rows indexed by participant_ids of 
# MT movement participants

movement_ids <- c(5376,5365,5379,5396,5398,5393,5392,5432,5391,5395,5446,5408,5413,5436,5433,5441,5424,5420,4701,
                  4702,4815,4791,4840,4855,4849,4854,4875)

remove_movement_ps <- function(dat, movement_ids) {
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    if ("participant_id" %in% colnames(dat[[i]])) {
      output[[i]] <- subset(dat[[i]], 
                            !(participant_id %in% movement_ids))
    } else {
      output[[i]] <- dat[[i]]
    }
  }
  
  names(output) <- names(dat)
  return(output)
}

# Run function

dat <- remove_movement_ps(dat, movement_ids)

## Check that no movement IDs remain
nrow(dat$participant[dat$participant$participant_id %in% movement_ids, ])==0

# Remove all GIDI participants - ID numbers were provided by Max Larrazabal on 9/12/23

# NOTE: Skip section below if you are looking at GIDI participants, or TET & GIDI
# combined - this should only be used if looking exclusively at TET participants. 

# Beginning of section to skip
gidi_ids=c("2161", "2210", "2211", "2223", "2232", "2268", "2270", "2273", 
           "2274", "2276", "2280", "2282", "2285", "2286", "2287", "2294", 
           "2295", "2300", "2302", "2304", "2305", "2308", "2309", "2310", 
           "2315", "2316", "2317", "2323", "2324", "2325", "2327", "2328", 
           "2329", "2332", "2335", "2337", "2339", "2345", "2346", "2350", 
           "2351", "2352", "2353", "2357", "2359", "2363", "2365", "2368", 
           "2369", "2370", "2371", "2372", "2374", "2376", "2378", "2380", 
           "2383", "2384", "2387", "2391", "2396", "2400", "2401", "2403", 
           "2404", "2405", "2407", "2411", "2412", "2415", "2416", "2422", 
           "2423", "2426", "2427", "2429", "2430", "2431", "2433", "2437", 
           "2439", "2441", "2444", "2446", "2447", "2448", "2449", "2450", 
           "2456", "2459", "2460", "2461", "2463", "2464", "2465", "2466", 
           "2467", "2469", "2470", "2471", "2472", "2473", "2476", "2477", 
           "2478", "2479", "2480", "2481", "2482", "2484", "2488", "2493", 
           "2497", "2503", "2504", "2506", "2509", "2511", "2514", "2515", 
           "2520", "2522", "2523", "2524", "2526", "2527", "2528", "2529", 
           "2531", "2532", "2533", "2536", "2538", "2539", "2541", "2542", 
           "2544", "2547", "2548", "2552", "2553", "2555", "2556", "2558", 
           "2559", "2565", "2566", "2569", "2576", "2577", "2582", "2586", 
           "2587", "2599", "2600", "2602", "2603", "2604", "2606", "2608", 
           "2611", "2613", "2615", "2617", "2618", "2619", "2620", "2623", 
           "2627", "2629", "2630", "2632", "2633", "2634", "2635", "2637", 
           "2638", "2642", "2643", "2644", "2645", "2647", "2649", "2650", 
           "2652", "2653", "2654", "2656", "2662", "2664", "2665", "2666", 
           "2667", "2668", "2669", "2672", "2674", "2676", "2677", "2678", 
           "2681", "2682", "2683", "2685", "2686", "2687", "2691", "2696", 
           "2697", "2702", "2704", "2705", "2710", "2712", "2713", "2717", 
           "2720", "2731", "2733", "2734", "2737", "2738", "2739", "2742", 
           "2748", "2750", "2751", "2752", "2753", "2754", "2756", "2757", 
           "2758", "2759", "2764", "2765", "2766", "2767", "2768", "2769", 
           "2770", "2773", "2774", "2776", "2782", "2785", "2786", "2792", 
           "2798", "2800", "2805", "2810", "2811", "2812", "2813", "2818", 
           "2821", "2822", "2823", "2824", "2825", "2826", "2827", "2828", 
           "2829", "2830", "2833", "2834", "2836", "2837", "2839", "2844", 
           "2845", "2846", "2848", "2851", "2858", "2860", "2862", "2863", 
           "2864", "2865", "2870", "2871", "2873", "2875", "2876", "2877", 
           "2882", "2883", "2884", "2886", "2888", "2889", "2890", "2891", 
           "2892", "2893", "2900", "2903", "2905", "2908", "2910", "2911", 
           "2918", "2919", "2921", "2922", "2923", "2924", "2926", "2927", 
           "2929", "2932", "2933", "2935", "2938", "2940", "2941", "2943", 
           "2944", "2945", "2947", "2949", "2951", "2955", "2958", "2961", 
           "2964", "2965", "2970", "2974", "2975", "2976", "2978", "2981", 
           "2982", "2983", "2986", "2989", "2990", "2993", "2997", "3004", 
           "3005", "3006", "3012", "3014", "3015", "3016", "3020", "3022", 
           "3024", "3025", "3033", "3042", "3045", "3047", "3049", "3052", 
           "3053", "3059", "3060", "3062", "3063", "3064", "3065", "3066", 
           "3069", "3072", "3073", "3074", "3079", "3083", "3085", "3087", 
           "3089", "3092", "3093", "3096", "3097", "3100", "3106", "3108", 
           "3109", "3111", "3112", "3118", "3122", "3123", "3124", "3129", 
           "3131", "3132", "3133", "3134", "3136", "3139", "3145", "3150", 
           "3151", "3155", "3159", "3162", "3171", "3173", "3175", "3177", 
           "3178", "3182", "3183", "3184", "3189", "3192", "3193", "3194", 
           "3198", "3199", "3201", "3212", "3213", "3215", "3219", "3223", 
           "3225", "3226", "3231", "3232", "3234", "3246", "3257", "3258", 
           "3260", "3265", "3266", "3267", "3269", "3273", "3275", "3278", 
           "3282", "3285", "3288", "3291", "3296", "3297", "3298", "3301", 
           "3302", "3308", "3310", "3316", "3318", "3320", "3322", "3325", 
           "3327", "3328", "3331", "3332", "3334", "3336", "3337", "3340", 
           "3341", "3342", "3345", "3347", "3348", "3349", "3351", "3355", 
           "3357", "3360", "3361", "3364", "3365", "3369", "3371", "3374", 
           "3377", "3380", "3384", "3389", "3394", "3396", "3399", "3400", 
           "3403", "3405", "3409", "3411", "3413", "3415", "3416", "3418", 
           "3419", "3420", "3422", "3425", "3429", "3431", "3435", "3437", 
           "3438", "3441", "3443", "3445", "3447", "3456", "3460", "3462", 
           "3467", "3470", "3472", "3475", "3484", "3487", "3491", "3493", 
           "3500", "3501", "3502", "3503", "3505", "3507", "3508", "3510", 
           "3520", "3521", "3522", "3523", "3524", "3525", "3529", "3537", 
           "3548", "3552", "3553", "3566", "3573", "3575", "3579", "3580", 
           "3588", "3592", "3597", "3599", "3601", "3602", "3605", "3606", 
           "3608", "3609", "3612", "3618", "3620", "3623", "3625", "3627", 
           "3628", "3634", "3640", "3644", "3645", "3651", "3652", "3655", 
           "3657", "3658", "3660", "3663", "3664", "3669", "3670", "3672", 
           "3674", "3675", "3676", "3685", "3686", "3687", "3689", "3690", 
           "3693", "3694", "3698", "3701", "3705", "3706", "3708", "3709", 
           "3710", "3712", "3718", "3719", "3720", "3722", "3723", "3726", 
           "3728", "3730", "3731", "3732", "3733", "3737", "3739", "3741", 
           "3743")

# Define function that removes in each table rows indexed by participant_ids of 
# GIDI participants

remove_gidi_ps <- function(dat, gidi_ids) {
  output <- vector("list", length(dat))
  
  for (i in 1:length(dat)) {
    if ("participant_id" %in% colnames(dat[[i]])) {
      output[[i]] <- subset(dat[[i]], 
                            !(participant_id %in% gidi_ids))
    } else {
      output[[i]] <- dat[[i]]
    }
  }
  
  names(output) <- names(dat)
  return(output)
}

# Run function

dat <- remove_gidi_ps(dat, gidi_ids)

## Check that no GIDI IDs remain
nrow(dat$participant[dat$participant$participant_id %in% gidi_ids, ])==0

# End of section to skip

# ---------------------------------------------------------------------------- #
# Remove participant IDs associated with post-study data ----
# ---------------------------------------------------------------------------- #

# Participants in control conditions are given the option to enroll in active MindTrails conditions after 
# their study period is complete. When we switch a participant from one condition to another, they
# get assigned a new participant ID. We want to make sure to remove the participant IDs associate with 
# post-study data/the ID they get after switching assignments, as that is technically no longer part of
# the study, but just follow-up intervention for the participants who request it, so we don't want to analyze it. 
# To find these IDs, you can search the MT admin site for "migrated": if a participant switches conditions, 
# they will have one study ID associated with their email address containing "migrated" and a string of numbers/letters, 
# indicating that we migrated their account to a new study ID, and one study ID associated with their regular email.
# After finding these participants, you can use the email minus the migrated/letters/numbers, then search for the
# individual emails that have been migrated, and find the participants' post-study IDs, which are associated
# with their plain email. The email/PID with "migrated" in it contains the actual study data; the clean email
# contains the post-study data. So, we want to remove the participant IDs associated with those clean emails. 
# These accounts may already be removed in the test accounts section above, but we will double check 
# below, and remove the IDs that were missed. 

# This section was last updated in October 2023. 

# Participant 5276 was in a control condition, and their post-study data is associated with
# ID number 5473. 
nrow(dat$participant[dat$participant$participant_id==5473, ])==0 # If properly removed, this should be TRUE!

# Participant 5503 was in a control condition, and their post-study data is associated with
# ID number 5610. 
nrow(dat$participant[dat$participant$participant_id==5610, ])==0 # If properly removed, this should be TRUE!


# ---------------------------------------------------------------------------- #
# Check for duplicate participant IDs ----
# ---------------------------------------------------------------------------- #

# Double check that we don't have any repeat participant IDs
   
length(dat$participant$participant_id) 
length(unique(dat$participant$participant_id))
# The 2 lengths should match.

# ---------------------------------------------------------------------------- #
# Obtain time of last collected data ----
# ---------------------------------------------------------------------------- #

# Identify latest value for system-generated time stamps across all tables. Use
# "EST" because all system-generated time stamps are stored as "EST".

output <- data.frame(table = rep(NA, length(dat)),
                     max_system_date_time_latest = rep(NA, length(dat)))
output$max_system_date_time_latest <- as.POSIXct(output$max_system_date_time_latest,
                                                 tz = "EST")

for (i in 1:length(dat)) {
  output$table[i] <- names(dat[i])
  
  if ("system_date_time_latest" %in% names(dat[[i]]) &
      !(all(is.na(dat[[i]]["system_date_time_latest"])))) {
    output$max_system_date_time_latest[i] <- 
      max(as.Date(dat[[i]][["system_date_time_latest"]]), na.rm = TRUE)
  } else {
    output$max_system_date_time_latest[i] <- NA
  }
}

max(output$max_system_date_time_latest, na.rm = TRUE) 
# The date listed here should be the latest collected data, which would likely be on/around the date
# of when the data was downloaded, or the last day of the TET study. For the data pulled on 10/4/23,
# it would be "2023-10-02 19:00:00 EST", for example. 


# ---------------------------------------------------------------------------- #
# Identify participants with inaccurate "active" column ----
# ---------------------------------------------------------------------------- #

# Participants were supposed to be labeled as inactive at "preTest" or after 21 
# days of inactivity before "PostFollowUp" or "COMPLETE", but many were not 
# labeled as such (unclear why). If not labeled as inactive after inactivity,
# the participant might not be sent a final reminder email and might not be told 
# their account is closed when they return to the site. Such participants are
# listed below, but their values of "active" are not changed given that whether
# and how this unexpected behavior matters will depend on the specific analysis.

inactive_participant_ids <- 
  dat$study[dat$study$current_session == "preTest" |
              ((Sys.time() - dat$study$last_session_date_as_POSIXct > 21) &
                 !(dat$study$current_session %in% c("PostFollowUp", "COMPLETE"))), 
            "participant_id"]
mislabeled_inactive_participant_ids <- 
  dat$participant[dat$participant$participant_id %in% inactive_participant_ids &
                    dat$participant$active == 1, 
                  "participant_id"]
mislabeled_inactive_participant_ids 

# Participants were otherwise supposed to be labeled as active (default value),
# but a few were labeled as inactive (unclear why). In these cases, participants
# may have incorrectly been sent a final reminder email or told that their account 
# was closed when they returned to the site. Again, such participants are listed
# below, but their values of "active" are not changed.

active_participant_ids <- 
  dat$participant[!(dat$participant$participant_id %in% inactive_participant_ids),
                  "participant_id"]
mislabeled_active_participant_ids <-
  dat$participant[dat$participant$participant_id %in% active_participant_ids &
                    dat$participant$active == 0,
                  "participant_id"]
mislabeled_active_participant_ids 

# ---------------------------------------------------------------------------- #
# Check "conditioning" values in "angular_training" and "study" tables ----
# ---------------------------------------------------------------------------- #

# Note: "conditioning" is blank for some rows of "angular_training". Dan Funk 
# said on 1/4/2021 that pressing the "Continue" button (i.e., "button_pressed" == 
# "continue", which has a high prevalence in these cases) does not always contain 
# a condition. He said that he believes these participants had a session timeout 
# of some kind and likely received a red-error bar saying "you are not logged in" 
# and prompting them to go back to the main site; however, they can ignore the 
# prompt and continue anyway.

nrow(dat$angular_training[dat$angular_training$conditioning == "", ])

# Create aggregated "angular_training" dataset to check "conditioning" column
# and to compare this column's values with "conditioning" in "study" table

ang_train_ag <- dat$angular_training[dat$angular_training$conditioning != "", 
                                     c("participant_id", 
                                       "conditioning", 
                                       "session_and_task_info")]
ang_train_ag <- unique(ang_train_ag)
ang_train_ag <- ang_train_ag[order(ang_train_ag$participant_id), ]

# Check that there are no blank condition assignments in new df
nrow(ang_train_ag[ang_train_ag$conditioning == "", ])

# Check that condition stays the same from "firstSession" through "fifthSession"

ang_train_ag_s1_to_s5 <- ang_train_ag[ang_train_ag$session_and_task_info %in% 
                                        c("firstSession", "secondSession", 
                                           "thirdSession", "fourthSession", 
                                           "fifthSession"), ]
ang_train_ag_s1_to_s5_less <- 
  unique(ang_train_ag_s1_to_s5[, c("participant_id", "conditioning")])

summary <- ang_train_ag_s1_to_s5_less %>% 
  group_by(participant_id) %>% summarise(count = n())
summarySubset <- subset(summary, summary$count > 1)

cond_change_ids_past_s1 <- summarySubset$participant_id 

cond_change_ids_past_s1

#   Participant 3939 switches from "NONE" to "TRAINING_ED"
#   Participant 4914 switches from "NONE" to "TRAINING_ORIG"

# On 9/18/23, Jeremy said one thing to keep in mind is that if the data reflects that 
# they switched conditions, it's likely that they actually did switch conditions. 
# His approach for Calm Thinking was not to change their condition assignment in the data 
# because that would actually obscure the fact that they switched conditions. He suggested that
# we find some way to flag such participants so people can decide how to deal with them for their 
# specific analysis rather than actually changing their condition in the data. Any analysis 
# will require additional data cleaning specific to that analysis; this is one of those cases.
# He noted that an intent-to-treat analysis (which is typically our primary analysis) technically 
# should include all participants randomized to condition, regardless of what happens after 
# randomization (i.e., even if they subsequently received a different condition by mistake). 
# As a general principle you'd typically include them in the condition they were originally randomized to.


# Check for "conditioning" in "angular_training" table not matching "conditioning"
# in "study" table at the same session

study_less <- dat$study[, c("participant_id", "conditioning", "current_session")]
names(study_less)[names(study_less) == "conditioning"] <- "current_conditioning"

ang_study_less_merge <- merge(ang_train_ag, study_less, by = "participant_id", all.x = TRUE)
ang_study_less_merge_same_session <- ang_study_less_merge[ang_study_less_merge$session_and_task_info ==
                                                            ang_study_less_merge$current_session, ]

ang_study_cond_mismatch_same_session_ids <- 
  ang_study_less_merge_same_session[(ang_study_less_merge_same_session$conditioning !=
                                       ang_study_less_merge_same_session$current_conditioning), 
                                    "participant_id"] 

ang_study_cond_mismatch_same_session_ids
# This will flag participant IDs for any participants that have mismatch 
  # conditioning from angular_training to study

# Check for "conditioning" at Session 5 in "angular_training" table not matching 
# "conditioning" at "COMPLETE" in "study" table

ang_study_less_merge_s5_complete <- 
  ang_study_less_merge[ang_study_less_merge$session_and_task_info == "fifthSession" &
                         ang_study_less_merge$current_session == "COMPLETE", ]

ang_study_cond_mismatch_s5_complete_ids <- 
  ang_study_less_merge_s5_complete[(ang_study_less_merge_s5_complete$conditioning !=
                                      ang_study_less_merge_s5_complete$current_conditioning), 
                                   "participant_id"] 

ang_study_cond_mismatch_s5_complete_ids
# No participants have mismatch conditioning from session 5 to complete

# ---------------------------------------------------------------------------- #
# Clean "reasons_for_ending" table ----
# ---------------------------------------------------------------------------- #

# Changes/Issues Log on 10/7/2019 says that some completers of the 2-month follow-
# up assessment were incorrectly administered "reasons_for_ending". No data were
# collected after this measure. Thus, these entries can be deleted. Note that the
# "reasons_for_ending" task is not recorded in the "task_log" table.

reasons_for_ending_complete_ids <- 
  dat$reasons_for_ending[dat$reasons_for_ending$session_only == "COMPLETE", "id"]
reasons_for_ending_complete_ids
# No participants, so this is something we do not need to clean for TET as of 12/19/24.

# ---------------------------------------------------------------------------- #
# Exclude screenings resembling bots ----
# ---------------------------------------------------------------------------- #

# In Calm Thinking, some bot-like activity was indicated by rows that had a 
# "time_on_page" of exactly 1 or 10 at screening, in which case none of them got
# a "participant_id". We will remove rows with the same conditions to remove
# any possible bots. 

summary <- dat$dass21_as %>%
  group_by(as.Date(date)) %>%
  summarise(count=n())
head(summary[order(summary$count, decreasing = TRUE), ])


bot_session_ids <- dat$dass21_as[dat$dass21_as$time_on_page %in% c(1, 10) &
                                   dat$dass21_as$session_only == "Eligibility",
                                 "session_id"]
sum(!is.na(dat$dass21_as[dat$dass21_as$session_id %in% bot_session_ids, 
                         "participant_id"]))

length(unique(bot_session_ids))
# As of 10/16/23 there is not any bot-like activity for TET. For future data cleaning, if
# there are bots, the line below will remove them. 

# Remove the screenings for these bots

dat$dass21_as <- dat$dass21_as[!(dat$dass21_as$session_id %in% bot_session_ids), ]

# ---------------------------------------------------------------------------- #
# Identify and remove nonmeaningful duplicates ----
# ---------------------------------------------------------------------------- #

# For rows that have duplicated values on every meaningful column (i.e., every
# column except "X" and "id"), keep only the last row after sorting by "id" for
# tables that contain "id" (throw error if "attrition_prediction", "participant", 
# or "study" tables, which lack "id", contain multiple rows per "participant_id",
# in which case they will need to be sorted and have their rows consolidated).

for (i in 1:length(dat)) {
  meaningful_cols <- names(dat[[i]])[!(names(dat[[i]]) %in% c("X", "id"))]
  
  if (names(dat[i]) %in% c("attrition_prediction", "participant", "study")) {
    if (nrow(dat[[i]]) != length(unique(dat[[i]][, "participant_id"]))) {
      stop(paste0("Unexpectedly, table ", names(dat[i]), 
                  "contains multiple rows for at least one participant_id"))
    }
  } else if ("id" %in% names(dat[[i]])) {
    dat[[i]] <- dat[[i]][order(dat[[i]][, "id"]), ]
    
    dat[[i]] <- dat[[i]][!duplicated(dat[[i]][, meaningful_cols],
                                     fromLast = TRUE), ]
  } else {
    stop(paste0("Table ", names(dat[i]), "needs to be checked for duplicates"))
  }
}
# If there is no output for this function, then all is good! Output would list any 
# tables that need to be further checked for duplicates. 

# ---------------------------------------------------------------------------- #
# Handle multiple screenings ----
# ---------------------------------------------------------------------------- #

# Some participants do not have their "participant_id" connected to all screening 
# attempts for their corresponding "session_id" (unclear why, as only for some, not 
# all, attempts without "participant_id" was the participant ineligible on age, and 
# all attempts were eligible on DASS). Correct this.

# DASS
unique_s_p_ids_dass <- unique(dat$dass21_as[dat$dass21_as$session_only == "Eligibility", 
                                                 c("session_id", "participant_id")])

n_unq_s_p_ids_dass <- unique_s_p_ids_dass %>% 
  group_by(session_id) %>% 
  summarise(count=n())

s_ids_with_mlt_p_ids_dass <- n_unq_s_p_ids_dass$session_id[n_unq_s_p_ids_dass$count > 1]
length(unique(s_ids_with_mlt_p_ids_dass)) # 3 session IDs have multiple PIDs

unique_s_p_ids_rest_dass <- unique_s_p_ids_dass[unique_s_p_ids_dass$session_id %in% s_ids_with_mlt_p_ids_dass, ]
unique_s_p_ids_rest_dass <- unique_s_p_ids_rest_dass[!is.na(unique_s_p_ids_rest_dass$participant_id), ]

nrow(unique_s_p_ids_rest_dass[duplicated(unique_s_p_ids_rest_dass$session_id), ]) == 0

for (i in 1:nrow(unique_s_p_ids_rest_dass)) {
  for (j in 1:nrow(dat$dass21_as)) {
    if (dat$dass21_as$session_id[j] == unique_s_p_ids_rest_dass$session_id[[i]]) {
      dat$dass21_as$participant_id[j] <- unique_s_p_ids_rest_dass$participant_id[[i]]
    }
  }
}

# Check that we've connected all participant/session ids and screening attempts
unique_s_p_ids_dasscheck <- unique(dat$dass21_as[dat$dass21_as$session_only == "Eligibility", 
                                       c("session_id", "participant_id")])

n_unq_s_p_ids_dasscheck <- unique_s_p_ids_dasscheck %>% 
  group_by(session_id) %>% 
  summarise(count=n())

s_ids_with_mlt_p_ids_dasscheck <- n_unq_s_p_ids_dasscheck$session_id[n_unq_s_p_ids_dasscheck$count > 1]
length(unique(s_ids_with_mlt_p_ids_dasscheck)) # This should now be zero!

# Repeat steps above for the OASIS, a new screener added for TET/GIDI

unique_s_p_ids_oa <- unique(dat$oa[dat$oa$session_only == "Eligibility", 
                                        c("session_id", "participant_id")])

n_unq_s_p_ids_oa <- unique_s_p_ids_oa %>% 
  group_by(session_id) %>% 
  summarise(count=n())

s_ids_with_mlt_p_ids_oa <- n_unq_s_p_ids_oa$session_id[n_unq_s_p_ids_oa$count > 1]
length(unique(s_ids_with_mlt_p_ids_oa)) # 5 session IDs have multiple PIDs


unique_s_p_ids_rest_oa <- unique_s_p_ids_oa[unique_s_p_ids_oa$session_id %in% s_ids_with_mlt_p_ids_oa, ]
unique_s_p_ids_rest_oa <- unique_s_p_ids_rest_oa[!is.na(unique_s_p_ids_rest_oa$participant_id), ]

nrow(unique_s_p_ids_rest_oa[duplicated(unique_s_p_ids_rest_oa$session_id), ]) == 0

for (i in 1:nrow(unique_s_p_ids_rest_oa)) {
  for (j in 1:nrow(dat$oa)) {
    if (dat$oa$session_id[j] == unique_s_p_ids_rest_oa$session_id[[i]]) {
      dat$oa$participant_id[j] <- unique_s_p_ids_rest_oa$participant_id[[i]]
    }
  }
}

# Check that we've connected all participant/session ids and screening attempts
unique_s_p_ids_oacheck <- unique(dat$oa[dat$oa$session_only == "Eligibility", 
                                        c("session_id", "participant_id")])

n_unq_s_p_ids_oacheck <- unique_s_p_ids_oacheck %>% 
  group_by(session_id) %>% 
  summarise(count=n())

s_ids_with_mlt_p_ids_oacheck <- n_unq_s_p_ids_oacheck$session_id[n_unq_s_p_ids_oacheck$count > 1]
length(unique(s_ids_with_mlt_p_ids_oacheck)) # This should now be zero!

# Define DASS-21-AS items

dass21_as_items <- c("bre", "dry", "hea", "pan", "sca", "tre", "wor")

# Define OASIS items

oasis_items <- c("axf","axs","avo","wrk","soc")

# After removing nonmeaningful duplicates (see above), for remaining rows that 
# have duplicated values on DASS-21-AS and OASIS items, "over18", and "time_on_page" for 
# a given "session_id" and "session_only", keep only the last row after sorting
# based on "session_id", "session_only", and "id"

response_cols_dass <- c(dass21_as_items, "over18", "time_on_page")

dat$dass21_as <- dat$dass21_as[order(dat$dass21_as$session_id,
                                     dat$dass21_as$session_only,
                                     dat$dass21_as$id), ]

dat$dass21_as <- dat$dass21_as[!duplicated(dat$dass21_as[, c(response_cols_dass, 
                                                             "session_id", 
                                                             "session_only")],
                                           fromLast = TRUE), ]

response_cols_oa <- c(oasis_items, "time_on_page")

dat$oa <- dat$oa[order(dat$oa$session_id,
                                     dat$oa$session_only,
                                     dat$oa$id), ]

dat$oa <- dat$oa[!duplicated(dat$oa[, c(response_cols_oa, 
                                                             "session_id", 
                                                             "session_only")],
                                           fromLast = TRUE), ]

# Compute number of multiple rows per "session_id" at screening

dass21_as_eligibility <- dat$dass21_as[dat$dass21_as$session_only == "Eligibility", ]

n_eligibility_rows_dass <- dass21_as_eligibility %>% 
  group_by(session_id, session_only) %>% 
  summarise(count=n()) %>%
  as.data.frame()

names(n_eligibility_rows_dass)[names(n_eligibility_rows_dass) == "count"] <- "n_eligibility_rows_dass"

dat$dass21_as <- merge(dat$dass21_as, 
                       n_eligibility_rows_dass, 
                       c("session_id", "session_only"), 
                       all.x = TRUE,
                       sort = FALSE)

oasis_eligibility <- dat$oa[dat$oa$session_only == "Eligibility", ]

n_eligibility_rows_oa <- oasis_eligibility %>% 
  group_by(session_id, session_only) %>% 
  summarise(count=n()) %>%
  as.data.frame()

names(n_eligibility_rows_oa)[names(n_eligibility_rows_oa) == "count"] <- "n_eligibility_rows_oa"

dat$oa <- merge(dat$oa, 
                       n_eligibility_rows_oa, 
                       c("session_id", "session_only"), 
                       all.x = TRUE,
                       sort = FALSE)

# Compute mean "time_on_page" across multiple rows per "session_id". Note that 
# this currently only applies to rows at screening.

time_on_page_mean_dass <- aggregate(dass21_as_eligibility$time_on_page, 
                               list(dass21_as_eligibility$session_id,
                                    dass21_as_eligibility$session_only), 
                               mean)
names(time_on_page_mean_dass) <- c("session_id", "session_only", "time_on_page_mean")

time_on_page_mean_dass[is.nan(time_on_page_mean_dass[, "time_on_page_mean"]), 
                  "time_on_page_mean"] <- NA

dat$dass21_as <- merge(dat$dass21_as, 
                       time_on_page_mean_dass, 
                       c("session_id", "session_only"), 
                       all.x = TRUE,
                       sort = FALSE)

time_on_page_mean_oa <- aggregate(oasis_eligibility$time_on_page, 
                                    list(oasis_eligibility$session_id,
                                         oasis_eligibility$session_only), 
                                    mean)
names(time_on_page_mean_oa) <- c("session_id", "session_only", "time_on_page_mean")

time_on_page_mean_oa[is.nan(time_on_page_mean_oa[, "time_on_page_mean"]), 
                       "time_on_page_mean"] <- NA

dat$oa <- merge(dat$oa, 
                       time_on_page_mean_oa, 
                       c("session_id", "session_only"), 
                       all.x = TRUE,
                       sort = FALSE)

# Compute number of unique rows on DASS-21-AS & OASIS items per "session_id" at screening. 
# If a participant has more than two sets of unique values on DASS-21-AS/OASIS items, 
# we will exclude them from analysis given concerns about their data integrity. 
# Otherwise, we will include them in analysis, even if they have two or more entries 
# for "over18" (their final "over18" entry had to be TRUE for them to enroll in the 
# program). However, we will compute the column mean across their unique DASS-21-AS/OASIS 
# item entries and then use these column means to compute their average item score
# (taking the mean of available column means). In this way, we will have one set 
# of items and one average item score for analysis that take into account the 
# participant's multiple unique item entries.

unique_dass21_as_eligibility_items <- 
  unique(dass21_as_eligibility[, c("participant_id", "session_id",
                                   "session_only",
                                   dass21_as_items)])

n_eligibility_unq_item_rows_dass <- unique_dass21_as_eligibility_items %>% 
  group_by(session_id, session_only) %>% 
  summarise(count=n())

n_eligibility_unq_item_rows_dass <- as.data.frame(n_eligibility_unq_item_rows_dass)
names(n_eligibility_unq_item_rows_dass)[names(n_eligibility_unq_item_rows_dass) == "count"] <-
  "n_eligibility_unq_item_rows_dass"

dat$dass21_as <- merge(dat$dass21_as, 
                       n_eligibility_unq_item_rows_dass, 
                       c("session_id", "session_only"), 
                       all.x = TRUE,
                       sort = FALSE)

unique_oasis_eligibility_items <- 
  unique(oasis_eligibility[, c("participant_id", "session_id",
                                   "session_only",
                                   oasis_items)])

n_eligibility_unq_item_rows_oa <- unique_oasis_eligibility_items %>% 
  group_by(session_id, session_only) %>% 
  summarise(count=n())

n_eligibility_unq_item_rows_oa <- as.data.frame(n_eligibility_unq_item_rows_oa)
names(n_eligibility_unq_item_rows_oa)[names(n_eligibility_unq_item_rows_oa) == "count"] <-
  "n_eligibility_unq_item_rows_oa"

dat$oa <- merge(dat$oa, 
                       n_eligibility_unq_item_rows_oa, 
                       c("session_id", "session_only"), 
                       all.x = TRUE,
                       sort = FALSE)

# Compute column mean of unique values on DASS-21-AS/OASIS items per "session_id",
# treating values of "Prefer Not to Answer" as NA without recoding them as NA in 
# the actual table. Note that this currently only applies to rows at screening.

unique_items_dass <- unique_dass21_as_eligibility_items

unique_items_dass[, dass21_as_items][unique_items_dass[, dass21_as_items] == 555] <- NA

for (i in 1:length(dass21_as_items)) {
  col_name <- dass21_as_items[i]
  col_mean_name <- paste0(dass21_as_items[i], "_mean")
  
  dass21_as_item_mean <- aggregate(unique_items_dass[, col_name], 
                                   list(unique_items_dass$session_id,
                                        unique_items_dass$session_only), 
                                   mean, na.rm = TRUE)
  names(dass21_as_item_mean) <- c("session_id", "session_only", col_mean_name)
  
  dass21_as_item_mean[is.nan(dass21_as_item_mean[, col_mean_name]), 
                      col_mean_name] <- NA
  
  dat$dass21_as <- merge(dat$dass21_as, 
                         dass21_as_item_mean, 
                         c("session_id", "session_only"), 
                         all.x = TRUE,
                         sort = FALSE)
}

unique_items_oa <- unique_oasis_eligibility_items

unique_items_oa[, oasis_items][unique_items_oa[, oasis_items] == 555] <- NA

for (i in 1:length(oasis_items)) {
  col_name <- oasis_items[i]
  col_mean_name <- paste0(oasis_items[i], "_mean")
  
  oasis_item_mean <- aggregate(unique_items_oa[, col_name], 
                                   list(unique_items_oa$session_id,
                                        unique_items_oa$session_only), 
                                   mean, na.rm = TRUE)
  names(oasis_item_mean) <- c("session_id", "session_only", col_mean_name)
  
  oasis_item_mean[is.nan(oasis_item_mean[, col_mean_name]), 
                      col_mean_name] <- NA
  
  dat$oa <- merge(dat$oa, 
                         oasis_item_mean, 
                         c("session_id", "session_only"), 
                         all.x = TRUE,
                         sort = FALSE)
}

# Compute DASS-21-AS total score per row (as computed by system, not accounting
# for multiple entries) by taking mean of available raw items and multiplying 
# by 7 (to create "dass21_as_total"). Treat "Prefer Not to Answer" as NA without 
# recoding it as NA in the actual dataset. At screening, multiply by 2 to interpret 
# against eligibility criterion ("dass21_as_total_interp"; >= 10 is eligible) and 
# create indicator ("dass21_as_eligible") to reflect eligibility on DASS-21-AS.

dat$dass21_as$dass21_as_total <- NA
dat$dass21_as$dass21_as_total_interp <- NA
dat$dass21_as$dass21_as_eligible <- NA

temp_dass21_as <- dat$dass21_as
temp_dass21_as[, dass21_as_items][temp_dass21_as[, dass21_as_items] == 555] <- NA

for (i in 1:nrow(temp_dass21_as)) {
  if (all(is.na(temp_dass21_as[i, dass21_as_items]))) {
    dat$dass21_as$dass21_as_total[i] <- NA
  } else {
    dat$dass21_as$dass21_as_total[i] <- 
      rowMeans(temp_dass21_as[i, dass21_as_items], na.rm = TRUE)*7
  }
}

for (i in 1:nrow(dat$dass21_as)) {
  if (dat$dass21_as$session_only[i] == "Eligibility") {
    dat$dass21_as$dass21_as_total_interp[i] <- dat$dass21_as$dass21_as_total[i]*2
    
    if (is.na(dat$dass21_as$dass21_as_total_interp[i])) {
      dat$dass21_as$dass21_as_eligible[i] <- 0
    } else if (dat$dass21_as$dass21_as_total_interp[i] < 10) {
      dat$dass21_as$dass21_as_eligible[i] <- 0
    } else if(dat$dass21_as$dass21_as_total_interp[i] >= 10) {
      dat$dass21_as$dass21_as_eligible[i] <- 1
    }
  }
}

# Compute OASIS total score per row (as computed by system, not accounting
# for multiple entries) by taking mean of available raw items and multiplying by 5 (to create "oasis_total"). 
# Treat "Prefer Not to Answer" as NA without recoding it as NA in the actual dataset. 
# At screening, interpret against eligibility criterion ("oasis_total_interp";
# >= 6 is eligible) and create indicator ("oasis_eligible") to reflect eligibility on OASIS.

dat$oa$oasis_total <- NA
dat$oa$oasis_total_interp <- NA
dat$oa$oasis_eligible <- NA

temp_oa <- dat$oa
temp_oa[, oasis_items][temp_oa[, oasis_items] == 555] <- NA

for (i in 1:nrow(temp_oa)) {
  if (all(is.na(temp_oa[i, oasis_items]))) {
    dat$oa$oasis_total[i] <- NA
  } else {
    dat$oa$oasis_total[i] <- 
    rowMeans(temp_oa[i, oasis_items], na.rm = TRUE)* 5
  }
}

for (i in 1:nrow(dat$oa)) {
  if (dat$oa$session_only[i] == "Eligibility") {
    dat$oa$oasis_total_interp[i] <- dat$oa$oasis_total[i]
    
    if (is.na(dat$oa$oasis_total_interp[i])) {
      dat$oa$oasis_eligible[i] <- 0
    } else if (dat$oa$oasis_total_interp[i] < 6) {
      dat$oa$oasis_eligible[i] <- 0
    } else if(dat$oa$oasis_total_interp[i] >= 6) {
      dat$oa$oasis_eligible[i] <- 1
    }
  }
}

# Compute DASS-21-AS total score for analysis (accounting for multiple entries at 
# screening). At screening, take mean of available item column means and multiply 
# by 7 (to create "dass21_as_total_anal"); at other time points, copy values from
# "dass21_as_total" into "dass21_as_total_anal".

dass21_as_item_means <- paste0(dass21_as_items, "_mean")

dat$dass21_as$dass21_as_total_anal <- NA

for (i in 1:nrow(dat$dass21_as)) {
  if (dat$dass21_as$session_only[i] == "Eligibility") {
    if (all(is.na(dat$dass21_as[i, dass21_as_item_means]))) {
      dat$dass21_as$dass21_as_total_anal[i] <- NA
    } else {
      dat$dass21_as$dass21_as_total_anal[i] <- 
        rowMeans(dat$dass21_as[i, dass21_as_item_means], na.rm = TRUE)*7
    }
  } else {
    dat$dass21_as$dass21_as_total_anal[i] <- dat$dass21_as$dass21_as_total[i]
  }
}

# Check that we've created the new column with DASS total scores for analysis.
dat$dass21_as$dass21_as_total_anal[1:5]

# Compute OASIS total score for analysis (accounting for multiple entries at 
# screening). At screening, take mean of available item column means and multiply 
# by 5 (to create "oasis_total_anal"); at other time points, copy values from
# "oasis_total" into "oasis_total_anal".

oasis_item_means <- paste0(oasis_items, "_mean")

dat$oa$oasis_total_anal <- NA

for (i in 1:nrow(dat$oa)) {
  if (dat$oa$session_only[i] == "Eligibility") {
    if (all(is.na(dat$oa[i, oasis_item_means]))) {
      dat$oa$oasis_total_anal[i] <- NA
    } else {
      dat$oa$oasis_total_anal[i] <- 
        rowMeans(dat$oa[i, oasis_item_means], na.rm = TRUE)*5
    }
  } else {
    dat$oa$oasis_total_anal[i] <- dat$oa$oasis_total[i]
  }
}

# Check that we've created the new column with OASIS total scores for analysis.
dat$oa$oasis_total_anal[1:5]

# We will take care of removing participants with more than 2 screener entries in a later section of this script!


# ---------------------------------------------------------------------------- #
# Report participant flow up to enrollment and identify analysis exclusions ----
# ---------------------------------------------------------------------------- #

# Report number of participants screened, enrolled, and not enrolled. For not 
# enrolled, report the reason; for people with multiple entries, base the
# reason on the most recent entry (but note that nonenrollment following each
# attempt could have occurred for a different reason--e.g., not eligible on age,
# not eligible on DASS, not eligible on OASIS, eligible but not interested). 

# DASS
dass21_as_eligibility_last <- dat$dass21_as[dat$dass21_as$session_only == "Eligibility", ]
dass21_as_eligibility_last <- 
  dass21_as_eligibility_last[order(dass21_as_eligibility_last$session_id, dass21_as_eligibility_last$id),]
dass21_as_eligibility_last <- 
  dass21_as_eligibility_last[!duplicated(dass21_as_eligibility_last$session_id, 
                                         fromLast = TRUE),]

# Below is the number of participants who were screened for eligibility on the DASS

nrow(dass21_as_eligibility_last) #10/16/23: 7703

# OASIS 
oa_eligibility_last <- dat$oa[dat$oa$session_only == "Eligibility", ]
oa_eligibility_last <- 
  oa_eligibility_last[order(oa_eligibility_last$session_id, oa_eligibility_last$id),]
oa_eligibility_last <- 
  oa_eligibility_last[!duplicated(oa_eligibility_last$session_id, 
                                         fromLast = TRUE),]

# Below is the number of participants who were screened for eligibility on the OASIS

nrow(oa_eligibility_last) #10/16/23: 7866

# Merge the eligibility datasets to look at eligibility for both screeners

dass21_as_eligibility_last<-dass21_as_eligibility_last[,c("session_id", "session_only", "date", "participant_id", 
                                            "n_eligibility_unq_item_rows_dass", "dass21_as_eligible", "over18")]

oa_eligibility_last<-oa_eligibility_last[,c("session_id", "session_only", "date", "participant_id", 
                                            "n_eligibility_unq_item_rows_oa", "oasis_eligible")]

eligibility_merge <- merge(dass21_as_eligibility_last, oa_eligibility_last, by = c('session_id',
                                               "participant_id", "session_only"), all = TRUE)

eligibility_merge <- unique(eligibility_merge)

nrow(eligibility_merge) #10/19/23: 8249 screened 

# For unknown reasons, some entries are missing either the DASS, OASIS, or age. It doesn't necessarily mean that the participant
# was ineligible for that criteria, as there are some people who were assigned a participant ID yet do not have a recorded age,
# even though being 18 or over is a definite criteria. Most likely just a recording issue on the site/tech side, but shouldn't
# majorly affect anything. On 12/13/24, Jeremy let Kaitlyn know that even with Calm Thinking, the participant flow 
# numbers calculated here did not match what he did manually, as sometimes our screener entries are incorrect. So, we
# recommend that folks manually calculate participant flow groups.  

# Replace NAs in any eligibility criteria (OASIS, DASS, age) with 2s to count as missing and not get mixed up with the 
# 1s and 0s that indicate actual eligibility
eligibility_merge$dass21_as_eligible[is.na(eligibility_merge$dass21_as_eligible)] <- 2
eligibility_merge$oasis_eligible[is.na(eligibility_merge$oasis_eligible)] <- 2
eligibility_merge$over18[is.na(eligibility_merge$over18)] <- 2

# Of those screened, below is the number of participants who did  enroll, followed by those who did not enroll

nrow(eligibility_merge[!is.na(eligibility_merge$participant_id), ]) #10/16/23: 3499 PLUS 2 participants below who did not have screener data but were enrolled
nrow(eligibility_merge[is.na(eligibility_merge$participant_id), ]) #10/16/23: 4750


# Of those who did enroll (3499), below is the number of participants who were eligible on either the
# DASS, OASIS, or both (and always over 18/eligible on age).
enrolled=eligibility_merge[!is.na(eligibility_merge$participant_id), ]

# Eligible on DASS, not eligible on OASIS
inel_oa=enrolled[enrolled$dass21_as_eligible == 1 &
              enrolled$oasis_eligible == 0, ]
nrow(inel_oa) #4/23/24: 20

# Eligible on OASIS, not eligible on DASS
inel_dass=enrolled[enrolled$dass21_as_eligible == 0 &
              enrolled$oasis_eligible == 1, ] 
nrow(inel_dass) #4/23/24: 739

# Eligible on all OASIS, DASS, and age
el_all=enrolled[enrolled$dass21_as_eligible == 1 &
              enrolled$oasis_eligible == 1, ] 
nrow(el_all) #4/23/24: 2672

# At least one of the eligibility criteria is missing 
missing_el=enrolled[enrolled$oasis_eligible == 2 |
                      enrolled$dass21_as_eligible == 2 |
                      enrolled$over18 == 2, ] 
nrow(missing_el) #4/22/24: 68  

sum(nrow(inel_oa)+nrow(inel_dass)+nrow(el_all)+nrow(missing_el))
# Should equal number of enrolled Ps, 3499 on 4/23/24


# Of those who did not enroll (n = 4750), below is the number of participants who were ineligible or eligible across the 
# 3 eligibility criteria (DASS, OASIS, and age).
not_enrolled=eligibility_merge[is.na(eligibility_merge$participant_id), ]
over18=not_enrolled[not_enrolled$over18 == "true",]
under18=not_enrolled[not_enrolled$over18 == "false",]

# At least one of the eligibility criteria is missing (does NOT necessarily mean it was ineligible, as seen above)
missing_inel=not_enrolled[not_enrolled$oasis_eligible == 2 |
                          not_enrolled$dass21_as_eligible == 2 |
                          not_enrolled$over18 == 2, ] 
nrow(missing_inel) #4/22/24: 861  

# Ineligible on DASS and OASIS, only eligible on age
inel_d_o_el_age=over18[over18$dass21_as_eligible == 0 &
                      over18$oasis_eligible == 0, ] 
nrow(inel_d_o_el_age) #4/22/24: 423

# Eligible for only DASS, ineligible for OASIS and age
el_d_inel_o_age=under18[under18$dass21_as_eligible == 1 &
                          under18$oasis_eligible == 0, ] 
nrow(el_d_inel_o_age) #4/22/24: 6

# Eligible for only OASIS, ineligible for DASS and age
el_o_inel_d_age=under18[under18$oasis_eligible == 1 &
                          under18$dass21_as_eligible == 0, ] 
nrow(el_o_inel_d_age) #4/22/24: 76

# Eligible for DASS & OASIS, ineligible for age
el_o_d_inel_age=under18[under18$oasis_eligible == 1 &
                          under18$dass21_as_eligible == 1, ] 
nrow(el_o_d_inel_age) #4/22/24: 233

# Eligible for age & OASIS, ineligible for DASS
el_age_o_inel_d=over18[over18$oasis_eligible == 1 &
                        over18$dass21_as_eligible == 0, ] 
nrow(el_age_o_inel_d) #4/22/24: 745

# Eligible for age & DASS, ineligible for OASIS
el_age_a_inel_o=over18[over18$oasis_eligible == 0 &
                         over18$dass21_as_eligible == 1, ] 
nrow(el_age_a_inel_o) #4/22/24: 67

# Eligible on all DASS, OASIS, and age
all_el=over18[over18$dass21_as_eligible == 1 &
                over18$oasis_eligible == 1, ] 
nrow(all_el) #4/22/24: 2306

# Ineligible for all DASS, OASIS, and age
all_inel=under18[under18$oasis_eligible == 0 &
                   under18$dass21_as_eligible == 0, ] 
nrow(all_inel) #4/22/24: 33  

sum(nrow(missing_inel)+nrow(inel_d_o_el_age)+nrow(el_d_inel_o_age)+nrow(el_o_inel_d_age)+nrow(el_o_d_inel_age)+nrow(el_age_o_inel_d)+
      nrow(el_age_a_inel_o)+nrow(all_el)+nrow(all_inel))
# Should equal number of not enrolled Ps, 4750 on 4/23/24 


# Note that if screening data from participants who did not enroll is going to be
# analyzed, the following participants should be excluded from analysis because they have more 
# than two sets of unique values on DASS-21-AS or OASIS items

exclude_nonenrolled_session_ids <- 
  eligibility_merge[is.na(eligibility_merge$participant_id) &
                      eligibility_merge$n_eligibility_unq_item_rows_dass > 2 | eligibility_merge$n_eligibility_unq_item_rows_oa > 2, 
                             "session_id"]
length(exclude_nonenrolled_session_ids)

table(eligibility_merge[is.na(eligibility_merge$participant_id), 
                                 "n_eligibility_unq_item_rows"])

# Of the those who did enroll, below shows which participants should be excluded from analysis 
# because they have more than two sets of unique values on DASS-21-AS or OASIS items

exclude_enrolled_participant_ids <- 
  eligibility_merge[!is.na(eligibility_merge$participant_id) &
                      eligibility_merge$n_eligibility_unq_item_rows_dass > 2 | eligibility_merge$n_eligibility_unq_item_rows_oa > 2, 
                             "participant_id"]
length(exclude_enrolled_participant_ids)

table(eligibility_merge[!is.na(eligibility_merge$participant_id), 
                                 "n_eligibility_unq_item_rows"])

# Create indicator "exclude_analysis" to reflect nonenrolled/enrolled participants
# who should be excluded from analysis

dat$dass21_as$exclude_analysis <- 0

dat$dass21_as$exclude_analysis[dat$dass21_as$session_id %in% 
                                 exclude_nonenrolled_session_ids |
                                 dat$dass21_as$participant_id %in% 
                                 exclude_enrolled_participant_ids] <- 1

dat$oa$exclude_analysis <- 0

dat$oa$exclude_analysis[dat$oa$session_id %in% 
                                 exclude_nonenrolled_session_ids |
                                 dat$oa$participant_id %in% 
                                 exclude_enrolled_participant_ids] <- 1

# Add "exclude_analysis" to "participant" table

dat$participant$exclude_analysis <- 0
dat$participant$exclude_analysis[dat$participant$participant_id %in%
                                   exclude_enrolled_participant_ids] <- 1

# ---------------------------------------------------------------------------- #
# Check for participants who do not have screener data but enrolled in the study ----
# ---------------------------------------------------------------------------- #

# Some participants do not have screener data, but made it into the study - we 
# are unsure why. Handling of these participants will be dependent on analyses, 
# but we will identify them below. 

# Participants who do not have screener data, but were assigned a participant ID,
# meaning that they enrolled in the study. 

no_screener_pid <- dat$participant$participant_id[dat$participant$participant_id %in% na.omit(eligibility_merge$participant_id) == FALSE] 
no_screener_pid # Participants 3659 & 4949

# Participants who do not have screener data but have data for firstSession, meaning
# they actively started the program and completed at least one session. 

firstSession <- dat$task_log[dat$task_log$session_only == "firstSession",]
no_screener_first <- firstSession$participant_id[firstSession$participant_id %in% na.omit(eligibility_merge$participant_id) == FALSE] 
no_screener_first # None

# ---------------------------------------------------------------------------- #
# Add GIDI-UP 12 month follow-up from Qualtrics ----
# ---------------------------------------------------------------------------- #

# Note: this section should only be added if you are looking at GIDI participants. 
# If looking exclusively at TET participants, you can skip this section. The GIDI
# participants were administered a 12-month follow-up survey through Qualtrics - we
# will import the .csv into our dat dataset as a new table within the data below. 
# Additional data cleaning may need to take place for specific analyses. 

# The gidiup_12month.csv should be located in your "data" folder in the larger cleaning folder
# on your desktop - read in the csv using your own file path. This file has the data from Qualtrics.
gidiup_12month <- read.csv("./data/1_raw_qualtrics/gidiup_12month.csv")
gidiup_12month <- gidiup_12month[-c(1,2), -c(1,4,5,7,8,10:18)]

# The data above gives each participant a Qualtrics ID, and we must connect that to 
# the MT participant IDs. The gidiup_ids.csv should be located in your "data" folder 
# in the larger cleaning folder on your desktop - read in the csv using your own file path. 
gidiup_ids <- read.csv("./data/1_raw_qualtrics/gidiup_ids.csv")

# Rename ID columns and merge datasets by Qualtrics ID 
gidiup_12month <- gidiup_12month%>%rename("qualtrics_id" = "Qualtrics_ID.")
gidiup_ids <- gidiup_ids%>%rename("participant_id" = "MT_id")
gidiup_ids <- gidiup_ids%>%rename("qualtrics_id" = "Qualtrics_id")
gidiup_12month <- merge(gidiup_12month,gidiup_ids,by="qualtrics_id")
# Note: there are 609 observations in gidiup_ids.csv, but only 286 observations in gidiup_12month.csv
# after merging. This is because many participants did not fill out the GIDI-UP follow up on
# Qualtrics, and because we lose all participants who did not correctly input their assigned 
# Qualtrics ID and therefore their follow-up data is not correctly matched to a MT participant ID (Note: 
# if participants entered an email address as their Qualtrics ID, we relabeled that cell before data 
# cleaning and they will still be in the data - only participants who entered a number that is not
# a valid assigned Qualtrics ID will be removed, since we cannot trace them back). 

# Rearrange columns so that participant ID is first
gidiup_12month <- gidiup_12month[, c(214, 1:5, 8:19, 6, 7, 20:213)]

# Check for duplicate entries by the same participant
length(gidiup_12month$participant_id) # 286 entries
length(unique(gidiup_12month$participant_id)) # 253 unique entries

# Figure out how many times each ID is in the data, and create a new dataset with just the duplicates 
# to examine further.
gidiup_dups_counts <- gidiup_12month %>% 
  group_by(participant_id) %>% 
  summarise(count=n())
gidiup_dups_ids <- gidiup_dups_counts$participant_id[gidiup_dups_counts$count > 1]
gidiup_dups <- gidiup_12month[gidiup_12month$participant_id %in% gidiup_dups_ids, ]

# On 11/13/23, Max said that we can remove any duplicated ID rows where there is no data and only
# take the row for that ID that has data. We will do this by looking at the rows in gidiup_dups that are missing data,
# and removing those rows from our larger GIDI-UP dataset, gidiup_12month. For rows with duplicated 
# IDs where both entries have data, we can remove the row with the later entry and keep the row with the first/
# earliest entry. We will do this by looking at the rows in gidiup_dups that have data for the same ID, and 
# removing the row with the later "RecordedDate" from our larger GIDI-UP dataset, gidiup_12month. 

# Rows 6, 27, 39, 65, 72, 93, 106, 155, 181, 193, 205, and 279 are duplicate IDs that have missing data; 
# rows 12, 14, 19, 42, 54, 70, 91, 97, 105, 131, 135, 145, 171, 238, 259, 266, 275, 277, 282, 283, 285 are duplicate IDs that are the later entry.

gidiup_12month <- gidiup_12month[-c(6,12,14,19,27,39,42,54,65,70,72,91,93,97,105,106,131,135,145,155,171,181,193,
                                    205,238,259,266,275,277,279,282,283,285), ] 

gidiup_dups_counts_check <- gidiup_12month %>% 
  group_by(participant_id) %>% 
  summarise(count=n())
gidiup_dups_ids_check <- gidiup_dups_counts_check$participant_id[gidiup_dups_counts_check$count > 1] 
gidiup_dups_ids_check # This should now be empty (output = 'integer(0)')


# Check that admin and test MT accounts are not in the data and remove any.
sum(gidiup_12month$participant_id %in% admin_test_account_ids) # No admin or test IDs are in data
gidiup_12month <- subset(gidiup_12month, !(participant_id %in% admin_test_account_ids)) # Run function to remove admin and test accounts just in case

# Calculate final score for OASIS and DASS assessments at follow-up
# Define DASS-21-AS items

dass_gidiup_items <- c("DASS.AS_1", "DASS.AS_2", "DASS.AS_3", "DASS.AS_4", "DASS.AS_5", "DASS.AS_6", "DASS.AS_7")

# Define OASIS items

oasis_gidiup_items <- c("OA_1","OA_2","OA_3.","OA_4","OA_5")

# Compute DASS-21-AS total score per row (as computed by system, not accounting
# for multiple entries) by taking sum of available raw items (to create "dass21_as_total"). 

temp_dass <- gidiup_12month[, dass_gidiup_items]
temp_dass[, dass_gidiup_items][temp_dass[, dass_gidiup_items] == ""] <- NA
temp_dass$dass21_as_total <- NA
temp_dass[,1]=as.numeric(temp_dass[,1])
temp_dass[,2]=as.numeric(temp_dass[,2])
temp_dass[,3]=as.numeric(temp_dass[,3])
temp_dass[,4]=as.numeric(temp_dass[,4])
temp_dass[,5]=as.numeric(temp_dass[,5])
temp_dass[,6]=as.numeric(temp_dass[,6])
temp_dass[,7]=as.numeric(temp_dass[,7])

for (i in 1:nrow(temp_dass)) {
  temp_dass$dass21_as_total[i] <- 
      (temp_dass[i,1]+temp_dass[i,2]+temp_dass[i,3]+temp_dass[i,4]+temp_dass[i,5]+temp_dass[i,6]+
         temp_dass[i,7])}  

gidiup_12month$dass21_as_total <- temp_dass$dass21_as_total
gidiup_12month <- gidiup_12month[, c(1:18, 214, 19:213)]

# Compute OASIS total score per row (as computed by system, not accounting
# for multiple entries) by taking sum of available raw items (to create "oasis_total"). 

temp_oa <- gidiup_12month[, oasis_gidiup_items]
temp_oa[, oasis_gidiup_items][temp_oa[, oasis_gidiup_items] == ""] <- NA
temp_oa$oasis_total <- NA
temp_oa[,1]=as.numeric(temp_oa[,1])
temp_oa[,2]=as.numeric(temp_oa[,2])
temp_oa[,3]=as.numeric(temp_oa[,3])
temp_oa[,4]=as.numeric(temp_oa[,4])
temp_oa[,5]=as.numeric(temp_oa[,5])

for (i in 1:nrow(temp_oa)) {
  temp_oa$oasis_total[i] <- 
    (temp_oa[i,1]+temp_oa[i,2]+temp_oa[i,3]+temp_oa[i,4]+temp_oa[i,5])}  

gidiup_12month$oasis_total <- temp_oa$oasis_total
gidiup_12month <- gidiup_12month[, c(1:11, 215, 12:214)]

# ---------------------------------------------------------------------------- #
# Identify unexpected multiple entries ----
# ---------------------------------------------------------------------------- #

# This function will output dataframes and participant
    # ids that contain unexpected multiple entries. Once those are 'flagged', the person cleaning 
    # the data would proceed by investigating the source of the multiple entries, and deciding
    # how to handle those. 

# Define functions to report multiple entries based on a given set of target columns 
# ("target_cols"). The target columns (e.g., "participant_id" and "session_only") for 
# each table should be chosen such that for each unique combination of values across 
# the target columns only one row is expected in the table ("df", named "df_name"). 
# For each unexpected entry, we report the value of a given index column ("index_col"; 
# e.g., "participant_id") that the unexpected entry belongs to.

# The function "report_dups_df" defines the general procedure for a given table and
# is used in the function "report_dups_list" to apply the procedure to each table in 
# a list. However, because we expect multiple entries at "Eligibility" for "dass21_as" 
# & "oa" table and for "DASS21_AS" & "OA" values of "task_name" in "task_log" table (representing 
# multiple screening attempts, which were already handled in a code section above), 
# we use a special procedure for "dass21_as", "oa", and "task_log" tables.

report_dups_df <- function(df, df_name, target_cols, index_col) {
  duplicated_rows <- df[duplicated(df[, target_cols]), ]
  
  if (nrow(duplicated_rows) > 0) {
    cat(nrow(duplicated_rows), "duplicated rows for table:", df_name)
    cat("\n")
    cat("With these '", index_col, "': ", duplicated_rows[, index_col])
    cat("\n-------------------------\n")
  } else {
    cat("No duplicated rows for table:", df_name)
    cat("\n-------------------------\n")
  }
}

# Note: It is unclear how to check for multiple entries in "angular_training" and 
# "js_psych_trial" tables. In "angular_training", for example, there does not appear 
# to be a set of columns such that for each unique combination of values across the 
# set only one row would be expected. Additional data cleaning of these tables would 
# be needed. Thus, here we check for multiple entries only based on "X" and "id".

# We also check for multiple entries only based on "X" and "id" for other tables in
# which checking for multiple entries based on other columns is irrelevant given the
# table's nature (e.g., "condition_assignment_settings", "demographics_race", "sms_log")

report_dups_list <- function(dat) {
  for (i in 1:length(dat)) {
    if (names(dat[i]) %in% c("angular_training", "js_psych_trial") |
        names(dat[i]) %in% c("condition_assignment_settings", 
                             "demographics_race",
                             "error_log",
                             "evaluation_coach_help_topics", "evaluation_devices",
                             "evaluation_places", "evaluation_preferred_platform",
                             "evaluation_reasons_control", 
                             "mental_health_change_help", "mental_health_disorders", 
                             "mental_health_help", "mental_health_why_no_help", 
                             "reasons_for_ending_change_med", "reasons_for_ending_device_use",
                             "reasons_for_ending_location", "reasons_for_ending_reasons",
                             "session_review_distractions",
                             "sms_log")) {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("X", "id"), 
                     "id")
    } else if (names(dat[i]) == "affect") {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("participant_id", 
                       "session_only", 
                       "tag"), 
                     "participant_id")
    } else if (names(dat[i]) %in% c("attrition_prediction", "participant")) {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     "participant_id", 
                     "participant_id")
    } else if (names(dat[i]) %in% c("dass21_as","oa")) {
      duplicated_rows_eligibility <- 
        dat[[i]][dat[[i]][, "session_only"] == "Eligibility" &
                   (duplicated(dat[[i]][, c("session_id",
                                            "session_only")])), ]
      duplicated_rows_other <-
        dat[[i]][dat[[i]][, "session_only"] != "Eligibility" &
                   (duplicated(dat[[i]][, c("participant_id",
                                            "session_only")])), ]
      duplicated_rows <- rbind(duplicated_rows_eligibility, duplicated_rows_other)
      
      if (nrow(duplicated_rows) > 0) {
        p_ids <- duplicated_rows_eligibility[!is.na(duplicated_rows_eligibility$participant_id),
                                             "participant_id"]
        s_ids <- duplicated_rows_eligibility[is.na(duplicated_rows_eligibility$participant_id),
                                             "session_id"]
        
        cat(nrow(duplicated_rows_eligibility), 
            "duplicated rows at Eligibility for table:", names(dat[i]))
        cat("\n")
        cat("With these ", length(p_ids), "'participant_id' (where available): ", p_ids)
        cat("\n")
        cat("And with ", length(s_ids), "'session_id' (where 'participant_id' unavailable)")
        cat("\n")
        cat(nrow(duplicated_rows_other), 
            "duplicated rows at other time points for table:", names(dat[i]))
        if (nrow(duplicated_rows_other) > 0) {
          cat("\n")
          cat("With these 'participant_id': ", duplicated_rows_other$participant_id)
        }
        cat("\n-------------------------\n")
      } else {
        cat("No duplicated rows for table:", names(dat[i]))
        cat("\n-------------------------\n")
      }
    } else if (names(dat[i]) == "email_log") {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("participant_id", 
                       "session_only", 
                       "email_type", 
                       "date_sent"), 
                     "participant_id")
    } else if (names(dat[i]) == "gift_log") {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("participant_id", 
                       "session_and_admin_awarded_info",
                       "order_id"), 
                     "participant_id")
    } else if (names(dat[i]) == "task_log") {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("participant_id", 
                       "session_only", 
                       "task_name", 
                       "tag"), 
                     "participant_id")
      
      duplicated_rows_dass21_as_eligibility <- 
        dat[[i]][duplicated(dat[[i]][, c("participant_id", 
                                         "session_only", 
                                         "task_name", 
                                         "tag")]) &
                   dat[[i]][, "session_only"] == "Eligibility" &
                   dat[[i]][, "task_name"] == "DASS21_AS", ]
      duplicated_rows_oa_eligibility <- 
        dat[[i]][duplicated(dat[[i]][, c("participant_id", 
                                         "session_only", 
                                         "task_name", 
                                         "tag")]) &
                   dat[[i]][, "session_only"] == "Eligibility" &
                   dat[[i]][, "task_name"] == "OA", ]
      duplicated_rows_other <- 
        dat[[i]][duplicated(dat[[i]][, c("participant_id", 
                                         "session_only", 
                                         "task_name", 
                                         "tag")]) &
                   !(dat[[i]][, "session_only"] == "Eligibility" &
                       dat[[i]][, "task_name"] %in% c("dass21_as","oa")), ]
      if (nrow(duplicated_rows_dass21_as_eligibility) > 0 | nrow(duplicated_rows_oa_eligibility) |
          nrow(duplicated_rows_other) > 0) {
        cat(nrow(duplicated_rows_dass21_as_eligibility),
            "duplicated rows for DASS21_AS at Eligibility in table:", names(dat[i]))
        cat("\n")
        cat("With these 'participant_id': ", duplicated_rows_dass21_as_eligibility$participant_id)
        cat("\n")
        cat(nrow(duplicated_rows_oa_eligibility),
            "duplicated rows for OA at Eligibility in table:", names(dat[i]))
        cat("\n")
        cat("With these 'participant_id': ", duplicated_rows_oa_eligibility$participant_id)
        cat("\n")
        cat(nrow(duplicated_rows_other),
            "duplicated rows for other tasks in table:", names(dat[i]))
        cat("\n")
        cat("With these 'participant_id': ", duplicated_rows_other$participant_id)
        cat("\n-------------------------\n")
      }
    } else if (names(dat[i]) == "study") {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("participant_id", 
                       "current_session"), 
                     "participant_id")
    } else {
      report_dups_df(dat[[i]], 
                     names(dat[i]), 
                     c("participant_id", 
                       "session_only"), 
                     "participant_id")
    }
  }
}

# Run function and then investigate and handle multiple entries in sections below

report_dups_list(dat)

# ---------------------------------------------------------------------------- #
# Investigate unexpected multiple entries ----
# ---------------------------------------------------------------------------- #

# Note: The multiple entries at "Eligibility" in "dass21_as" or "oa" tables (and those for 
# "DASS21_AS" "task_name" at "Eligibility" in "task_log" table) reflect multiple 
# screening attempts. These were already handled in a code section above.

# Note, however, that multiple "dass21_as" or "oa" screening attempts are reflected in 
# "task_log" only for some participants. Thus, "task_log" should not be used to identify 
# repeated screening attempters.

# Also note that "task_log" does not reflect other kinds of multiple entries. Do 
# not rely on "task_log" to find multiple entries or reflect task completion.

# We now investigate other cases of multiple entries based on the console output 
# from the section above.

#   1 duplicated rows for table: affect
#   With these ' participant_id ':  2805

View(dat$affect[dat$affect$participant_id == 2805, ])
# Participant has two "pre" entries for "thirdSession". Decide which to remove. 

#   1 duplicated rows for table: covid19
#   With these ' participant_id ':  3569

View(dat$covid19[dat$covid19$participant_id == 3569, ])
# All same responses and same exact time, but separate ID #s for some reason. Can remove either row. 

#   1 duplicated row for table: email_log
#   With these ' participant_id ':  2759 

View(dat$email_log[dat$email_log$participant_id == 2759, ])
# Participant got reset password email twice on 7/20/21, one having the message "Mail server connection failed; 
# nested exception is javax.mail.MessagingException: Could not connect to SMTP host: smtp.mail.virg". Can remove this row (39301). 

#   2 duplicated rows for table: gift_log
#   With these ' participant_id ':  2731 2733

View(dat$gift_log[dat$gift_log$participant_id == 2731, ])
# All same responses and same exact time, but separate ID & X #s for some reason. Can remove either row. 

View(dat$gift_log[dat$gift_log$participant_id == 2733, ])
# All same responses and same exact time, but separate ID & X #s for some reason. Can remove either row. 

#   1 duplicated rows for table: reasons_for_ending
#   With these ' participant_id ':  2260

View(dat$reasons_for_ending[dat$reasons_for_ending$participant_id == 2260, ])
# Same day, just a few minutes apart. The second entry has all null/0 inputs. Decide which to remove. 



# ---------------------------------------------------------------------------- #
# Handle unexpected multiple entries ----
# ---------------------------------------------------------------------------- #

# Define function to compute number of entries ("n_rows") for a given set of index 
# columns ("index_cols") in a table, mean values for the table's "time_on_" column
# ("time_on_col"; e.g., "time_on_page") across the entries ("<time_on_col>_mean"), 
# and number of entries that have unique responses ("n_unq_item_rows") to a given set 
# of items ("item_cols"). If multiple unique entries are present (i.e., "n_unq_item_rows" 
# > 1), we compute column means for all items ("<item>_mean"), treating "Prefer Not to 
# Answer" as NA (i.e., take mean of available items) without recoding them as NA in the 
# actual table. This way, column means can be analyzed while retaining the values that
# comprise them. If multiple unique entries are absent, we do not compute column means.

compute_n_rows_col_means <- function(df, index_cols, time_on_col, item_cols) {
  # Compute number of rows per index columns
  
  n_rows <- df %>%
    group_by(across(all_of(index_cols))) %>%
    summarise(count=n()) %>%
    as.data.frame()
  
  names(n_rows)[names(n_rows) == "count"] <- "n_rows"
  
  df2 <- merge(df, n_rows, index_cols, all.x = TRUE, sort = FALSE)
  
  # Compute mean "time_on_" column across multiple rows per index columns
  
  time_on_col_mean_name <- paste0(time_on_col, "_mean")
  
  time_on_col_mean <- aggregate(df2[, time_on_col], 
                                as.list(df2[, index_cols]), 
                                mean)
  names(time_on_col_mean) <- c(index_cols, time_on_col_mean_name)
  
  time_on_col_mean[is.nan(time_on_col_mean[, time_on_col_mean_name]), 
                   time_on_col_mean_name] <- NA
  
  df3 <- merge(df2, time_on_col_mean, index_cols, all.x = TRUE, sort = FALSE)
  
  # Compute number of unique rows on item columns per index columns. We will 
  # compute the column mean across the unique item entries.
  
  unique_items <- unique(df[, c(index_cols, item_cols)])
  
  n_unq_item_rows <- unique_items %>% 
    group_by(across(all_of(index_cols))) %>% 
    summarise(count=n()) %>%
    as.data.frame()
  
  names(n_unq_item_rows)[names(n_unq_item_rows) == "count"] <- "n_unq_item_rows"
  
  df4 <- merge(df3, n_unq_item_rows, index_cols, all.x = TRUE, sort = FALSE)
  
  # If multiple unique values on any item per index columns are present, compute 
  # column means across unique values for all items, treating values of "Prefer
  # Not to Answer" as NA without recoding them as NA in the actual dataset
  
  df5 <- df4
  
  unique_items[, item_cols][unique_items[, item_cols] == 555] <- NA
  
  if (any(df5$n_unq_item_rows > 1)) {
    for (i in 1:length(item_cols)) {
      col_name <- item_cols[i]
      col_mean_name <- paste0(item_cols[i], "_mean")
      
      item_mean <- aggregate(unique_items[, col_name], 
                             as.list(unique_items[, index_cols]),
                             mean, 
                             na.rm = TRUE)
      names(item_mean) <- c(index_cols, col_mean_name)
      
      item_mean[is.nan(item_mean[, col_mean_name]), col_mean_name] <- NA
      
      df5 <- merge(df5, item_mean, index_cols, all.x = TRUE, sort = FALSE)
    }
  }
  
  return(df5)
}

# Run function on each table investigated in code section above

covid19_items <- 
  c("checked_in", "childcare", "chores", "control", "cough", "cough_others", "distancing",
    "events", "exercise", "family", "finances", "focus", "food", "friends", "healthcare", "high_risk",
    "laundry", "news", "nose", "nose_others", "partners", "physical", "productivity", "products_additional",
    "products_more", "sanitizer", "sleep", "social_media", "touching", "upset", "wellbeing", "work", "worry",
     "brightside", "emotions", "plan", "problem", "reality", "support", "thoughts", "covid_know", "diagnosis",
    "mask", "symptoms", "symptoms_date","symptoms_date_no_answer", "test_antibody", "test_antibody_date",
    "test_antibody_date_no_answer", "test_antibody_result", "test_covid","test_covid_date", "test_covid_date_no_answer",
    "test_covid_result")

dat$covid19 <- compute_n_rows_col_means(dat$covid19, 
                                      c("participant_id", "session_only"),
                                      "time_on_page",
                                      covid19_items)

dat$reasons_for_ending <- compute_n_rows_col_means(dat$reasons_for_ending, 
                                   c("participant_id", "session_only"),
                                   "time_on_page",
                                   c("connected", "easy", "focused", "forgot", "hard_to_read", "hard_to_understand",
                                     "helpful", "in_general", "interest","internet", "looked", "navigation_hard", "not_useful",
                                     "personal_issues", "point_in_control", "privacy", "work", "take_too_long", "thought_in_control",
                                     "too_many_words", "trust", "understand_assessments", "understand_training" ))

# ---------------------------------------------------------------------------- #
# Arrange columns and sort tables ----
# ---------------------------------------------------------------------------- #

# Arrange columns "X", "id", "participant_id", "session_only", and "tag" to left
# in tables that contain them

start_cols <- c("X", "id", "participant_id", "session_only", "tag")
start_cols_rev <- rev(start_cols)

for (i in 1:length(dat)) {
  for (j in 1:length(start_cols_rev)) {
    if (start_cols_rev[j] %in% names(dat[[i]])) {
      col_names <- c(start_cols_rev[j], 
                     names(dat[[i]])[names(dat[[i]]) != start_cols_rev[j]])
      dat[[i]] <- dat[[i]][, col_names]
    }
  }
}

# "X" (row name in Data Server database) is in every table and uniquely identifies 
# every row, whereas "id", though in every table, does not distinguish all rows

all(as.logical(lapply(dat, function(x) { length(x$X) == length(unique(x$X)) })))

lapply(dat, function(x) { length(x$id) == length(unique(x$id)) })

# Sort tables by "X", mimicking the sorting upon dump of Data Server database

dat <- lapply(dat, function(x) { x[order(x$X), ] })

# Note from Max: here, again, if it runs, that's the check!


# ---------------------------------------------------------------------------- #
# Export intermediately cleaned data ----
# ---------------------------------------------------------------------------- #

# Ensure that consistent format with timezone will output when writing to CSV. 
# Given that these columns will be read back into R as characters, they will need 
# to be converted back to POSIXct using "as.POSIXct" function (with "tz = 'UTC'"
# for user-provided "return_date_as_POSIXct" of "return_intention" table and "tz 
# = 'EST'" for all system-generated timestamps).

for (i in 1:length(dat)) {
  POSIXct_colnames <- c(names(dat[[i]])[grep("as_POSIXct", names(dat[[i]]))],
                        "system_date_time_earliest",
                        "system_date_time_latest")
  dat[[i]][, POSIXct_colnames] <- format(dat[[i]][, POSIXct_colnames],
                                         usetz = TRUE)
}

# ---------------------------------------------------------------------------- #
# Add GIDI-UP table to full data ----
# ---------------------------------------------------------------------------- #

# Merge the GIDI-UP 12 month data into our full dat dataset as a new table; this part has to come basically last because
# the table does not have the same column names as the rest of the data, so the above steps will not properly run with it in.
dat$gidiup_12month=gidiup_12month

# Write intermediately cleaned CSV files

dir.create("./data/3_intermediate_clean")

for (i in 1:length(dat)) {
  write.csv(dat[[i]], 
            paste0("./data/3_intermediate_clean/", names(dat[i]), ".csv"),
            row.names = FALSE)
}

