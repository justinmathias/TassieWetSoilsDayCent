###############################################################################
#
# run_DayCent_singlepoint_example.R
#
# Author: Danielle Berardi - Adapted from Melannie Hartman
#
#
# Description:
#   * This R script runs DayCent-CABBI miscanthus and switchgrass grasstree model simulations 
#     for the energy farm.
#   * Uses the version of DayCent-CABBI that can simulate either the traditional
#     1st-order decomposition or microbial explicit version.
#
# 
#
#
###############################################################################

# Reset the variables 
rm(list=ls())

library(tidyverse)
library(lubridate)
# plotting package
library(ggplot2)
library(viridis) #this is a color palette package for ggplot
# data frame manipulations
library(dplyr)
library(readr)



# Path to files
modelPath = "/Users/justinmathias/Library/CloudStorage/OneDrive-UniversityofIdaho/NovemberTassieDaycentPaper/RScripts/DayCent_CABBI_test_som.exe"
setwd(modelPath)

siteName = "enfarm"

# Names of executable programs

daycent <- "DayCent_CABBI_test_som.exe"  # version with perennial and annual grasstrees
list100 <- "list100_DayCent_CABBI_som.exe"

# Set these variables to TRUE to run the spinup, historic simulation, or miscanthus simulation
doSpin = TRUE
doHist = TRUE
doMisc = TRUE
doSwitch = TRUE

# Set soil model
doFirstOrder <- F
doMic <- T

#Assigning a name to identify which model ran
if (doFirstOrder){
  soil <-  "FO"
} else {
  soil <- "Mic"
}

##Best Combo for the Microbial Model == doSMHill & doTQ10
# Set soil moisture effect function
doSMIncreasing <- F
doSMHill <- T #only works with Microbial model

#Assigning a name to identify which soil moisture effect ran
  if (doSMIncreasing) {
    SMeffect <- "IncSM"
  } else {
    SMeffect <-  "HillSM"
  }

#Set soil temperature effect function
doTQ10 <- TRUE
doTExp <- FALSE #only works with Microbial model

#Assigning a name to identify which temperature effect ran
if (doTQ10) {
  Teffect <- "Q10Temp"
} else {
  Teffect <- "ExpTemp"
}


#---------------- Step 1: Run equilibrium DayCent simulation (1-1847) ------------------
#
# This equilibrium simulation takes a long time, so don't execute
# these commands if you already have an equilibrium binary file and 
# you haven't made any changes to any parameter files.

