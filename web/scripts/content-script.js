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

function fillFields(fields) {
    for (const field of fields) {

        const elements = reference_store[field.ref]
        let element;
        if (elements.length === 1) {
            element = elements[0]
        } else {
            console.warn("Unsupported: multiple elements found for field", field)
            continue
        }

        if (element.tagName === "SELECT") {
            let selected = false
            for (const option of element.options) {
                if (option.value === field.value) {
                    option.selected = true
                    selected = true
                } else {
                    option.selected = false
                }
            }
            if (!selected) {
                console.warn("Could not find option", field.value, "for", element)
            }
        } else {
            console.log("Setting value", field.value, "for", element)
        
            // https://stackoverflow.com/a/62111884
            // https://stackoverflow.com/a/75880020
            const valueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
            const prototype = Object.getPrototypeOf(element);
            const prototypeValueSetter = Object.getOwnPropertyDescriptor(prototype, 'value').set;
            if (valueSetter && valueSetter !== prototypeValueSetter) {
                prototypeValueSetter.call(element, field.value);
            } else {
                valueSetter.call(element, field.value);
            }

            //element.value = field.value
        
        }

        // Notify about fields being changed
        element.dispatchEvent(new Event("input", { bubbles: true }));
        element.dispatchEvent(new Event("change", { bubbles: true }));
        //element.dispatchEvent(new Event("click", { bubbles: true }));
        element.dispatchEvent(new Event("keyup"));
    } 
}

// Called when site finishes loading, not all iframes
(async () => {
    // Load site specific overrides
    const overrideResponse = await fetch(chrome.runtime.getURL("data/overrides.json"))
    const overrides = await overrideResponse.json()

    chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
        // Called when the popup requests fields
        if (request.action === "requestFields") {
            console.log("Received request for fields from popup");

            resetStore()
            let fieldData = detectFields(overrides)
            // Remove fields with duplicate ref number, leaving only the last one
            fieldData = Object.values(
                fieldData.reduce((acc, obj) => {
                    acc[obj.ref] = obj
                    return acc
                }, {})
            )
            console.log("Detected fields", fieldData)

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
