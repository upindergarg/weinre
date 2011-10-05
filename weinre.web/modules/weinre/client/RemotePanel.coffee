
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Binding       = require('../common/Binding')
Weinre        = require('../common/Weinre')

ConnectorList = require('./ConnectorList')
DT            = require('./DOMTemplates')

# fix WebInspector.Panel's prototype so our super call works
WebInspector.Panel.prototype.constructor = WebInspector.Panel

#-------------------------------------------------------------------------------
module.exports = class RemotePanel extends WebInspector.Panel

    RemotePanel::__defineGetter__("toolbarItemClass", -> "remote")
    RemotePanel::__defineGetter__("toolbarItemLabel", -> "Remote")
    RemotePanel::__defineGetter__("statusBarItems", -> [] )
    RemotePanel::__defineGetter__("defaultFocusedElement", -> @contentElement)

    constructor: ->
        super "remote"
        @initialize()

    #---------------------------------------------------------------------------
    initialize: () ->
        div = DT.DIV()
        div.style.position = "absolute"
        div.style.top = "1em"
        div.style.right = "1em"
        div.style.left = "1em"
        div.style.bottom = "1em"
        div.style.overflow = "auto"
        icon = DT.IMG(src: "../images/weinre-icon-128x128.png")
        icon.style.float = "right"
        div.appendChild icon
        @targetList = new TargetList()
        @clientList = new ClientList()
        div.appendChild @targetList.getElement()
        div.appendChild @clientList.getElement()
        @serverProperties = DT.DIV($className: "weinreServerProperties")
        div.appendChild DT.H1("Server Properties")
        div.appendChild @serverProperties
        @element.appendChild div
        @reset()

    #---------------------------------------------------------------------------
    addClient: (client) ->
        @clientList.add client


    addTarget: (target) ->
        @targetList.add target


    getTarget: (channel) ->
        @targetList.get channel


    removeClient: (channel) ->
        @clientList.remove channel


    removeTarget: (channel) ->
        @targetList.remove channel


    setCurrentClient: (channel) ->
        @clientList.setCurrent channel


    setCurrentTarget: (channel) ->
        @targetList.setCurrent channel


    setClientState: (channel, state) ->
        @clientList.setState channel, state


    setTargetState: (channel, state) ->
        @targetList.setState channel, state

    #---------------------------------------------------------------------------
    getNewestTargetChannel: (ignoring) ->
        @targetList.getNewestConnectorChannel ignoring

    #---------------------------------------------------------------------------
    afterInitialConnection: ->
        @clientList.afterInitialConnection()

    #---------------------------------------------------------------------------
    reset: ->
        @clientList.removeAll()
        @targetList.removeAll()
        Weinre.WeinreClientCommands.getTargets Binding(this, "cb_getTargets")
        Weinre.WeinreClientCommands.getClients Binding(this, "cb_getClients")

    #---------------------------------------------------------------------------
    connectionClosed: ->
        @clientList.removeAll()
        @targetList.removeAll()

    #---------------------------------------------------------------------------
    cb_getTargets: (targets) ->
        for target in targets
            @addTarget target

        return  unless Weinre.client.autoConnect()
        newestTargetChannel = @getNewestTargetChannel()
        return  unless newestTargetChannel
        return  unless Weinre.messageDispatcher
        Weinre.WeinreClientCommands.connectTarget Weinre.messageDispatcher.channel, newestTargetChannel

    #---------------------------------------------------------------------------
    cb_getClients: (clients) ->
        for client in clients
            @addClient client

    #---------------------------------------------------------------------------
    show: ->
        super()

    #---------------------------------------------------------------------------
    hide: () ->
        super()

    #---------------------------------------------------------------------------
    setServerProperties: (properties) ->
        table = "<table>"
        keys = []
        for key of properties
            keys.push key
        keys = keys.sort()
        for key in keys
            val = properties[key]
            if typeof val == "string"
                val = val.escapeHTML()
            else
                finalVal = ""
                for aVal in val
                    finalVal += "<li>" + aVal.escapeHTML()

                val = "<ul>" + finalVal + "</ul>"
            table += "<tr class='weinre-normal-text-size'><td valign='top'>" + key.escapeHTML() + ": <td>" + val

        table += "</table>"
        @serverProperties.innerHTML = table

#-------------------------------------------------------------------------------
class TargetList extends ConnectorList

    constructor: ->
        super "Targets"

    #---------------------------------------------------------------------------
    getListItem: (target) ->
        self = this
        text = target.hostName + " [channel: " + target.channel + " id: " + target.id + "]" + " - " + target.url
        item = DT.LI($connectorChannel: target.channel, text)
        item.addStyleClass "weinre-connector-item"
        item.addStyleClass "target"
        item.addEventListener "click", ((e) ->
            self.connectToTarget target.channel, e
        ), false
        target.element = item
        item

    #---------------------------------------------------------------------------
    connectToTarget: (targetChannel, event) ->
        if event
            event.preventDefault()
            event.stopPropagation()
        target = @connectors[targetChannel]
        return false  unless target
        return false  if target.closed
        Weinre.WeinreClientCommands.connectTarget Weinre.messageDispatcher.channel, targetChannel
        false

#-------------------------------------------------------------------------------
class ClientList extends ConnectorList

    constructor: ->
        super "Clients"
        @noneItem.innerHTML = "Waiting for connection..."

    #---------------------------------------------------------------------------
    afterInitialConnection: () ->
        @noneItem.innerHTML = "Connection lost, reload this page to reconnect."
        @noneItem.addStyleClass "error"

    #---------------------------------------------------------------------------
    getListItem: (client) ->
        text = client.hostName + " [channel: " + client.channel + " id: " + client.id + "]"
        item = DT.LI($connectorChannel: client.channel, text)
        item.addStyleClass "weinre-connector-item"
        item.addStyleClass "client"

        if Weinre.messageDispatcher
            if client.channel == Weinre.messageDispatcher.channel
                item.addStyleClass "current"

        client.element = item
        item

#-------------------------------------------------------------------------------
require("../common/MethodNamer").setNamesForClass(module.exports)
