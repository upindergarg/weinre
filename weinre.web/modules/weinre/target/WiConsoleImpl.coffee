
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Weinre = require('../common/Weinre')

#-------------------------------------------------------------------------------
module.exports = class WiConsoleImpl

    constructor: ->
        @messagesEnabled = true

    #---------------------------------------------------------------------------
    setConsoleMessagesEnabled: ( enabled, callback) ->
        oldValue = @messagesEnabled
        @messagesEnabled = enabled
        Weinre.WeinreTargetCommands.sendClientCallback callback, [ oldValue ]  if callback

    #---------------------------------------------------------------------------
    clearConsoleMessages: (callback) ->
        Weinre.wi.ConsoleNotify.consoleMessagesCleared()
        Weinre.WeinreTargetCommands.sendClientCallback callback, []  if callback

    #---------------------------------------------------------------------------
    setMonitoringXHREnabled: ( enabled, callback) ->
        Weinre.WeinreTargetCommands.sendClientCallback callback, []  if callback

#-------------------------------------------------------------------------------
require("../common/MethodNamer").setNamesForClass(module.exports)
