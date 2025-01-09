install.packages("rvest")
install.packages("readr")
install.packages("tidyverse")
library(rvest)
library(readr)
library(tidyverse)
urls <- read.csv("../rawdata/haredits.csv")
# Create an empty list to store the scraped data
scraped_data <- list()

for (i in 1:nrow(urls)) {
  url <- urls[i, 15] # Assuming the URLs are in the first column
  reference <-urls[i,11]
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
    scraped_data[[i]] <- list(url = url, text_content = NA)
  })
  # Print the extracted text content
  print(text_content)
  Sys.sleep(0.5)
}
# Convert the list to a data frame
scraped_data_df <- do.call(rbind, lapply(scraped_data, as.data.frame))

# Print the scraped data
head(scraped_data_df)

# Optionally, write the scraped data to a new CSV file
write_csv(scraped_data_df, "../rawdata/scraped_data.csv") # Replace with the desired output path