if (doSpin)
{
  scheq = paste(siteName, "eq", sep="_")
  scheqext = paste(scheq, ".sch", sep="")
  bineq = paste0(scheq,soil,Teffect,SMeffect)
  file.copy("outfiles_spin.in", "outfiles.in", overwrite=TRUE)  # Don't save daily files for equilibrium run
  file.copy("eq_enfarm_gt.100", "eq_enfarm.100", overwrite=TRUE)
 
#######Soil Model files #####
####Copy model specific files to run
###If changing parameters in any of these files, change them in ALL applicable files!!
  #Sitepar.in and fix.100 have parameters to select which soil model
  #fix2.100 has parameters to select which temperature and soil moisture effect functions
  #to use in the microbial model. 
   if (doFirstOrder) {
    file.copy("sitepar_Org.in", "sitepar.in", overwrite = TRUE)
     file.copy("fix_Org.100", "fix.100", overwrite = TRUE)
     
   } else {
      file.copy("sitepar_Mic.in", "sitepar.in", overwrite = TRUE)
     file.copy("fix_Mic.100", "fix.100", overwrite = TRUE)
     
  }
  if (doSMIncreasing) {
    if(doTExp){
      file.copy("fix2_IncSM_ExpT.100", "fix2.100", overwrite = TRUE)
      } else {
      file.copy("fix2_IncSM_Q10T.100", "fix2.100", overwrite = TRUE)
    }} 
  if (doSMHill){
    if (doTExp) {
      file.copy("fix2_HillSM_ExpT.100", "fix2.100", overwrite = TRUE)
      }else {
        file.copy("fix2_HillSM_Q10T.100", "fix2.100", overwrite = TRUE)  
      }}
  
    # Standard error and output from DayCent are written to log files 
  # stdout_dc_eq.log, stderr_dc_eq.log
  logfile1 <- "stdout_dc_spin.log"
  logfile2 <- "stderr_dc_spin.log"
  unlink(logfile1)
  unlink(logfile2)
  
  # Run DayCent: DD17centEVI.exe -s <sch file> -n <new bin file>
  bineqext = paste(bineq, ".bin", sep="")
  unlink(bineqext)   # DayCent won't allow you to write over an existing .bin file
  
  args1 <- paste("-s", scheq, "-n", bineq, sep=" ")
  print(paste(daycent, args1, sep=" "))
  #system2(daycent, args=args1, wait=TRUE, stdout=logfile1, stderr=logfile2)
  system(paste(daycent, args1, sep=" "))
  
  # Standard error and output from List100 are written to log files 
  # stdout_list100_eq.log, stderr_list100_eq.log 
  logfile3 <- "stdout_list100_eq.log"
  logfile4 <- "stderr_list100_eq.log"
  unlink(logfile3)
  unlink(logfile4)
  
  # Delete the existing equilibrium .lis file
  lisName <- paste(bineq,".lis", sep="")
  unlink(lisName) # List100 won't allow you to write over an existing .lis file
  
  #Run List100: DD17list100.exe <bin file> <lis file> outvars.txt
  args2 <- paste(bineq, bineq, "outvars.txt", sep=" ")
  print(paste(list100, args2, sep=" "))
  #system2(list100, args=args2, wait=TRUE, stdout=logfile3, stderr=logfile4)
  system(paste(list100, args2, sep=" "))
  
}

if (doHist)
{
  # ---------------- Step 2: Energy Farm Historic Land Use Simulation (1848-2007) ------------------ 
  
  bineq = paste0(siteName, "_eq", soil, Teffect, SMeffect)
  schhlu = paste(siteName, "hlu", sep="_")
  binhlu = paste0(schhlu, soil, Teffect, SMeffect)
  file.copy("outfiles_hlu.in", "outfiles.in", overwrite=TRUE) # Save daily files for experiment runs
  
  #######Soil Model files #####
  ####Copy model specific files to run
  ###If changing parameters in any of these files, change them in ALL applicable files!!
  #Sitepar.in and fix.100 have parameters to select which soil model
  #fix2.100 has parameters to select which temperature and soil moisture effect functions
  #to use in the microbial model. 
  if (doFirstOrder) {
    file.copy("sitepar_Org.in", "sitepar.in", overwrite = TRUE)
  } else {
    file.copy("sitepar_Mic.in", "sitepar.in", overwrite = TRUE)
  }
  if (doSMIncreasing) {
    if(doTExp){
      file.copy("fix2_IncSM_ExpT.100", "fix2.100", overwrite = TRUE)
    } else {
      file.copy("fix2_IncSM_Q10T.100", "fix2.100", overwrite = TRUE)
    }} 
  if (doSMHill){
    if (doTExp) {
      file.copy("fix2_HillSM_ExpT.100", "fix2.100", overwrite = TRUE)
    }else {
      file.copy("fix2_HillSM_Q10T.100", "fix2.100", overwrite = TRUE)  
    }}
  
  
  # Standard error and output from DayCent are written to log files 
  
  logfile1 <- "stdout_dc_hlu.log"
  logfile2 <- "stderr_dc_hlu.log"
  unlink(logfile1)
  unlink(logfile2)
  
  # Run DayCent: daycent.exe -s <sch file> -n <new bin file> -e <prev bin file> 
  binhluext = paste(binhlu, ".bin", sep="")
  unlink(binhluext)     # DayCent won't allow you to write over an existing .bin file
  
  args1 <- paste("-s", schhlu, "-n", binhlu, "-e", bineq, sep=" ")
  print(paste(daycent, args1, sep=" "))
  #system2(daycent, args=args1, wait=TRUE, stdout=logfile1, stderr=logfile2)
  system(paste(daycent, args1, sep=" "))
  file.rename("harvest.csv", "harvest_hlu.csv")
  
  # Standard error and output from List100 are written to log files 
  logfile3 <- "stdout_list100_hlu.log"
  logfile4 <- "stderr_list100_hlu.log"
  unlink(logfile3)
  unlink(logfile4)
  
  # Delete the existing ag history .lis file
  lisName <- paste(binhlu,".lis", sep="")
  unlink(lisName) # List100 won't allow you to write over an existing .lis file
  
  #Run List100: daycent.exe <bin file> <lis file> outvars.txt
  args2 <- paste(binhlu, binhlu, "outvars.txt", sep=" ")
  print(paste(list100, args2, sep=" "))
  #system2(list100, args=args2, wait=TRUE, stdout=logfile3, stderr=logfile4)
  system(paste(list100, args2, sep=" "))
  
}

