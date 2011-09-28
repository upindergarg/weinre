
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

module.exports = class MethodNamer

    @setNamesForClass: (aClass) ->
        for own key, val of aClass
            if typeof(val) is "function"
                val.signature   = "#{aClass.name}::#{key}"
                val.displayName = "#{key}"

        for own key, val of aClass.prototype
            if typeof(val) is "function"
                val.signature   = "#{aClass.name}.#{key}"
                val.displayName = "#{key}"

#-------------------------------------------------------------------------------
MethodNamer.setNamesForClass(module.exports)
