# Requesting fields

Upon requesting JavaScript module to get fillable fields, it returns ... for each frame.

Each frame contains an array with the following data:
```json
[
    // Refers to a specific generatable field
    {
        "ref": 1, // always a number
        // List of generators that can be potentially used
        "generators": [{
            // Namespaced generator name
            "name": "namespace::username_generator"
        }],
        // An array of options, returned for SELECT elements
        "options": [{
            "value": "string",
            "text": "string",
            "selected": true
        }],
        // An array of contextual information for field backing elements
        // In cases of RADIO elements, there's more than one context object
        "context": [{
            "tagName": "string",
            "type": "string",
            "name": "string",
            "value": "string",
            "id": "string",
            "className": "string",
            "required": true,
            "readOnly": false,
            "disabled": false,
            "maxLength": -1,
            "minLength": -1,
            "placeholder": "string or null",
            "ariaLabel": "string or null"
        }]
    }
]
```
This is not necessarily guaranteed to be up to date and you're advised to inspect JSDoc definitions
in cases of ambiguity.

# Filling fields
...