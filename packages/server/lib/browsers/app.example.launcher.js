const { app, BrowserWindow } = require('electron')

const urlToLoad = process.argv[2]

app.whenReady()
.then(() => {
  for (const arg of process.argv) {
    if (arg.startsWith('--load-extension=')) {
      const exts = arg.replace('--load-extension=', '').split(',')

      for (const ext of exts) {
        BrowserWindow.addExtension(ext)
      }
    }
  }

  const w = new BrowserWindow({
    webPreferences: {
      nodeIntegration: false,
      nativeWindowOpen: true,
      webSecurity: false,
    },
  })

  // dialog.showMessageBox({
  //   title: 'woo',
  //   message: JSON.stringify(process.argv.slice(0, 10))
  // })

  w.loadURL(urlToLoad)
})
