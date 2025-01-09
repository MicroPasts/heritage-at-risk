# Load necessary library
library(dplyr)

# Read the CSV files
file1 <- read.csv("../rawdata/processed_scraped_data.csv")
file2 <- read.csv("../rawdata/har.csv")
common_column <- "url" # Replace with the actual column name

# Find common rows based on the common column
common_rows_cons <- merge(file1, file2, by = common_column)


# Print the common rows
print(common_rows_cons)
head(common_rows_cons)
write_csv(common_rows_cons, '../rawdata/har-lp-ready.csv')
