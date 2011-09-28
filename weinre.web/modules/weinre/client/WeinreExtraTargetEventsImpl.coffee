
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

module.exports = class WeinreExtraTargetEventsImpl

    constructor: ->

    #---------------------------------------------------------------------------
    databaseOpened: (databaseRecord) ->
        WeinreExtraTargetEventsImpl.addDatabaseRecords [ databaseRecord ]

    #---------------------------------------------------------------------------
    @addDatabaseRecords: (databaseRecords) ->
        return  unless WebInspector.panels
        return  unless WebInspector.panels.resources
        return  unless WebInspector.panels.resources._databases
        existingDbs = WebInspector.panels.resources._databases
        existingDbNames = {}
        i = 0

        while i < existingDbs.length
            existingDbNames[existingDbs[i].name] = existingDbs[i]
            i++
        i = 0

        while i < databaseRecords.length
            continue  if existingDbNames[databaseRecords[i].name]
            databaseRecord = databaseRecords[i]
            database = new WebInspector.Database(databaseRecord.id, databaseRecord.domain, databaseRecord.name, databaseRecord.version)
            WebInspector.panels.resources.addDatabase database
            i++

#-------------------------------------------------------------------------------
require("../common/MethodNamer").setNamesForClass(module.exports)
