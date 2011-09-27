
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Native = require('../common/Native')

Ex = require('../common/Ex')
Binding = require('../common/Binding')
Callback = require('../common/Callback')
MessageDispatcher = require('../common/MessageDispatcher')
Weinre = require('../common/Weinre')

CheckForProblems = require('./CheckForProblems')
NodeStore = require('./NodeStore')
CSSStore = require('./CSSStore')
ElementHighlighter = require('./ElementHighlighter')
InjectedScriptHostImpl = require('./InjectedScriptHostImpl')

WeinreTargetEventsImpl = require('./WeinreTargetEventsImpl')
WeinreExtraClientCommandsImpl = require('./WeinreExtraClientCommandsImpl')

WiConsoleImpl = require('./WiConsoleImpl')
WiCSSImpl = require('./WiCSSImpl')
WiDatabaseImpl = require('./WiDatabaseImpl')
WiDOMImpl = require('./WiDOMImpl')
WiDOMStorageImpl = require('./WiDOMStorageImpl')
WiInspectorImpl = require('./WiInspectorImpl')
WiRuntimeImpl = require('./WiRuntimeImpl')

#-------------------------------------------------------------------------------
module.exports = class Target

    constructor: ->
    
    #---------------------------------------------------------------------------
    @main: ->
        CheckForProblems.check()
        Weinre.target = new Target()
        Weinre.target.initialize()
        Weinre.addCSSProperties = addCSSProperties = (properties) ->
            CSSStore.addCSSProperties properties
    
    #----------------------------------------------------------------------------
    setWeinreServerURLFromScriptSrc: (element) ->
        return  if window.WeinreServerURL
        if element
            pattern = /(http:\/\/(.*?)\/)/
            match = pattern.exec(element.src)
            if match
                window.WeinreServerURL = match[1]
                return
        message = "unable to calculate the weinre server url; explicity set the variable window.WeinreServerURL instead"
        alert message
        throw new Ex(arguments, message)
    
    #---------------------------------------------------------------------------
    setWeinreServerIdFromScriptSrc: (element) ->
        return  if window.WeinreServerId
        element = @getTargetScriptElement()
        hash = "anonymous"
        if element
            attempt = element.src.split("#")[1]
            if attempt
                hash = attempt
            else
                attempt = location.hash.split("#")[1]
                hash = attempt  if attempt
        window.WeinreServerId = hash
    
    #---------------------------------------------------------------------------
    getTargetScriptElement: ->
        elements = document.getElementsByTagName("script")
        scripts = [ "Target.", "target-script.", "target-script-min." ]
        i = 0
        
        while i < elements.length
            element = elements[i]
            j = 0
            while j < scripts.length
                return element  unless -1 == element.src.indexOf("/" + scripts[j])
                j++
            i++
    
    #---------------------------------------------------------------------------
    initialize: () ->
        self = this
        element = @getTargetScriptElement()
        @setWeinreServerURLFromScriptSrc element
        @setWeinreServerIdFromScriptSrc element
        window.WeinreServerURL += "/"  unless window.WeinreServerURL[window.WeinreServerURL.length - 1] == "/"
        injectedScriptHost = new InjectedScriptHostImpl()
        Weinre.injectedScript = injectedScriptConstructor(injectedScriptHost, window, 0, "?")
        window.addEventListener "load", Binding(this, "onLoaded"), false
        document.addEventListener "DOMContentLoaded", Binding(this, "onDOMContent"), false
        @_startTime = currentTime()
        if document.readyState == "loaded"
            setTimeout (->
                self.onDOMContent()
            ), 10
        if document.readyState == "complete"
            setTimeout (->
                self.onDOMContent()
            ), 10
            setTimeout (->
                self.onLoaded()
            ), 20
        messageDispatcher = new MessageDispatcher(window.WeinreServerURL + "ws/target", window.WeinreServerId)
        Weinre.messageDispatcher = messageDispatcher
        Weinre.wi = {}
        Weinre.wi.Console = new WiConsoleImpl()
        Weinre.wi.CSS = new WiCSSImpl()
        Weinre.wi.Database = new WiDatabaseImpl()
        Weinre.wi.DOM = new WiDOMImpl()
        Weinre.wi.DOMStorage = new WiDOMStorageImpl()
        Weinre.wi.Inspector = new WiInspectorImpl()
        Weinre.wi.Runtime = new WiRuntimeImpl()
        messageDispatcher.registerInterface "Console", Weinre.wi.Console, false
        messageDispatcher.registerInterface "CSS", Weinre.wi.CSS, false
        messageDispatcher.registerInterface "Database", Weinre.wi.Database, false
        messageDispatcher.registerInterface "DOM", Weinre.wi.DOM, false
        messageDispatcher.registerInterface "DOMStorage", Weinre.wi.DOMStorage, false
        messageDispatcher.registerInterface "Inspector", Weinre.wi.Inspector, false
        messageDispatcher.registerInterface "Runtime", Weinre.wi.Runtime, false
        messageDispatcher.registerInterface "WeinreExtraClientCommands", new WeinreExtraClientCommandsImpl(), true
        messageDispatcher.registerInterface "WeinreTargetEvents", new WeinreTargetEventsImpl(), true
        Weinre.wi.ApplicationCacheNotify = messageDispatcher.createProxy("ApplicationCacheNotify")
        Weinre.wi.ConsoleNotify = messageDispatcher.createProxy("ConsoleNotify")
        Weinre.wi.DOMNotify = messageDispatcher.createProxy("DOMNotify")
        Weinre.wi.DOMStorageNotify = messageDispatcher.createProxy("DOMStorageNotify")
        Weinre.wi.DatabaseNotify = messageDispatcher.createProxy("DatabaseNotify")
        Weinre.wi.InspectorNotify = messageDispatcher.createProxy("InspectorNotify")
        Weinre.wi.TimelineNotify = messageDispatcher.createProxy("TimelineNotify")
        Weinre.WeinreTargetCommands = messageDispatcher.createProxy("WeinreTargetCommands")
        Weinre.WeinreExtraTargetEvents = messageDispatcher.createProxy("WeinreExtraTargetEvents")
        messageDispatcher.getWebSocket().addEventListener "open", Binding(this, @cb_webSocketOpened)
        Weinre.nodeStore = new NodeStore()
        Weinre.cssStore = new CSSStore()
        window.addEventListener "error", ((e) ->
            Target.handleError e
        ), false
    
    #---------------------------------------------------------------------------
    @handleError: (event) ->
        filename = event.filename or "[unknown filename]"
        lineno = event.lineno or "[unknown lineno]"
        message = event.message or "[unknown message]"
        Weinre.logError "error occurred: " + filename + ":" + lineno + ": " + message
    
    #---------------------------------------------------------------------------
    cb_webSocketOpened: () ->
        Weinre.WeinreTargetCommands.registerTarget window.location.href, Binding(this, @cb_registerTarget)
    
    #---------------------------------------------------------------------------
    cb_registerTarget: (targetDescription) ->
        Weinre.targetDescription = targetDescription
    
    #---------------------------------------------------------------------------
    onLoaded: ->
        Weinre.wi.InspectorNotify.loadEventFired currentTime() - @_startTime
    
    #---------------------------------------------------------------------------
    onDOMContent: ->
        Weinre.wi.InspectorNotify.domContentEventFired currentTime() - @_startTime
    
    #---------------------------------------------------------------------------
    setDocument: () ->
        Weinre.elementHighlighter = new ElementHighlighter()
        nodeId = Weinre.nodeStore.getNodeId(document)
        nodeData = Weinre.nodeStore.getNodeData(nodeId, 2)
        Weinre.wi.DOMNotify.setDocument nodeData
    
# WebKit's currentTime() seems to return time in seconds
currentTime =  () ->
      (new Date().getMilliseconds()) / 1000.0
  
