#----------------------------------------------------------------------------------------
# Program name: abakus_tests
# Authors: Azzurra Spagnesi
# Date: April 2021
# Objective: Import data for abakus, conductivity, draw wire and flowmeter from 
#            a selected folder, manage statistics and plot the results
#----------------------------------------------------------------------------------------
#FIRST PART: DATA IMPORT AND MANAGEMENT
#----------------------------------------------------------------------------------------
#clean the virtual work folder
rm(list = ls()) 

library(plyr)
library(readr)
library(dplyr) #necessary to create vector of data frame names from a list of data frames
library(purrr) #necessary to create vector of data frame names from a list of data frames


#REMEMBER TO UPDATE FOLDERS WITH NEW FILES!!!
#set main wd
setwd("C:/Users/azzur/Dropbox/Il mio PC (LAPTOP-AUDRMQN9)/Desktop/CFA_data/CFA_HPLC")

#set locations and select all files with "*.txt" suffix 
#from the current working directories (creating them as arrays 
#for the next steps),then import them all at once as entries 
#in a list and repeat the same operations for each device

setwd("C:/Users/azzur/Dropbox/Il mio PC (LAPTOP-AUDRMQN9)/Desktop/CFA_data/CFA_HPLC/abakus_data")
abakus_files <- as.array(list.files(pattern = "*_dust.txt"))
abakus_datalist <- lapply(abakus_files, 
                          read.table, 
                          header=FALSE, 
                          fill = TRUE,
                          sep="\t", skip = 6)

setwd("C:/Users/azzur/Dropbox/Il mio PC (LAPTOP-AUDRMQN9)/Desktop/CFA_data/CFA_HPLC/cond_data")
conductivity_files <- as.array(list.files(pattern = "*_cond.txt"))
conductivity_datalist <- lapply(conductivity_files, function(x) {
  tryCatch(read.table(x, header = FALSE, sep = ' '), error=function(e) NULL)
})

setwd("C:/Users/azzur/Dropbox/Il mio PC (LAPTOP-AUDRMQN9)/Desktop/CFA_data/CFA_HPLC/estensimetro_data")
drawwire_files <- as.array(list.files(pattern="*_height.txt"))
drawwire_datalist <- lapply(drawwire_files, 
                            tryCatch(read.table, 
                                     header=FALSE, 
                                     fill = TRUE,
                                     sep="\t", skip = 6))

setwd("C:/Users/azzur/Dropbox/Il mio PC (LAPTOP-AUDRMQN9)/Desktop/CFA_data/CFA_HPLC/flow_data")
flowmeter_files <- as.array(list.files(pattern="*_flow.txt"))
flowmeter_datalist <- lapply(flowmeter_files, 
                             tryCatch(read.table, 
                                      header=FALSE, 
                                      fill = TRUE,
                                      sep="\t", skip = 6))

#apply correspondent and reducted file names to each list.
#The reduction of file names would be fundamental for the next steps
abakus_files <- substr(abakus_files, start = 1, stop = 17) 
conductivity_files <- substr(conductivity_files, start = 1, stop = 17) 
drawwire_files <- substr(drawwire_files, start = 1, stop = 17) 
flowmeter_files <- substr(flowmeter_files, start = 1, stop = 17)

abakus_datalist <- setNames(abakus_datalist, abakus_files)
conductivity_datalist <- setNames(conductivity_datalist, conductivity_files)
drawwire_datalist <- setNames(drawwire_datalist, drawwire_files)
flowmeter_datalist <- setNames(flowmeter_datalist, flowmeter_files)

rm(abakus_files, conductivity_files, drawwire_files, flowmeter_files)

#MANAGE ABAKUS DATA
#delete dataframes with less than 34 columns
abakus_datalist <- Filter(function(x) ncol(x) == 34, abakus_datalist)
#SET HEADER for each file of abakus_datalist 
abakus_colnames <- c("Index","Duration (s)","0,8","0,9","1,0","1,1","1,2","1,3",
                     "1,4","1,6","1,8","2,0","2,2","2,4","2,6","2,9","3,2","3,5",
                     "3,9","4,3","4,8","5,3","5,8","6,4","7,1","7,8","8,6","9,5",
                     "10,5","11,6","12,8","14,1","15,5","80,0")
abakus_datalist <-  lapply(abakus_datalist, setNames, abakus_colnames)
#delete the first row from each df in the list using numeric index
abakus_datalist <-  lapply(abakus_datalist, function(x) {x <- x[-1, ]})
#delete files with less than 10sec of acquisition (failed tests) from abakus list 
abakus_datalist <- abakus_datalist[sapply(abakus_datalist, function(x) dim(x)[1]) > 10]

