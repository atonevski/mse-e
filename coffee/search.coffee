ipc = require('electron').ipcRenderer
con = require 'console'
nconsole = new con.Console process.stdout, process.stderr

inputEl = document.getElementById 'search-input'
nconsole.log "IN SEARCH VIEW"
nconsole.log inputEl

inputEl.addEventListener 'input', () ->
  if inputEl.value.length is 0
    nconsole.log "STOP SEARCH #{ inputEl.value }"
    ipc.send 'stop-search'
    inputEl.focus()
    return
 
  ipc.send 'perform-search', inputEl.value
  nconsole.log "PERFORM SEARCH #{ inputEl.value }"
  inputEl.focus()

ipc.on 'found-in-page', (event, result) ->
  nconsole.log "IN SEARCH: found in page #{ result.activeMatchOrdinal }/#{ result.matches }"
  return
