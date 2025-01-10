# Heritage at Risk Mapping

This project uses Peripleo to map heritage at risk data from Historic England. Peripleo is a powerful tool for visualizing and exploring geospatial data, making it ideal for showcasing heritage sites that are at risk.

<img width="959" alt="image" src="https://github.com/user-attachments/assets/bf334ad5-cdde-49ed-b0a3-424d8be6ba6e" />


## Overview

The Heritage at Risk Mapping project aims to provide an interactive map that highlights heritage sites identified by Historic England as being at risk. This visualization helps in raising awareness and promoting efforts to preserve these important cultural landmarks.

## Features

- Interactive map displaying heritage at risk sites
- Detailed information about each site, including its risk status
- Search and filter functionality to explore specific areas or types of heritage

## Data Source

The data for this project is sourced from Historic England's Heritage at Risk Register. This register includes buildings, monuments, and other heritage assets that are at risk due to neglect, decay, or inappropriate development.

## Getting Started

To get started with the project, follow these steps:

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/heritage-at-risk.git
    ```
2. Navigate to the project directory:
    ```bash
    cd heritage-at-risk
    ```
3. Install the necessary dependencies:
    ```bash
    npm install
    ```
4. This installs the node script dependencies for transforming CSV data that has been obtained from Historic England's opendata hub and transformed by the R scripts.
    ```bash
    cd scripts 
    node ./transform-har-lp.js
    ```

The web application is served off github pages for free, using the docs folder. 
## Contributing

We welcome contributions to the project. If you have suggestions or improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgements

- Historic England for providing the Heritage at Risk data
- The Peripleo team for developing and maintaining the mapping tool

## Contact

For any questions or inquiries put an issue in and I'll respond.
