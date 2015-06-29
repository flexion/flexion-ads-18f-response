_ = require 'lodash'
fs = require 'fs'
path = require 'path'
AWS = require 'aws-sdk'
Promise = require 'bluebird'

inspect = (data) ->
  console.log JSON.stringify(data, null, 2)

# TODO:
# ELB Management
# AutoScaling Management
# Cloudformation templates

class ECSDeploy
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
    # ECS Container Management
    @ecs = new AWS.ECS()

    # Service Discovery through VPC, DNS and ELBs.
    @elb = new AWS.ELB()
    @route53 = new AWS.Route53()
    @ec2 = new AWS.EC2()

    # Promisification through bluebird.
    Promise.promisifyAll this[x] for x in ['ecs', 'elb', 'route53', 'ec2']

    console.log "building task configs"
    _.each @config.services, (service) =>
      service.cluster = @config.cluster
      service.task = task =
        name: "#{service.name}-task"

      @setTaskVersion task
      @buildTaskConfig task

    @setupVPC()

  setupVPC: ->
    console.log 'setupVPC()'
    @findVPC().then (vpcId) =>
      if vpcId?
        return @config.vpc.id = vpcId
      @createVPC().then (vpcId) =>
        @config.vpc.id = vpcId

  createVPC: ->
    console.log "createVPC()"
    params =
      CidrBlock: @config.vpc.cidr

    @ec2.createVpcAsync(params).then (response) =>
      if (id = response?.Vpc?.VpcId)?
        console.log "creating tag for new VPC with ID: #{id}"
        tags =
          Resources: [id]
          Tags: [
            {
              Key: 'Name'
              Value: @config.vpc.name
            }
          ]
        @ec2.createTagsAsync(tags).then (response) ->
          console.log 'tagging response:', response
          return id

  findVPC: ->
    console.log "findVPC()"
    params =
      MaxResults: 5
      Filters: [
        {Name: 'resource-type', Values: ['vpc']}
        {Name: 'key', Values: ['Name']}
        {Name: 'value', Values: [@config.vpc.name]}
      ]

    console.log 'findVPC params:', params.Filters

    @ec2.describeTagsAsync(params).then (response) ->
      console.log "response:", response
      response.Tags?[0]?.ResourceId

  setTaskVersion: (task) ->
    task.version = process.env.CIRCLE_BUILD_NUM or 0

  buildTaskConfig: (task) ->
    console.log "buildTaskConfig(#{task.name})"
    task_file = "#{path.resolve __dirname}/ecs_tasks/#{task.name}.json"
    data = _.template fs.readFileSync(task_file), task
    task.config = JSON.parse data
    # task.config.name = task.name

  registerTaskDefinition: (task) ->
    console.log "registerTaskDefinition(#{task.name})"
    params =
      containerDefinitions: task.config
      family: task.name

    @ecs.registerTaskDefinitionAsync(params).then (response) ->
      console.log "response for #{task.name}:", response
      if (taskDef = response?.taskDefinition)?
        task.id = "#{taskDef.family}:#{taskDef.revision}"
        return taskDef

  # Cluster Management
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

  # Service Management
  findService: (service) ->
    console.log "findService() for #{service.name}"
    params =
      cluster: @config.cluster
      services: [service.name]

    @ecs.describeServicesAsync(params).then (response) ->
      return null if response.services.length is 0
      response.services[0]

  upsertService: (service) ->
    console.log "upsertService(#{service.name})"
    # TODO: register the service.taskDefinition first
    params =
      desiredCount: service.nodes
      taskDefinition: service.task.id
      cluster: @config.cluster
      # TODO: loadBalancer

    @findService(service).then (serviceConfig) =>
      op = do =>
        if serviceConfig?
          console.log "service #{service.name} found. updating it.", params
          params.service = service.name

          @ecs.updateServiceAsync(params).then (response) ->
            console.log "service #{service.name} updated"
            response.service
        else
          console.log 'found serviceConfig:'
          params.serviceName = service.name

          console.log "service #{service.name} not found. creating it.", params
          @ecs.createServiceAsync(params).then (response) ->
            console.log "service #{service.name} created:"
            response.service

      op.then (serviceConfig) =>
        @setupELB(service)

  setupELB: (service) ->
    console.log "setupELB(#{service.name})"
    return Promise.resolve() unless service.ELB is true



###
ELB Support:

* If `elb` is `true` for a service, upsertLoadBalancer
* createELB should also add a CNAME pointing to that ELB address
* createELB and updateELB should also register service instances into the ELB.
###

###
Autoscaling Group Support:

* TODO: Learn about the autoscaling API.
###

config =
  region: 'us-east-1'
  defaultInstance: 'flexion-18f-t2-small-ecs'
  cluster: 'flexion-18f'
  vpc:
    name: 'flexion-18f'
    cidr: '10.10.1.0/24'
  services: [
    # Use only 1 node-server instance until I add support for setting up ELB.
    {name: 'node-server', ELB: true, nodes: 1}
    {name: 'nginx-static', ELB: true, nodes: 1}
    {name: 'logstash', nodes: 1}
  ]

do (ecs = new ECSDeploy(config), services = []) ->
  # Remove this if the following environment variables are set:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN (optional)
  ecs.authenticate('deploy').fromProfile()

  ecs.initialize().then (vpc) ->
    inspect ecs.config

    ecs.findOrCreateCluster().then (cluster) ->
      _.each ecs.config.services, (service) ->
        services.push ecs.registerTaskDefinition(service.task).then (taskDef) ->
          ecs.upsertService(service)

      Promise.all(services).then ->
        console.log 'ECS deployment completed.'
