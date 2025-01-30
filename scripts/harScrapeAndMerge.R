# This script checks if the required packages are installed and installs them if they are not.
# It is used in the heritage-at-risk project to ensure that all necessary dependencies are available for the script to run.
# 
packages <- c("readr","jsonlite", "sf", "utils", "janitor", "rvest", "tidyverse", "stringr", "dplyr")
any_not_installed <- !all(packages %in% installed.packages()[, "Package"])
if (any_not_installed) {
  # Code to execute if at least one package is not installed
  message("At least one of the packages is not installed.")
  # Install missing packages
  missing_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing_packages) > 0) {
    install.packages(missing_packages)
  }
} 

# Create directory for storing CSV files
if (!file.exists('../rawdata/csv')){
  dir.create('../rawdata/csv')
}
# Create directory for storing final CSV data
if (!file.exists('../rawdata/final')){
  dir.create('../rawdata/final')
}
# Create directory for storing merged CSV data
if (!file.exists('../rawdata/merged')){
  dir.create('../rawdata/merged')
}
# Download data from the Digital Planning page in csv format
library(readr)
rawdata <- read.csv('https://files.planning.data.gov.uk/dataset/heritage-at-risk.csv')
# Check the data you downloaded for structure
head(rawdata)
cols <-  ncol(rawdata)
message(paste0('This produces a data frame that is a ', cols , ' column data set'))

# Define columns to drop
drops <- c("organisation.entity","prefix", "categories", "legislation", "notes", "geometry", "geojson")
# Drop the columns
rawDataCols <-rawdata[ , !(names(rawdata) %in% drops)]
# Rename reference column
names(rawDataCols)[names(rawDataCols) == "reference"] <- "ListEntry"

# Test your data again
head(rawDataCols)
write_csv(rawDataCols, '../rawdata/csv/HAR.csv')
cols <-  ncol(rawDataCols)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 

# Load the jsonlite library
library(jsonlite)
# Get the json response from the ARCVIEW server
# To get the parameters required read the API manual https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service/
# The id for the server is ZOdPfBS3aqqDYPUQ
# The FeatureServer is 0
# The dataset for NHLE points is National_Heritage_List_for_England_NHLE_v02_VIEW
countNHLE <- fromJSON('https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/ArcGIS/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/0/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=true&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=200&returnZ=false&returnM=false&returnTrueCurves=true&returnExceededLimitFeatures=false&quantizationParameters=&sqlFormat=none&f=json&token=')
# Get the count
totalNHLE <- countNHLE$count[1]
# Print this value
message(paste0('The total number of NHLE listed buildings equals: ', totalNHLE))
# We are going to get 50 records at a time
recordsToReturn <- 50
# We are going to paginate this response
pagination <- ceiling(totalNHLE/recordsToReturn)
message(paste0('Pages to download normally: ', pagination))
# Obtain data from the ArcGIS feature server
# The id for the server is ZOdPfBS3aqqDYPUQ
# The FeatureServer is 0
# The dataset for NHLE points is National_Heritage_List_for_England_NHLE_v02_VIEW
url <- paste0("https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/arcgis/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/0/query?where=0%3D0&outFields=%2A&f=json&resultRecordCount=", recordsToReturn)
json <- fromJSON(url)
data <- json$features$attributes
# Decide which columns to keep
keeps <- c("ListEntry","Name","Grade","hyperlink","NGR","Easting","Northing")
data <- data[,(names(data) %in% keeps)]

# Now paginate through the data set
for (i in seq(from=(1 * recordsToReturn), to=(pagination*recordsToReturn), by=recordsToReturn)){
  urlDownload <- paste(url, '&resultOffset=', i, sep='')
  print(urlDownload)
  pagedJson <- fromJSON(urlDownload)
  records <- pagedJson$features$attributes
  records <- records[,(names(records) %in% keeps)]
  data <-rbind(data,records)
  # Add a snooze so we don't get blocked easily
  Sys.sleep(1.0)
}
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 

