# note:
# using code from:
# https://www.jqueryscript.net/time-clock/Clean-Data-Timepicker-with-jQuery-Bootstrap-3.html

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

# needed for datetimepicker: set maxDate
maxDateOpt = () -> 
  d = new Date()
  switch d.getDay()
    when 0 then new Date(d.getTime() - 2 * 24 * 60 * 60 * 1000)
    when 6 then new Date(d.getTime() - 1 * 24 * 60 * 60 * 1000)
    else d
    
opts =
  defaultDate: false
  format: 'YYYY-MM-DD'
  minDate: new Date('2003-01-01')
  maxDate: maxDateOpt() # set last date not to be sat or sun
  daysOfWeekDisabled: [0, 6] # Sunday and Saturday
  locale: moment.locale 'en', { week: { dow: 1 } }
#  calendarWeeks: yes


$('#pickdate')
  .datetimepicker(opts)
  .on 'dp.change', () ->
    vue.setDate new Date($('#pickdate').data('date'))
    document.getElementById('select-date-reminder')
            .style.display = 'none'
  .on 'dp.update', () ->
    vue.setDate new Date($('#pickdate').data('date'))

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

    mseUrl: (d) -> # add second arg line 1, true, yes for old format
      if arguments.length > 1 # old URL
        "https://www.mse.mk/Repository/Reports/MK/ReportMK_1_" +
        "#{ @toYMD d }_#{ @toYMD d }.xls"
      else
        "https://www.mse.mk/Repository/Reports/MK_New/" +
        "#{ @toDMY d, '.' }mk.xls"

    setDate: (d) ->
      @date = d
      @loadDaily()

    processReport: () ->
      @trns = []
      console.log @wb

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

    loadDaily: () ->
      # reset data
      @buf    = null
      @wb     = null
      @trns   = []
      @bonds  = []
      @totals = {}
      @change = {}

      url = if @date < D_NEW_FMT
              @mseUrl @date, yes
            else
              @mseUrl @date

      console.log "Trying to load: #{ @toYMD @date, '-' }"
      https.get url, (res) =>
        if res.statusCode is 404          # file not found
          alert "No report available for #{ @toYMD @date, '-' }"
          return null
        else if res.statusCode isnt 200
          alert "Unexpected status: #{ res.statusCode }"
          return null
    
        body = ''
        res.setEncoding 'binary'
        res.on 'data', (d) -> body += d
        res.on 'end', () =>
          @buf  = body
          @wb   = xlsx.read @buf, type: 'binary'
          console.log "successfully loaded report for #{ @toYMD @date, '-' }"
          @processReport()

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

# RETREIVE datetime value
# $("#datetimepicker1").data("datetimepicker").getDate(); 

# EVENTS:$('#example').datetimepicker()
# .on( "dp.hide", function() {
#   // Fired when the widget is hidden.
# })
# .on( "dp.show", function() {
#   // Fired when the widget is shown.
# })
# .on( "dp.change", function() {
#   // Fired when the date is changed.
# })
# .on( "dp.error", function() {
#   // Fired when a selected date fails to pass validation.
# })
# .on( "dp.update", function() {
#   // Fired (in most cases) when the viewDate changes. E.g. Next and Previous buttons, selecting a year.
# })

