import fs from 'fs';
import Papa from 'papaparse';

const getPlace = (lon,lat) => {
    console.log(lon)
    console.log(lat)
    return {
        type: 'Point',
        coordinates: [ parseFloat(lon), parseFloat(lat) ]
    };

}

const buildFeature = (record, place, lon, lat) => {
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
        }
    }
}


const recordsCsv = fs.readFileSync('../rawData/har-lp-ready.csv', { encoding: 'utf8' });
const records = Papa.parse(recordsCsv, { header: true });
const features = records.data.reduce((all, row) => {
    console.log(row)
    

    const title = row['name'];
    const lat = row['lat'];
    const lon = row['lon'];
    const source = row['url'];
    const listEntryNumber = row['List entry number'];
    const designatedSiteName = row['Designated.Site.Name'];
    const heritageCategory = row['Heritage.Category'];
    const localPlanningAuthority = row['Local planning authority'];
    const siteType = row['Site type'];
    const siteSubType = row['Site sub type'];
    const county = row['County'];   
    const districtOrBorough = row['District or borough'];
    const parish = row['Parish'];
    const parliamentaryConstituency = row['Parliamentary Constituency'];
    const region = row['Region'];
    const assessmentType = row['Assessment Type'];
    const condition = row['Condition'];
    const principalVunerability = row['Principal Vunerability'];
    const trend = row['Trend'];
    const ownership = row['Ownership'];
    const unitaryAuthority = row['Unitary Authority'];
    const buildingName = row['Building name'];
    const occupancyOrUse = row['Occupancy or use'];
    const priority = row['Priority'];
    const priorityComment = row['Priority comment'];
    const previousPriority = row['Previous priority']; 
    const designation = row['Designation'];
    const locality = row['Locality'];
    const listEntryNumbers = row['List entry numbers'];
    const nationalPark = row['National park'];
    const streetName = row['Street name'];
    const vulnerability = row['Vulnerability'];
    const endDate = row['end date'];
    const entity = row['entity'];
    const entryDate = row['entry date'];

    const place = county;
    let description = 'Heritage at Risk Entry: ' + listEntryNumber + '<br/>' + title + '<ul>';

    if (entryDate && entryDate.length > 0) description += '<li>Entry date: ' + entryDate + '</li>';
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
    console.log(place)
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
            entryDate: entryDate
        },
        descriptions: [{
            value: description
        }]
    };
    console.log(peripleoRecord)
    const Link = listEntryNumber + '-HAR2024';

    const features = Link?.trim() ? [
        buildFeature(peripleoRecord, place, lon, lat)
    ].filter(rec => rec) : [];

    return [...all, ...features];
}, []);

const fc = {
    type: 'FeatureCollection',
    features
};

fs.writeFileSync('../finaldata/harLP.json', JSON.stringify(fc, null, 2), 'utf8');