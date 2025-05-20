# MT-Data-TETOffensiveStudy

This repository is the knowledge base for the MindTrails TET Offensive Study (TET) dataset. For more information about the TET Offensive Study, see the [TET Offensive page](https://sites.google.com/a/virginia.edu/mindtrails-wiki/studies/calm-thinking-variations-r01) of the [MindTrails Wiki](https://sites.google.com/a/virginia.edu/mindtrails-wiki/home).

## Contact

If you are a researcher who wants to contribute to this project, please contact Bethany Teachman at bteachman@virginia.edu. Thanks!

## README Authors: Jeremy W. Eberle, Kaitlyn Petz, & Maria “Max” Larrazabal

This README describes centralized data cleaning for the [MindTrails Project](https://mindtrails.virginia.edu/) Testing Engagement and Transfer (TET) study, an NIMH-funded ([R01MH113752](https://reporter.nih.gov/project-details/9513058)) randomized controlled trial of web-based interpretation bias training for anxious adults (enrollment started 4/2/2020, and enrollment and data collection ended on 2/7/2025 when the MindTrails servers were shut down, stopping any participants from signing into the program). **Importantly, we only have reliably protected and cleaned data up to October 4, 2023 (N = ~3500), the last time the data was pulled from the server before things started shutting down.** We have most data from November 2023-February 2025, but it is not formatted or cleaned the same as the data up to Oct. 2023, so we caution researchers to carefully review and clean this data before combining it with the data up to Oct. 2023 if using. The primary goal of TET is to compare the effectiveness of four different versions of CBM-I in reducing interpretation bias and anxiety, with psychoeducation as an active comparator. The study includes an eligibility screening, pretreatment assessment, five sessions of training and assessment, and a 2-month follow-up assessment.

The data cleaning also encompasses data collected for GIDI (named after the [Global Infectious Disease Institute](https://gidi.virginia.edu/about-gidi), a substudy of TET funded by a GIDI Rapid Response Grant in which TET participants who completed the first session’s training and assessment between July to December 2020 were invited to complete a 6-month follow-up assessment. Enrollment in GIDI was open from 7/10/2020 through 12/12/2020, and data collection ended on 10/12/2021. This data cleaning also encompasses data collected for GIDI-UP, a 12-month follow-up assessment distributed to all 609 participants enrolled in GIDI, funded by the GIDI-UP Summer Research Award. Data collection for this 12-month follow-up opened on 11/30/2022 and closed on 12/2/2023 (three months after the Qualtrics survey was made available to all participants). 

This README and the associated cleaning scripts were adapted from the [MindTrails Calm Thinking study](https://github.com/TeachmanLab/MT-Data-CalmThinkingStudy/blob/master/README.md) README and scripts (v1.0.1) authored by Jeremy W. Eberle ([Eberle et al., 2022](https://doi.org/10.5281/zenodo.6192907)). The Calm Thinking study and the TET/GIDI studies’ data are structured identically (they are stored in the same database), and much of the cleaning code written for Calm Thinking also applies to the TET/GIDI data. Thus, the README and cleaning scripts are similar to those for the Calm Thinking study, but include extra pieces relevant for TET/GIDI. We ran the Calm Thinking scripts on TET/GIDI data and implemented checks to confirm that all cleaning still occurred successfully.   
For questions, please contact [Kaitlyn Petz](kdp8y@virginia.edu).

## Data Cleaning
### Data on Open Science Framework
Raw and centrally cleaned data from the "calm" SQL database are stored in the [MindTrails TET Offensive Study](https://osf.io/xfn3k/) (which includes GIDI substudy data) and [MindTrails GIDI Study](https://osf.io/47ws2/) (which is restricted to GIDI substudy data) projects on the Open Science Framework (OSF). The additional GIDI-UP data will also be stored in both OSF projects. The projects have two components, with different permissions: a Private Component and a Public Component.

### Private Component
The Private Component contains the full set of 67 raw data tables (with some exceptions) for TET and GIDI dumped from the "calm" SQL database on the "teachmanlab" Data Server on October 4, 2023 (using the steps outlined in the document titled “PUBLIC Instructions for MindTrails teachmanlab Server Data Pull.pdf” on the Private Component of the OSF page. (this Google document will be a PDF on the OSF but im keeping the link here for now for you jwe4ec@virginia.edu) 

This component also contains the 2 GIDI-UP data tables required for cleaning. GIDI-UP data were collected via Qualtrics on Max Larrazabal’s UVA Qualtrics account, and the data was later shared with Kaitlyn to put into this data cleaning pipeline. Participants were invited to complete this survey approximately 12 months following the conclusion of their participation in MindTrails, marked by their completion of Session 5. Max supplied Kaitlyn with the raw Qualtrics data for the purposes of data cleaning. The folder structure of a version's ZIP file is below.

The exceptions are that only redacted versions of "gift_log", "import_log", and "sms_log" tables are included (redacted using 3_redact_data.R).

```
.
├── data
├── ├── 1_raw_full               # 67 CSV files (e.g., "dass21_as-04_10_2023.csv", "angular_training-04_10_2023.csv", 
                                 #   "gift_log-04_10_2023-redacted.csv")
├── ├── 1_raw_qualtrics       	   # 2 CSV files with GIDI-UP data
├── materials
├── ├── data server # “PUBLIC Instructions for MindTrails teachmanlab Server Data Pull
├── ├──appendices               # Appendices
└── └── codebooks                # Codebooks
```

Researchers can request access to files on this component by contacting the study PI (bat5x@virginia.edu).

### Public Component
The Public Component contains a partial set of raw data tables (i.e., those obtained from the calm database using the instructions outlined in the Private Component section above that did not need redaction), redacted tables (from 3_redact_data.R), and intermediately clean tables for both TET and GIDI on the TET OSF project, and just GIDI on the GIDI OSF project (from 4_clean_data.R). It also contains the 2 GIDI-UP data tables required for cleaning. The structure of a version's ZIP file is below.
Note: Tables in the 1_raw_full folder of the Private Component that are not in the 1_raw_partial folder of this Public Component contain free-text responses that may or may not have identifiers. In the Public Component, redacted versions of such tables are in 2_redacted.

```
.
├── data                    
├── ├── 1_raw_calm_partial       # 53 CSV files (did not need redaction; e.g., "dass21_as-04_10_2023.csv")
├── ├── 1_raw_qualtrics   	   # 2 CSV files with GIDI-UP data
├── ├── 2_redacted               # 14 CSV files (needed redaction; e.g., "angular_training-04_10_2023-redacted.csv", 
│   │                            #   "gift_log-04_10_2023-redacted.csv")
├── ├── 3_intermediate_clean     # 51 CSV files (note: 17 files were deemed irrelevant and removed during cleaning)
├── materials
├── ├── appendices               # Appendices
└── └── codebooks                # Codebooks
```

### TET Data past October 2023 
The data after the pull on October 4, 2023 was not reliably stored in one place as servers began shutting down, so it is not cleaned or organized the same as the other data files. All data past October 4, 2023 will live in its own OSF folder labeled as such. As a reminder, this data was downloaded sporadically and not cleaned using these rigorous data cleaning scripts, and so we recommend that researchers very carefully review and clean this data before using it, or only use data up to October 2023. 

**The rest of the README contains information solely on data cleaning of the data up until the October 4, 2023 data pull. No data cleaning besides innate cleaning in the downloading process has been performed on data past October 2023.**

## Cleaning Scripts: Setup and File Relations
The scripts in the code folder of this repository import the full raw data files, redact certain files, and clean the redacted and remaining raw files to yield intermediately clean files. The resulting files are considered only intermediately cleaned because further analysis-specific cleaning will be required for any given analysis.
To run the cleaning scripts, create a parent folder (with any desired name, indicated by . below) with two subfolders: data and code. The working directory must be set to the parent folder for the scripts to import and export data correctly using relative file paths.

```
.                                # Parent folder (i.e., working directory)
├── data                         # Data subfolder
└── code                         # Code subfolder
```

If you have access to the full raw data (from the Private Component), you can reproduce the redaction. You will have 2 folders with raw data files, 1 called “1_raw_calm_full” with the full raw data from the calm server, and 1 called “1_raw_qualtrics” with the full raw data from Qualtrics for the GIDI-UP study. When you run the scripts, 3_redact_data.R will create 2_redacted and files therein, and 4_clean_data.R will create 3_intermediate_clean and files therein.
4_clean_data.R will also create docs containing data_filenames.txt, which documents the names of data files the cleaning scripts are based on.

```
.
├── data                    
├── ├── 1_raw_calm_full          # 67 CSV files from Private Component
├── ├── 1_raw_qualtrics   	   # 2 CSV files with GIDI-UP data
├── ├──(2_redacted)              # Folder with 14 CSV files will be created by "3_redact_data.R"
├── └──(3_intermediate_clean)    # Folder with 51 CSV files will be created by "4_clean_data.R"
├── (docs)
├── └── (data_filenames.txt)     # Names of CSV files cleaning scripts are based on
└── ...
```

If you have access to the partial raw data and the redacted data (from the Public Component), you will have 2 folders with raw data files – 1 called “1_raw_calm_full” with the partial raw data from the calm server, and 1 called “1_raw_qualtrics” with the full raw data from Qualtrics for the GIDI-UP study – and 1 folder with the redacted data files called “2_redacted”. When you run the scripts, 4_clean_data.R will create 3_intermediate_clean and files therein.
4_clean_data.R will also create docs containing data_filenames.txt, which documents the names of data files the cleaning scripts are based on.

```
.
├── data                    
├── ├── 1_raw_calm_partial            # 53 CSV files from Public Component
├── ├── 1_raw_qualtrics   	   # 2 CSV files with GIDI-UP data
├── ├──(2_redacted)              # Folder with 14 CSV files will be created by "3_redact_data.R"
├── └──(3_intermediate_clean)    # Folder with 51 CSV files will be created by "4_clean_data.R"
├── (docs)
├── └── (data_filenames.txt)     # Names of CSV files cleaning scripts are based on
└── ...
```

Put the cleaning scripts in the code subfolder. The scripts are to be run in the order listed. Assuming you already have full or partial raw data, start with 2_define_functions.R. If you have full raw data, run 3_redact_data.R next; otherwise, skip it. Run the remaining scripts.
At the top of each R script, restart R (CTRL+SHIFT+F10 on Windows) and set your working directory to the parent folder (CTRL+SHIFT+H).

```
.
├── ...
├── code
├── ├── 1_get_raw_data.ipynb     # Dump 67 CSV files from "calm" SQL database on Data Server (for "1_raw_calm_full")
├── ├── 2_define_functions.R     # Define functions for use by subsequent R scripts
├── ├── 3_redact_data.R          # Redact 14 CSV files from "1_raw_full" and output them to "2_redacted"
├── ├── 4_clean_data.R           # Clean 14 CSV files from "2_redacted", 2 CSV files from “1_raw_qualtrics”, and 53 CSV files from "1_raw_calm_full"
│   │                            #   or "1_raw_calm_partial" and output 51 CSV files to "3_intermediate_clean"
└── └── 5_import_clean_data.R    # Import 51 CSV files from "3_intermediate_clean"
```

On a Macbook 12-inch 2017 laptop, the R scripts run in 18 min. As noted in 2_define_functions.R, packages may take longer to load the first time you load them with groundhog.library. After that, the runtimes below should apply.
* 3_redact_data.R = 4 min
* 4_clean_data.R = 13 min
* 5_import_clean_data.R = 1 min

## Cleaning Scripts: Functionality
### 1_get_raw_data.ipynb
This Jupyter Notebook script (author: Sonia Baee) dumps the full set of 67 raw CSV files from the "calm" SQL database on the "teachmanlab" Data Server as of the date of the last data pull (which is 10/4/2023) when used with the steps outlined in the document titled “PUBLIC Instructions for MindTrails teachmanlab Server Data Pull.pdf” on the Private Component of the OSF page. 

### 2_define_functions.R
This R script defines functions for use by subsequent R scripts, which source this file at the top of each script.
Version control for R scripts is achieved by checking that the R version used to write the scripts ("R version 4.2.3 (2023-3-15)") matches the user's R version and by defining dates for meta.groundhog and groundhog_day, which are used by the groundhog package to load the versions of R packages that were used to write the scripts. See script for details.

### 3_redact_data.R
This R script performs the following functions. Here, redact means to replace relevant values with "REDACTED_BY_CLEANING_SCRIPT", retaining the structure of the raw data files.
- Specify columns to retain that were considered for redaction
- Determine which "button_pressed" data in "angular_training" table to redact
- Redact "button_pressed" data for "FillInBlank" rows in "angular_training" table
- Redact free-text responses for certain other columns that may contain identifiers
- Redact "order_id" data from "gift_log" and "import_log" tables
- Redact phone numbers from "sms_log" table
  
Note: So that "order_id" and phone number data are not retained in the full raw data, only redacted versions of the "gift_log", "import_log", and "sms_log" tables are stored in 1_raw_full, and the unredacted versions dumped by 1_get_raw_data.ipynb were deleted.

By contrast, unredacted versions of other redacted tables are retained in 1_raw_full on the Private Component because these tables contain free-text responses that may or may not contain identifiers. Notably, participants were not asked to provide identifiers in their responses.

### 4_clean_data.R
After documenting names of data files the cleaning scripts are based on, this R script performs the following functions.

#### Part I. Database-Wide Data Cleaning
Part I applies to data for all three studies (Calm Thinking, TET, GIDI) in the "calm" SQL database.
- Recode binary variables
- Remove irrelevant tables
- Rename "id" columns in "participant" and "study" tables
- Add "participant_id" to all participant-specific tables (see Participant Indexing for details)
- Correct test accounts (see Test Accounts for details)
- Remove admin and test accounts
- Label columns redacted by server with "REDACTED_ON_DATA_SERVER"
- Remove irrelevant columns
- Identify any remaining blank columns
- Identify and recode time stamp and date columns
  - Correct blank "session", "date", and "date_submitted" in "js_psych_trial" table for some participants
  - Recode system-generated timestamps as POSIXct data types in "EST" and user-provided timestamps as POSIXct data types in "UTC"
    - Includes checking for any corrupted timestamp data and removing those rows (as of December 2024, this applies to only row one of the “js_psych_trial” table that lacked meaningful data)
  - Create variables for filtering on system-generated time stamps (see Filtering on System-Generated Timestamps for details)
  - Reformat user-provided dates so that they do not contain empty times, which were not assessed
- Identify and rename session-related columns (see Session-Related Columns for details)
- Check for repeated columns across tables (see Repeated Column Names for details)
- Correct study extensions (see Study Extensions for details)

#### Part II. Filter Data for Desired Study
Part II filters data for the specific study of interest; the "study_name" can be changed to filter data for TET, GIDI, or both TET and GIDI studies if desired. (Because GIDI is a substudy of the TET parent trial, most analyses of TET data should include both TET and GIDI data to retain all participants randomly assigned to condition in TET.)
- Define enrollment period and participant_ids (see Enrollment Period for details)
  - Note: This will now be marked as October 4, 2023, the date of the last reliable TET data pull, as no data past this date will exist in the reliable dataset and these scripts should likely not be run on the data collected past October 2023. 
- Filter all data

#### Part III: TET/GIDI Study-Specific Data Cleaning
Part III cleans the TET and GIDI data. 
- Note lack of data for some tables 
- Recode "coronavirus" column of "anxiety_triggers" table 
- Exclude participants from other studies
  - Remove MindTrails Movement participants
  - Remove GIDI participants, if you are analyzingTET data without including GIDI substudy participants (generally not recommended)
- Remove participant IDs associated with post-study data (if a participant requests to continue using MindTrails after their study period has ended, we assign them a new participant ID so they can re-enroll in the TET study; we need to exclude these new participant IDs from analyses)
- Check for duplicate participant IDs
- Obtain time of last collected data
- Identify participants with inaccurate "active" column (see "active" Column for details)
- Check "conditioning" values in "angular_training" and "study" tables
  - Note that "conditioning" is blank for some rows of "angular_training"
  - Check that condition stays the same from "firstSession" through "fifthSession"
  - Check for "conditioning" at Session 5 in "angular_training" table not matching "conditioning" at "COMPLETE" in "study" table
- Clean "reasons_for_ending" table
- Exclude screenings resembling bots
- Identify and remove nonmeaningful duplicates
- Handle multiple screenings (see Multiple Screening Attempts for details)
  - Correct "participant_id" not linking to all screening attempts for corresponding "session_id"
  - For duplicated values on DASS-21-AS items, "over18", and "time_on_page" and duplicated values on OASIS item “time_on_page” for a given "session_id" and "session_only", keep last row
  - Compute number of multiple rows per "session_id" at screening, mean "time_on_page" across these rows, and number of unique rows
  - Compute column mean of unique values on DASS-21-AS and OASIS items per "session_id"
  - Compute DASS-21-AS total score "dass21_as_total" and OASIS total score as “oasis_total” (as computed by system, not accounting for multiple entries)
  - Multiply "dass21_as_total" score by 2 to compute "dass21_as_total_interp", and create “oasis_total_interp”, for interpretation against eligibility criterion
  - Create indicators "dass21_as_eligible" and “oasis_eligible” to reflect eligibility on DASS-21-AS and OASIS 
  - Compute DASS-21-AS total score "dass21_as_total_anal" and OASIS total score “oasis_total_anal” for analysis (accounting for multiple entries at screening)
- Report participant flow up to enrollment and identify analysis exclusions (see Participant Flow and Analysis Exclusions for details)
  - Report number of participants screened, enrolled, and not enrolled (for not enrolled, report reason based on most recent entry)
  - Identify session_ids of participants who did not enroll to be excluded from any analysis of screening data
  - Identify participant_ids of participants who did enroll to be excluded from any analysis
  - Create indicator "exclude_analysis" to reflect participants who should be excluded from analysis and add it to "participant" table
- Check for participants who do not have screener data but were enrolled in the study
- Add GIDI-UP 12-month follow-up data from Qualtrics
  - Import CSV files containing survey data and participant IDs
  - Link Qualtrics data to MindTrails participant IDs
  - Remove duplicates and admin and test accounts
  - Compute final DASS-21 and OASIS scores
  - Merge GIDI-UP table into full data
- Identify unexpected multiple entries (see Unexpected Multiple Entries for details)
- Investigate unexpected multiple entries (see Unexpected Multiple Entries for details)
- Handle unexpected multiple entries (see Unexpected Multiple Entries for details)
- Arrange columns and sort tables (see Table Sorting for details)

### 5_import_clean_data.R
This R script imports the intermediately cleaned TET and/or GIDI study data and converts system-generated timestamps back to POSIXct data types given that 4_clean_data.R outputs them as characters. As such, this script serves as a starting point for further cleaning and analysis.

#### Further Cleaning and Analysis Considerations
This section highlights some considerations prompted by data cleaning that may be relevant to further cleaning or to analysis. Refer to the actual script for more details.
For Calm Thinking Study, TET Study, and GIDI Substudy

#### Participant Indexing
Part I of 4_clean_data.R indexes all participant-specific data by "participant_id". Refer to participants by "participant_id" (not "study_id").
Filtering on System-Generated Timestamps

Part I of 4_clean_data.R creates "system_date_time_earliest" and "system_date_time_latest" in each table in the “calm” database (i.e., not for the GIDI-UP table, which stemmed from Qualtrics data) given that some tables have multiple system-generated timestamps. They are the earliest and latest timestamps for each row in the table--useful for filtering the entire dataset.

#### Session-Related Columns
Part I of 4_clean_data.R reveals that in some tables from the “calm” database (e.g., "dass21_as") "session" conflates time point with other information (e.g., eligibility status). Here, "session" is renamed to reflect the information it contains (e.g., "session_and_eligibility_status"), and "session_only" is created to reflect only the time point. In some tables (i.e., "angular_training", "gift_log") it is unclear how to extract the time point, so these tables lack "session_only". In tables where "session" does not conflate time point with other information, "session" is renamed "session_only".
Thus, "session_only" is the preferred column for filtering by time point, but not all tables have it. Moreover, "session_only" includes values of "COMPLETE" in some tables (i.e., "action_log", "email_log") but not others (i.e., "task_log"). The GIDI-UP table also lacks “session_only”. Thus, filter by time point with care.
Repeated Column Names

Part I of 4_clean_data.R reveals that although some tables from the “calm” database contain the same column name, the meanings of the columns differ. As a result, care must be taken when comparing columns between tables. See the cleaning script for explanations of repeated column names.

#### Study Extensions
Part I of 4_clean_data.R corrects the "study_extension" for participants 2004 and 2005, who are enrolled in Calm Thinking.
Enrollment Period

Part II of 4_clean_data.R defines the enrollment periods for Calm Thinking, TET, and GIDI in the "America/New_York" timezone, as this is the study team's timezone. "America/New_York" is preferred to "EST" because "America/New_York" accounts for switches between "EST" and "EDT". By contrast, system-generated timestamps are stored only in "EST" as this is how they are stored in the "calm" SQL database.

Enrollment periods are used to filter screening data, most of which is not indexed by "participant_id" but required for participant flow diagrams.

Note: Once TET enrollment closes, an “official_enroll_close_date” timestamp will need to be added to this section. 

#### For TET Study and GIDI Substudy
#### "active" Column
Part III of 4_clean_data.R indicates that for "active" in "participant" table, some participants are mislabeled as active when they are inactive, or inactive when they are active. The "active" column may have affected final reminder emails or notices of account closure. Thus, the mislabeled data are retained to reflect potential unexpected behavior of the site for these participants.

#### Remove Participant IDs Associated With Post-Study Data 
Part III of 4_clean_data.R describes how to remove participants who have two participant IDs due to re-enrolling in the TET study after they have completed all TET assessments . Participants in the control condition who want to try CBM-I, or CBM-I participants who want to continue CBM-I, are able to do so by requesting a new account from our tech team (we “migrate” their email address from their old participant ID to a new participant ID). Thus, we must exclude from analyses the new participant ID associated with the data after the participant’s study period. Researchers with admin access on the MindTrails site can find participants who have post-study data by searching on the user administration page for participant email addresses that have “migrated” in the email address name; the participant ID associated with this email address has the real study data for the participant. Then, search for the participant’s email address without “migrated” in the name, and the participant ID currently associated with this email address has the participant’s post-study data; thus, that is the participant ID that needs to be excluded. The MindTrails team tries to log all participants who re-enroll post-study in the Changes and Issues log to find and add participant IDs to exclude to the cleaning script easily. The script must be updated with the current set of participant IDs to exclude at the time of each data pull.

#### Condition Switching
Part III of 4_clean_data.R reveals various cases of unexpected values for "conditioning" in "angular_training". See cleaning script for details.

#### Multiple Screening Attempts
After removing nonmeaningful duplicates (i.e., for duplicated values on every column in table except "X" and "id", keep last row after sorting by "id") for all tables, Part III of 4_clean_data.R first corrects cases where "participant_id" is not linked to all screening attempts by its corresponding "session_id" in "dass21_as" or “oa” tables.
Second, the script removes duplicates on DASS-21-AS items, "over18", and "time_on_page" columns in "dass21_as" table and on OASIS items and the “time_on_page” column in “oa” table for a given "session_id" and "session_only" time point by keeping the last row after sorting by "session_id", "session_only", and "id". The idea is that duplicates on these columns do not reflect unique screening attempts.

Third, the script counts the number of multiple screening attempts remaining for each "session_id" at screening ("n_eligibility_rows") and computes the mean "time_on_page" across those rows for each "session_id". This "time_on_page_mean" is used for analysis. It represents the mean time a given "session_id" spent on the page across their screening attempts, which could reflect different responses on DASS-21-AS or OASIS items, different responses on "over18", or both.

To isolate unique responses on DASS-21-AS and OASIS items, the script counts the number of unique rows on DASS-21-AS and OASIS items for each "session_id" at screening ("n_eligibility_unq_item_rows_dass" and “n_eligibility_unq_item_rows_oa”). The study team decided that participants with more than two sets of unique rows on DASS-21-AS or OASIS items will be excluded from analysis due to concerns about data integrity, whereas those with two sets of unique rows on DASS-21-AS or OASIS items will be included, even if they have two or more entries for "over18". The script does not exclude the former participants, but rather marks them for exclusion (see Participant Flow and Analysis Exclusions).

Fourth, the script computes column means for DASS-21-AS and OASIS items across these unique DASS-21-AS and OASIS item rows for each "session_id", treating values of "prefer not to answer" as NA without recoding them as NA in the actual table. These column means are used to compute a total score for analysis ("dass21_as_total_anal" and "oasis_total_anal") below.

Fifth, the script seeks to distinguish whether a given ineligible screening attempt is ineligible due to the DASS-21-AS or OASIS responses or due to age. Given that the site allows multiple screening attempts and scores each in isolation from the others, the script computes a total score for each attempt ("dass21_as_total" and “oasis_total”) by taking the mean of available DASS-21-AS items (again treating values of "prefer not to answer" as NA without actually recoding them) and multiplying by 7, or by taking the mean of available OASIS items (again treating values of "prefer not to answer" as NA without actually recoding them) and multiplying by 5.

Sixth, this per-attempt "dass21_as_total" score is multiplied by 2 to get "dass21_as_total_interp", which is compared with the criterion (>= 10 is eligible), and the "oasis_total" score is duplicated to get "oasis_total_interp", which is compared with the criterion (>= 6 is eligible). Seventh, the script creates "dass21_as_eligible" and "oasis_eligible" to indicate eligibility status on the DASS-21-AS and OASIS–used to report participant flow.

Finally, the script computes a per-"session_id" total DASS-21-AS and OASIS scores for analysis ("dass21_as_total_anal" and "oasis_total_anal") by taking the mean of available DASS-21-AS column means (from above; again treating values of "prefer not to answer" as NA without actually recoding them) and multiplying by 7 and taking the mean of available OASIS column means (from above; again treating values of "prefer not to answer" as NA without actually recoding them) and multiplying by 5. Given that these scores account for multiple unique rows on DASS-21-AS or OASIS items, use this as the baseline score in analysis.

#### Participant Flow and Analysis Exclusions
Part III of 4_clean_data.R reports number of participants screened, enrolled, and not enrolled.

For participants with multiple entries who did not enroll, the script bases the reason they did not enroll on their last entry, though recognizing that non-enrollment following each attempt could have occurred for a different reason. 

Participants with more than two unique rows on DASS-21-AS or OASIS items ("n_eligibility_unq_item_rows_dass" or “n_eligibility_unq_item_rows_oa” > 2) are marked for exclusion from analysis using "exclude_analysis" in "dass21_as", “oa”, and "participant" tables. 

However, note that, per CONSORT, analysis exclusions still appear in participant flow diagrams until the analysis stage, where numbers excluded (with reasons) are listed. Therefore, ensure these participants are not excluded too early in your procedure for generating the flow diagram.

#### Enrolled Participants Without Screening Data
Part III of 4_clean_data.R finds that two participants, participant IDs 3659 and 4949, were assigned participant IDs (meaning that they enrolled in the study) but do not have any screening data. This occurs because of the way that the eligibility screening data are tied to participant IDs. If a participant keeps the screening page open and does not submit it for an extended period (e.g., 30 min), during which the browser session resets, then their screening data will not get associated with the participant ID they receive upon creating an account. This is important to note for creating participant flow diagrams, as such participants do not show up when looking just at screening numbers, but should be counted in enrollment. 

#### Adding GIDI-UP Qualtrics Data
Part III of 4_clean_data.R imports the GIDI-UP 12-month follow-up Qualtrics data CSV file and the participant ID linking CSV file. GIDI-UP participants were given a unique ID number to enter into Qualtrics, which is different from their MindTrails participant ID. Thus, we merge these two tables so that we have a MindTrails participant ID associated with each GIDI-UP Qualtrics ID. 

Then, we compute total DASS-21-AS and OASIS scores similarly to as outlined above. 

Further cleaning steps will need to be taken on the GIDI-UP data for a given analysis project. 

#### Unexpected Multiple Entries
After removing nonmeaningful duplicates (i.e., for duplicated values on every column in table except "X" and "id", keep last row after sorting by "id") for all tables, Part III of 4_clean_data.R checks for unexpected multiple entries for all tables except for the GIDI-UP table (e.g., multiple rows for a given "participant_id" and "session_only" time point where only one row is expected). However, it is unclear how to check for multiple entries in "angular_training" and "js_psych_trial" tables, so they are not precisely checked.

Note: "task_log" does not reflect some entries in other tables ("dass21_as", "credibility"). Thus, do not rely on "task_log" to find multiple entries or reflect task completion.

Besides multiple screening attempts, multiple entries are handled by computing (a) number of rows ("n_rows") for a given set of index columns (e.g., "participant_id", "session_only"); (b) mean "time_on_" values (e.g., "time_on_page") across those rows, for use in analysis (e.g., "time_on_page_mean"); and (c) number of rows with unique values for a given set of items ("n_unq_item_rows").

If multiple unique rows are present ("n_unq_item_rows" > 1), we compute column means for all items for analysis, treating values of "prefer not to answer" as NA without actually recoding them. In the script, we report all duplicates and why there are duplicates, and suggest which entry should be removed by those working with the data (but of note we keep duplicates to allow researchers to choose the row they would like to remove for purposes of their analyses).

#### Table Sorting
Given that "X" (row name in "calm" SQL database on "teachmanlab" Data Server) is in every table and uniquely identifies every row, whereas "id", though in every table, does not distinguish all rows, all tables from “calm” database are sorted on "X" before export.

#### Next Steps
As noted above, this centralized cleaning of TET/GIDI data yields data deemed intermediately cleaned because further cleaning will be needed for any given analysis. We focused on issues that cut across multiple tables or that will affect almost any analysis. And in many cases, we opted to flag issues for further cleaning and analysis rather than implement decisions suitable for only a narrow application.
Here are some known next steps for further cleaning and analysis:
- Use 5_import_clean_data.R as a starting point for further cleaning and analysis
- Further clean GIDI-UP 12-month data
- Review the following items and conduct further cleaning as needed for your analysis
- MindTrails Changes and Issues Log entries
- Further consider the following issues not addressed by centralized cleaning
- Exclude participants indicated by "exclude_analysis" in "dass21_as", “oa”, and "participant" tables
- Clean "angular_training" and "js_psych_trial" tables (see outtakes_clean_angular_training.R for details)
- Handle values of "prefer not to answer" (coded as 555; see outtakes_create_reports.R for details)
- Check the response ranges of each item (see outtakes_create_reports.R for details)
- Appropriately handle missing data (see outtakes_create_reports.R for details)

## Resources
### Appendices and Codebooks
Several appendices and codebooks for the TET/GIDI studies are on the Public Component.

### MindTrails Changes and Issues Log
This is a log of site changes, data issues, etc., tagged by study that is privately stored by the MindTrails team. In July 2023, we lost most Changes and Issues Log data prior to this time, but have since created a new log and have changes and issues logged since then. If you address an issue for a specific analysis, please note in the log how you addressed it and provide a link to your code. 
Researchers can request access to relevant information from the log by contacting the study PI (bat5x@virginia.edu).

### MindTrails Wiki
This is a wiki with MindTrails project-wide and study-specific information that is privately stored by the study team.
Researchers can request access to relevant information from the wiki by contacting the study PI (bat5x@virginia.edu).

### Data Integrity Files
The data_integrity folder contains files that were used to check integrity of the data during data collection pre-2023. The files were created and managed by Sonia Baee and Ángel Vela de la Garza Evia. 
