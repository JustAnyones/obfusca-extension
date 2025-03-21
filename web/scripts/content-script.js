let ref_keeper = {}
let cnt = 0;

function initRefKeeper() {
    ref_keeper = {}
    cnt = 0
}

const Generators = {
    USERNAME: "namespace::username_generator",
    FIRSTNAME: "namespace::firstname_generator",
    LASTNAME: "namespace::lastname_generator",
    EMAIL: "namespace::email_generator",
    PASSWORD: "namespace::password_generator",

    BIRTH_DAY: "namespace::birth_day_generator",
    BIRTH_MONTH: "namespace::birth_month_generator",
    BIRTH_YEAR: "namespace::birth_year_generator",
    BIRTH_DATE: "namespace::birth_date_generator",
}

const autocomplete_bindings = {
    "name": "First Name or Username or Email?",

    "given-name": Generators.FIRSTNAME,
    "family-name": Generators.LASTNAME,
    "additional-name": "",

    "honorific-prefix": "HONORIFIC PREFIX",
    "honorific-suffix": "HONORIFIC SUFFIX",

    "email": Generators.EMAIL,
    "nickname": "",
    "organization-title": "",
    "username": Generators.USERNAME,
    "new-password": Generators.PASSWORD,
    "current-password": Generators.PASSWORD,
    "organization": "",

    // Address
    "postal-code": "",
    "street-address": "",
    "address-line1": "",
    "address-line2": "",
    "address-line3": "",
    "address-level1": "",
    "address-level2": "",
    "address-level4": "",
    "address-level3": "",
    "country": "",
    "country-name": "",

    // Credit card
    "cc-name": "",
    "cc-given-name": "",
    "cc-additional-name": "",
    "cc-family-name": "",
    "cc-number": "",
    "cc-exp": "",
    "cc-exp-month": "",
    "cc-exp-year": "",
    "cc-csc": "",
    "cc-type": "",

    "transaction-currency": "",
    "transaction-amount": "",

    "language": "",

    // Birth date
    "bday": "",
    "bday-day": Generators.BIRTH_DAY,
    "bday-month": Generators.BIRTH_MONTH,
    "bday-year": Generators.BIRTH_YEAR,

    "sex": "",
    "url": "",
    "photo": "",

    // Phone related
    "tel": "",
    "tel-country-code": "",
    "tel-national": "",
    "tel-area-code": "",
    "tel-local": "",
    "tel-local-prefix": "",
    "tel-local-suffix": "",
    "tel-extension": "",

    "impp": "",
}


function serializeOptions(options) {
    let serialized = []

    for (const option of options) {
        serialized.push({
            value: option.value,
            text: option.text,
            selected: option.selected
        })
    }

    return serialized
}

/**
 * 
 * @param {any} field Represents a HTML field.
 * @param {string} generator Namespaced generator name.
 * @returns 
 */
function registerField(field, generator) {
    cnt++
    ref_keeper[cnt] = field
    if (field.tagName === "SELECT") {
        return {ref: cnt, type: "SELECT", options: serializeOptions(field.options), generator: generator}
    }
    return {ref: cnt, generator: generator}
}

function isForm(form, url) {
    if (form.match.type === "static") {
        const pattern = new RegExp(form["match"]["pattern"] ?? ".+", "g")
        const match = url.match(pattern)
        //console.log("Regex match", pattern, match)
        return match !== null
    } else {
        console.error("Unknown form match type " + form.match.type.toString())
    }
    return false
}

function fieldDetails(generator) {
    return {
        "generator": generator
    }
}

function detectFirstName(field) {
    if (RegExp(/firstname/).test(field.name)) {
        return fieldDetails(Generators.FIRSTNAME)
    }
}

function detectLastName(field) {
    if (RegExp(/lastname/).test(field.name)) {
        return fieldDetails(Generators.LASTNAME)
    }
}

function detectEmail(field) {
    if (RegExp(/email/).test(field.name)) {
        return fieldDetails(Generators.EMAIL)
    }
}

function detectUsername(field) {
    if (field.name === "username") {
        return fieldDetails(Generators.USERNAME)
    }
}

