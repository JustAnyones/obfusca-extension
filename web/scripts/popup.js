/**
 * Queries all active tab frames and returns the entries of the first found.
 * @returns 
 */
async function queryFields() {
	const tabs = await chrome.tabs.query({ active: true, currentWindow: true })
	if (tabs.length === 0) return;
	const frames = await chrome.webNavigation.getAllFrames({tabId : tabs[0].id})

	let foundEntry = {status: "NOT_FOUND"}; // initialize so its not null
	for (let frame of frames) {
		let response;
		try {
			response = await chrome.tabs.sendMessage(tabs[0].id, {action: "requestFields"}, {frameId: frame.frameId});
		} catch (e) {
			console.log(`Could not query frame ${frame.frameId}:`, frame, e)
			continue
		}

		if (chrome.runtime.lastError) {
			console.log(`Could not query frame ${frame.frameId}:`, chrome.runtime.lastError?.message);
			continue
		}

		response["frameId"] = frame.frameId
		foundEntry = response;
		// Break on first found
		if (response.status === "FOUND") {
			break
		}
	}
	return foundEntry
}

/**
 * Requests a content script on a specific frame to fill the specified fields.
 * @param {number} frameId 
 * @param {array[Int16Array]} fields 
 * @returns Whether the operation was successful.
 */
async function fillFields(frameId, fields) {
	const tabs = await chrome.tabs.query({ active: true, currentWindow: true })
	if (tabs.length === 0) return false;
	const frames = await chrome.webNavigation.getAllFrames({tabId : tabs[0].id})

	let success = false;
	for (let frame of frames) {
		// Skip until we match the frame
		if (frame.frameId !== frameId) {
			continue
		}

		let response;
		try {
			response = await chrome.tabs.sendMessage(tabs[0].id, {action: "fillFields", fields: fields}, {frameId: frameId});
		} catch (e) {
			console.log(`Could not fill fields in frame ${frame.frameId}:`, frame, e)
			break
		}

		if (chrome.runtime.lastError) {
			console.log(`Could not fill fields in frame ${frame.frameId}:`, chrome.runtime.lastError.message);
			break
		}

		if (response.status === "OK") {
			success = true;
		}
		break
	}
	return success
}

async function getURL() {
	const tabs = await chrome.tabs.query({ active: true, currentWindow: true});
	if(tabs.length == 0) return;
	var matches = tabs[0].url.match(/^https?\:\/\/([^\/?#]+)(?:[\/?#]|$)/i);
	var domain = matches && matches[1];
	return domain;
}

async function getFavIconUrl() {
	const domain = await getURL();
	return "https://www.google.com/s2/favicons?domain=" + domain;
}

async function createSettingsPage() {
	const tabs = await chrome.tabs.query({ active: true, currentWindow: true});
	const tab = tabs[0];
	chrome.tabs.create({
		index: tab.index + 1,
		url: '/settings.html#/settings',
	});
}

// Function to create a new tab with the specified page.
// Page must be exactly as a route that is defined in extension state.
async function navigateToPageRoute(route) {
	const tabs = await chrome.tabs.query({ active: true, currentWindow: true});
	const tab = tabs[0];
	chrome.tabs.create({
		index: tab.index + 1,
		url: '/index.html#' + route,
	});
}

async function closeCurrentTab() {
	const tabs = await chrome.tabs.query({ active: true, currentWindow: true});
	const tab = tabs[0];
	chrome.tabs.remove(tab.id);
}

async function closeLastFocusedWindow() {
	chrome.windows.getLastFocused(w => {
  		chrome.extension.getViews({type: 'popup', windowId: w.id}).forEach(v => v.close());
	});
}

async function authorize(){
	const redirectUrl = chrome.identity.getRedirectURL();
	console.log(redirectUrl);
	//console.log(redirectUrl);
	//console.log(encodeURIComponent(redirectUrl));
	const clientId = "344005524114-elaat47rrc75hh1h1tt5qmn22i4e661u.apps.googleusercontent.com";
	const scopes = ["https://www.googleapis.com/auth/drive.file"];
	let authURL = "https://accounts.google.com/o/oauth2/auth";
	authURL += `?client_id=${clientId}`;
	authURL += `&response_type=token`;
	authURL += `&redirect_uri=${encodeURIComponent(redirectUrl)}`;
	authURL += `&scope=${encodeURIComponent(scopes.join(" "))}`;
	//console.log(authURL);
	return chrome.identity.launchWebAuthFlow({interactive: true, url: authURL});
}

async function validate(redirectURL){
	console.log(redirectURL);
	var access_token = redirectURL.match(/\#(?:access_token)\=([\S\s]*?)\&/)[1];
	return access_token;
}

async function getToken() {
	const url = await authorize();
	const access = await validate(url);
	console.log(access);
	chrome.storage.session.set({'access_token': access});
	return access;
}
