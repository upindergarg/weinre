
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

dt = require('./DOMTemplates')

#-------------------------------------------------------------------------------
module.exports = class ConnectorList

    constructor: (title) ->
        @connectors = {}
        @noneItem = dt.LI("none")
        @ulConnectors = dt.UL(@noneItem)
        @div = dt.DIV(dt.H1(title), @ulConnectors)
        @noneItem.addStyleClass "weinre-connector-item"
    
    #---------------------------------------------------------------------------
    getElement: ->
        @div
    
    #---------------------------------------------------------------------------
    add: (connector) ->
        return  if @connectors[connector.channel]
        @connectors[connector.channel] = connector
        li = @getListItem(connector)
        @noneItem.style.display = "none"  unless @noneItem.style.display == "none"
        li.addStyleClass "weinre-fadeable"
        insertionPoint = @getConnectorInsertionPoint(connector)
        unless insertionPoint
            @ulConnectors.appendChild li
        else
            @ulConnectors.insertBefore li, insertionPoint
    
    #---------------------------------------------------------------------------
    get: (channel) ->
        @connectors[channel]
    
    #---------------------------------------------------------------------------
    getNewestConnectorChannel: (ignoring) ->
        newest = 0
        for connectorChannel of @connectors
            continue  if connectorChannel == ignoring
            newest = connectorChannel  if connectorChannel > newest
        return null  if newest == 0
        newest
    
    #---------------------------------------------------------------------------
    getConnectorInsertionPoint: (connector) ->
        i = 0
        
        while i < @ulConnectors.childNodes.length
            childNode = @ulConnectors.childNodes[i]
            continue  if null == childNode.connectorChannel
            return childNode  if childNode.connectorChannel < connector.channel
            i++
        null
    
    #---------------------------------------------------------------------------
    remove: (channel, fast) ->
        self = this
        element = @getConnectorElement(channel)
        return  unless element
        connector = @connectors[channel]
        connector.closed = true  if connector
        delete @connectors[channel]
        
        if fast
            @_remove element
        else
            @setState element, "closed"
            element.addStyleClass "weinre-fade"
            window.setTimeout (->
                self._remove element
            ), 5000
    
    #---------------------------------------------------------------------------
    _remove: (element) ->
        @ulConnectors.removeChild element
        @noneItem.style.display = "list-item"  if @getConnectors().length == 0
    
    #---------------------------------------------------------------------------
    removeAll: () ->
        @getConnectors().forEach ((connector) ->
            @remove connector.channel, true
        ), this
    
    #---------------------------------------------------------------------------
    getConnectors: () ->
        result = []
        for channel of @connectors
            continue  unless @connectors.hasOwnProperty(channel)
            result.push @connectors[channel]
        result
    
    #---------------------------------------------------------------------------
    getConnectorElement: (channel) ->
        connector = @connectors[channel]
        return null  unless connector
        connector.element
    
    #---------------------------------------------------------------------------
    setCurrent: (channel) ->
        @getConnectors().forEach (connector) ->
            connector.element.removeStyleClass "current"
        
        element = @getConnectorElement(channel)
        return  if null == element
        element.addStyleClass "current"
    
    #---------------------------------------------------------------------------
    setState: (channel, state) ->
        if typeof channel == "string"
            element = @getConnectorElement(channel)
        else
            element = channel
        return  unless element
        element.removeStyleClass "error"
        element.removeStyleClass "closed"
        element.removeStyleClass "connected"
        element.removeStyleClass "not-connected"
        element.addStyleClass state
    
