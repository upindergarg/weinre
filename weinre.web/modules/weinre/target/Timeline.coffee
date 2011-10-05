
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Ex = require('../common/Ex')
Weinre = require('../common/Weinre')
IDGenerator = require('../common/IDGenerator')
StackTrace = require('../common/StackTrace')

Native = require('../common/Native')

Running = false

TimerTimeouts  = {}
TimerIntervals = {}

TimelineRecordType =
    EventDispatch:            0
    Layout:                   1
    RecalculateStyles:        2
    Paint:                    3
    ParseHTML:                4
    TimerInstall:             5
    TimerRemove:              6
    TimerFire:                7
    XHRReadyStateChange:      8
    XHRLoad:                  9
    EvaluateScript:          10
    Mark:                    11
    ResourceSendRequest:     12
    ResourceReceiveResponse: 13
    ResourceFinish:          14
    FunctionCall:            15
    ReceiveResourceData:     16
    GCEvent:                 17
    MarkDOMContent:          18
    MarkLoad:                19
    ScheduleResourceRequest: 20


#-------------------------------------------------------------------------------
module.exports = class Timeline

    constructor: ->

    #---------------------------------------------------------------------------
    @start: ->
        Running = true

    #---------------------------------------------------------------------------
    @stop: ->
        Running = false

    #---------------------------------------------------------------------------
    @isRunning: ->
        Running

    #---------------------------------------------------------------------------
    @addRecord_Mark: (message) ->
        return  unless Timeline.isRunning()
        record = {}
        record.type = TimelineRecordType.Mark
        record.category = name: "scripting"
        record.startTime = Date.now()
        record.data = message: message
        addStackTrace record, 3
        Weinre.wi.TimelineNotify.addRecordToTimeline record

    #---------------------------------------------------------------------------
    @addRecord_EventDispatch: (event, name, category) ->
        return  unless Timeline.isRunning()
        category = "scripting"  unless category
        record = {}
        record.type = TimelineRecordType.EventDispatch
        record.category = name: category
        record.startTime = Date.now()
        record.data = type: event.type
        Weinre.wi.TimelineNotify.addRecordToTimeline record

    #---------------------------------------------------------------------------
    @addRecord_TimerInstall: (id, timeout, singleShot) ->
        return  unless Timeline.isRunning()
        record = {}
        record.type = TimelineRecordType.TimerInstall
        record.category = name: "scripting"
        record.startTime = Date.now()
        record.data =
            timerId: id
            timeout: timeout
            singleShot: singleShot

        addStackTrace record, 4
        Weinre.wi.TimelineNotify.addRecordToTimeline record

    #---------------------------------------------------------------------------
    @addRecord_TimerRemove: (id, timeout, singleShot) ->
        return  unless Timeline.isRunning()
        record = {}
        record.type = TimelineRecordType.TimerRemove
        record.category = name: "scripting"
        record.startTime = Date.now()
        record.data =
            timerId: id
            timeout: timeout
            singleShot: singleShot

        addStackTrace record, 4
        Weinre.wi.TimelineNotify.addRecordToTimeline record

    #---------------------------------------------------------------------------
    @addRecord_TimerFire: (id, timeout, singleShot) ->
        return  unless Timeline.isRunning()
        record = {}
        record.type = TimelineRecordType.TimerFire
        record.category = name: "scripting"
        record.startTime = Date.now()
        record.data =
            timerId: id
            timeout: timeout
            singleShot: singleShot

        Weinre.wi.TimelineNotify.addRecordToTimeline record

    #---------------------------------------------------------------------------
    @addRecord_XHRReadyStateChange: (method, url, id, xhr) ->
        return  unless Timeline.isRunning()

        if xhr.readyState == XMLHttpRequest.OPENED
            record =
                type: TimelineRecordType.ResourceSendRequest
                category: name: "loading"
                startTime: Date.now()
                data:
                    identifier: id
                    url: url
                    requestMethod: method
        else if xhr.readyState == XMLHttpRequest.DONE
            record =
                type: TimelineRecordType.ResourceReceiveResponse
                category: name: "loading"
                startTime: Date.now()
                data:
                    identifier: id
                    statusCode: xhr.status
                    mimeType: xhr.getResponseHeader("Content-Type")
                    expectedContentLength: xhr.getResponseHeader("Content-Length")
                    url: url
        else
            return
        Weinre.wi.TimelineNotify.addRecordToTimeline record

    #---------------------------------------------------------------------------
    @installGlobalListeners: ->
        if applicationCache
            applicationCache.addEventListener "checking", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.checking", "loading"
            ), false
            applicationCache.addEventListener "error", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.error", "loading"
            ), false
            applicationCache.addEventListener "noupdate", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.noupdate", "loading"
            ), false
            applicationCache.addEventListener "downloading", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.downloading", "loading"
            ), false
            applicationCache.addEventListener "progress", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.progress", "loading"
            ), false
            applicationCache.addEventListener "updateready", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.updateready", "loading"
            ), false
            applicationCache.addEventListener "cached", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.cached", "loading"
            ), false
            applicationCache.addEventListener "obsolete", ((e) ->
                Timeline.addRecord_EventDispatch e, "applicationCache.obsolete", "loading"
            ), false
        window.addEventListener "error", ((e) ->
            Timeline.addRecord_EventDispatch e, "window.error"
        ), false
        window.addEventListener "hashchange", ((e) ->
            Timeline.addRecord_EventDispatch e, "window.hashchange"
        ), false
        window.addEventListener "message", ((e) ->
            Timeline.addRecord_EventDispatch e, "window.message"
        ), false
        window.addEventListener "offline", ((e) ->
            Timeline.addRecord_EventDispatch e, "window.offline"
        ), false
        window.addEventListener "online", ((e) ->
            Timeline.addRecord_EventDispatch e, "window.online"
        ), false
        window.addEventListener "scroll", ((e) ->
            Timeline.addRecord_EventDispatch e, "window.scroll"
        ), false

    #---------------------------------------------------------------------------
    @installFunctionWrappers: ->
        window.clearInterval = wrapped_clearInterval
        window.clearTimeout = wrapped_clearTimeout
        window.setTimeout = wrapped_setTimeout
        window.setInterval = wrapped_setInterval
        window.XMLHttpRequest::open = wrapped_XMLHttpRequest_open
        window.XMLHttpRequest = wrapped_XMLHttpRequest


