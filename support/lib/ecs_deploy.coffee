fs = require 'fs'
_ = require 'lodash'
path = require 'path'
SDK = require 'aws-sdk'
buffer = require 'buffer'
Promise = require 'bluebird'
AWS = require './aws'

module.exports = class ECSDeploy

  constructor: (config) ->
    @config = _.cloneDeep config
    SDK.config.region = @config.region

  authenticate: (credentials) ->
    fromProfile: ->
      console.log "authenticating with profile: #{credentials}"
      auth = new SDK.SharedIniFileCredentials(profile: credentials)
      SDK.config.credentials = auth

  initialize: ->
    console.log "initializing"

    # AWS Abstraction API
    @AWS = new AWS(@config)


  uploadS3Assets: ->
    @AWS.S3.Bucket.setup(@config.S3.bucket).then (bucket) =>
      uploads = Promise.cast()
      for own key, file of @config.S3.files
        do (key, file) =>
          uploads = uploads.then => @AWS.S3.Bucket.upload bucket, file
      uploads

  applyStacks: ->
    stacks = Promise.cast()
    for stack in @config.Stacks
      do (stack) =>
        stacks = stacks.then =>
          console.log "Applying CloudFormation stack: #{stack.name}"
          @AWS.CloudFormation.Stack.setup(stack)
    stacks

  updateService: ->
    if process.env['CIRCLE_BUILD_NUM']?
      # Pull up the taskdef from the CloudFormation Stack
      # Extract the task family (see updateTaskDef)
      # Update the image to be from CircleCI in the object
      # re-register the taskdef
      # update the service with the new taskdef.

      console.log 'CI update initiated.'

      stack = _.find @config.Stacks, (configStack) ->
        configStack.name is 'flexion-18f-app-server'

      console.log 'looking for stack:', stack

      @AWS.CloudFormation.Stack.find(stack).then (cfStack) =>
        console.log 'find results:', cfStack
        return unless cfStack?
        console.log 'found app-server CFstack'

        @AWS.CloudFormation.Stack.getLogicalResource(cfStack, 'FlexionTaskDef').then (resource) =>
          return unless resource?
          console.log 'resource', resource
          @updateTaskDef resource.PhysicalResourceId


  updateTaskDef: (taskDefId) ->
    matches = taskDefId.match /.*\/(.*):[0-1]+/
    return unless (family = matches?[1])

    image = "#{@config.container.image}:v_#{process.env['CIRCLE_BUILD_NUM']}"
    @AWS.ECS.TaskDefinition.find(taskDefId).then (taskDef) =>
      return unless taskDef?

      taskDef.containerDefinitions.image = image
      taskDef.family = family

      @AWS.ECS.TaskDefinition.create(taskDef).then (task) ->
        console.log 'fucking done.', task

  deploy: ->
    @uploadS3Assets()
      .then -> console.log 'S3 Assets uploaded.'
      .then => @applyStacks()
      .then => @updateService()
      # TODO: Collect stack outputs so we can get a link to the ELB IP.
      .then -> console.log "Deployment completed."
