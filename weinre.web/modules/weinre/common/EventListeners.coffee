
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Ex = require('./Ex')
Weinre = require('./Weinre')

#-------------------------------------------------------------------------------
module.exports = class EventListeners

    constructor: ->
        @_listeners = []
    
    #---------------------------------------------------------------------------
    add: (listener, useCapture) ->
        @_listeners.push [ listener, useCapture ]
    
    #---------------------------------------------------------------------------
    remove: (listener, useCapture) ->
        i = 0
        
        while i < @_listeners.length
            listener = @_listeners[i]
            continue  unless listener[0] == listener
            continue  unless listener[1] == useCapture
            @_listeners.splice i, 1
            return
            i++
    
    #---------------------------------------------------------------------------
    fire: (event) ->
        @_listeners.slice().forEach (listener) ->
            listener = listener[0]
            if typeof listener == "function"
                try
                    listener.call null, event
                catch e
                    Weinre.logError arguments.callee.signature + " invocation exception: " + e
                return
            throw new Ex(arguments, "listener does not implement the handleEvent() method")  unless typeof listener.handleEvent == "function"
            try
                listener.handleEvent.call listener, event
            catch e
                Weinre.logError arguments.callee.signature + " invocation exception: " + e
    
