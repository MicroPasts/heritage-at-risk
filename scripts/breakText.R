library(tidyverse)

# Read the CSV file
df <- read_csv('../rawdata/scraped_data.csv')

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

# Write the result to a new CSV file
write_csv(result_df, '../rawdata/processed_scraped_data.csv')