ipc = require('electron').ipcRenderer

console.log "* enter search.coffee"

inputEl = document.getElementById 'search-input'
prevEl = document.getElementById 'search-prev'
nextEl = document.getElementById 'search-next'
cancelEl = document.getElementById 'search-cancel'
statusEl = document.getElementById 'search-status'


nextEl.addEventListener 'click', () ->
  if not nextEl.disabled and inputEl.value.length > 0
    ipc.send 'search-next', inputEl.value
    inputEl.focus()

prevEl.addEventListener 'click', () ->
  if not prevEl.disabled and inputEl.value.length > 0
    ipc.send 'search-prev', inputEl.value
    inputEl.focus()

cancelEl.addEventListener 'click', () ->
  statusEl.innerHTML = ''
  ipc.send 'stop-search', inputEl.value
  # inputEl.value = ''
  # prevEl.disabled = yes
  # nextEl.disabled = yes
  console.log "stop-search"

  
inputEl.addEventListener 'input', () ->
  if inputEl.value.length is 0
    prevEl.disabled = yes
    nextEl.disabled = yes
    # cancelEl.disabled = yes
    ipc.send 'clear-search'
    inputEl.focus()
    return
 
  prevEl.disabled = no
  nextEl.disabled = no
  # cancelEl.disabled = no
  ipc.send 'perform-search', inputEl.value
  console.log "* PERFORM SEARCH #{ inputEl.value }"
  inputEl.focus()

ipc.on 'get-focus', () ->
  console.log '* got focus'
  inputEl.focus()
  return


ipc.on 'ipc-message', (e, r) ->
  console.log "* received message:", e.channel
  return

window.addEventListener "load", (event) ->
  console.log "Search DOM ready!"
  ipc.on 'search-results', (event, result) ->
    console.log "* Got search results:", result
    statusEl.innerHTML = "#{ result.current }/#{ result.matches }"
    return
