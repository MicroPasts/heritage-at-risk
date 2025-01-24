# Check if packages exist and if not install them for use
packages <- c("readr","jsonlite")
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
library(readr)
rawdata <- read.csv('https://files.planning.data.gov.uk/dataset/heritage-at-risk.csv')
# Check the data you downloaded for structure
head(rawdata)
message(This gives you a dataset of 20 columns)
# Define columns to drop
drops <- c("organisation.entity","prefix", "categories", "legislation", "notes", "geometry", "geojson")
# Drop the columns
rawDataCols <-rawdata[ , !(names(rawdata) %in% drops)]
# Rename reference column
names(rawDataCols)[names(rawDataCols) == "reference"] <- "ListEntry"

# Test your data again
head(rawDataCols)
write_csv(rawDataCols, '../rawdata/HAR.csv')
message('This produces a 13 column data set of HAR data')
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
# We are going to get 1000 records at a time
recordsToReturn <- 50
# We are going to paginate this response
pagination <- ceiling(totalNHLE/recordsToReturn)
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

message('This produces a data frame that is 7 column data set') 

# Check if packages exist and if not install them for use
packages <- c("sf", "utils")
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
message('This produces a data frame that is 9 column data set') 

# Write to a csv file 
write_csv(data, '../rawdata/NHLE.csv')

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
message(totalScheduled)
# We are going to get 1000 records at a time
recordsToReturn <- 10
# We are going to paginate this response
pagination <- ceiling(totalScheduled/recordsToReturn)

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
data$grade <- NA
head(data)

message('This produces a data frame that is 7 column data set') 

# Check if packages exist and if not install them for use
packages <- c("sf", "utils")
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
message('This produces a data frame that is 9 column data set') 

# Write to a csv file 
write_csv(data, '../rawdata/ScheduledMonuments.csv')

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
head(totalParks)
# We are going to get 10 records at a time
recordsToReturn <- 10
# We are going to paginate this response
pagination <- ceiling(totalParks/recordsToReturn)

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
head(data)

message('This produces a data frame that is 7 column data set') 

# Check if packages exist and if not install them for use
packages <- c("sf", "utils")
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
message('This produces a data frame that is 9 column data set') 

# Write to a csv file 
write_csv(data, '../rawdata/Parks.csv')
message('These data have been written to Parks.csv') 
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
head(totalBattles)
# We are going to get 10 records at a time
recordsToReturn <- 10
# We are going to paginate this response
pagination <- ceiling(totalParks/recordsToReturn)

message(paste0('Pages to download: ', pagination))

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

message('This produces a data frame that is 6 column data set') 

# Check if packages exist and if not install them for use
packages <- c("sf", "utils")
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
message('This produces a data frame that is a 9 column data set') 

# Write to a csv file 
write_csv(data, '../rawdata/Battlefields.csv')
message('These data have been written to Battlefields.csv') 

# Load necessary library
library(dplyr)
# Read the CSV files
file0 <- read.csv("../rawdata/HAR.csv")
head(file0)
file1 <- read.csv("../rawdata/NHLE.csv")
head(file1)
file2 <- read.csv("../rawdata/Battlefields.csv")
head(file2)
file3 <- read.csv("../rawdata/Parks.csv")
head(file3)
file4 <- read.csv("../rawdata/ScheduledMonuments.csv")
head(file4)

# Set the common column, which is always ListEntry
common_column <- "ListEntry" 
# Now start enriching by scraping
# Filter file0 and join with NHLE
common_rows_nhle <- merge(file0, file1, by = common_column) 
head(common_rows_nhle)
common_rows_battlefields <- merge(file0, file2, by = common_column) 
head(common_rows_battlefields)
common_rows_parks <- merge(file0, file3, by = common_column) 
head(common_rows_parks)
common_rows_scheduled <- merge(file0, file4, by = common_column) 
head(common_rows_scheduled)

library(dplyr)
merged <- bind_rows(common_rows_scheduled, common_rows_parks, common_rows_battlefields, common_rows_nhle)
names(merged)[names(merged) == "documentation.url"] <- "url"
head(merged)
write.csv(merged, "../rawdata/merged_har.csv", row.names = FALSE) 

# Check if packages exist and if not install them for use
packages <- c("rvest", "readr", "tidyverse", "stringr")
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

library(rvest)
library(readr)
library(tidyverse)
library(stringr)

# Get the urls list from the previous CSV file created 
urls <- read.csv("../rawdata/merged_har.csv")
# Create an empty list to store the scraped data
scraped_data <- list()
# Loop through the list of urls.
for (i in 1:nrow(urls)) {
  url <- urls[i, 10] # Assuming the URLs are in the tenth column
  reference <-urls[i,1] # Assuming the reference number is column 1
  print(url)
  print(reference)
  # Use tryCatch to handle connection errors
  tryCatch({
    page <- read_html(url)
    css_selector <- ".HARListEntry__bullets-container" # Replace with the actual CSS selector
    
    # Extract the text content from the specified CSS selector
    #text_content <- page %>% html_nodes(css_selector) %>% html_text()
    text_content <- page %>% 
      html_nodes(css_selector) %>% 
      html_text() %>% 
      paste(collapse = " ")

    # Store the extracted data in the list
    scraped_data[[i]] <- list(url = url, text_content = text_content)
    # Remove the page object to free up memory
    rm(page)
    closeAllConnections()
    # Run garbage collection to free up memory
    gc()
  }, error = function(e) {
    # Handle the error (e.g., print a message and continue)
    message(sprintf("Failed to scrape %s: %s", url, e$message))
  })
  # Print the extracted text content
  print(text_content)
  Sys.sleep(0.5)
}
errors_df <- do.call(rbind, lapply(errors, as.data.frame))
head(scraped_data_df)

remove_text_before_location <- function(text) {
   heritage_index <- str_locate(text, "Heritage Category:")
  if (!is.na(heritage_index[1])) { 
    return(str_sub(text, heritage_index[1])) 
  } else {
    return(text) 
  }
}

scraped_data_df <- scraped_data_df %>% 
  mutate(text_content = sapply(text_content, remove_text_before_location))
head(scraped_data_df)

# Write the scraped data to a new CSV file
write_csv(scraped_data_df, "../rawdata/scraped_data.csv") 

# Tidyverse was installed previously. 
library(tidyverse)

# Read the CSV file
df <- read_csv('scraped_data.csv', col_types = cols(.default = "c"))

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
# Write the result to a new CSV file
write_csv(result_df, '../rawdata/processed_scraped_data.csv')

# Load necessary library
library(dplyr)

# Read the CSV files
file1 <- read.csv("../rawdata/processed_scraped_data.csv")
file2 <- read.csv("../rawdata/merged_har.csv")
common_column <- "url" # Replace with the actual column name

# Find common rows based on the common column
common_rows <- merge(file1, file2, by = common_column)


# Print the common rows
head(common_rows)
write_csv(common_rows, '../rawdata/openrefineHAR.csv')