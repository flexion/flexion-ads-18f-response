fs = require 'fs'
_ = require 'lodash'
path = require 'path'
SDK = require 'aws-sdk'
buffer = require 'buffer'
Promise = require 'bluebird'
AWS = require './aws'

module.exports = class ECSDeploy
  defaults:
    nodes:
      ami: 'ami-8da458e6'
      instanceType: 't2.micro'
      min: 1
      desired: 1
      max: 2

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

    console.log "building task configs"
    _.each @config.services, (service) =>
      service.cluster = @config.cluster
      service.task = task =
        name: "#{service.name}-task"

      _.defaults service.nodes, @defaults.nodes

      @setTaskVersion task
      @buildTaskConfig task

  setTaskVersion: (task) ->
    task.version = process.env.CIRCLE_BUILD_NUM or 0

  buildTaskConfig: (task) ->
    console.log "buildTaskConfig(#{task.name})"
    task_file = path.join @config.templatesDir, 'ecs_tasks', "#{task.name}.json"
    data = _.template fs.readFileSync(task_file), task
    task.config = JSON.parse data

  deploy: ->
    @AWS.EC2.VPC.setup()
      .then @AWS.EC2.Subnet.setup
      .then @AWS.EC2.InternetGateway.setup
      .then @AWS.ECS.Cluster.setup
      .then =>
        current = Promise.cast()
        _.each @config.services, (service) =>
          current = current.then =>
            @AWS.EC2.ELB.setup(service)
              .then => @AWS.AutoScaling.LaunchConfiguration.setup(service)
              .then => @AWS.AutoScaling.AutoScalingGroup.setup(service)
              .then => @AWS.ECS.TaskDefinition.setup(service.task)
              .then => @AWS.ECS.Service.setup(service)

        current = current.then => return @config


  # TODO: Route53 management.
  setupCNAME: (service) ->

  findCNAME: (service) ->

  createCNAME: (service) ->

  updateCNAME: (service) ->