library(utils)
library(sf)

# Subset the point data
pointData <- subset(data, select = c("Easting","Northing"))

## Create coordinates variable
coordsCast <- cbind(Easting = as.numeric(as.character(pointData$Easting)),
                Northing = as.numeric(as.character(pointData$Northing)))

# Create an sf object with BNG coordinates
bng_coords <- st_as_sf(data.frame(coordsCast), 
                     coords = c("Easting", "Northing"), 
                     crs = 27700) 

# Transform to WGS84 (EPSG:4326)
wgs84_coords <- st_transform(bng_coords, 4326)

# Extract latitude and longitude and append to data
data$lat <- st_coordinates(wgs84_coords)[, "Y"]
data$lon <- st_coordinates(wgs84_coords)[, "X"]

# Print the head rows of the new data frame
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 

# Write to a csv file 
write_csv(data, '../rawdata/csv/NHLE.csv')

# Load the jsonlite library
library(jsonlite)
# Get the json response from the ARCVIEW server
# To get the parameters required read the API manual https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service/
# The id for the server is ZOdPfBS3aqqDYPUQ
# The FeatureServer is 6
# The dataset for NHLE points is National_Heritage_List_for_England_NHLE_v02_VIEW
countNHLE_Monuments <- fromJSON('https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/ArcGIS/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/6/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=true&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=200&returnZ=false&returnM=false&returnTrueCurves=true&returnExceededLimitFeatures=false&quantizationParameters=&sqlFormat=none&f=json&token=')
# Get the count
totalScheduled <- countNHLE_Monuments$count[1]
# Print this value
message(paste0('Total number of scheduled monuments ', totalScheduled))
# We are going to get 50 records at a time
recordsToReturn <- 50
# We are going to paginate this response
pagination <- ceiling(totalScheduled/recordsToReturn)
message(paste0('Pages to download normally: ', pagination))

# Obtain data from the ArcGIS feature server - Scheduled monuments are layer 6
url <- paste0("https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/arcgis/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/6/query?where=0%3D0&outFields=%2A&f=json&resultRecordCount=", recordsToReturn)
json <- fromJSON(url)
data <- json$features$attributes
# Decide which columns to keep
keeps <- c("ListEntry","Name","Grade","hyperlink","NGR","Easting","Northing")
data <- data[,(names(data) %in% keeps)]

# Now paginate through the data set
for (i in seq(from=(1 * recordsToReturn), to=(pagination*recordsToReturn), by=recordsToReturn)){
  urlDownload <- paste(url, '&resultOffset=', i, sep='')
  print(urlDownload)
  pagedJson <- fromJSON(urlDownload)
  records <- pagedJson$features$attributes
  records <- records[,(names(records) %in% keeps)]
  data <-rbind(data,records)
  # Add a snooze so we don't get blocked easily
  Sys.sleep(1.0)
}
data$Grade <- NA
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 

library(utils)
library(sf)

# Subset the point data
pointData <- subset(data, select = c("Easting","Northing"))

## Create coordinates variable
coordsCast <- cbind(Easting = as.numeric(as.character(pointData$Easting)),
                Northing = as.numeric(as.character(pointData$Northing)))

# Create an sf object with BNG coordinates
bng_coords <- st_as_sf(data.frame(coordsCast), 
                     coords = c("Easting", "Northing"), 
                     crs = 27700) 

# Transform to WGS84 (EPSG:4326)
wgs84_coords <- st_transform(bng_coords, 4326)

# Extract latitude and longitude and append to data
data$lat <- st_coordinates(wgs84_coords)[, "Y"]
data$lon <- st_coordinates(wgs84_coords)[, "X"]

# Print the head rows of the new data frame
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 
# Write to a csv file 
write_csv(data, '../rawdata/csv/ScheduledMonuments.csv')

