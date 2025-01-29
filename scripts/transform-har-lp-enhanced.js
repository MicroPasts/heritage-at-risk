/**
 * This script processes a CSV file containing heritage site data, transforms it into GeoJSON format, 
 * and writes the resulting data to a JSON file. The script includes functions to generate GeoJSON 
 * objects, metadata, types, depictions, and links based on the provided data.
 *
 * @file /heritage-at-risk/scripts/transform-har-lp-enhanced.js
 * @requires fs - The Node.js File System module to read and write files.
 * @requires Papa - The PapaParse library to parse CSV data.
 * @requires commons - A module to generate Wikimedia Commons file paths.
 * @requires moment - The Moment.js library to handle date formatting.
 */
import fs, { link } from 'fs';
import Papa from 'papaparse';
import commons from 'wikimedia-commons-file-path';
import moment from 'moment';

/**
 * Creates a GeoJSON Point object from longitude and latitude.
 *
 * @param {number|string} lon - The longitude of the point.
 * @param {number|string} lat - The latitude of the point.
 * @returns {Object} A GeoJSON Point object with the specified coordinates.
 */
const getPlace = (lon,lat) => {
   
    return {
        type: 'Point',
        coordinates: [ parseFloat(lon), parseFloat(lat) ]
    };

}

/**
 * Generates an indexing object for the Heritage-at-Risk dataset.
 *
 * @returns {Object} An object containing metadata for the Heritage-at-Risk dataset.
 * @returns {string} @returns.@context - The context URL for the schema.
 * @returns {string} @returns.@type - The type of the schema object.
 * @returns {string} @returns.name - The name of the dataset.
 * @returns {string} @returns.description - A description of the dataset.
 * @returns {string} @returns.license - The license URL for the dataset.
 * @returns {string} @returns.identifier - The identifier URL for the dataset.
 */
const getIndexing = () => {
    return  {
        "@context": "https://schema.org/",
        "@type": "Dataset",
        "name": "Heritage-at-Risk - Historic England",
        "description": "An enriched dataset of Heritage at Risk entries in England",
        "license": "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/",
        "identifier": "https://www.planning.data.gov.uk/dataset/heritage-at-risk"
    }
}


/**
 * Generates an object containing types based on the provided properties.
 *
 * @param {Object} properties - The properties object.
 * @param {string} [properties.wikiInstanceOf] - The Wikidata instance identifier.
 * @param {string} [properties.wikidataEntityID] - The Wikidata entity identifier.
 * @param {string} [properties.heritage_category] - The heritage category.
 * @param {string} [properties.site_sub_type] - The site sub-type.
 * @returns {Object} An object containing the types with their identifiers and labels.
 */
const getTypes = (properties) => {
    const wikiInstanceOf = properties.wikiInstanceOf ? 'https://www.wikidata.org/wiki/' + properties.wikiInstanceOf : null;
    const wikidataEntityID  = properties.wikidataEntityID ? 'https://www.wikidata.org/wiki/' + properties.wikidataEntityID : null;
    const heritageCategory = properties.heritage_category;
    const siteSubType = properties.site_sub_type;
    const types = [];

    if (wikiInstanceOf && siteSubType) {
        types.push({
            identifier: wikiInstanceOf,
            label: 'A Wikidata type: ' + siteSubType
        });
    }

    if (wikidataEntityID && heritageCategory) {
        types.push({
            identifier: wikidataEntityID,
            label: 'A Wikidata type: ' + heritageCategory
        });
    }

    const flatTypes = types.reduce((all, type) => {
        return {
            ...all,
            types: [
            ...(all.types || []),
            {
                identifier: type.identifier,
                label: type.label
            }
            ]
        };
    }, {});
    return flatTypes;
}

/**
 * Generates a depiction object for a heritage site based on the provided row data.
 *
 * @param {Object} row - The data row containing information about the heritage site.
 * @param {string} row.image_path_commons - The path to the image on Wikimedia Commons.
 * @returns {Object|undefined} An object containing depictions of the heritage site, or undefined if no image path is provided.
 */
