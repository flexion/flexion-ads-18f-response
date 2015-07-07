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
    return
    stacks = Promise.cast()
    for stack in @config.Stacks
      do (stack) =>
        stacks = stacks.then =>
          console.log "Applying CloudFormation stack: #{stack.name}"
          @AWS.CloudFormation.Stack.create(stack)
    stacks

  deploy: ->
    @uploadS3Assets()
      .then -> console.log 'S3 Assets uploaded.'
      .then => @applyStacks()
      # TODO: Collect stack outputs so we can get a link to the ELB IP.
      .then => console.log "Deployment completed."
