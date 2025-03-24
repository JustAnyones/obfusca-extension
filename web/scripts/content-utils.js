/**
 * Recursive depth-first search to find elements matching the selector within all shadow roots.
 * @param {Node} root 
 * @param {string} selector 
 * @returns 
 */
function deepQuerySelectorAll(root, selector) {
    const elements = [];

    function search(node) {
        if (!node) return;

        //console.log("Searching", node);

        // Try to find elements at the current level
        const found = node.querySelectorAll(selector);
        if (found.length) elements.push(...found);

        // Recursively search in shadow roots
        for (const element of node.querySelectorAll('*')) {
            if (element.shadowRoot) {
                //console.log("Searching shadow root", element.shadowRoot);
                search(element.shadowRoot);
            }
        }

    }

    search(root);
    return elements;
}