const getDepiction = (row) => {
    if (!row.image_path_commons) return;
    const wikicommons = commons('File:' + row.image_path_commons, 800);
    return {
        depictions: [{
            '@id': wikicommons,
            thumbnail: wikicommons,
            label: 'A depiction of the heritage site sourced via Wikimedia Commons'
        }]
    };
}

/**
 * Generates a list of links based on the provided properties.
 *
 * @param {Object} properties - The properties object containing various IDs and information.
 * @param {string} [properties.churchnearyouID] - The ID for the "A Church Near You" entry.
 * @param {string} [properties.britishListedBuildingID] - The ID for the British Listed Building entry.
 * @param {string} [properties.wikidata] - The ID for the Wikidata entity.
 * @param {string} [properties.list_entry_number] - The list entry number for Historic England.
 * @param {string} [properties.wikicommonsCategoryID] - The ID for the Wikimedia Commons category.
 * @param {string} [properties.wikipediaENID] - The ID for the English Wikipedia entry.
 * @returns {Object} An object containing an array of link objects, each with an identifier, type, and label.
 */
const getLinks = (properties) => {
    const urls = {
        churchnearyouID: 'https://www.achurchnearyou.com/church/',
        britishListedBuildingID: 'https://britishlistedbuildings.co.uk/',
        wikidata: 'https://www.wikidata.org/wiki/',
        list_entry_number: 'https://historicengland.org.uk/listing/the-list/list-entry/',
        wikipediaENID: 'https://en.wikipedia.org/wiki/',
        wikicommonsCategoryID: 'https://commons.wikimedia.org/wiki/'
    };

    const labels = {
        churchnearyouID: 'A Church Near You entry ',
        britishListedBuildingID: 'British Listed Building entry ',
        wikidata: 'Wikidata entity ',
        list_entry_number: 'Historic England NHLE number ',
        wikipediaENID: 'Wikipedia (English)',
        wikicommonsCategoryID: 'Wikimedia Commons Category'
    };

    const links = Object.keys(urls).reduce((acc, key) => {
        if (properties[key]) {
            acc.push({
                identifier: urls[key] + properties[key],
                type: 'seeAlso',
                label: labels[key] + (key === 'wikipediaENID' || key === 'wikicommonsCategoryID' ? '' : properties[key])
            });
        }
        return acc;
    }, []);

    return { links };
}

/**
 * Builds a feature object from the given parameters.
 *
 * @param {Object} record - The record object containing initial properties.
 * @param {string} place - The place name associated with the feature.
 * @param {string} lon - The longitude coordinate of the feature.
 * @param {string} lat - The latitude coordinate of the feature.
 * @param {Object} row - The row object containing additional data for the feature.
 * @returns {Object|undefined} The constructed feature object or undefined if place and lon are not provided.
 */
const buildFeature = (record, place, lon, lat, row) => {
    console.log(record)
    if (!place?.trim() && !lon?.trim())
        return;

    return {
        ...record,
        properties: {
            ...record.properties,
            place: place.trim(),
        },
        geometry: {
            ...getPlace(lon,lat)
        },
        
            ...getDepiction(row)
        ,
            ...getTypes(row) 
        ,
            ...getLinks(row)
        
    }
}


/**
 * Reads the content of the CSV file located at '../rawData/har-lp-ready-csv-enhanced.csv' 
 * and stores it in the `recordsCsv` variable.
 *
 * @constant {string} recordsCsv - The content of the CSV file as a UTF-8 encoded string.
 * @requires fs - The Node.js File System module to read the file.
 */
const recordsCsv = fs.readFileSync('../rawData/har-lp-ready-csv-enhanced.csv', { encoding: 'utf8' });

/**
 * Parses a CSV string into an array of objects using PapaParse.
 *
 * @param {string} recordsCsv - The CSV string to be parsed.
 * @returns {Object[]} An array of objects representing the parsed CSV records.
 */
