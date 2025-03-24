//@ts-check
"use strict";

class Generator {
    /**
     * @param {string} name 
     */
    constructor(name) {
        this.name = name;
    }
}

/**
 * @typedef {Object} FieldContext
 * @property {string} tagName
 * @property {string} type
 * @property {string} name
 * @property {string} value
 * @property {string} id
 * @property {string} className
 * @property {boolean} required
 * @property {boolean} readOnly
 * @property {boolean} disabled
 * @property {number} maxLength
 * @property {number} minLength
 * @property {string | null} placeholder
 * @property {string | null} ariaLabel
 */

/**
 * @typedef {Object} Option
 * @property {string} value
 * @property {string} text
 * @property {boolean} selected
 */

/**
 * 
 * This data is passed to Flutter.
 * @typedef {Object} Field
 * @property {number} ref The reference number to the field.
 * @property {Generator[]} generators A list of generators that can be used to fill the field.
 * @property {string} generator Backwards compatibility with the old format.
 * @property {Option[]} options A list of possible options for the field.
 * @property {FieldContext[]} context A list of context data for each HTML field of this field.
 */

/**
 * @typedef {(HTMLInputElement|HTMLSelectElement)} ParseableElement
 */


/** @type {Object.<number, ParseableElement[]>} */
let reference_store = {}
let reference_count = 0

/**
 * Resets the reference store.
 */
function resetStore() {
    reference_store = {}
    reference_count = 0
}

/**
 * Serializes the options of a select field for transmission to Flutter.
 * @param {HTMLOptionsCollection} options 
 * @returns {Option[]}
 */
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
 * @param {HTMLInputElement | HTMLSelectElement} field 
 * @param {Generator[]} generators
 * @returns {Field}
 */
function registerField(field, generators) {
    console.log("Registering field", field, "with generators", generators)

    let options = []
    /** @type {FieldContext[]} */
    let context = []

    // Determine the reference number for the field
    // Radios are a special case and should be grouped together if the name is the same
    if (field.type === "radio") {
        let found = false
        for (const ref in reference_store) {
            let refAsNum = parseInt(ref, 10)
            const storedFields = reference_store[refAsNum]
            for (const stored of storedFields) {
                if (stored.name === field.name) {
                    reference_count = refAsNum
                    reference_store[refAsNum].push(field)
                    found = true
                    break
                }
            }
        }
        if (!found) {
            reference_count++
            reference_store[reference_count] = [field]
        }

    } else {
        reference_count++
        reference_store[reference_count] = [field]
    }

    // If the field is a select field, we need to serialize the options
    if (field.tagName === "SELECT") {
        options = serializeOptions(field.options)
    }

    // Add context data for each field
    for (const field of reference_store[reference_count]) {
        context.push({
            tagName: field.tagName,
            type: field.type,
            name: field.name,
            value: field.value,
            id: field.id,
            className: field.className,
            required: field.required,
            readOnly: field instanceof HTMLInputElement ? field.readOnly : false,
            disabled: field.disabled,
            maxLength: field instanceof HTMLInputElement ? field.maxLength : -1,
            minLength: field instanceof HTMLInputElement ? field.minLength: -1,
            placeholder: field instanceof HTMLInputElement ? field.placeholder : null,
            ariaLabel: field.getAttribute("aria-label"),
        })
    }

    return {
        ref: reference_count,
        generator: generators[0].name,
        generators: generators,
        options: options,
        context: context,
    }
}

