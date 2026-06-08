function cleanImage(url) {
    if (!url) return null;
    const match = url.match(/https:\/\/.*?\.png/);
    return match ? match[0] : url;
}

module.exports = cleanImage;