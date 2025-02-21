function print(){
	var item = document.getElementsByTagName("html")[0];
	console.log(item);
	item.setAttribute("labas","Pasauli");
	console.log("hello");
}
function good(tab){
	chrome.scripting.executeScript({
		target: {
			tabId: tab[0].id
		},
		func: print,
	});
}
function onError(error){
	alert("error");
}

function hello(){
	chrome.tabs.query({ currentWindow: true, active: true }).then(good, onError);
}

document.getElementById("clickMe").addEventListener('click', hello);
