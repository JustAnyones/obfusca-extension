browser.action.onClicked.addListener(async (tab) => {
  try {
    await browser.scripting.executeScript({
      target: {
        tabId: tab.id,
      },
      func: () => {
        document.body.style.border = "5px solid green";
        console.log("Hello");
        alert("good");
      },
    });
  } catch (err) {
    console.error(`failed to execute script: ${err}`);
    alert("error 2");
  }
});
