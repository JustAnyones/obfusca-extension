//@ts-check
"use strict";

// TODO: research https://gist.github.com/ErosLever/51c794dc1f2bab888f571e47275c85cd

/**
 * Represents a type of detector that can be used to find a field.
 * @typedef {string} DetectorType
 **/

/**
 * Represents supported detector types.
 * @enum {DetectorType}
 */
const DETECTOR_TYPE = {
    QUERY_SELECTOR: "querySelector",
    URL_SELECTOR: "urlSelector",
}

/**
 * Represents a generator that can be used to fill a field.
 */
class Generator {
    /**
     * @param {string} name 
     */
    constructor(name) {
        this.name = name;
    }
}

/**
 * Stores additional information about the field.
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
 * @property {string} url
 */

/**
 * @typedef {Object} Option
 * @property {string} value
 * @property {string} text
 * @property {boolean} selected
 */

/**
 * Represents a field that can be filled in a form for Flutter backend.
 * @typedef {Object} Field
 * @property {number} ref The reference number to the field.
 * @property {Generator[]} generators A list of generators that can be used to fill the field.
 * @property {string} generator Backwards compatibility with the old format.
 * @property {Option[]} options A list of possible options for the field.
 * @property {FieldContext[]} context A list of context data for each HTML field of this field.
 */

/**
 * This represents a detector that can be used to find a field.
 * @typedef {Object} Detector
 * @property {DetectorType} type The type of the detector.
 * @property {string} value The value of the detector.
 */

/**
 * Represents a specific field that can be overridden.
 * This is used to override the default field detection.
 * @typedef {Object} OverrideField
 * @property {Detector[]} detectors The detectors to use to find the field.
 * @property {Generator[]} generators The generators to use to fill the field.
 */

/**
 * Represents a domain-based entry in the override list.
 * @typedef {Object} OverrideEntry
 * @property {OverrideField[]} fields Fields to override.
 */

/**
 * @typedef {Object.<string, OverrideEntry>} OverrideMapping
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
    if (field.tagName === "SELECT" && field instanceof HTMLSelectElement) {
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
            url: window.location.href,
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
    FULLNAME: new Generator("namespace::fullname_generator"),
    EMAIL: new Generator("namespace::email_generator"),
    PASSWORD: new Generator("namespace::password_generator"),

    BIRTH_DAY: new Generator("namespace::birth_day_generator"),
    BIRTH_MONTH: new Generator("namespace::birth_month_generator"),
    BIRTH_YEAR: new Generator("namespace::birth_year_generator"),
    BIRTH_DATE: new Generator("namespace::birth_date_generator"),

    SEX: new Generator("namespace::sex_generator"),

    TEL: new Generator("namespace::tel_generator"),

    COUNTRY: new Generator("namespace::country_generator"),
    POSTAL_CODE: new Generator("namespace::postal_code_generator"),

    UNKNOWN: new Generator("namespace::unknown_generator"),
}


const autocomplete_bindings = {
    "name": [Generators.FIRSTNAME, Generators.USERNAME, Generators.EMAIL],
    "given-name": Generators.FIRSTNAME,
    "family-name": Generators.LASTNAME,
    "additional-name": Generators.UNKNOWN,

    "honorific-prefix": Generators.UNKNOWN,
    "honorific-suffix": Generators.UNKNOWN,

    "email": Generators.EMAIL,
    "nickname": Generators.USERNAME,
    "organization-title": Generators.UNKNOWN,
    "username": Generators.USERNAME,
    "new-password": Generators.PASSWORD,
    "current-password": Generators.PASSWORD,
    "organization": Generators.UNKNOWN,

    // Address
    "postal-code": Generators.UNKNOWN,
    "street-address": Generators.UNKNOWN,
    "address-line1": Generators.UNKNOWN,
    "address-line2": Generators.UNKNOWN,
    "address-line3": Generators.UNKNOWN,
    "address-level1": Generators.UNKNOWN,
    "address-level2": Generators.UNKNOWN,
    "address-level4": Generators.UNKNOWN,
    "address-level3": Generators.UNKNOWN,
    "country": Generators.UNKNOWN,
    "country-name": Generators.UNKNOWN,

    // Credit card
    "cc-name": Generators.UNKNOWN,
    "cc-given-name": Generators.UNKNOWN,
    "cc-additional-name": Generators.UNKNOWN,
    "cc-family-name": Generators.UNKNOWN,
    "cc-number": Generators.UNKNOWN,
    "cc-exp": Generators.UNKNOWN,
    "cc-exp-month": Generators.UNKNOWN,
    "cc-exp-year": Generators.UNKNOWN,
    "cc-csc": Generators.UNKNOWN,
    "cc-type": Generators.UNKNOWN,

    "transaction-currency": Generators.UNKNOWN,
    "transaction-amount": Generators.UNKNOWN,

    "language": Generators.UNKNOWN,

    // Birth date
    "bday": Generators.UNKNOWN,
    "bday-day": Generators.BIRTH_DAY,
    "bday-month": Generators.BIRTH_MONTH,
    "bday-year": Generators.BIRTH_YEAR,

    "sex": Generators.SEX,
    "url": Generators.UNKNOWN,
    "photo": Generators.UNKNOWN,

    // Phone related
    "tel": Generators.TEL,
    "tel-country-code": Generators.UNKNOWN,
    "tel-national": Generators.UNKNOWN,
    "tel-area-code": Generators.UNKNOWN,
    "tel-local": Generators.UNKNOWN,
    "tel-local-prefix": Generators.UNKNOWN,
    "tel-local-suffix": Generators.UNKNOWN,
    "tel-extension": Generators.UNKNOWN,

    "impp": Generators.UNKNOWN,
}

/**
 * This list is used to define which fields should be ignored for automatic detection.
 * @type {((field: ParseableElement) => boolean)[]}
 */
