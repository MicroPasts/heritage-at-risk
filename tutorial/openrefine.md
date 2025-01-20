# Tutorial: Reconciling Historic England Place Names with Wikidata using OpenRefine

## Introduction

This tutorial will guide you through the process of using OpenRefine to reconcile Historic England place names and lists against Wikidata entities. OpenRefine is a powerful tool for working with messy data, and reconciliation allows you to match your data with external databases like Wikidata.

## Prerequisites

- OpenRefine installed on your computer. You can download it from [openrefine.org](https://openrefine.org/download.html).
- A dataset containing Historic England place names and lists in a CSV format.
- An internet connection to access Wikidata.

## Steps

### Step 1: Load Your Dataset

1. Open OpenRefine and create a new project.
2. Click on "Choose Files" and select your CSV file containing the Historic England place names.
3. Click "Next" and review the data preview. Make sure the data is correctly parsed.
4. Click "Create Project".

### Step 2: Prepare Your Data

1. Review your dataset and ensure that the place names are in a single column.
2. If necessary, clean your data using OpenRefine's text transformation functions.

### Step 3: Add Reconciliation Service

1. Go to the "Reconcile" menu and select "Add Standard Service".
2. Enter the URL for the Wikidata reconciliation service: `https://wikidata.reconci.link/en/api`.
3. Click "Add Service".

### Step 4: Reconcile Place Names

1. Click on the drop-down menu of the column containing the place names.
2. Select "Reconcile" > "Start Reconciling".
3. Choose the Wikidata reconciliation service you added earlier.
4. Select the type of entity you want to match (e.g., "Place").
5. Click "Start Reconciling".

### Step 5: Review and Match Results

1. OpenRefine will attempt to match your place names with Wikidata entities.
2. Review the matches and manually correct any mismatches.
3. Confirm the matches by clicking on the checkmarks.

### Step 6: Export the Reconciled Data

1. Once you are satisfied with the reconciliation, click on "Export" at the top right corner.
2. Choose your preferred export format (e.g., CSV, Excel).
3. Save the reconciled dataset to your computer.

## Conclusion

You have successfully reconciled Historic England place names with Wikidata entities using OpenRefine. This process helps enrich your dataset with additional information from Wikidata, making it more valuable for further analysis.

For more information on OpenRefine and its features, visit the [OpenRefine documentation](https://docs.openrefine.org/).

### Appendix: Trimming Whitespace from Text Values

Sometimes your dataset may contain leading or trailing whitespace in text values, which can affect data quality and reconciliation results. OpenRefine provides a simple way to trim whitespace from text values in cells.

#### Steps to Trim Whitespace

1. Click on the drop-down menu of the column you want to clean.
2. Select "Edit cells" > "Common transforms" > "Trim leading and trailing whitespace".

This will remove any leading or trailing whitespace from the text values in the selected column, ensuring cleaner and more consistent data.

For more advanced text transformations, you can use OpenRefine's GREL (General Refine Expression Language) functions. For example, to trim whitespace from a specific column using GREL:

1. Click on the drop-down menu of the column you want to clean.
2. Select "Edit cells" > "Transform...".
3. In the expression box, enter the following GREL expression: `trim(value)`.
4. Click "OK" to apply the transformation.

This will trim whitespace from all text values in the selected column using the GREL `trim` function.

### Appendix: Renaming Columns

Renaming columns in OpenRefine can help you better organize and understand your dataset. Follow these steps to rename a column:

#### Steps to Rename a Column

1. Click on the drop-down menu of the column you want to rename.
2. Select "Edit column" > "Rename this column...".
3. In the dialog box, enter the new name for the column.
4. Click "OK" to apply the new name.

This will rename the selected column to the new name you provided, making it easier to identify and work with your data.

For more information on column operations, refer to the [OpenRefine documentation](https://docs.openrefine.org/manual/column).

### Appendix: Replacing Text in Cells

In some cases, you may need to replace specific text values within your dataset. OpenRefine allows you to easily find and replace text in cells, which can be useful for standardizing data or correcting errors.

#### Steps to Replace Text

1. Click on the drop-down menu of the column you want to modify.
2. Select "Edit cells" > "Transform...".
3. In the expression box, enter the following GREL expression: `replace(value, "http://historicengland.org.uk", "https://historicengland.org.uk")`.
4. Click "OK" to apply the transformation.

This will replace all instances of `http://historicengland.org.uk` with `https://historicengland.org.uk` in the selected column.

For more complex replacements, you can use regular expressions with the `replace` function. For example, to replace all instances of "Historic England" with "HE":

1. Click on the drop-down menu of the column you want to modify.
2. Select "Edit cells" > "Transform...".
3. In the expression box, enter the following GREL expression: `replace( value, '/Historic England/', "HE")`.
4. Click "OK" to apply the transformation.

This will replace all occurrences of "Historic England" with "HE" in the selected column using a regular expression.

### Appendix: Retrieving JSON Data from Wikidata URLs

You can enhance your dataset by retrieving additional information from Wikidata URLs and storing it as a new column in OpenRefine. This can be useful for enriching your data with more detailed information from Wikidata.

#### Steps to Retrieve JSON Data

1. Ensure that your dataset contains a column with Wikidata URLs.
2. Click on the drop-down menu of the column containing the Wikidata URLs.
3. Select "Edit column" > "Add column by fetching URLs...".
4. In the dialog box, enter the following settings:
    - **New column name**: Enter a name for the new column that will store the JSON data.
    - **Throttle delay**: Set a delay (e.g., 500 milliseconds) to avoid overloading the Wikidata server.
    - **URL expression**: Use the column name containing the URLs, e.g., `value`.
5. Click "OK" to start fetching the JSON data.

OpenRefine will fetch the JSON data from each Wikidata URL and store it in the new column. You can then parse and extract specific information from the JSON data using OpenRefine's GREL functions.

#### Example: Extracting Labels from JSON Data

1. Click on the drop-down menu of the new column containing the JSON data.
2. Select "Edit column" > "Add column based on this column...".
3. In the expression box, enter the following GREL expression to extract the label from the JSON data:

    ```grel
    parseJson(value).entities[0].labels.en.value
    ```

4. Click "OK" to create the new column with the extracted labels.

This will create a new column containing the labels extracted from the JSON data, enriching your dataset with additional information from Wikidata.

For more advanced JSON parsing, refer to the [OpenRefine documentation](https://docs.openrefine.org/manual/grelfunctions#parsejson).

### Example GREL queries to extract data from a wikidata json field

#### Steps to Create a New Column from Parsed JSON Data

1. Ensure that your dataset contains a column with JSON data.
2. Click on the drop-down menu of the column containing the JSON data.
3. Select "Edit column" > "Add column based on this column...".
4. In the dialog box, enter the following settings:
    - **New column name**: Enter a name for the new column that will store the parsed data.
    - **Expression**: Use a GREL expression to parse the JSON data and extract the desired information.
5. Click "OK" to create the new column with the parsed data.

For example, to extract the English Wikipedia URL from the JSON data:

1. Click on the drop-down menu of the column containing the JSON data.
2. Select "Edit column" > "Add column based on this column...".
3. In the expression box, enter the following GREL expression:

    ```grel
    value.parseJson()['entities'][cells['ids'].value]['sitelinks']['enwiki']['url']
    ```

4. Click "OK" to create the new column with the extracted English Wikipedia URLs.

This process can be repeated with different GREL expressions to extract various pieces of information from the JSON data and store them in new columns.

Extract english wikipedia URI from json:

```
value.parseJson()['entities'][cells['ids'].value]['sitelinks']['enwiki']['url']
```

Extract wikicommons URI from json:

```
value.parseJson()['entities'][cells['ids'].value]['sitelinks']['commonswiki']['url']
```

Extract P31 claim from json (instance of):

```
value.parseJson()['entities'][cells['ids'].value]['claims']['P31'][0]['mainsnak'].datavalue.value.id
```

Extract P18 claim from json (image file name): 

```
value.parseJson()['entities'][cells['ids'].value]['claims']['P31'][0]['mainsnak']['datavalue'].value
```

Extract P12485 claim from json (British Listed Building ID):

```
value.parseJson()['entities'][cells['ids'].value]['claims']['P12485'][0]['mainsnak'].datavalue.value
```

Extract P5464 claim from json (A Church Near You church ID):

```
value.parseJson()['entities'][cells['ids'].value]['claims']['P5464'][0]['mainsnak'].datavalue.value
```

Extract P580 claim from json (first listed or start time), create new column from URLS:

```
value.parseJson()['entities'][cells['ids'].value]['claims']['P1435'][0]['qualifiers']['P580'][0].datavalue.value.time
```

export const getTypes = (node) => {
  if (node.types?.length > 0)
    return node.types.map(t => ({ label: t.label, identifier: t.identifier }));
  else if (node.properties?.type)
    return [{ label: node.properties.type, identifier: node.properties.identifier }];
  else if (node.types?.length > 0)
    return node.types.map(t => ({ label: t.label, identifier: t.identifier }));
  else
    return [];
}

  <p className="p6o-node-types">
              {getTypes(node).join(', ')}
            </p>