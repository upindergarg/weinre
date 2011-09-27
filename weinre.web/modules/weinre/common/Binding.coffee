
#---------------------------------------------------------------------------------
# weinre is available under *either* the terms of the modified BSD license *or* the
# MIT License (2008). See http:#opensource.org/licenses/alphabetical for full text.
#
# Copyright (c) 2010, 2011 IBM Corporation
#---------------------------------------------------------------------------------

Ex = require('./Ex')

#-------------------------------------------------------------------------------
module.exports = class Binding

    constructor: (receiver, method) ->
        throw new Ex(arguments, "receiver argument for Binding constructor was null")  unless receiver?
        method = receiver[method]  if typeof (method) == "string"
        throw new Ex(arguments, "method argument didn't specify a function")  unless typeof (method) == "function"
        ->
            method.apply receiver, [].slice.call(arguments)
    