const records = Papa.parse(recordsCsv, { header: true });

/**
 * Generates a GeoJSON feature object for a heritage site based on the provided data.
 *
 * @param {Object} record - The base record object containing properties of the heritage site.
 * @param {string} record['@id'] - The source URL of the heritage site.
 * @param {string} record.type - The type of the GeoJSON object, typically 'Feature'.
 * @param {Object} record.properties - The properties of the heritage site.
 * @param {string} record.properties.title - The title of the heritage site.
 * @param {string} record.properties.source - The source URL of the heritage site.
 * @param {string} record.properties.listEntryNumber - The list entry number for Historic England.
 * @param {string} record.properties.heritageCategory - The heritage category of the site.
 * @param {string} record.properties.localPlanningAuthority - The local planning authority.
 * @param {string} record.properties.siteType - The type of the site.
 * @param {string} record.properties.siteSubType - The subtype of the site.
 * @param {string} record.properties.county - The county where the site is located.
 * @param {string} record.properties.districtOrBorough - The district or borough where the site is located.
 * @param {string} record.properties.parish - The parish where the site is located.
 * @param {string} record.properties.parliamentaryConstituency - The parliamentary constituency.
 * @param {string} record.properties.region - The region where the site is located.
 * @param {string} record.properties.assessmentType - The type of assessment.
 * @param {string} record.properties.condition - The condition of the site.
 * @param {string} record.properties.principalVunerability - The principal vulnerability of the site.
 * @param {string} record.properties.trend - The trend of the site's condition.
 * @param {string} record.properties.ownership - The ownership of the site.
 * @param {string} record.properties.unitaryAuthority - The unitary authority.
 * @param {string} record.properties.buildingName - The name of the building.
 * @param {string} record.properties.occupancyOrUse - The occupancy or use of the site.
 * @param {string} record.properties.priority - The priority level of the site.
 * @param {string} record.properties.priorityComment - Comments on the priority level.
 * @param {string} record.properties.previousPriority - The previous priority level.
 * @param {string} record.properties.designation - The designation of the site.
 * @param {string} record.properties.locality - The locality of the site.
 * @param {string} record.properties.listEntryNumbers - The list entry numbers.
 * @param {string} record.properties.nationalPark - The national park where the site is located.
 * @param {string} record.properties.streetName - The street name where the site is located.
 * @param {string} record.properties.vulnerability - The vulnerability of the site.
 * @param {string} record.properties.endDate - The end date of the site's listing.
 * @param {string} record.properties.entity - The entity associated with the site.
 * @param {string} record.properties.entryDate - The entry date of the site's listing.
 * @param {string} record.properties.yearListed - The year the site was listed.
 * @param {string} record.properties.wikicommonsCategoryID - The Wikimedia Commons category ID.
 * @param {string} record.properties.wikipediaENID - The English Wikipedia entry ID.
 * @param {string} record.properties.wikiInstanceOf - The Wikidata instance of the site.
 * @param {string} record.properties.wikidataEntityID - The Wikidata entity ID.
 * @param {Array<Object>} record.descriptions - An array of description objects.
 * @param {string} record.descriptions[].value - The description of the heritage site.
 * @param {string} place - The place name associated with the heritage site.
 * @param {string} lon - The longitude coordinate of the heritage site.
 * @param {string} lat - The latitude coordinate of the heritage site.
 * @param {Object} row - The data row containing additional information about the heritage site.
 * @param {string} row.image_path_commons - The path to the image on Wikimedia Commons.
 * @param {string} row.wikiInstanceOf - The Wikidata instance of the site.
 * @param {string} row.wikidataEntityID - The Wikidata entity ID.
 * @param {string} row.heritage_category - The heritage category of the site.
 * @param {string} row.site_sub_type - The subtype of the site.
 * @param {string} row.churchnearyouID - The ID for the "A Church Near You" entry.
 * @param {string} row.britishListedBuildingID - The ID for the British Listed Building entry.
 * @param {string} row.wikidata - The ID for the Wikidata entity.
 * @param {string} row.list_entry_number - The list entry number for Historic England.
 * @param {string} row.wikicommonsCategoryID - The ID for the Wikimedia Commons category.
 * @param {string} row.wikipediaENID - The ID for the English Wikipedia entry.
 * @returns {Object|undefined} A GeoJSON feature object representing the heritage site, or undefined if place and lon are not provided.
 */