# OPTIONS:
# // timezone
# timeZone: '',
# 
# // Date format. See moment.js' docs for valid formats.
# format: false,
# 
# // Changes the heading of the datepicker when in "days" view.
# dayViewHeaderFormat: 'MMMM YYYY',
# 
# // Allows for several input formats to be valid. 
# extraFormats: false,
# 
# // Number of minutes the up/down arrow's will move the minutes value in the time picker
# stepping: 1,
# 
# // Prevents date/time selections before this date
# minDate: false,
# 
# // Prevents date/time selections after this date
# maxDate: false,
# 
# // On show, will set the picker to the current date/time
# useCurrent: true,
# 
# // Using a Bootstraps collapse to switch between date/time pickers.
# collapse: true,
# 
# // See moment.js for valid locales.
# locale: moment.locale(),
# 
# // Sets the picker default date/time. 
# defaultDate: false,
# 
# // Disables selection of dates in the array, e.g. holidays
# disabledDates: false,
# 
# // Disables selection of dates NOT in the array, e.g. holidays
# enabledDates: false,
# 
# // Change the default icons for the pickers functions.
# icons: {
#   time: 'glyphicon glyphicon-time',
#   date: 'glyphicon glyphicon-calendar',
#   up: 'glyphicon glyphicon-chevron-up',
#   down: 'glyphicon glyphicon-chevron-down',
#   previous: 'glyphicon glyphicon-chevron-left',
#   next: 'glyphicon glyphicon-chevron-right',
#   today: 'glyphicon glyphicon-screenshot',
#   clear: 'glyphicon glyphicon-trash'
# },
# 
# // custom tooltip text
# tooltips: {
#   today: 'Go to today',
#   clear: 'Clear selection',
#   close: 'Close the picker',
#   selectMonth: 'Select Month',
#   prevMonth: 'Previous Month',
#   nextMonth: 'Next Month',
#   selectYear: 'Select Year',
#   prevYear: 'Previous Year',
#   nextYear: 'Next Year',
#   selectDecade: 'Select Decade',
#   prevDecade: 'Previous Decade',
#   nextDecade: 'Next Decade',
#   prevCentury: 'Previous Century',
#   nextCentury: 'Next Century',
#   pickHour: 'Pick Hour',
#   incrementHour: 'Increment Hour',
#   decrementHour: 'Decrement Hour',
#   pickMinute: 'Pick Minute',
#   incrementMinute: 'Increment Minute',
#   decrementMinute: 'Decrement Minute',
#   pickSecond: 'Pick Second',
#   incrementSecond: 'Increment Second',
#   decrementSecond: 'Decrement Second',
#   togglePeriod: 'Toggle Period',
#   selectTime: 'Select Time'
# },
# 
# // Defines if moment should use scrict date parsing when considering a date to be valid
# useStrict: false,
# 
# // Shows the picker side by side when using the time and date together
# sideBySide: false,
# 
# // Disables the section of days of the week, e.g. weekends.
# daysOfWeekDisabled: [],
# 
# // Shows the week of the year to the left of first day of the week
# calendarWeeks: false,
# 
# // The default view to display when the picker is shown
# // Accepts: 'years','months','days'
# viewMode: 'days',
# 
# // Changes the placement of the icon toolbar
# toolbarPlacement: 'default',
# 
# // Show the "Today" button in the icon toolbar
# showTodayButton: false,
# 
# // Show the "Clear" button in the icon toolbar
# showClear: false,
# 
# // Show the "Close" button in the icon toolbar
# showClose: false,
# 
# // On picker show, places the widget at the identifier (string) or jQuery object if the element has css position: 'relative'
# widgetPositioning: {
#   horizontal: 'auto',
#   vertical: 'auto'
# },
# 
# // On picker show, places the widget at the identifier (string) or jQuery object **if** the element has css `position: 'relative'`
# widgetParent: null,
# 
# // Allow date picker show event to fire even when the associated input element has the `readonly="readonly"`property.
# ignoreReadonly: false,
# 
# // Will cause the date picker to stay open after selecting a date if no time components are being used
# keepOpen: false,
# 
# // If `false`, the textbox will not be given focus when the picker is shown.
# focusOnShow: true,
# 
# // Will display the picker inline without the need of a input field. This will also hide borders and shadows.
# inline: false,
# 
# // Will cause the date picker to **not** revert or overwrite invalid dates.
# keepInvalid: false,
# 
# // CSS selector
# datepickerInput: '.datepickerinput',
# 
# // Debug mode
# debug: false,
# 
# // If `true`, the picker will show on textbox focus and icon click when used in a button group.
# allowInputToggle: false,
# 
# // Must be in 24 hour format. Will allow or disallow hour selections (much like `disabledTimeIntervals`) but will affect all days.
# disabledTimeIntervals: false,
# 
# // Disable/enable hours
# disabledHours: false,
# enabledHours: false,
# 
# // This will change the `viewDate` without changing or setting the selected date.
# viewDate: false
