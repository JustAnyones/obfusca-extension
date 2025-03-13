let ref_keeper = {}
let cnt = 0;

function initRefKeeper() {
    ref_keeper = {}
    cnt = 0
}

/**
 * 
 * @param {number} field 
 * @param {string} generator 
 * @returns 
 */
function wrapGen(field, generator) {
    cnt++
    ref_keeper[cnt] = field
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




/*
chrome.runtime.onConnect.addListener(function(port) {
    console.assert(port.name === "knockknock");
    port.onMessage.addListener(function(msg) {
      if (msg.joke === "Knock knock")
        port.postMessage({question: "Who's there?"});
      else if (msg.answer === "Madame")
        port.postMessage({question: "Madame who?"});
      else if (msg.answer === "Madame... Bovary")
        port.postMessage({question: "I don't get it."});
    });
  });
  */

window.addEventListener("message", (event) => {
    if (event.source !== window) return; // Avoid messages from other sources
    if (event.data.type === "FROM_A") {
        console.log("Message received in B:", event.data.data);
    }
});

function locateAutomatically() {

    const fields = ["input", "select", "textarea"]

    console.log(document.getElementsByTagName("input"))
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
                fields.push(wrapGen(eleme, field["generator"]))
            }
        }
    }
    return fields;
}

function fillFields(fields) {
    for (const field of fields) {
        const element = ref_keeper[field.ref]
        element.value = field.value
        // Notify about fields being changed
        element.dispatchEvent(new Event("change"));
    } 
}



function locateFields(data) {
    const entry = data[window.location.hostname]
    if (entry === undefined) return []

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
    const dataUrl = chrome.runtime.getURL("d.json");
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
