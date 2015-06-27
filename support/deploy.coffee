_ = require 'lodash'
fs = require 'fs'
path = require 'path'
AWS = require 'aws-sdk'
Promise = require 'bluebird'

inspect = (data) ->
  console.log JSON.stringify(data, null, 2)

class DeployManager
  constructor: (config) ->
    @config = _.cloneDeep config
    AWS.config.region = @config.region

  authenticate: (credentials) ->
    fromProfile: ->
      console.log "authenticating with profile: #{credentials}"
      auth = new AWS.SharedIniFileCredentials(profile: credentials)
      AWS.config.credentials = auth

  initialize: ->
    console.log "initializing"
    @ecs = new AWS.ECS()
    Promise.promisifyAll @ecs


    console.log "building task configs"
    _.each @config.services, (service) =>
      service.task = task =
        name: "#{service.name}-task"

      @setTaskVersion task
      @buildTaskConfig task
      # task.active = @find_service @config.cluster, task.name

    inspect @config

    # @findOrCreateCluster().then (cluster) =>
    #   console.log 'bam'

  setTaskVersion: (task) ->
    task.version = process.env.CIRCLE_BUILD_NUM or 0

  buildTaskConfig: (task) ->
    console.log "buildTaskConfig(#{task.name})"
    task_file = "#{path.resolve __dirname}/ecs_tasks/#{task.name}.json"
    data = _.template fs.readFileSync(task_file), task
    task.config = JSON.parse data
    task.config.name = task.name

  findOrCreateCluster: ->
    console.log "find_or_create_cluster()"
    @findCluster().then (cluster) =>
      unless cluster?
        @createCluster().then (cluster) ->
          console.log 'cluster created.'
          cluster
      cluster

  findCluster: ->
    console.log "findCluster()"
    params = clusters: [@config.cluster]

    @ecs.describeClustersAsync(params).then (response) ->
      return null if response.clusters.length is 0
      response.clusters[0]

  createCluster: ->
    console.log "createCluster()"
    params =
      clusterName: "#{@config.cluster}"

    @ecs.createClusterAsync(params).then (response) ->
      console.log 'Cluster created:'
      inspect response.cluster
      response.cluster

  findService: (service) ->
    console.log "findService() for #{service.name}"
    params =
      cluster: @config.cluster
      services: [service.name]

    @ecs.describeServicesAsync(params).then (response) ->
      return null if response.services.length is 0
      response.services[0]

  createService: (service) ->
    # TODO: register the service.taskDefinition first
    params =
      desiredCount: service.nodes
      serviceName: service.name
      taskDefinition: service.taskDefinition
      cluster: @config.cluster
      # TODO: loadBalancer

    @ecs.createService(params).then (response) ->
      console.log 'service created:',




config =
  region: 'us-east-1'
  cluster: 'flexion-18f'
  services: [
    # Use only 1 node-server instance until I add support for setting up the load-balancing.
    {name: 'node-server', nodes: 1}
    {name: 'nginx-static', nodes: 1}
    {name: 'logstash', nodes: 1}
  ]

ecs = new DeployManager(config)

# Remove this if the following environment variables are set:
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN (optional)
ecs.authenticate('deploy').fromProfile()

ecs.initialize()
ecs.findOrCreateCluster().then (cluster) ->
  console.log 'bam', cluster

  # ecs.registerTasks()
  # ecs.registerServices()