# Load the jsonlite library
library(jsonlite)
# Get the json response from the ARCVIEW server
# To get the parameters required read the API manual https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service/
# The id for the server is ZOdPfBS3aqqDYPUQ
# The FeatureServer is 7
# The dataset for NHLE points is National_Heritage_List_for_England_NHLE_v02_VIEW
countNHLEParks <- fromJSON('https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/ArcGIS/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/7/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=true&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=200&returnZ=false&returnM=false&returnTrueCurves=true&returnExceededLimitFeatures=false&quantizationParameters=&sqlFormat=none&f=json&token=')
# Get the count
totalParks <- countNHLEParks$count[1]
# Print this value
message(paste0('The total number of parks is ', totalParks))
# We are going to get 50 records at a time
recordsToReturn <- 50
# We are going to paginate this response
pagination <- ceiling(totalParks/recordsToReturn)
message(paste0('Pages to download normally: ', pagination))

# Obtain data from the ArcGIS feature server 
url <- paste0("https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/arcgis/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/7/query?where=0%3D0&outFields=%2A&f=json&resultRecordCount=", recordsToReturn)
json <- fromJSON(url)
data <- json$features$attributes
# Decide which columns to keep
keeps <- c("ListEntry","Name","Grade","hyperlink","NGR","Easting","Northing")
data <- data[,(names(data) %in% keeps)]

# Now paginate through the data set
for (i in seq(from=(1 * recordsToReturn), to=(pagination*recordsToReturn), by=recordsToReturn)){
  urlDownload <- paste(url, '&resultOffset=', i, sep='')
  print(urlDownload)
  pagedJson <- fromJSON(urlDownload)
  records <- pagedJson$features$attributes
  records <- records[,(names(records) %in% keeps)]
  data <-rbind(data,records)
  # Add a snooze so we don't get blocked easily
  Sys.sleep(1.0)
}
# Check these data
head(data)

# Print a message to tell you about the data frame
message(paste0('This produces a data frame that is a ', ncol(data), ' column data set')) 

library(utils)
library(sf)

# Subset the point data
pointData <- subset(data, select = c("Easting","Northing"))

## Create coordinates variable
coordsCast <- cbind(Easting = as.numeric(as.character(pointData$Easting)),
                Northing = as.numeric(as.character(pointData$Northing)))

# Create an sf object with BNG coordinates
bng_coords <- st_as_sf(data.frame(coordsCast), 
                     coords = c("Easting", "Northing"), 
                     crs = 27700) 

# Transform to WGS84 (EPSG:4326)
wgs84_coords <- st_transform(bng_coords, 4326)

# Extract latitude and longitude and append to data
data$lat <- st_coordinates(wgs84_coords)[, "Y"]
data$lon <- st_coordinates(wgs84_coords)[, "X"]

# Print the head rows of the new data frame
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 
# Write to a csv file 
write_csv(data, '../rawdata/csv/Parks.csv')

# Load the jsonlite library
library(jsonlite)
# Get the json response from the ARCVIEW server
# To get the parameters required read the API manual https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service/
# The id for the server is ZOdPfBS3aqqDYPUQ
# The FeatureServer layer is 8
# The dataset for NHLE points is National_Heritage_List_for_England_NHLE_v02_VIEW
countNHLEBattlefields <- fromJSON('https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/ArcGIS/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/8/query?where=0%3D0&objectIds=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&returnEnvelope=false&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=true&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&collation=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=200&returnZ=false&returnM=false&returnTrueCurves=true&returnExceededLimitFeatures=false&quantizationParameters=&sqlFormat=none&f=json&token=')
# Get the count
totalBattles <- countNHLEBattlefields$count[1]
# Print this value
message(paste0('Total battlefield records available: ', totalBattles))
# We are going to get 50 records at a time
recordsToReturn <- 50
# We are going to paginate this response
pagination <- ceiling(totalBattles/recordsToReturn)
message(paste0('Pages to download normally: ', pagination))

