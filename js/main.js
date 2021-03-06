// Generated by CoffeeScript 1.10.0
var BrowserWindow, Menu, app, createWindow, electron, path, url, win, winSearch;

electron = require('electron');

path = require('path');

url = require('url');

app = electron.app, BrowserWindow = electron.BrowserWindow, Menu = electron.Menu;

win = null;

winSearch = null;

createWindow = function() {
  var menu, mnutmpl, setSearchWinPos;
  win = new BrowserWindow({
    width: 1000,
    height: 600,
    minWidth: 600,
    minHeight: 200,
    title: 'MSE',
    background: '#fdf6e3',
    icon: './img/mse-e-logo.png',
    maximizable: true
  });
  win.loadFile('./views/last.html');
  win.webContents.openDevTools();
  mnutmpl = [
    {
      label: 'Reports',
      submenu: [
        {
          label: 'Last report',
          click: function() {
            return win.loadFile('./views/last.html');
          },
          accelerator: 'Ctrl+L'
        }, {
          type: 'separator'
        }, {
          label: 'Daily',
          click: function() {
            return win.loadFile('./views/daily.html');
          },
          accelerator: 'Ctrl+D'
        }, {
          label: 'Weekly',
          click: function() {
            return win.loadFile('./views/weekly.html');
          },
          accelerator: 'Ctrl+W'
        }, {
          label: 'Monthly',
          click: function() {
            return win.loadFile('./views/monthly.html');
          },
          accelerator: 'Ctrl+M'
        }
      ]
    }, {
      label: 'Find',
      accelerator: 'Ctrl+F',
      click: function() {
        return winSearch.show();
      }
    }, {
      label: 'Debug',
      accelerator: 'Ctrl+Shift+I',
      click: function() {
        return win.webContents.toggleDevTools();
      }
    }, {
      label: 'Quit',
      accelerator: 'Ctrl+Q',
      click: function() {
        return app.quit();
      }
    }
  ];
  menu = Menu.buildFromTemplate(mnutmpl);
  Menu.setApplicationMenu(menu);
  win.on('closed', function() {
    win = null;
    if (winSearch != null) {
      return winSearch.close();
    }
  });
  setSearchWinPos = function() {
    var h, ref, ref1, ref2, w, wh, ww, x, y;
    ref = win.getPosition(), x = ref[0], y = ref[1];
    ref1 = win.getSize(), w = ref1[0], h = ref1[1];
    ref2 = win.getContentSize(), ww = ref2[0], wh = ref2[1];
    return winSearch.setPosition(x + ww - 500 - 10, y + (h - wh) + 10);
  };
  win.on('move', function() {
    return setSearchWinPos();
  });
  win.on('resize', function() {
    return setSearchWinPos();
  });
  win.on('maximize', function() {
    return setSearchWinPos();
  });
  win.once('did-finish-load', function() {
    return setSearchWinPos();
  });
  return null;
};

app.on('ready', function() {
  var h, ipc, ref, ref1, ref2, w, wh, ww, x, y;
  createWindow();
  ref = win.getPosition(), x = ref[0], y = ref[1];
  ref1 = win.getSize(), w = ref1[0], h = ref1[1];
  ref2 = win.getContentSize(), ww = ref2[0], wh = ref2[1];
  winSearch = new BrowserWindow({
    width: 500,
    height: 80,
    x: x + ww - 500 - 10,
    y: y + (h - wh) + 10,
    show: false,
    frame: false,
    resizable: false,
    closable: false
  });
  winSearch.loadFile('./views/search.html');
  ipc = electron.ipcMain;
  ipc.on('perform-search', function(event, arg) {
    console.log("Perform search " + arg);
    win.webContents.findInPage(arg);
    event.sender.send('get-focus');
  });
  ipc.on('clear-search', function(event, arg) {
    console.log("Clear search");
    win.webContents.stopFindInPage('clearSelection');
  });
  ipc.on('stop-search', function(event, arg) {
    winSearch.hide();
    console.log("Stop! search " + arg);
    win.webContents.stopFindInPage('clearSelection');
  });
  ipc.on('search-next', function(event, arg) {
    console.log("Search NEXT");
    win.webContents.findInPage(arg, {
      findNext: true
    });
  });
  ipc.on('search-prev', function(event, arg) {
    console.log("Search PREV");
    win.webContents.findInPage(arg, {
      forward: false,
      findNext: true
    });
  });
  win.webContents.on('found-in-page', function(event, result) {
    console.log("found in page " + result.activeMatchOrdinal + "/" + result.matches);
    winSearch.webContents.send('search-results', {
      current: result.activeMatchOrdinal,
      matches: result.matches
    });
  });
  return null;
});

app.on('activate', function() {
  if (win === null) {
    return createWindow();
  }
});

app.on('window-all-closed', function() {
  if (process.platform !== 'darwin') {
    return app.quit();
  }
});
