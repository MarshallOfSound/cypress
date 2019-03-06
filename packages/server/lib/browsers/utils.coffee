path     = require("path")
Promise  = require("bluebird")
launcher = require("@packages/launcher")
fs       = require("../util/fs")
appData  = require("../util/app_data")
profileCleaner = require("../util/profile_cleaner")

PATH_TO_BROWSERS = appData.path("browsers")

getBrowserPath = (browser) ->
  path.join(
    PATH_TO_BROWSERS,
    "#{browser.name}"
  )

copyExtension = (src, dest) ->
  fs.copyAsync(src, dest)

getPartition = (isTextTerminal) ->
  if isTextTerminal
    return "run-#{process.pid}"

  return "interactive"

getProfileDir = (browser, isTextTerminal) ->
  path.join(
    getBrowserPath(browser)
    getPartition(isTextTerminal),
  )

getExtensionDir = (browser, isTextTerminal) ->
  path.join(
    getProfileDir(browser, isTextTerminal),
    "CypressExtension"
  )

ensureCleanCache = (browser, isTextTerminal) ->
  p = path.join(
    getProfileDir(browser, isTextTerminal),
    "CypressCache"
  )

  fs
  .removeAsync(p)
  .then ->
    fs.ensureDirAsync(p)
  .return(p)

removeOldProfiles = ->
  ## a profile is considered old if it was used
  ## in a previous run for a PID that is either
  ## no longer active, or isnt a cypress related process
  pathToProfiles = path.join(PATH_TO_BROWSERS, "*")
  pathToPartitions = appData.electronPartitionsPath()

  Promise.all([
    ## we now store profiles in either interactive or run-* folders
    ## so we need to remove the old root profiles that existed before
    profileCleaner.removeRootProfile(pathToProfiles, [
      path.join(pathToProfiles, "run-*")
      path.join(pathToProfiles, "interactive")
    ])
    profileCleaner.removeInactiveByPid(pathToProfiles, "run-"),
    profileCleaner.removeInactiveByPid(pathToPartitions, "run-"),
  ])

module.exports = {
  copyExtension

  getProfileDir

  getExtensionDir

  ensureCleanCache

  removeOldProfiles

  getBrowserByPath: launcher.detectByPath

  launch: launcher.launch

  getBrowsers: ->
    ## TODO: accept an options object which
    ## turns off getting electron browser?
    launcher.detect()
    .then (browsers = []) ->
      version = process.versions.chrome or ""

      ## the internal version of Electron, which won't be detected by `launcher`
      browsers.concat({
        name: "electron"
        family: "electron"
        displayName: "Electron"
        version: version
        path: ""
        majorVersion: version.split(".")[0]
        info: "Electron is the default browser that comes with Cypress. This is the browser that runs in headless mode. Selecting this browser is useful when debugging. The version number indicates the underlying Chromium version that Electron uses."
      })

      customApp = process.env.CUSTOM_APP
      if customApp isnt undefined
        if process.platform is 'darwin'
          plist = fs.readFileSync(path.resolve(customApp, '..', '..', 'Info.plist'), 'utf8')
          readPlistKey = (key) ->
            reg = new RegExp(key + '<\/key>(?:.|\n)+?<string>(.+?)</')
            return plist.match(reg)[1]
          version = readPlistKey('CFBundleShortVersionString')
          browsers.concat({
            name: 'custom-app'
            family: "chromium-based"
            displayName: readPlistKey('CFBundleDisplayName')
            version: version
            path: customApp
            majorVersion: version
            info: "Custom chromium based app that supported the Cypress launcher"
          })
        else
          browsers.concat({
            name: 'custom-app'
            family: "chromium-based"
            displayName: "Custom Chromium App"
            version: "0.0.0"
            path: customApp
            majorVersion: "99"
            info: "Custom chromium based app that supported the Cypress launcher"
          })
}
