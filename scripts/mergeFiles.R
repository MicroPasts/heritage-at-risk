# Load necessary library
library(dplyr)

# Read the CSV files
file1 <- read.csv("../rawdata/National_Heritage_List_for_England_NHLE.csv")
file2 <- read.csv("../rawdata/heritage-at-risk.csv")
file3 <- read.csv("../rawdata/conservation.csv")
common_column <- "reference" # Replace with the actual column name

# Find common rows based on the common column
common_rows_cons <- merge(file2, file3, by = common_column)
common_rows_nhle <- merge(file2, file1, by = common_column)


# Print the common rows
print(common_rows)

# Optionally, write the common rows to a new CSV file
write.csv(common_rows, "../rawdata/common_rows.csv", row.names = FALSE)