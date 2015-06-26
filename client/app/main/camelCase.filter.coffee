'use strict'

angular.module 'gsfFdaApp'
  .filter 'titleCase', ->
    (input) ->
      input = input or ''
      input.replace /\w\S*/g, (txt) ->
        txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
