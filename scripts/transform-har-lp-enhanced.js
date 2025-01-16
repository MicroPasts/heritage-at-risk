import fs, { link } from 'fs';
import { type } from 'os';
import Papa from 'papaparse';
import commons from 'wikimedia-commons-file-path';
import moment from 'moment';

const getPlace = (lon,lat) => {
   
    return {
        type: 'Point',
        coordinates: [ parseFloat(lon), parseFloat(lat) ]
    };

}


const getType = (row) => {
    if (row.wikidataID) {
        return {
            identifier: 'https://www.wikidata.org/wiki/' + row.wikidataEntityID,
            label: row.Heritage_Category
        };
    }
    return null;
}

const getDepiction = (row) => {
    console.log(row)
    if (!row.image_path_commons)
        return;
    const wikicommons = commons('File:'+ row.image_path_commons, 800 /*px*/);
    const depictions = [];
    depictions.push({   
        '@id': wikicommons, 
        thumbnail: wikicommons,
        label: 'A depiction of the heritage site sourced via Wikimedia Commons'
    });
    const flatdepictions = depictions.reduce((all, depiction) => {
        return {
            ...all,
            depictions: [
            ...(all.depictions || []),
            {
                '@id': depiction['@id'],
                thumbnail: depiction.thumbnail,
                label: depiction.label
            }
            ]
        };
    }, {});
    return flatdepictions;
}

const getLinks = (properties) => {
    const churchNearYouURL = 'https://www.achurchnearyou.com/church/';
    const britishListedBuildingURL = 'https://britishlistedbuildings.co.uk/';
    const wikidataURL = 'https://www.wikidata.org/wiki/';
    const historicenglandURL = 'https://historicengland.org.uk/listing/the-list/list-entry/';
    
    const churchnearyou = properties.churchnearyouID ? churchNearYouURL + properties.churchnearyouID : null;
    const britishListedBuilding = properties.britishListedBuildingID ? britishListedBuildingURL + properties.britishListedBuildingID : null;
    const wikidata = properties.wikidataID ? wikidataURL + properties.wikidataID : null;
    const historicengland = properties.List_entry_number ? historicenglandURL + properties.List_entry_number : null;
    const churchnearyouLabel = properties.churchnearyouID ? 'A Church Near You' : null;
    const britishListedBuildingLabel = properties.britishListedBuildingID ? 'British Listed Building' : null;
    const wikidataLabel = properties.wikidataID ? 'Wikidata' : null;
    const historicenglandLabel = properties.List_entry_number ? 'Historic England' : null;
    const churchnearyouType = 'seeAlso';
    const britishListedBuildingType = 'seeAlso';
    const wikidataType = 'seeAlso';
    const historicenglandType = 'seeAlso';
   
    const links = [];
    
    if (churchnearyou && churchnearyou !== 'undefined') {
        links.push({
            identifier: churchnearyou,
            type: churchnearyouType,
            label: churchnearyouLabel
        });
    }

    if (britishListedBuilding && britishListedBuilding !== 'undefined') {
        links.push({
            identifier: britishListedBuilding,
            type: britishListedBuildingType,
            label: britishListedBuildingLabel
        });
    }

    if (wikidata && wikidata !== 'undefined') {
        links.push({
            identifier: wikidata,
            type: wikidataType,
            label: wikidataLabel
        });
    }

    if (historicengland && historicengland !== 'undefined') {
        links.push({
            identifier: historicengland,
            type: historicenglandType,
            label: historicenglandLabel
        });
    }
   
    const flatLinks = links.reduce((all, link) => {
        return {
            ...all,
            links: [
            ...(all.links || []),
            {
                identifier: link.identifier,
                type: link.type,
                label: link.label
            }
            ]
        };
    }, {});
    return flatLinks;
}

const buildFeature = (record, place, lon, lat, row) => {
    console.log(record)
    if (!place?.trim() && !lon?.trim())
        return;

    return {
        ...record,
       // '@id': nanoid(),
        properties: {
            ...record.properties,
            place: place.trim(),
            // relation
        },
        geometry: {
            ...getPlace(lon,lat)
        },
        
            ...getDepiction(row)
        ,
        types: {
            ...getType(row) 
        },
        ...getLinks(row)
        
    }
}