# Obtain data from the ArcGIS feature server - Battlefields are layer 8
url <- paste0("https://services-eu1.arcgis.com/ZOdPfBS3aqqDYPUQ/arcgis/rest/services/National_Heritage_List_for_England_NHLE_v02_VIEW/FeatureServer/8/query?where=0%3D0&outFields=%2A&f=json&resultRecordCount=", recordsToReturn)
json <- fromJSON(url)
data <- json$features$attributes
# Decide which columns to keep
keeps <- c("ListEntry","Name","Grade","hyperlink","NGR","Easting","Northing","geometry")
data <- data[,(names(data) %in% keeps)]

# Now paginate through the data set
for (i in seq(from=(1 * recordsToReturn), to=(pagination*recordsToReturn), by=recordsToReturn)){
  urlDownload <- paste(url, '&resultOffset=', i, sep='')
  print(urlDownload)
  pagedJson <- fromJSON(urlDownload)
  records <- pagedJson$features$attributes
  records <- records[,(names(records) %in% keeps)]
  data <-rbind(data,records)
  # Add a snooze so we don't get blocked easily
  Sys.sleep(1.0)
}
data$Grade <- NA
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 

library(utils)
library(sf)

# Subset the point data
pointData <- subset(data, select = c("Easting","Northing"))

## Create coordinates variable
coordsCast <- cbind(Easting = as.numeric(as.character(pointData$Easting)),
                Northing = as.numeric(as.character(pointData$Northing)))

# Create an sf object with BNG coordinates
bng_coords <- st_as_sf(data.frame(coordsCast), 
                     coords = c("Easting", "Northing"), 
                     crs = 27700) 
..
# Transform to WGS84 (EPSG:4326)
wgs84_coords <- st_transform(bng_coords, 4326)

# Extract latitude and longitude and append to data
data$lat <- st_coordinates(wgs84_coords)[, "Y"]
data$lon <- st_coordinates(wgs84_coords)[, "X"]

# Print the head rows of the new data frame
head(data)
cols <- ncol(data)
message(paste0('This produces a data frame that is a ', cols , ' column data set')) 

# Write to a csv file 
write_csv(data, '../rawdata/csv/Battlefields.csv')
# Load necessary library
library(dplyr)
# Read the CSV files
file0 <- read.csv("../rawdata/csv/HAR.csv")
head(file0)
file1 <- read.csv("../rawdata/csv/NHLE.csv")
head(file1)
file2 <- read.csv("../rawdata/csv/Battlefields.csv")
head(file2)
file3 <- read.csv("../rawdata/csv/Parks.csv")
head(file3)
file4 <- read.csv("../rawdata/csv/ScheduledMonuments.csv")
head(file4)

# Set the common column, which is always ListEntry
common_column <- "ListEntry" 

# Now start enriching by scraping
# Filter file0 and join with NHLE
common_rows_nhle <- merge(file0, file1, by = common_column) 
head(common_rows_nhle)


library(dplyr)

common_rows_nhle <- merge(file0, file1, by = common_column) 
head(common_rows_nhle)
common_rows_battlefields <- merge(file0, file2, by = common_column) 
head(common_rows_battlefields)
common_rows_parks <- merge(file0, file3, by = common_column) 
head(common_rows_parks)
common_rows_scheduled <- merge(file0, file4, by = common_column) 
head(common_rows_scheduled)

merged <- bind_rows(common_rows_scheduled, common_rows_parks, common_rows_battlefields, common_rows_nhle)
names(merged)[names(merged) == "documentation.url"] <- "url"
head(merged)
write.csv(merged, "../rawdata/merged/merged_har.csv", row.names = FALSE) 

library(rvest)
library(readr)
library(tidyverse)
library(stringr)

# Get the urls list from the previous CSV file created 
urls <- read.csv("../rawdata/merged/merged_har.csv")

