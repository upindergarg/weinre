
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Weinre = require('../common/Weinre')

#-------------------------------------------------------------------------------
module.exports = class WiRuntimeImpl

    constructor: ->

    #---------------------------------------------------------------------------
    evaluate: ( expression,  objectGroup,  includeCommandLineAPI, callback) ->
        result = Weinre.injectedScript.evaluate(expression, objectGroup, includeCommandLineAPI)
        Weinre.WeinreTargetCommands.sendClientCallback callback, [ result ]  if callback

    #---------------------------------------------------------------------------
    getCompletions: ( expression,  includeCommandLineAPI, callback) ->
        result = Weinre.injectedScript.getCompletions(expression, includeCommandLineAPI)
        Weinre.WeinreTargetCommands.sendClientCallback callback, [ result ]  if callback

    #---------------------------------------------------------------------------
    getProperties: ( objectId,  ignoreHasOwnProperty,  abbreviate, callback) ->
        objectId = JSON.stringify(objectId)
        result = Weinre.injectedScript.getProperties(objectId, ignoreHasOwnProperty, abbreviate)
        Weinre.WeinreTargetCommands.sendClientCallback callback, [ result ]  if callback

    #---------------------------------------------------------------------------
    setPropertyValue: ( objectId,  propertyName,  expression, callback) ->
        objectId = JSON.stringify(objectId)
        result = Weinre.injectedScript.setPropertyValue(objectId, propertyName, expression)
        Weinre.WeinreTargetCommands.sendClientCallback callback, [ result ]  if callback

    #---------------------------------------------------------------------------
    releaseWrapperObjectGroup: ( injectedScriptId,  objectGroup, callback) ->
        result = Weinre.injectedScript.releaseWrapperObjectGroup(objectGroupName)
        Weinre.WeinreTargetCommands.sendClientCallback callback, [ result ]  if callback