#-------------------------------------------------------------------------------
addStackTrace =  (record, skip) ->
      skip = 1  unless skip
      trace = new StackTrace(arguments).trace
      record.stackTrace = []
      i = skip

      while i < trace.length
          record.stackTrace.push
              functionName: trace[i]
              scriptName: ""
              lineNumber: ""
          i++

#-------------------------------------------------------------------------------
wrapped_setInterval =  (code, interval) ->
      code = instrumentedTimerCode(code, interval, false)
      id = Native.setInterval(code, interval)
      code.__timerId = id
      addTimer id, interval, false
      id

#-------------------------------------------------------------------------------
wrapped_setTimeout =  (code, delay) ->
      code = instrumentedTimerCode(code, delay, true)
      id = Native.setTimeout(code, delay)
      code.__timerId = id
      addTimer id, delay, true
      id

#-------------------------------------------------------------------------------
wrapped_clearInterval =  (id) ->
      result = Native.clearInterval(id)
      removeTimer id, false
      result

#-------------------------------------------------------------------------------
wrapped_clearTimeout =  (id) ->
      result = Native.clearTimeout(id)
      removeTimer id, true
      result

#-------------------------------------------------------------------------------
addTimer =  (id, timeout, singleShot) ->
      timerSet = (if singleShot then TimerTimeouts else TimerIntervals)
      timerSet[id] =
          id: id
          timeout: timeout
          singleShot: singleShot

      Timeline.addRecord_TimerInstall id, timeout, singleShot

#-------------------------------------------------------------------------------
removeTimer =  (id, singleShot) ->
      timerSet = (if singleShot then TimerTimeouts else TimerIntervals)
      timer = timerSet[id]
      return  unless timer
      Timeline.addRecord_TimerRemove id, timer.timeout, singleShot
      delete timerSet[id]

#-------------------------------------------------------------------------------
instrumentedTimerCode =  (code, timeout, singleShot) ->
      return code  unless typeof (code) == "function"
      instrumentedCode = ->
          result = code()
          id = arguments.callee.__timerId
          Timeline.addRecord_TimerFire id, timeout, singleShot
          result

      instrumentedCode

#-------------------------------------------------------------------------------
wrapped_XMLHttpRequest =  () ->
      xhr = new Native.XMLHttpRequest()
      IDGenerator.getId xhr
      xhr.addEventListener "readystatechange", getXhrEventHandler(xhr), false
      xhr

wrapped_XMLHttpRequest.UNSENT           = 0
wrapped_XMLHttpRequest.OPENED           = 1
wrapped_XMLHttpRequest.HEADERS_RECEIVED = 2
wrapped_XMLHttpRequest.LOADING          = 3
wrapped_XMLHttpRequest.DONE             = 4

#-------------------------------------------------------------------------------
wrapped_XMLHttpRequest_open =  () ->
      xhr = this
      xhr.__weinre_method = arguments[0]
      xhr.__weinre_url = arguments[1]
      result = Native.XMLHttpRequest_open.apply(xhr, [].slice.call(arguments))
      result

#-------------------------------------------------------------------------------
getXhrEventHandler =  (xhr) ->
      (event) ->
          Timeline.addRecord_XHRReadyStateChange xhr.__weinre_method, xhr.__weinre_url, IDGenerator.getId(xhr), xhr

#-------------------------------------------------------------------------------
Timeline.installGlobalListeners()
Timeline.installFunctionWrappers()

#-------------------------------------------------------------------------------
require("../common/MethodNamer").setNamesForClass(module.exports)