function detectPassword(field) {
    if (field.type === "password") {
        return fieldDetails(Generators.PASSWORD)
    }
}

const heuristicDetectors = [
    detectFirstName,
    detectLastName,
    detectUsername,
    detectEmail,
    detectPassword,
    // Birth day
    (field) => {
        if (RegExp(/birthday_day/).test(field.name)) {
            return fieldDetails(Generators.BIRTH_DAY)
        }
    },
    // Birth month
    (field) => {
        if (RegExp(/birthday_month/).test(field.name)) {
            return fieldDetails(Generators.BIRTH_MONTH)
        }
    },
    // Birth year
    (field) => {
        if (RegExp(/birthday_year/).test(field.name)) {
            return fieldDetails(Generators.BIRTH_YEAR)
        }
    }
]

function determineFieldData(field) {
    const autocomplete = field.getAttribute("autocomplete")
    if (autocomplete !== null && autocomplete !== "off") {
        console.log("Determining from autocomplete")
        const val = autocomplete_bindings[autocomplete]
        if (val === undefined) {
            console.warn("No autocomplete binding for", autocomplete)
        } else {
            return fieldDetails(val)
        }
    }

    for (const detector of heuristicDetectors) {
        const result = detector(field)
        if (result !== undefined) {
            return result
        }
    }

    console.warn("Could not determine field data for", field)
}

function locateAutomatically() {
    let fields = []

    const inputs = document.querySelectorAll('input, select')
    for (const field of inputs) {
        // Skip hidden fields
        if (field.type === "hidden") {
            continue
        }

        const res = determineFieldData(field)
        if (res !== undefined) {
            fields.push(registerField(field, res.generator))
        }
    }
    return fields;
}

/**
 * 
 * @param {*} entry 
 * @returns 
 */
function locateFromDataEntry(entry) {
    console.log("Running on", document, window.location.href)

    let fields = []
    for (const form of entry["forms"]) {
        console.log(form);

        if (!isForm(form, window.location.href)) {
            continue;   
        }
        console.log("Matched via", form["match"])

        for (const field of form["fields"]) {
            const eleme = document.querySelector(field["selector"])
            console.log("Query", field["selector"], eleme)
            if (eleme !== null) {
                fields.push(registerField(eleme, field["generator"]))
            }
        }
    }
    return fields;
}

function fillFields(fields) {
    for (const field of fields) {
        const element = ref_keeper[field.ref]
        // TODO: implement support for selects
        element.value = field.value
        // Notify about fields being changed
        element.dispatchEvent(new Event("change"));
        element.dispatchEvent(new Event("click"));
        element.dispatchEvent(new Event("keyup"));
    } 
}



function locateFields(data) {
    const entry = data[window.location.hostname]
    if (entry === undefined) return locateAutomatically()

    return locateFromDataEntry(entry)

    window.postMessage({ type: "FROM_A", data: "Hello from A" }, "*");

    /*var port = chrome.runtime.connect({name: "knockknock"});
    port.postMessage({joke: "Knock knock"});
    port.onMessage.addListener(function(msg) {
        if (msg.question === "Who's there?")
            port.postMessage({answer: "Madame"});
        else if (msg.question === "Madame who?")
            port.postMessage({answer: "Madame... Bovary"});
    });*/
}

// Called when site finishes loading, not all iframes
(async () => {
    const dataUrl = chrome.runtime.getURL("predefined.json");
    const response = await fetch(dataUrl)
    const data = await response.json()


    chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
        // Called when the popup requests fields
        if (request.action === "requestFields") {
            console.log("Received request for fields from popup");
            initRefKeeper()
            let fieldData = locateFields(data)
            console.log(fieldData)

            if (fieldData.length === 0) {
                sendResponse({status: "NOT_FOUND", data: fieldData})
            } else {
                sendResponse({status: "FOUND", data: fieldData});
            }
        }

        // Called when the popup requests fields
        if (request.action === "fillFields") {
            console.log("Received request to fill fields from popup:", request.fields);
            fillFields(request.fields)
            sendResponse({status: "OK"});
        }
    });
})()