# Function to scrape data from a single URL
scrape_url <- function(url, reference) {
  tryCatch({
    page <- read_html(url)
    css_selector <- ".HARListEntry__bullets-container" 
    text_content <- page %>% 
      html_nodes(css_selector) %>% 
      html_text() %>% 
      paste(collapse = " ")
    
    list(url = url, reference = reference, text_content = text_content) 
  }, error = function(e) {
    message(sprintf("Failed to scrape %s: %s", url, e$message))
    list(url = url, reference = reference, text_content = NA, error = e$message) 
  },
  finally = {
    # Garbage collection within the function
    closeAllConnections()
    gc() # Call garbage collection after each URL is processed
  })
}

# Apply the scraping function to each row in the urls data frame using lapply
scraped_data <- lapply(1:nrow(urls), function(i) {
  scrape_url(urls[i, 10], urls[i, 1]) 
})

# Convert the list of lists to a data frame
scraped_data_df <- bind_rows(scraped_data)

# Separate successful and failed scrapes
successful_scrapes <- scraped_data_df %>% filter(!is.na(text_content)) %>% select(-error)
failed_scrapes <- scraped_data_df %>% filter(is.na(text_content))

# Write failed results to CSV file
write_csv(failed_scrapes, "../rawdata/csv/scraping_errors.csv") 
# You might want these for reference.

remove_text_before_location <- function(text) {
   heritage_index <- str_locate(text, "Heritage Category:")
  if (!is.na(heritage_index[1])) { 
    return(str_sub(text, heritage_index[1])) 
  } else {
    return(text) 
  }
}

scraped_data_df <- successful_scrapes %>% 
  mutate(text_content = sapply(text_content, remove_text_before_location))
head(scraped_data_df)

# Write the scraped data to a new CSV file
write_csv(scraped_data_df, "../rawdata/csv/scraped_data.csv") 

# Tidyverse was installed previously. 
library(tidyverse)

# Read the CSV file
df <- read_csv('../rawdata/csv/scraped_data.csv', col_types = cols(.default = "c"))

# Function to split text_content into key-value pairs
split_text_content <- function(text) {
  lines <- str_split(text, "\n")[[1]]
  data <- list()
  key <- NULL
  for (line in lines) {
    if (str_detect(line, ":")) {
      parts <- str_split(line, ":", n = 2)[[1]]
      key <- str_trim(parts[1])
      value <- str_trim(parts[2])
      data[[key]] <- value
    } else if (!is.null(key)) {
      data[[key]] <- paste(data[[key]], str_trim(line))
    }
  }
  return(data)
}

# Apply the function to the text_content column
split_data <- map(df$text_content, split_text_content)

# Create a new data frame from the split data
split_df <- bind_rows(split_data)

# Combine the original URL column with the new data frame
result_df <- bind_cols(df %>% select(url), split_df)
head(result_df)
cols <- ncol(result_df)
message(paste0('This has created a scraped and enhanced dataset of ', cols, ' columns'))

# Write the result to a new CSV file
write_csv(result_df, '../rawdata/csv/processed_scraped_data.csv')

# Load necessary library installed previously
library(dplyr)
# Check if packages exist and if not install them for use
packages <- c("janitor")
any_not_installed <- !all(packages %in% installed.packages()[, "Package"])
if (any_not_installed) {
  # Code to execute if at least one package is not installed
  message("At least one of the packages is not installed.")
  # Install missing packages
  missing_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(missing_packages) > 0) {
    install.packages(missing_packages)
  }
}
# Read the CSV files
file1 <- read.csv("../rawdata/csv/processed_scraped_data.csv")
file2 <- read.csv("../rawdata/merged/merged_har.csv")

# Merge by the common column - url 
common_column <- "url" 

# Find common rows based on the common column
common_rows <- merge(file1, file2, by = common_column)
cols <- ncol(common_rows) 

# Using janitor change column names to snake case (snake_case)
library(janitor)
common_rows <- clean_names(common_rows)

#Check these data 
head(common_rows)

# Write csv
write_csv(common_rows, '../rawdata/final/openrefineHAR.csv')
message(paste0('You have now downloaded and enhanced the Heritage At Risk dataset with ', cols , 
               ' columns - remember to change the pagination numbers for a full set')) 