#MANAGE CONDUCTIVITY DATA
#delete unnecessary columns
dropList <- c("V4", "V5", "V6", "V7", "V8", "V10", "V11", "V12", "V13", "V14", "V15", "V16", "V17", "V18", "V19", "V20", "V22")
conductivity_datalist <- lapply(conductivity_datalist, function(x) { x[dropList] <- NULL; x })
#delete dataframes with NULL dimension
conductivity_datalist <- conductivity_datalist[lapply(conductivity_datalist,length)>0] 
#delete files with less than 10sec of acquisition (failed tests) from conductivity list 
conductivity_datalist <- conductivity_datalist[sapply(conductivity_datalist, function(x) dim(x)[1]) > 10]
#rename columns for all df in the list 
col_names <- c("Date","Time_%H:%M:%S", "SENSOR1(mS)", "SENSOR2(mS)", "SENSOR4(mS)")
conductivity_datalist <-  lapply(conductivity_datalist, setNames, col_names)

#MANAGE DRAW WIRE DATA
#rename columns for all df in the list 
#delete files with less than 10sec of acquisition (failed tests) from drawwire list 
drawwire_datalist <- drawwire_datalist[sapply(drawwire_datalist, function(x) dim(x)[1]) > 10]
col_names <- c("Date","Time_%H:%M:%S", "Ice Height (mm)", "Melt speed (mm/sec)")
drawwire_datalist <-  lapply(drawwire_datalist, setNames, col_names)

#MANAGE FLOWMETER DATA
col_names <- c("Date","Time_%H:%M:%S", "Flow (ul/min)")
flowmeter_datalist <-  lapply(flowmeter_datalist, setNames, col_names)

#SELECT sample files from each list using grepl function
abakus_sample <- abakus_datalist[names(abakus_datalist) %in% c("2021-04-14_130504", 
                                                               "2021-04-14_134809",
                                                               "2021-04-14_142819")]
conductivity_sample <- conductivity_datalist[names(conductivity_datalist) %in% c("2021-04-14_130504", 
                                                                           "2021-04-14_134809",
                                                                           "2021-04-14_142819")]
estens_sample <- drawwire_datalist[names(drawwire_datalist) %in% c("2021-04-14_130504", 
                                                                       "2021-04-14_134809",
                                                                       "2021-04-14_142819")]
flow_sample <- flowmeter_datalist[names(flowmeter_datalist) %in% c("2021-04-14_130504", 
                                                                  "2021-04-14_134809",
                                                                  "2021-04-14_142819")]
#MANAGE these new lists 
#ABAKUS - remove the first row
abakus_sample <-  lapply(abakus_sample, function(x) {x <- x[-1, ]})

#CONDUCTIVITY, DRAWWIRE AND FLOWMETER DATA: apply the strp time function
# conductivity_sample2 <- lapply(conductivity_sample, strptime, "%H:%M:%OS")
# conductivity_sample2 <- lapply(conductivity_sample, strptime, "%H:%M:%S")
# conductivity_sample2 <- lapply(conductivity_sample, as.POSIXct, format= "%Y-%m-%d %H:%M:%S")


# conductivity_sample2 <- lapply(conductivity_sample,function(x) {
#   x[,6] <- strptime(x[,2], "%H:%M:%OS")})
# conductivity_sample2 <- lapply(conductivity_sample,function(x) {
#   x[,6] <- strptime(x[,2], "%H:%M:%S")})
# conductivity_sample2 <- lapply(conductivity_sample,function(x) {
#   x[,6] <- as.POSIXct(x[,2], format="%Y-%m-%d %H:%M:%S")})

# conductivity$TIME <- strptime(conductivity$`Time_%H:%M:%S`, "%H:%M:%OS")
# conductivity$TIME <- strptime(conductivity$`Time_%H:%M:%S`, "%H:%M:%S")
# conductivity$TIME <- as.POSIXct(conductivity$TIME, format="%Y-%m-%d %H:%M:%S")


#CREATE A LIST WITH NESTED LISTS OF DATAFRAMES
sample_list <- list(abakus_sample, conductivity_sample, estens_sample, flow_sample)
names(sample_list) <- c("abakus", "conductivity", "draw_wire", "flowmeter")

rm(abakus_colnames,col_names, dropList, abakus_sample, conductivity_sample, estens_sample, flow_sample)


