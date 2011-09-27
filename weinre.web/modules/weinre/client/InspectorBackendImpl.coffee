
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Ex = require('../common/Ex')
IDLTools = require('../common/IDLTools')
MessageDispatcher = require('../common/MessageDispatcher')
Weinre = require('../common/Weinre')

#-------------------------------------------------------------------------------
module.exports = class InspectorBackendImpl

    constructor: ->
        @registeredDomainDispatchers = {}
        MessageDispatcher.setInspectorBackend this
    
    #---------------------------------------------------------------------------
    @setupProxies: ->
        intfNames = [ "ApplicationCache", "BrowserDebugger", "CSS", "Console", "DOM", "DOMStorage", "Database", "Debugger", "InjectedScript", "Inspector", "Network", "Profiler", "Runtime" ]
        intfNames.forEach (intfName) ->
            proxy = Weinre.messageDispatcher.createProxy(intfName)
            throw new Ex(arguments, "backend interface '" + intfName + "' already created")  if window[intfName]
            intf = IDLTools.getIDL(intfName)
            throw new Ex(arguments, "interface not registered: '" + intfName + "'")  unless intf
            window[intfName] = {}
            intf.methods.forEach (method) ->
                proxyMethod = InspectorBackendImpl.getProxyMethod(proxy, method)
                InspectorBackendImpl::[method.name] = proxyMethod
                window[intfName][method.name] = proxyMethod
    
    #---------------------------------------------------------------------------
    @getProxyMethod: (proxy, method) ->
        ->
            proxy[method.name].apply proxy, arguments
    
    #---------------------------------------------------------------------------
    registerDomainDispatcher: (name, intf) ->
        @registeredDomainDispatchers[name] = intf
    
    #---------------------------------------------------------------------------
    getRegisteredDomainDispatcher: (name) ->
        return null  unless @registeredDomainDispatchers.hasOwnProperty(name)
        @registeredDomainDispatchers[name]
    