const ignoredDetectors = [
    (field) => {
        const aria = field.getAttribute("aria-label")
        const type = field.getAttribute("type")
        const id = field.id

        if (id && RegExp(/recaptcha|code/, "i").test(id)) {
            return true
        }

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
 * This list is used to define which fields should be detected using heuristics.
 * The order of the detectors is important, as the first one that matches will be used.
 * That distinction is very important in cases such as name,
 * where the first name and last name are both detected.
 * @type {((field: ParseableElement) => Generator[] | Generator | undefined)[]}
 */
const heuristicDetectors = [

    // Email or phone
    // Specifically found on Instagram
    (field) => {
        if (RegExp(/emailOrPhone/, "i").test(field.name)) {
            return [Generators.EMAIL, Generators.TEL]
        }
    },

    // Phone
    (field) => {
        if (RegExp(/phone/, "i").test(field.name)) {
            return Generators.TEL
        }
    },

    // Post code
    (field) => {
        if (RegExp(/post_code/, "i").test(field.name)) {
            return Generators.POSTAL_CODE
        }
    },

    // Full name
    // Specifically found on Instagram
    (field) => {
        if (RegExp(/fullName/, "i").test(field.name)) {
            return [Generators.FULLNAME]
        }
    },

    // Last name
    (field) => {
        if (RegExp(/lastname|surname/, "i").test(field.name)) {
            return Generators.LASTNAME
        }
    },
    // Username
    (field) => {
        // Specific to Google
        if (field.id == "identifierId") {
            return [Generators.USERNAME, Generators.EMAIL, Generators.TEL]
        }

        if (field.name === "username" || RegExp(/username|user_name/, "i").test(field.name)) {
            return Generators.USERNAME
        }
    },

    // First name
    (field) => {
        if (RegExp(/firstname|name/, "i").test(field.name)) {
            return Generators.FIRSTNAME
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
        if (RegExp(/birthday_month|birthmonth|month/, "i").test(field.id) || RegExp(/birthday_month|birthmonth|month/, "i").test(field.name)) {
            return Generators.BIRTH_MONTH
        }
    },
    // Birth year
    (field) => {
        if (RegExp(/birthday_year|birthyear|year/, "i").test(field.name)) {
            return Generators.BIRTH_YEAR
        }
    },
    // Birth day
    (field) => {
        if (RegExp(/birthday_day|birthday|day/, "i").test(field.name)) {
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
        if (RegExp(/sex|gender/, "i").test(field.id) || RegExp(/sex|gender/, "i").test(field.name)) {
            return Generators.SEX
        }
    },
]

/**
 * Returns the overridden field generators for a given field.
 * It will check if the specified field matches any of the fields in the override entry.
 * It will match the first field whose all detectors match the field.
 * @param {ParseableElement} field A HTML element.
 * @param {OverrideEntry} overrideEntry The override entry for the current domain.
 * @returns {Generator[] | undefined} A list of generators that can be used to fill the field.
 */
function getOverriddenFieldGenerators(field, overrideEntry) {
    for (const overrideField of overrideEntry.fields) {
        let match = true
        for (const detector of overrideField.detectors) {
            if (detector.type === DETECTOR_TYPE.QUERY_SELECTOR) {
                const element = document.querySelector(detector.value)
                if (element !== field) {
                    match = false
                    break
                }
            } else if (detector.type === DETECTOR_TYPE.URL_SELECTOR) {
                const urlMatch = window.location.href.match(new RegExp(detector.value, "g"))
                if (urlMatch === null) {
                    match = false
                    break
                }
            } else {
                console.error("Unknown detector type " + detector.type.toString())
            }
        }
        if (match) {
            return overrideField.generators
        }
    }
    return undefined
}

/**
 * Detects fields that can be filled in the current frame automatically.
 * @param {ParseableElement} field A HTML element.
 * @param {OverrideEntry?} overrideEntry The override entry for the current domain.
 * @returns {Generator[] | Generator | undefined} A list of generators that can be used to fill the field.
 */
function determineFieldData(field, overrideEntry) {
    if (overrideEntry !== null) {
        console.log("Checking for overridden field generators")
        const generators = getOverriddenFieldGenerators(field, overrideEntry)
        if (generators !== undefined) {
            return generators
        }
    }

    const autocomplete = field.getAttribute("autocomplete")

    let foundGenerators = [];
    if (autocomplete !== null && autocomplete !== "off") {
        console.log("Determining from autocomplete")
        const val = autocomplete_bindings[autocomplete]
        if (val === undefined) {
            console.warn("No autocomplete binding for", autocomplete)
        } else if (Array.isArray(val)) {
            foundGenerators.push(...val)
        } else {
            foundGenerators.push(val)
        }
    }

    // Explicitly ignore some fields
    for (const detector of ignoredDetectors) {
        if (detector(field)) {
            return undefined
        }
    }

    // Try to determine field data using heuristics
    for (const detector of heuristicDetectors) {
        const result = detector(field)
        if (result !== undefined) {
            if (Array.isArray(result)) {
                // put all the values in front of the array
                foundGenerators.unshift(...result)
            } else {
                // put it in front of the array
                foundGenerators.unshift(result)
            }
            return foundGenerators
        }
    }

    if (foundGenerators.length > 0) {
        return foundGenerators
    }

    console.warn("Could not determine field data for", field)
}

/**
 * Detects fields that can be filled in the current frame automatically.
 * @param {OverrideEntry?} overrideEntry The override entry for the current domain.
 * @returns {Field[]} A list of fields that can be filled.
 */
function detectAutomatically(overrideEntry) {
    /** @type {Array<ParseableElement>} */
    //const inputs = document.querySelectorAll('input, select')
    const inputs = deepQuerySelectorAll(document, 'input, select')

    let fields = []
    for (const field of inputs) {

        // Skip hidden fields
        // https://stackoverflow.com/a/21696585
        if (field.type === "hidden" || field.offsetParent === null) {
            console.log("Skipping hidden field", field)
            continue
        }

        const generators = determineFieldData(field, overrideEntry)
        if (generators !== undefined) {
            if (!Array.isArray(generators)) {
                fields.push(registerField(field, [generators]))
            } else {
                // Deduplicate the generators
                const uniqueByName = [
                    ...new Map(
                        generators.map(item => [item.name, item])
                    ).values()
                ];
                fields.push(registerField(field, uniqueByName))
            }
        }
    }
    return fields;
}

/**
 * Detects fields that can be filled in the current frame.
 * @param {OverrideMapping} data 
 * @returns {Field[]} A list of fields that can be filled.
 */
function detectFields(data) {
    // TODO: replace with overrides

    // The plan would be such:
    // First, check if there is an override for the current domain
    // If there is, check if it's a system override or a user override, prioritize user overrides
    // If there's a user override and a system override for different fields, merge them
    // Otherwise, if there is no override, detect automatically

    const entry = data[window.location.hostname]
    if (entry !== undefined) {
        console.log("Found override entry for", window.location.hostname, entry, "that will be ignored")
        return detectAutomatically(entry)
    }
    return detectAutomatically(null)
}
