# How to customise Peripleo 

For this instance of Peripleo, several changes were made to the system. To do this
I cloned the code from the Fitzwilliam Museum project that I worked on with Rainer Simon
as part of the Open University's OSC funded project with Elton Barker to map antiquity.

The code for this is installed in the [peripleo](/peripleo/) directory. 

## Changes made 

1. Colour scheme for the info boxes from royal blue to black
2. Made types a clickable line break separated list

### How to do this

The following files were changed. 

#### Colour scheme
Edit the following file [peripleo/src/map/Map.scss](peripleo/src/map/Map.scss) and change 

```css
.maplibregl-popup-tip {
    position:relative;
    top:3px;
    border-bottom-color: #000000;
  }
```
Edit [peripleo/src/Colors.js](peripleo/src/Colors.js) and add an extra color key:

```
export const SIGNATURE_COLOR = [
  '#ffd300', // Yellow
  '#0d8b22', // Green
  '#0e47c8', // Dark blue
  '#0095ff', // Light blue
  '#9d00d1', // Purple
  '#ff5bdb', // Pink
  '#ff2e38', // Red
  '#ff8000', // Orange
  '#000000'  // Black
];
```
Edit [peripleo/src/map/selection/cards/ItemListCard.jsx](peripleo/src/map/selection/cards/ItemListCard.jsx) and [peripleo/src/map/selection/cards/ItemCard.jsx](peripleo/src/map/selection/cards/ItemCard.jsx) change the signature colour to pick up the new black key in both files.

```javascript
  const color = SIGNATURE_COLOR[8]; 
```

### Change types to a clickable key value pair

I then changed the rendering for the types pulled from the geojson. Edit
[peripleo/src/map/selection/cards/Utils.js](peripleo/src/map/selection/cards/Utils.js) and
the new types:

```javascript
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
```

Then edit [peripleo/src/map/selection/cards/ItemListCard.jsx](peripleo/src/map/selection/cards/ItemListCard.jsx) and [peripleo/src/map/selection/cards/ItemCard.jsx](peripleo/src/map/selection/cards/ItemCard.jsx)

```javascript
        <p className="p6o-node-types" dangerouslySetInnerHTML={{ __html: getTypes(node).map(type => `<a href="${type.identifier}" target="_blank">${type.label}</a>`).join('<br /> ') }} />
```

## Compiling new javascript bundle

Once changes have been made, the bundled javascript needs updating. To do this:

```bash
cd peripleo
npm install
npm run build
```

Once complete, I copied the file to a new js folder in the docs root that the project is served from using Github pages (see the Peripleo full tutorial on how to do this) and edited the index.html file to point to the JS folder. 