# ------------------------------------------------------------------------------------------
# --------------- Step 3: Energy Farm Contemporary Simulation (2008-2019) ------------------ 

if (doMisc)
{
  binhlu = paste0(siteName, "_hlu", soil, Teffect, SMeffect)
  file.copy("outfiles_misc.in", "outfiles.in", overwrite=TRUE) # Save daily files for experiment runs
  
  
  #######Soil Model files #####
  ####Copy model specific files to run
  ###If changing parameters in any of these files, change them in ALL applicable files!!
  #Sitepar.in and fix.100 have parameters to select which soil model
  #fix2.100 has parameters to select which temperature and soil moisture effect functions
  #to use in the microbial model. 
  if (doFirstOrder) {
    file.copy("sitepar_Org.in", "sitepar.in", overwrite = TRUE)
  } else {
    file.copy("sitepar_Mic.in", "sitepar.in", overwrite = TRUE)
  }
  if (doSMIncreasing) {
    if(doTExp){
      file.copy("fix2_IncSM_ExpT.100", "fix2.100", overwrite = TRUE)
    } else {
      file.copy("fix2_IncSM_Q10T.100", "fix2.100", overwrite = TRUE)
    }} 
  if (doSMHill){
    if (doTExp) {
      file.copy("fix2_HillSM_ExpT.100", "fix2.100", overwrite = TRUE)
    }else {
      file.copy("fix2_HillSM_Q10T.100", "fix2.100", overwrite = TRUE)  
    }}
  
  
  #schcnt = "cnt_misc-UFCTL_gt" # unfertilized miscanthus
  schcnt = "cnt_misc-FCTL_gt"   # fertilized miscanthus
  bincnt = schcnt
  
  
  
  # Standard error and output from DayCent are written to log files 
  
  logfile1 <- "stdout_dc_cnt.log"
  logfile2 <- "stderr_dc_cnt.log"
  unlink(logfile1)
  unlink(logfile2)
  
  # Run DayCent: daycent.exe -s <sch file> -n <new bin file> -e <prev bin file> 
  bincntext = paste(bincnt, ".bin", sep="")
  unlink(bincntext)     # DayCent won't allow you to write over an existing .bin file
  
  args1 <- paste("-s", schcnt, "-n", bincnt, "-e", binhlu, sep=" ")
  print(paste(daycent, args1, sep=" "))
  system2(daycent, args=args1, wait=TRUE, stdout=logfile1, stderr=logfile2)
  #system(paste(daycent, args1, sep=" "))
  
  
  # Standard error and output from List100 are written to log files 
  logfile3 <- "stdout_list100_cnt.log"
  logfile4 <- "stderr_list100_cnt.log"
  unlink(logfile3)
  unlink(logfile4)
  
  # Delete the existing ag history .lis file
  lisName <- paste(bincnt,".lis", sep="")
  unlink(lisName) # List100 won't allow you to write over an existing .lis file
  
  #Run List100: daycent.exe <bin file> <lis file> outvars.txt
  args2 <- paste(bincnt, bincnt, "outvars.txt", sep=" ")
  print(paste(list100, args2, sep=" "))
  #system2(list100, args=args2, wait=TRUE, stdout=logfile3, stderr=logfile4)
  system(paste(list100, args2, sep=" "))
  
  #Copy all output and lis files from run into output folder
  Crop= "misc_cont" #Assign a scenario name
  model.name <- paste(Crop, soil, Teffect, SMeffect, sep = "_") #This names output files and then is used to pull information into dataframes when reading in output files to R
  file.copy("year_summary.csv", paste("output/", paste(model.name, "year_summary.csv", sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("nflux.csv",  paste("output/", paste(model.name, "nflux.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("bio.csv",  paste("output/", paste(model.name, "bio.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("livec.csv", paste("output/", paste(model.name, "livec.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("deadc.csv", paste("output/", paste(model.name, "deadc.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("cflows.csv", paste("output/", paste(model.name, "cflows.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("soilc.csv", paste("output/", paste(model.name, "soilc.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("soiln.csv", paste("output/", paste(model.name, "soiln.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("dc_sip.csv", paste("output/", paste(model.name, "dc_sip.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("harvestgt.csv", paste("output/", paste(model.name, "harvestgt.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("potgt.csv", paste("output/", paste(model.name, "potgt.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("psyn.csv", paste("output/", paste(model.name, "psyn.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("resp.csv", paste("output/", paste(model.name, "resp.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("summary.csv", paste("output/", paste(model.name, "summary.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("year_cflows.csv", paste("output/", paste(model.name, "yearcflows.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("cnt_misc-FCTL_gt.lis", paste("output/", paste(model.name, ".lis",sep = ""), sep = ""), overwrite=TRUE)
  
}


################################################################

if (doSwitch)
{
  binhlu = paste0(siteName, "_hlu", soil, Teffect, SMeffect)
  file.copy("outfiles_misc.in", "outfiles.in", overwrite=TRUE) # Save daily files for experiment runs

  #######Soil Model files #####
  if (doFirstOrder) {
    file.copy("sitepar_Org.in", "sitepar.in", overwrite = TRUE)
  } else {
    file.copy("sitepar_Mic.in", "sitepar.in", overwrite = TRUE)
  }
  if (doSMIncreasing) {
    if(doTExp){
      file.copy("fix2_IncSM_ExpT.100", "fix2.100", overwrite = TRUE)
    } else {
      file.copy("fix2_IncSM_Q10T.100", "fix2.100", overwrite = TRUE)
    }} 
  if (doSMHill){
    if (doTExp) {
      file.copy("fix2_HillSM_ExpT.100", "fix2.100", overwrite = TRUE)
    }else {
      file.copy("fix2_HillSM_Q10T.100", "fix2.100", overwrite = TRUE)  
    }}
  
  
  schcnt = "cnt_switch_warm"  
  bincnt = schcnt
  
  
  # Standard error and output from DayCent are written to log files 
  
  logfile1 <- "stdout_dc_cnt.log"
  logfile2 <- "stderr_dc_cnt.log"
  unlink(logfile1)
  unlink(logfile2)
  
  # Run DayCent: daycent.exe -s <sch file> -n <new bin file> -e <prev bin file> 
  bincntext = paste(bincnt, ".bin", sep="")
  unlink(bincntext)     # DayCent won't allow you to write over an existing .bin file
  
  args1 <- paste("-s", schcnt, "-n", bincnt, "-e", binhlu, sep=" ")
  print(paste(daycent, args1, sep=" "))
  system2(daycent, args=args1, wait=TRUE, stdout=logfile1, stderr=logfile2)
  #system(paste(daycent, args1, sep=" "))
  
  
  # Standard error and output from List100 are written to log files 
  logfile3 <- "stdout_list100_cnt.log"
  logfile4 <- "stderr_list100_cnt.log"
  unlink(logfile3)
  unlink(logfile4)
  
  # Delete the existing ag history .lis file
  lisName <- paste(bincnt,".lis", sep="")
  unlink(lisName) # List100 won't allow you to write over an existing .lis file
  
  #Run List100: daycent.exe <bin file> <lis file> outvars.txt
  args2 <- paste(bincnt, bincnt, "outvars.txt", sep=" ")
  print(paste(list100, args2, sep=" "))
  #system2(list100, args=args2, wait=TRUE, stdout=logfile3, stderr=logfile4)
  system(paste(list100, args2, sep=" "))
  
  #Copy all output and lis files from run into output folder
  Crop= "switch_warm" #Assign Scenario name
  model.name <- paste(Crop, soil, Teffect, SMeffect, sep = "_")
  file.copy("year_summary.csv", paste("output/", paste(model.name, "year_summary.csv", sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("nflux.csv",  paste("output/", paste(model.name, "nflux.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("bio.csv",  paste("output/", paste(model.name, "bio.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("livec.csv", paste("output/", paste(model.name, "livec.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("deadc.csv", paste("output/", paste(model.name, "deadc.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("cflows.csv", paste("output/", paste(model.name, "cflows.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("soilc.csv", paste("output/", paste(model.name, "soilc.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("soiln.csv", paste("output/", paste(model.name, "soiln.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("dc_sip.csv", paste("output/", paste(model.name, "dc_sip.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("harvestgt.csv", paste("output/", paste(model.name, "harvestgt.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("potgt.csv", paste("output/", paste(model.name, "potgt.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("psyn.csv", paste("output/", paste(model.name, "psyn.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("resp.csv", paste("output/", paste(model.name, "resp.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("summary.csv", paste("output/", paste(model.name, "summary.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("year_cflows.csv", paste("output/", paste(model.name, "yearcflows.csv",sep = "_"), sep = ""), overwrite=TRUE)
  file.copy("cnt_switch_warm.lis", paste("output/", paste(model.name, ".lis",sep = ""), sep = ""), overwrite=TRUE)

}

#-------------------------------------------------------------------------------------------------
# Read in the .lis file

# Get the column names for the .lis files
# sep="" refers to any length of white space as being the delimiter.  Don't use " ".

files <- list.files(path = "./output",pattern = "*.lis", full.names = T)
list.DF <- lapply(files, read.table, skip=1,header=FALSE,sep="",dec=".",fill=TRUE)
names(list.DF) <- gsub("./output/", "", gsub(".lis", "", files))

dataLis1 <<- read.table(file="cnt_switch.lis",header=TRUE,sep="",dec=".",fill=TRUE)

#Makes a list of dataframes with all lis files 
# and extracts scenario information from the file names 
# to put into new columns for data analysis
list.lis <- list()
for (x in 1:length(list.DF)) {
  colnames(list.DF[[x]]) = colnames(dataLis1)
  list.lis[[names(list.DF[x])]] <- cbind(list.DF[[x]], "Crop" = if (grepl("corn", names(list.DF[x]))) {
    "Maize"
  } else if (grepl("miscUF", names(list.DF[x]), fixed = TRUE)) {
    "Miscanthus_NotFertilized"
  } else if (grepl("misc", names(list.DF[x]), fixed = TRUE)) {
    "Miscanthus"
  } else if (grepl("switch_", names(list.DF[x]), fixed = TRUE)) {
    "Switchgrass"})
  list.lis[[names(list.DF[x])]] <- cbind(list.lis[[x]], "Fut_Treatment" = if (grepl("ww", names(list.DF[x]))) {
    "Warming + Rain"
  } else if (grepl("wet_", names(list.DF[x]), fixed = TRUE)) {
    "Rain"
  } else if (grepl("cont_", names(list.DF[x]), fixed = TRUE)) {
    "Control"
  } else if (grepl("warm_", names(list.DF[x]), fixed = TRUE)) {
    "Warming"})
  list.lis[[names(list.DF[x])]] <- cbind(list.lis[[x]], "SoilModel" = if (grepl("FO", names(list.DF[x]), fixed = TRUE)) {
    "First_Order"
  } else if (grepl("Mic", names(list.DF[x]), fixed = TRUE)) {
    "Michaelis-Menten"
  })
  list.lis[[names(list.DF[x])]] <- cbind(list.lis[[x]], "SoilTempEffect" = if (grepl("Q10Temp", names(list.DF[x]), fixed = TRUE)) {
    "Q10"
  } else if (grepl("ExpTemp", names(list.DF[x]), fixed = TRUE)) {
    "Exp"
  })
  list.lis[[names(list.DF[x])]] <- cbind(list.lis[[x]],  "SoilVSWCEffect" = if (grepl("IncSM", names(list.DF[x]), fixed = TRUE)) {
    "Increasing"
  } else if (grepl("HillSM", names(list.DF[x]), fixed = TRUE)) {
    "Hill"
  })
}
  
#combines all lis files into one dataframe
allLIS <- bind_rows(list.lis)



#-------------------------------------------------------------------------------------------------
# Get the column names for the output files (other than the lis files)
# sep="" refers to any length of white space as being the delimiter.  Don't use " ".

files <- list.files(path = "./output",pattern = "*.csv", full.names = T)
list.DF <- lapply(files, read_csv)
names(list.DF) <- gsub("./output/", "", gsub(".csv", "", files))

#Makes a list of dataframes with output files 
# and extracts scenario information from the file names 
# to put into new columns for data analysis
n <- names(list.DF)
list.DFcrop <- list()
for (x in 1:length(list.DF)) {
  list.DFcrop[[names(list.DF[x])]] <- cbind(list.DF[[x]], "Crop" = if (grepl("corn", names(list.DF[x]))) {
    "Maize"
  } else if (grepl("miscUF", names(list.DF[x]), fixed = TRUE)) {
    "Miscanthus_NotFertilized"
  } else if (grepl("misc_", names(list.DF[x]), fixed = TRUE)) {
    "Miscanthus"
  } else if (grepl("switch_", names(list.DF[x]), fixed = TRUE)) {
    "Switchgrass"
  })}
list.DF <- list.DFcrop
list.DFtreat <- list()
for (x in 1:length(list.DF)) {
  list.DFtreat[[names(list.DF[x])]] <- cbind(list.DF[[x]], "Fut_Treatment" = if (grepl("ww", names(list.DF[x]))) {
    "Warming + Rain"
  } else if (grepl("wet_", names(list.DF[x]), fixed = TRUE)) {
    "Rain"
  } else if (grepl("cont_", names(list.DF[x]), fixed = TRUE)) {
    "Control"
  } else if (grepl("warm_", names(list.DF[x]), fixed = TRUE)) {
    "Warming"})}
list.DF <- list.DFtreat

#assign SoilModel column
list.DFsoil <- list()
for (x in 1:length(list.DF)) {
  list.DFsoil[[names(list.DF[x])]] <- cbind(list.DF[[x]], "SoilModel" = if (grepl("FO", names(list.DF[x]), fixed = TRUE)) {
    "First_Order"
  } else if (grepl("Mic", names(list.DF[x]), fixed = TRUE)) {
    "Michaelis-Menten"
  })}
list.DF <- list.DFsoil

#assign Soil Temp Effect  Function column
list.DFtemp <- list()
for (x in 1:length(list.DF)) {
  list.DFtemp[[names(list.DF[x])]] <- cbind(list.DF[[x]], "SoilTempEffect" = if (grepl("Q10Temp", names(list.DF[x]), fixed = TRUE)) {
    "Q10"
  } else if (grepl("ExpTemp", names(list.DF[x]), fixed = TRUE)) {
    "Exp"
  })}
list.DF <- list.DFtemp

#assign Soil Moisture Effect column
list.DFmoist <- list()
for (x in 1:length(list.DF)) {
  list.DFmoist[[names(list.DF[x])]] <- cbind(list.DF[[x]], "SoilVSWCEffect" = if (grepl("IncSM", names(list.DF[x]), fixed = TRUE)) {
    "Increasing"
  } else if (grepl("HillSM", names(list.DF[x]), fixed = TRUE)) {
    "Hill"
  })}
list.DF <- list.DFmoist


#-------------------------------------------------------------------------------------------------
# Read in the simulated GPP results

psyn <- ls(list.DF, pattern = "psyn")
list.DFpsyn <- list.DF[psyn]
dataPsyn <- bind_rows(list.DFpsyn)
dataPsyn$Time = as.integer(dataPsyn$time) + dataPsyn$dayofyr/366
dataPsyn$Model <- paste(dataPsyn$SoilModel, dataPsyn$SoilTempEffect, dataPsyn$SoilVSWCEffect,sep = "_")

#Create output dataframes of all scenarios based on output file type (e.g. dc_sip.csv, soilc.csv, etc.)
#-------------------------------------------------------------------------------------------------
# Read in the simulated AET and NEP results


SIP <- ls(list.DF, pattern = "dc_sip")
list.DFsip <- list.DF[SIP]
dataSIP <- bind_rows(list.DFsip)
dataSIP$Time = as.integer(dataSIP$time) + dataSIP$dayofyr/366
dataSIP$Model <- paste(dataSIP$SoilModel, dataSIP$SoilTempEffect, dataSIP$SoilVSWCEffect,sep = "_")


#-------------------------------------------------------------------------------------------------
# Read in the simulated respiration results


resp <- ls(list.DF, pattern = "resp")
list.DFresp <- list.DF[resp]
dataResp <- bind_rows(list.DFresp)
dataResp$Time = as.integer(dataResp$time) + dataResp$dayofyr/366
dataResp$Model <- paste(dataResp$SoilModel, dataResp$SoilTempEffect, dataResp$SoilVSWCEffect,sep = "_")



#-------------------------------------------------------------------------------------------------
# Read in the simulated daily biomass results

bio <- ls(list.DF, pattern = "bio")
list.DFbio <- list.DF[bio]
dataBio <- bind_rows(list.DFbio)
dataBio$Time = as.integer(dataBio$time) + dataBio$dayofyr/366
dataBio$Model <- paste(dataBio$SoilModel, dataBio$SoilTempEffect, dataBio$SoilVSWCEffect,sep = "_")


#-------------------------------------------------------------------------------------------------
# Read in the simulated daily soil C pools results
soilc <- ls(list.DF, pattern = "soilc")
list.DFsoilc <- list.DF[soilc]
dataSoilC <- bind_rows(list.DFsoilc)
dataSoilC$Time = as.integer(dataSoilC$time) + dataSoilC$dayofyr/366
dataSoilC$Model <- paste(dataSoilC$SoilModel, dataSoilC$SoilTempEffect, dataSoilC$SoilVSWCEffect,sep = "_")



#-------------------------------------------------------------------------------------------------
# Read in the simulated daily soilN results

soiln <- ls(list.DF, pattern = "soiln")
list.DFsoiln <- list.DF[soiln]
dataSoilN <- bind_rows(list.DFsoiln)
dataSoilN$Model <- paste(dataSoilN$SoilModel, dataSoilN$SoilTempEffect, dataSoilN$SoilVSWCEffect,sep = "_")


dataSoilN <- dataSoilN %>% mutate(Total_NO3 = NO3.0.+ NO3.1.+NO3.2.+NO3.3.+ NO3.4.+NO3.5.+
                                    NO3.6.+NO3.7.+ NO3.8.+NO3.9.+NO3.10.+ NO3.11.+NO3.12.)

SoilNMicc <- cbind(dataSoilC, dataSoilN$ammonium, dataSoilN$Total_NO3)


#-------------------------------------------------------------------------------------------------
# Read in the simulated nitrogen fluxes

nflux <- ls(list.DF, pattern = "nflux")
list.DFnflux <- list.DF[nflux]
dataNflux <- bind_rows(list.DFnflux)
dataNflux$Model <- paste(dataNflux$SoilModel, dataNflux$SoilTempEffect, dataNflux$SoilVSWCEffect,sep = "_")

