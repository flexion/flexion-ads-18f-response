module.exports = class AWSResource
  constructor: (@config = {}, @sdk) ->

  log: ->
    console.log.apply console, arguments

  setup: =>
    args = arguments

    unless @find? and @create?
      throw new Error "AWS Resource must provide `find` and `create` methods."

    @find.apply(this, args).then (resource) =>
      return resource if resource?
      @create.apply(this, args) unless resource?