const Generators = {
    USERNAME: new Generator("namespace::username_generator"),
    FIRSTNAME: new Generator("namespace::firstname_generator"),
    LASTNAME: new Generator("namespace::lastname_generator"),
    EMAIL: new Generator("namespace::email_generator"),
    PASSWORD: new Generator("namespace::password_generator"),

    BIRTH_DAY: new Generator("namespace::birth_day_generator"),
    BIRTH_MONTH: new Generator("namespace::birth_month_generator"),
    BIRTH_YEAR: new Generator("namespace::birth_year_generator"),
    BIRTH_DATE: new Generator("namespace::birth_date_generator"),

    SEX: new Generator("namespace::sex_generator"),

    COUNTRY: new Generator("namespace::country_generator"),
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

    "sex": Generators.SEX,
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

/**
 * This list is used to define which fields should be ignored for automatic detection.
 * @type {((field: ParseableElement) => boolean)[]}
 */
const ignoredDetectors = [
    (field) => {
        const aria = field.getAttribute("aria-label")
        const type = field.getAttribute("type")

        if (type && RegExp(/search|submit/, "i").test(type)) {
            return true
        }

        if (aria && RegExp(/otp/, "i").test(aria)) {
            return true
        }
        return false
    }
]

/**
 * @type {((field: ParseableElement) => Generator | undefined)[]}
 */
const heuristicDetectors = [
    // First name
    (field) => {
        if (RegExp(/firstname/, "i").test(field.name)) {
            return Generators.FIRSTNAME
        }
    },
    // Last name
    (field) => {
        if (RegExp(/lastname/, "i").test(field.name)) {
            return Generators.LASTNAME
        }
    },
    // Username
    (field) => {
        if (field.name === "username" || RegExp(/username|user_name/, "i").test(field.name)) {
            return Generators.USERNAME
        }
    },
    // Email
    (field) => {
        if (RegExp(/email/).test(field.name)) {
            return Generators.EMAIL
        }
    },
    // Password
    (field) => {
        if (field.type === "password") {
            return Generators.PASSWORD
        }
    },
    // Birth month
    (field) => {
        if (RegExp(/birthday_month|birthmonth/, "i").test(field.name)) {
            return Generators.BIRTH_MONTH
        }
    },
    // Birth year
    (field) => {
        if (RegExp(/birthday_year|birthyear/, "i").test(field.name)) {
            return Generators.BIRTH_YEAR
        }
    },
    // Birth day
    (field) => {
        if (RegExp(/birthday_day|birthday/, "i").test(field.name)) {
            return Generators.BIRTH_DAY
        }
    },

    // Country
    (field) => {
        if (RegExp(/countryregion/, "i").test(field.id)) {
            return Generators.COUNTRY
        }
    },

    // Sex
    (field) => {
        if (RegExp(/sex|gender/, "i").test(field.name)) {
            return Generators.SEX
        }
    },
]

/**
 * Detects fields that can be filled in the current frame automatically.
 * @param {ParseableElement} field A HTML element.
 * @returns {Generator[] | Generator | undefined} A list of generators that can be used to fill the field.
 */
function determineFieldData(field) {
    const autocomplete = field.getAttribute("autocomplete")
    if (autocomplete !== null && autocomplete !== "off") {
        console.log("Determining from autocomplete")
        const val = autocomplete_bindings[autocomplete]
        if (val === undefined) {
            console.warn("No autocomplete binding for", autocomplete)
        } else {
            // Override for email type usernames
            if (autocomplete == "username" && field.type === "email") {
                return Generators.EMAIL
            }
            return val
        }
    }

    // Explicitly ignore some fields
    for (const detector of ignoredDetectors) {
        if (detector(field)) {
            return
        }
    }

    // Try to determine field data using heuristics
    for (const detector of heuristicDetectors) {
        const result = detector(field)
        if (result !== undefined) {
            return result
        }
    }

    console.warn("Could not determine field data for", field)
}

/**
 * Detects fields that can be filled in the current frame automatically.
 * @returns {Field[]} A list of fields that can be filled.
 */
function detectAutomatically() {
    /** @type {NodeListOf<ParseableElement>} */
    const inputs = document.querySelectorAll('input, select')
    let fields = []
    for (const field of inputs) {

        // Skip hidden fields
        // https://stackoverflow.com/a/21696585
        if (field.type === "hidden" || field.offsetParent === null) {
            continue
        }

        const generators = determineFieldData(field)
        if (generators !== undefined) {
            if (!Array.isArray(generators)) {
                fields.push(registerField(field, [generators]))
            } else {
                fields.push(registerField(field, generators))
            }
        }
    }
    return fields;
}

/**
 * Detects fields that can be filled in the current frame from a list of predetermined fields.
 * @param {*} entry 
 * @returns {Field[]} A list of fields that can be filled.
 */
function detectFromPredefined(entry) {
    console.log("Running on", document, window.location.href)

    let fields = []
    for (const form of entry["forms"]) {
        console.log(form);

        if (!isForm(form, window.location.href)) {
            continue;   
        }
        console.log("Matched via", form["match"])

        for (const field of form["fields"]) {
            const element = document.querySelector(field["selector"])
            console.log("Query", field["selector"], element)
            if (element !== null) {
                fields.push(registerField(element, field["generator"]))
            }
        }
    }
    return fields;
}


/**
 * Detects fields that can be filled in the current frame.
 * @param {*} data 
 * @returns {Field[]} A list of fields that can be filled.
 */
function detectFields(data) {
    // TODO: replace with overrides
    const entry = data[window.location.hostname]
    if (entry === undefined) return detectAutomatically()
    return detectFromPredefined(entry)
}
