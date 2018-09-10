# last.coffe
#
# last sales info
#

https = require 'https'
http  = require 'http'
xlsx  = require 'xlsx'
fs    = require 'fs'
path  = require 'path'

D_NEW_FMT = new Date(Date.parse '2018-08-03')

notifyOnlineStatus = (e) ->
  new Notification 'Online status', 
        body: if navigator.onLine then 'You are online!' else 'You are offline now!'
        icon: if navigator.onLine then '../img/net-on.png' else '../img/net-off.png'


addEventListener 'load', notifyOnlineStatus, false
addEventListener 'offline', notifyOnlineStatus, false
addEventListener 'online', notifyOnlineStatus, false

vue = new Vue
  el: '#app'

  data:
    date:   null
    buf:    null
    wb:     null
    trns:   []
    bonds:  []
    totals: {}
    change: {}

  methods:
    toYMD: (d) ->
      d = new Date(Date.parse d) unless d instanceof Date
      sep = if arguments.length > 1 then arguments[1] else ''
      (new Date(d - d.getTimezoneOffset()*1000*60))
        .toISOString()[0..9]
        .split('-')
        .join(sep)

    toDMY: (d) ->
      d = new Date(Date.parse d) unless d instanceof Date
      sep = if arguments.length > 1 then arguments[1] else ''
      (new Date(d - d.getTimezoneOffset()*1000*60))
        .toISOString()[0..9]
        .split('-')
        .reverse()
        .join(sep)

    daysBefore: (d, n) -> # returns n days before
      new Date(d.getTime() - n * 24 * 60 * 60 * 1000)

    daysAfter: (d, n) -> # returns n days after
      new Date(d.getTime() + n * 24 * 60 * 60 * 1000)

    startEndOfMonth: (d) -> # returns array [start, end]
      start = new Date(d.getFullYear(), d.getMonth(), 1)
      end   = new Date(d.getFullYear(), d.getMonth() + 1, 0)
      [start, end]

    startEndOfWeek: (d) -> # returns array [monday, sunday]
      if d.getDay() is 0 # sunday
        [@daysBefore(d, 6), d]
      else
        [ @daysBefore(d, d.getDay() - 1), @daysAfter d, 7 - d.getDay() ]

    weekDays: () ->
      if arguments.length > 0 and arguments[0] is 'en'
        [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
          "Friday", "Saturday" ]
      else if arguments.length > 0 and arguments[0] is 'mk'
        [ "недела", "понеделник", "вторник", "среда", "четврток",
          "петок", "сабота" ]
      else
        [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
          "Friday", "Saturday" ]

    mseUrl: (d) -> # add second arg line 1, true, yes for old format
      if arguments.length > 1 # old URL
        "https://www.mse.mk/Repository/Reports/MK/ReportMK_1_" +
        "#{ @toYMD d }_#{ @toYMD d }.xls"
      else
        "https://www.mse.mk/Repository/Reports/MK_New/" +
        "#{ @toDMY d, '.' }mk.xls"

    prevValidDate:  (d) ->
      switch d.getDay()
        when 0 then @daysBefore d, 2
        when 1 then @daysBefore d, 3
        else @daysBefore d, 1
    
    loadLast: () ->
      @date = if arguments.length > 0 # then date is provided
                arguments[0]
              else if (new Date(Date.now())).getHours() < 14
                @prevValidDate new Date()
              else
                new Date()

      url = if @date < D_NEW_FMT
              @mseUrl @date, yes
            else
              @mseUrl @date

      console.log "Trying to load: #{ @toYMD @date, '-' }"
      https.get url, (res) =>
        if res.statusCode is 404          # file not found
          @loadLast @prevValidDate @date  # go back and return
          return null
    
        body = ''
        res.setEncoding 'binary'
        res.on 'data', (d) -> body += d
        res.on 'end', () =>
          @buf  = body
          @wb   = xlsx.read @buf, type: 'binary'
          console.log "successfully loaded report for #{ @toYMD @date, '-' }"
          @processReport()

    processReport: () ->
      @trns = []

      ws      = @wb.Sheets.Sheet1
      rcount  = ws['!rows'].length
      inbonds = no
      trns    = []
      bonds   = []
      change  = { win: 0, loss: 0, even: 0 }
      totals  = { trns: 0, bonds: 0 }
      for r in [4 .. rcount]
        Ar = "A#{ r }"  # company name
        Br = "B#{ r }"  # average price per share (non-block)
        Cr = "C#{ r }"  # raise percent
        Hr = "H#{ r }"  # price per share for block trns
        Ir = "I#{ r }"  # number of shares
        Jr = "J#{ r }"  # turnover (expressed in x1000)
        
        if ws[Ar].v.includes "обврзници"
          inbonds = yes
          continue

        inbonds = no  if inbonds and !ws[Jr]?
        continue if !ws[Ir]? or !ws[Jr]?
        continue if  ws[Ir].v <= 0
        unless inbonds
          trns.push
            company:  ws[Ar].v
            raise:    if ws[Cr]? then ws[Cr].v else null
            turnover: ws[Jr].v * 1000
            shares:   ws[Ir].v
            price:    if !ws[Br]? then ws[Hr].v else ws[Br].v

          switch
            when !ws[Cr]?      then
            when ws[Cr].v  < 0 then change.loss++
            when ws[Cr].v is 0 then change.even++
            when ws[Cr].v  > 0 then change.win++
          totals.trns += ws[Jr].v * 1000
        else
          bonds.push
            title:    ws[Ar].v
            qty:      ws[Ir].v
            turnover: ws[Jr].v * 1000
            price:    ws[Br].v
          totals.bonds += ws[Jr].v * 1000
      
      console.log trns
      @trns   = trns
      @bonds  = bonds
      @totals = totals
      @change = change

  created: () ->
    @loadLast()

  filters:
    number: (v) ->
      return v if typeof v is 'undefined'
      if v isnt null and typeof v.toLocaleString is 'function'
        v.toLocaleString()
      else
        v

    toDMY: (d, s) ->
      d = new Date(Date.parse d) unless d instanceof Date
      s = '' unless s
      (new Date(d - d.getTimezoneOffset()*1000*60))
        .toISOString()[0..9]
        .split('-')
        .reverse()
        .join(s)


# TODO:
#  - home view should become last and add report in menu
#  - create views for last day, specific date, weekly, mounthly
#  - find simple bootstrap datepicker
