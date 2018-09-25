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
winSearch = null

# when app logo is ready we can use it
# icon = nativeImage.createFromPath path.join __dirname, './img/air-e.png'

createWindow = () ->
  win = new BrowserWindow
            width: 1000, height: 600
            minWidth: 600, minHeight: 200 
            title: 'MSE'
            background: '#fdf6e3'
            icon: './img/mse-e-logo.png'

  win.loadFile './views/last.html'
  
  # win.maximize()
  win.webContents.openDevTools()

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
        {
          label: 'Monthly'
          click: () -> win.loadFile './views/monthly.html'
          accelerator: 'Ctrl+M'
        }
      ]
    },
    { label: 'Find', accelerator: 'Ctrl+F', click: () -> winSearch.show() },
    {
      label: 'Debug', accelerator: 'Ctrl+Shift+I', click: () ->win.webContents.toggleDevTools()
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
    winSearch.close() if winSearch?

  setSearchWinPos= () ->
    [x, y] = win.getPosition()
    [w, h] = win.getSize()
    [ww, wh] = win.getContentSize()
  
    winSearch.setPosition x + ww - 500 - 10, y + (h - wh) + 10

  win.on 'move', () -> setSearchWinPos()
  win.on 'resize', () -> setSearchWinPos()

  win.once 'did-finish-load', () ->setSearchWinPos()

  # return val from createWindow()
  null


# This method will be called when Electron has finished
# initialization and is ready to create browser windows.
# Some APIs can only be used after this event occurs.
app.on 'ready', () ->
  createWindow()

  [x, y] = win.getPosition()
  [w, h] = win.getSize()
  [ww, wh] = win.getContentSize()
  
  winSearch = new BrowserWindow
                width: 500, height: 80
                x: x + ww - 500 - 10, y: y + (h - wh) + 10
                show: false
                frame: no
                resizable: no
                closable: no

  winSearch.loadFile './views/search.html'

  ipc = electron.ipcMain
  # console.log ipc

  ipc.on 'perform-search', (event, arg) ->
    console.log "Perform search #{ arg }"
    win.webContents.findInPage arg
    event.sender.send 'get-focus'
    return

  ipc.on 'clear-search', (event, arg) ->
    console.log "Clear search"
    win.webContents.stopFindInPage 'clearSelection'
    return

  ipc.on 'stop-search', (event, arg) ->
    winSearch.hide()
    console.log "Stop! search #{ arg }"
    win.webContents.stopFindInPage 'clearSelection'
    return

  ipc.on 'search-next', (event, arg) ->
    console.log "Search NEXT"
    win.webContents.findInPage arg, findNext: yes
    return

  ipc.on 'search-prev', (event, arg) ->
    console.log "Search PREV"
    win.webContents.findInPage arg, forward: no, findNext: yes
    return

  win.webContents.on 'found-in-page', (event, result) ->
    console.log "found in page #{ result.activeMatchOrdinal }/#{ result.matches }"
    winSearch.webContents.send 'search-results',
        current: result.activeMatchOrdinal
        matches: result.matches
    return

  null

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
