# main.coffee:
# electron's main process
#

electron  = require 'electron'
path      = require 'path'
url       = require 'url'

{ app, BrowserWindow, Menu } = electron

# main window
# Keep a global reference of the window object, if you don't, the window will
# be closed automatically when the JavaScript object is garbage collected.
win = null

# when app logo is ready we can use it
# icon = nativeImage.createFromPath path.join __dirname, './img/air-e.png'

createWindow = () ->
  win = new BrowserWindow
            width: 1000, height: 600
            title: 'MSE'
            background: '#fdf6e3'
            # icon: './img/air-e.png'

  win.loadFile './views/last.html'
  
  # win.maximize()
  win.webContents.openDevTools()
  console.log process.argv

  # build menu
  mnutmpl = [
    {
      label: 'Reports'
      submenu: [
        {
          label: 'Last report'
          click: () -> win.loadFile './views/last.html'
          accelerator: 'Ctrl+L'
        },
        { type: 'separator' },
        { 
          label: 'Daily'
          click: () -> win.loadFile './views/daily.html'
          accelerator: 'Ctrl+D'
        },
        {
          label: 'Weekly'
          click: () -> win.loadFile './views/weekly.html'
          accelerator: 'Ctrl+W'
        },
        { label: 'Monthly' }
      ]
    },
    { label: 'Quit', accelerator: 'Ctrl+Q', click: () -> app.quit() }
  ]
  menu = Menu.buildFromTemplate mnutmpl
  Menu.setApplicationMenu menu

  # emitted when the window is closed
  # Dereference the window object, usually you would store windows
  # in an array if your app supports multi windows, this is the time
  # when you should delete the corresponding element.
  win.on 'closed', () ->
    # close any other windows here
    win = null  

  # return val from createWindow()
  null

# This method will be called when Electron has finished
# initialization and is ready to create browser windows.
# Some APIs can only be used after this event occurs.
app.on 'ready', () ->
  createWindow()

  # process command arguments via process.argv

  # create other windows here

# On macOS it's common to re-create a window in the app when the
# dock icon is clicked and there are no other windows open.
app.on 'activate', () ->
  createWindow() if win is null

# Quit when all windows are closed.
# On macOS it is common for applications and their menu bar
# to stay active until the user quits explicitly with Cmd + Q
app.on 'window-all-closed', () ->
  app.quit() unless process.platform is 'darwin'

# TODO:
#
