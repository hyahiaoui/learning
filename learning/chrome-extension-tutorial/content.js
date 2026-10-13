// This will run in the real visited page, NOT in the extension page.

const banner = document.createElement("div");
banner.textContent = "This page was touched by my extension";

banner.style.position = "fixed";
banner.style.top = "0";
banner.style.left = "0";
banner.style.right = "0";
banner.style.zIndex = "99999"; // Ridiculously high value
banner.style.background = "#ffd43b";
banner.style.padding = "10px";
banner.style.textAlign = "center";
banner.style.fontFamily = "system-ui, sans-serif";

document.body.prepend(banner);
