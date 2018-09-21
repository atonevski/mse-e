// Generated by CoffeeScript 1.10.0
var BrowserWindow, Menu, app, createWindow, electron, path, url, win;

electron = require('electron');

path = require('path');

url = require('url');

app = electron.app, BrowserWindow = electron.BrowserWindow, Menu = electron.Menu;

win = null;

createWindow = function() {
  var menu, mnutmpl;
  win = new BrowserWindow({
    width: 1000,
    height: 600,
    title: 'MSE',
    background: '#fdf6e3',
    icon: './img/mse-e-logo.png'
  });
  win.loadFile('./views/last.html');
  win.webContents.openDevTools();
  console.log(process.argv);
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
    return win = null;
  });
  return null;
};

app.on('ready', function() {
  var ipc;
  createWindow();
  ipc = electron.ipcMain;
  ipc.on('perform-search', function(event, arg) {
    console.log("MAIN: perform search " + arg);
    win.webContents.findInPage(arg);
  });
  return ipc.on('found-in-page', function(event, result) {
    return console.log("found in page " + result.activeMatchOrdinal + "/" + result.matches);
  });
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
