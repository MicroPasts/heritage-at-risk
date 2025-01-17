# Heritage Site Data Transformation Script

This script processes a CSV file containing heritage site data and transforms it into a GeoJSON FeatureCollection.

## Steps

### Installing Required Node Modules

Before running the script, ensure you have the necessary Node.js modules installed. You can do this by running the following command in your terminal:

```sh
npm install fs os papaparse wikimedia-commons-file-path moment
```

1. **Imports Required Modules**:
    - `fs`: For file system operations.
    - `os`: For operating system-related utility methods.
    - `papaparse`: For parsing CSV files.
    - `wikimedia-commons-file-path`: For generating Wikimedia Commons file paths just from the filename.
    - `moment`: For date manipulation.

2. **Helper Functions**:
    - `getPlace(lon, lat)`: Returns a GeoJSON Point object with the given longitude and latitude.
    - `getTypes(properties)`: Generates an array of types based on the properties of the heritage site.
    - `getDepiction(row)`: Generates an array of depictions based on the image path in the row.
    - `getLinks(properties)`: Generates an array of links based on the properties of the heritage site.

3. **Main Function `buildFeature`**:
    - Takes a record, place, longitude, latitude, and row as input.
    - Constructs a GeoJSON Feature object with the given data and additional properties like depictions, types, and links.

4. **Reading and Parsing CSV**:
    - Reads the CSV file `har-lp-ready-csv-enhanced.csv` and parses it using `Papa.parse`.

5. **Processing Each Row**:
    - Iterates over each row in the CSV file.
    - Extracts relevant data fields from the row.
    - Formats dates and constructs a description string.
    - Creates a `peripleoRecord` object with the extracted data.
    - Calls `buildFeature` to create a GeoJSON Feature for each row.
    - Collects all features into an array.

6. **Creating FeatureCollection**:
    - Constructs a GeoJSON FeatureCollection object with the collected features.

7. **Writing Output**:
    - Writes the resulting GeoJSON FeatureCollection to a file `harLP.json`.

   ### How `wikimedia-commons-file-path` Package Works

    The `wikimedia-commons-file-path` package is used to generate Wikimedia Commons file paths from a given filename. This is particularly useful when you need to link to images stored on Wikimedia Commons.

   #### Usage

    To use the `wikimedia-commons-file-path` package, you first need to import it into your script:

    ```javascript
    const commonsFilePath = require('wikimedia-commons-file-path');
    ```

    You can then generate a file path by passing the filename to the `commonsFilePath` function:

    ```javascript
    const filename = 'Example.jpg';
    const filePath = commonsFilePath(filename);
    console.log(filePath); // Outputs: 'https://upload.wikimedia.org/wikipedia/commons/e/ea/Example.jpg'
    ```

    The function automatically handles the necessary transformations to create a valid URL for the file on Wikimedia Commons.

   #### Example

    Here is an example of how you might use this package within the context of the script:

    ```javascript
    function getDepiction(row) {
        const filename = row['image'];
        if (filename) {
            return [commonsFilePath(filename)];
        }
        return [];
    }
    ```

    In this example, the `getDepiction` function takes a row from the CSV file, extracts the image filename, and generates the corresponding Wikimedia Commons file path using the `commonsFilePath` function.
