# ---------------------------------------------------------------------------- #
# Define Functions
# Author: Jeremy W. Eberle
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# Define version_control() ----
# ---------------------------------------------------------------------------- #

# Define function to check R version, load groundhog package, and return groundhog_day

version_control <- function() {
  # Ensure you are using the same version of R used at the time the script was 
  # written. To install a previous version, go to 
  # https://cran.r-project.org/bin/windows/base/old/
  
  script_R_version <- "R version 4.2.3 (2023-3-15)"
  
  # As of August 7 2023, Kaitlyn Petz ran through all Calm Thinking code with version 4.2.3 of R (rather than version 4.0.3), 
  # and all scripts run the same. Thus, we will use new versions of R (4.2.3) for cleaning the TET data, as we know the code
  # will run the same. This function will remain in the code to keep it as similar to Calm Thinking as possible, but note
  # that the current R version will NOT be the same as the script R version (4.2.3 vs 4.0.3). 
  
  current_R_version <- R.Version()$version.string
  
  if(current_R_version != script_R_version) {
    warning(paste0("This script is based on ", script_R_version,
                   ". You are running ", current_R_version, "."))
  }
  
  # Load packages using "groundhog", which installs and loads the most recent
  # versions of packages available on the specified date ("groundhog_day"). This 
  # is important for reproducibility so that everyone running the script is using
  # the same versions of packages used at the time the script was written.
  
  # Note that packages may take longer to load the first time you load them with
  # "groundhog.library". This is because you may not have the correct versions of 
  # the packages installed based on the "groundhog_day". After "groundhog.library"
  # automatically installs the correct versions alongside other versions you may 
  # have installed, it will load the packages more quickly.
  
  # If in the process of loading packages with "groundhog.library" for the first 
  # time the console states that you first need to install "Rtools", follow steps 
  # here (https://cran.r-project.org/bin/windows/Rtools/) for installing "Rtools" 
  # and putting "Rtools" on the PATH. Then try loading the packages again.
  
  library(groundhog)
  meta.groundhog("2023-04-20")
  groundhog_day <- "2023-04-20"
  
  # We are updating this date to be inclusive of R version 4.2.3, between 4-20-2023 and
  # 4-22-2023 as instructed by R Studio in the 4_clean_data script. Making the date 4-20-2023
  # measn that groundhog will run according to the R 4.2.3 version.
  
  return(groundhog_day)
}