const recordsCsv = fs.readFileSync('../rawData/har-lp-ready-csv-enhanced.csv', { encoding: 'utf8' });
const records = Papa.parse(recordsCsv, { header: true });
const features = records.data.reduce((all, row) => {

    const title = row['name'];
    const lat = row['lat'];
    const lon = row['lon'];
    const source = row['url'];
    const listEntryNumber = row['List_entry_number'];
    const designatedSiteName = row['Designated_Site_Name'];
    const heritageCategory = row['Heritage_Category'];
    const localPlanningAuthority = row['Local_planning_authority'];
    const siteType = row['Site_type'];
    const siteSubType = row['Site_sub_type'];
    const county = row['County'];   
    const districtOrBorough = row['District_or_borough'];
    const parish = row['Parish'];
    const parliamentaryConstituency = row['Parliamentary_Constituency'];
    const region = row['Region'];
    const assessmentType = row['Assessment_Type'];
    const condition = row['Condition'];
    const principalVunerability = row['Principal_Vunerability'];
    const trend = row['Trend'];
    const ownership = row['Ownership'];
    const unitaryAuthority = row['Unitary_Authority'];
    const buildingName = row['Building_name'];
    const occupancyOrUse = row['Occupancy_or_use'];
    const priority = row['Priority'];
    const priorityComment = row['Priority_comment'];
    const previousPriority = row['Previous_priority']; 
    const designation = row['Designation'];
    const locality = row['Locality'];
    const listEntryNumbers = row['List_entry_numbers'];
    const nationalPark = row['National_park'];
    const streetName = row['Street_name'];
    const vulnerability = row['Vulnerability'];
    const endDate = row['end_date'];
    const entity = row['entity'];
    const entryDate = row['entry_date'];
    const list_start_date = row['list_start_date'];


    const place = county;
    const formatDate = (dateString) => {
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0'); // Months are zero-based
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    };

    const formattedDate = formatDate(list_start_date);
    let yearListed = moment(formattedDate, "DD/MM/YYYY").year();
    if (isNaN(yearListed)) {
        yearListed = null;
    } else {
        yearListed = yearListed.toString();
    }

    
    let description = 'Heritage at Risk Entry: ' + listEntryNumber + '<br/>' + title + '<ul>';

    if (entryDate && entryDate.length > 0) description += '<li>Entry date: ' + entryDate + '</li>';
    if (list_start_date && list_start_date.length > 0) description += '<li>First listed: ' + formattedDate + '</li>';
    if (assessmentType && assessmentType.length > 0) description += '<li>Assessment type: ' + assessmentType + '</li>';
    if (condition && condition.length > 0) description += '<li>Condition: ' + condition + '</li>';
    if (principalVunerability && principalVunerability.length > 0) description += '<li>Principal vulnerability: ' + principalVunerability + '</li>';
    if (trend && trend.length > 0) description += '<li>Trend: ' + trend + '</li>';
    if (ownership && ownership.length > 0) description += '<li>Ownership: ' + ownership + '</li>';
    if (unitaryAuthority && unitaryAuthority.length > 0) description += '<li>Unitary authority: ' + unitaryAuthority + '</li>';
    if (buildingName && buildingName.length > 0) description += '<li>Building name: ' + buildingName + '</li>';
    if (occupancyOrUse && occupancyOrUse.length > 0) description += '<li>Occupancy or use: ' + occupancyOrUse + '</li>';
    if (priority && priority.length > 0) description += '<li>Priority: ' + priority + '</li>';
    if (priorityComment && priorityComment.length > 0) description += '<li>Priority comment: ' + priorityComment + '</li>';
    if (previousPriority && previousPriority.length > 0) description += '<li>Previous priority: ' + previousPriority + '</li>';
    if (designation && designation.length > 0) description += '<li>Designation: ' + designation + '</li>';
    if (locality && locality.length > 0) description += '<li>Locality: ' + locality + '</li>';
    if (listEntryNumbers && listEntryNumbers.length > 0) description += '<li>List entry numbers: ' + listEntryNumbers + '</li>';
    
    description += '</ul>';
   

    const peripleoRecord = {
       '@id': source.trim(),
        type: 'Feature',
        properties: {
            title: title,
            source: source,
            listEntryNumber: listEntryNumber,
            designatedSiteName: designatedSiteName,
            heritageCategory: heritageCategory,
            localPlanningAuthority: localPlanningAuthority,
            siteType: siteType,
            siteSubType: siteSubType,
            county: county,
            districtOrBorough: districtOrBorough,   
            parish: parish,
            parliamentaryConstituency: parliamentaryConstituency,
            region: region,
            assessmentType: assessmentType,
            condition: condition,
            principalVunerability: principalVunerability,
            trend: trend,
            ownership: ownership,
            unitaryAuthority: unitaryAuthority,
            buildingName: buildingName,
            occupancyOrUse: occupancyOrUse,
            priority: priority,
            priorityComment: priorityComment,
            previousPriority: previousPriority,
            designation: designation,
            locality: locality,
            listEntryNumbers: listEntryNumbers,
            nationalPark: nationalPark,
            streetName: streetName,
            vulnerability: vulnerability,
            endDate: endDate,
            entity: entity,
            entryDate: entryDate,
            yearListed: yearListed
        },
        descriptions: [{
            value: description
        }]
    };
    //console.log(peripleoRecord)
    const Link = listEntryNumber + '-HAR2024';

    const features = Link?.trim() ? [
        buildFeature(peripleoRecord, place, lon, lat, row)
    ].filter(rec => rec) : [];

    return [...all, ...features];
}, []);

const fc = {
    type: 'FeatureCollection',
    features
};

fs.writeFileSync('../finaldata/harLP.json', JSON.stringify(fc, null, 2), 'utf8');