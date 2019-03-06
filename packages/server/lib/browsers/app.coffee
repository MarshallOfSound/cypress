chromiumStyle = require("./chromium_style")

module.exports = chromiumStyle.createChromiumLauncher([
  "--remote-debugging-port=9222"
].concat(chromiumStyle.commonDefaultArgs), "--cypress-runner")