const features = records.data.map(row => {
    const {
        name: title, lat, lon, url: source, list_entry_number: listEntryNumber, heritage_category: heritageCategory,
        local_planning_authority: localPlanningAuthority, site_type: siteType, site_sub_type: siteSubType, county,
        district_or_borough: districtOrBorough, parish, parliamentary_constituency: parliamentaryConstituency, region,
        assessment_type: assessmentType, condition, principal_vunerability: principalVunerability, trend, ownership,
        unitary_authority: unitaryAuthority, building_name: buildingName, occupancy_or_use: occupancyOrUse, priority,
        priority_comment: priorityComment, previous_priority: previousPriority, designation, locality, list_entry_numbers: listEntryNumbers,
        national_park: nationalPark, street_name: streetName, vulnerability, end_date: endDate, entity, entry_date: entryDate,
        list_start_date, wikicommonsCategoryID, wikipediaENID, wikidataEntityID, wikiInstanceOf
    } = row;

    const place = county;
    const formatDate = dateString => moment(dateString, "YYYY-MM-DD").format("DD/MM/YYYY");
    const formattedDate = formatDate(list_start_date);
    const yearListed = moment(formattedDate, "DD/MM/YYYY").year().toString() || null;

    const fields = [
        { label: 'Entry date', value: entryDate },
        { label: 'First listed', value: list_start_date ? formattedDate : null },
        { label: 'Assessment type', value: assessmentType },
        { label: 'Condition', value: condition },
        { label: 'Principal vulnerability', value: principalVunerability },
        { label: 'Trend', value: trend },
        { label: 'Ownership', value: ownership },
        { label: 'Unitary authority', value: unitaryAuthority },
        { label: 'Building name', value: buildingName },
        { label: 'Occupancy or use', value: occupancyOrUse },
        { label: 'Priority', value: priority },
        { label: 'Priority comment', value: priorityComment },
        { label: 'Previous priority', value: previousPriority },
        { label: 'Designation', value: designation },
        { label: 'Locality', value: locality },
        { label: 'List entry numbers', value: listEntryNumbers }
    ];

    const description = `Heritage at Risk Entry: ${listEntryNumber}<br/>${title}<ul>` +
        fields.filter(field => field.value).map(field => `<li>${field.label}: ${field.value}</li>`).join('') +
        '</ul>'.trim().replace(/\n/g, '');
    
    const peripleoRecord = {
        '@id': source.trim(),
        type: 'Feature',
        properties: {
            title, source, listEntryNumber, heritageCategory, localPlanningAuthority, siteType, siteSubType, county,
            districtOrBorough, parish, parliamentaryConstituency, region, assessmentType, condition, principalVunerability,
            trend, ownership, unitaryAuthority, buildingName, occupancyOrUse, priority, priorityComment, previousPriority,
            designation, locality, listEntryNumbers, nationalPark, streetName, vulnerability, endDate, entity, entryDate,
            yearListed, wikicommonsCategoryID, wikipediaENID, wikiInstanceOf, wikidataEntityID
        },
        descriptions: [{ value: description }]
    };

    return buildFeature(peripleoRecord, place, lon, lat, row);
}).filter(Boolean);
const indexing = getIndexing();
const fc = {
    type: 'FeatureCollection',
    indexing,
    features
};

/**
 * Writes the GeoJSON FeatureCollection object to a JSON file located at '../docs/data/harLP.json'.
 *
 * @requires fs - The Node.js File System module to write the file.
 */
fs.writeFileSync('../docs/data/harLP.json', JSON.stringify(fc, null, 2), 'utf8');