browser.contextMenus.create({
    id: "download-with-motrix",
    title: "使用 Motrix 下载",
    contexts: ["link"]
});

browser.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId === "download-with-motrix") {
        const url = info.linkUrl;
        if (url) {
            browser.tabs.update(tab.id, { url: "applesword://" + url });
        }
    }
});
