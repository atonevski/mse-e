# note:
# using code from:
# https://www.jqueryscript.net/time-clock/Clean-Data-Timepicker-with-jQuery-Bootstrap-3.html

https = require 'https'
http  = require 'http'
xlsx  = require 'xlsx'
fs    = require 'fs'
path  = require 'path'
q     = require 'q'

D_NEW_FMT = new Date(Date.parse '2018-08-03')

notifyOnlineStatus = (e) ->
  new Notification 'Online status', 
        body: if navigator.onLine then 'You are online!' else 'You are offline now!'
        icon: if navigator.onLine then '../img/net-on.png' else '../img/net-off.png'


addEventListener 'load', notifyOnlineStatus, false
addEventListener 'offline', notifyOnlineStatus, false
addEventListener 'online', notifyOnlineStatus, false

# needed for datetimepicker: set maxDate
maxDateOpt = () -> 
  d = new Date()
  switch d.getDay()
    when 0 then new Date(d.getTime() - 2 * 24 * 60 * 60 * 1000)
    when 6 then new Date(d.getTime() - 1 * 24 * 60 * 60 * 1000)
    else d
    
opts =
  format: 'YYYY-MM-DD'
  minDate: new Date('2003-01-01')
  maxDate: maxDateOpt() # set last date not to be sat or sun
  daysOfWeekDisabled: [0, 6] # Sunday and Saturday
  locale: moment.locale 'en', { week: { dow: 1 } }
#  calendarWeeks: yes


$('#pickdate')
  .datetimepicker(opts)
  .on 'dp.change', () ->
    vue.setDates new Date($('#pickdate').data('date'))
    document.getElementById('select-week-reminder')
            .style.display = 'none'


vue = new Vue
  el: '#app'

  data:
    date:       null
    from:       null
    to:         null
    wbs:        [ ]
    companies:  { }
    bonds:      { }
    change:     { win: 0, loss: 0, even: 0 }
    totals:     { companies: 0, bonds: 0 }

  methods:
    setDates: (d) -> # sets from (monday), to (friday, or today) 
      @date = d
      today = new Date()
      wd    = d.getDay()
      @from = @daysBefore d, wd - 1
      friday = switch wd
                when 0 then @daysBefore d, 2
                when 6 then @daysBefore d, 1
                else @daysAfter d, 5 - wd
      @to = if friday > today then today else friday

      # now we can load weekly reports
      @loadWeekly()

    dmyToDate: (s) -> new Date s.split('.').reverse().join('-')

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

    mseUrl: (d) -> # add second arg line 1, true, yes for old format
      if arguments.length > 1 # old URL
        "https://www.mse.mk/Repository/Reports/MK/ReportMK_1_" +
        "#{ @toYMD d }_#{ @toYMD d }.xls"
      else
        "https://www.mse.mk/Repository/Reports/MK_New/" +
        "#{ @toDMY d, '.' }mk.xls"

    daysBefore: (d, n) -> # returns n days before
      new Date(d.getTime() - n * 24 * 60 * 60 * 1000)

    daysAfter: (d, n) -> # returns n days after
      new Date(d.getTime() + n * 24 * 60 * 60 * 1000)

    
    mseUrl: (d) -> # add second arg line 1, true, yes for old format
      if arguments.length > 1 # old URL
        "https://www.mse.mk/Repository/Reports/MK/ReportMK_1_" +
        "#{ @toYMD d }_#{ @toYMD d }.xls"
      else
        "https://www.mse.mk/Repository/Reports/MK_New/" +
        "#{ @toDMY d, '.' }mk.xls"

    parseXls: (data) -> # returns wb
      xlsx.read data, type: 'binary'

    processWbs: () -> # process all workboos
      companies  = { }
      bonds      = { }
      change     = { win: 0, loss: 0, even: 0 }
      totals     = { companies: 0, bonds: 0 }
      for wb in @wbs
        ws      = wb.Sheets.Sheet1
        rcount  = ws['!rows'].length
        inbonds = no
        # console.log ws
        # console.log rcount
        date = @dmyToDate ws['A2'].v.slice(ws['A2'].v.length - 10)
        console.log date
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
            unless companies[ws[Ar].v]?
              companies[ws[Ar].v] = []
                
            companies[ws[Ar].v].push
              date:     date
              # company:  ws[Ar].v
              raise:    if ws[Cr]? then ws[Cr].v else null
              turnover: ws[Jr].v * 1000
              shares:   ws[Ir].v
              price:    if !ws[Br]? then ws[Hr].v else ws[Br].v

            switch
              when !ws[Cr]?      then
              when ws[Cr].v  < 0 then change.loss++
              when ws[Cr].v is 0 then change.even++
              when ws[Cr].v  > 0 then change.win++
            totals.companies += ws[Jr].v * 1000
          else
            unless bonds[ws[Ar].v]?
              bonds[ws[Ar].v] = []
            bonds[ws[Ar].v].push
              date:     date
              # title:    ws[Ar].v
              qty:      ws[Ir].v
              turnover: ws[Jr].v * 1000
              price:    ws[Br].v

            totals.bonds += ws[Jr].v * 1000
      @companies  = companies
      @bonds      = bonds
      @change     = change
      @totals     = totals
      console.log @companies
      
    
    loadWeekly: () ->
      # reset data
      @companies  = { }
      @bonds      = { }
      @change     = { win: 0, loss: 0, even: 0 }
      @totals     = { companies: 0, bonds: 0 }

      wd = @from
      promises = [ ]
      while wd <= @to
        do (wd) =>
          p = q.Promise (resolve, reject) =>
              url = if wd < D_NEW_FMT
                      @mseUrl wd, yes
                    else
                      @mseUrl wd
              https.get url, (res) =>
                res.setEncoding 'binary'
                if res.statusCode isnt 200
                  reject new Error "Failed for date: #{ wd }"
                  return null
                body = []
                res.on 'data', (d) -> body.push d
                res.on 'end', () => resolve @parseXls body.join ''
                res.on 'error', (e) -> reject e
                null
              null
          p = p.catch (e) -> null # catch 404       
          promises.push p
        # increment week day
        wd = @daysAfter wd, 1

      all = q.all promises
      wbs = []
      all.then (wa) =>
        for wb in wa when wb isnt null # skip 404
          wbs.push wb
        # after filtering process them
        @wbs = wbs
        @processWbs()

  filters:
    number: (v) ->
      return v if typeof v is 'undefined'
      if v isnt null and typeof v.toLocaleString is 'function'
        v.toLocaleString()
      else
        v

    toDMY: (d, s) ->
      return unless d
      d = new Date(Date.parse d) unless d instanceof Date
      s = '' unless s
      (new Date(d - d.getTimezoneOffset()*1000*60))
        .toISOString()[0..9]
        .split('-')
        .reverse()
        .join(s)

# TODO:
# - put collected workbooks in data
# - check computational data
