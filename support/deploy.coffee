_ = require 'lodash'
fs = require 'fs'
path = require 'path'
AWS = require 'aws-sdk'
Promise = require 'bluebird'
buffer = require 'buffer'

inspect = (data) ->
  console.log JSON.stringify(data, null, 2)

# TODO:
# ELB Management
# AutoScaling Management
# Cloudformation templates

class ECSDeploy
  defaults:
    nodes:
      ami: 'ami-8da458e6'
      instanceType: 't2.small'
      min: 1
      desired: 1
      max: 2

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

    # Auto-scaling
    @autoscaling = new AWS.AutoScaling()

    # Promisification through bluebird.
    for x in ['ecs', 'elb', 'route53', 'ec2', 'autoscaling']
      Promise.promisifyAll this[x]

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
    task_file = "#{path.resolve __dirname}/ecs_tasks/#{task.name}.json"
    data = _.template fs.readFileSync(task_file), task
    task.config = JSON.parse data

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

  # VPC Management

  setupGateway: ->
    console.log 'setupGateway()'
    @findGateway().then (gateway) =>
      return gateway if gateway?
      @createGateway()
    .then (gatewayId) =>
      @config.vpc.gateway = gatewayId

  findGateway: ->
    console.log 'findGateway()'
    params =
      Filters: [
        {
          Name: 'attachment.vpc-id'
          Values:  [@config.vpc.id]
        }
      ]

    @ec2.describeInternetGatewaysAsync(params).then (response) =>
      console.log 'Gateway found:', response
      return null if response.InternetGateways.length is 0
      config.vpc.gateway = response.InternetGateways[0].InternetGatewayId

  createGateway: ->
    console.log 'createGateway()'
    @ec2.createInternetGatewayAsync({}).then (response) =>
      do (gateway = response.InternetGateway) =>
        id = gateway.InternetGatewayId

        params =
          InternetGatewayId: gateway.InternetGatewayId
          VpcId: @config.vpc.id

        @ec2.attachInternetGatewayAsync(params).then (response) ->
          console.log 'gateway created.', response
          @findGateway()



  setupVPC: ->
    console.log 'setupVPC()'
    @findVPC().then (vpcId) =>
      return @config.vpc.id = vpcId if vpcId?

      @createVPC().then (vpcId) =>
        @config.vpc.id = vpcId
    .then (vpcId) => @setupSubnet()
    .then => @setupGateway()

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
      return null if response.Tags.length is 0
      console.log "response:", response
      response.Tags[0]?.ResourceId

  setupSubnet: ->
    console.log 'setupSubnet()'
    @findSubnet().then (subnet) =>
      return subnet if subnet?
      @createSubnet()

  findSubnet: ->
    console.log "findSubnet..."
    params =
      Filters: [
        {
          Name: 'vpc-id'
          Values: [@config.vpc.id]
        }
      ]

    @ec2.describeSubnetsAsync(params).then (response) =>
      console.log "describeSubnets response", response
      return null if response.Subnets.length is 0
      return @config.subnet.id = response.Subnets[0].SubnetId

  createSubnet: ->
    console.log "createSubnet()"
    params =
      CidrBlock: @config.subnet.cidr
      VpcId: @config.vpc.id

    @ec2.createSubnetAsync(params).then (response) =>
      if (id = response?.Subnet?.SubnetId)?
        console.log "creating tag for new Subnet with ID: #{id}"
        tags =
          Resources: [id]
          Tags: [
            {
              Key: 'Name'
              Value: @config.subnet.name
            }
          ]
        @ec2.createTagsAsync(tags).then (response) ->
          console.log 'tagging response:', response
          return id

  deploy: ->
    @setupVPC().then =>
      @findOrCreateCluster().then (cluster) =>
        current = Promise.cast()
        _.each @config.services, (service) =>
          current = current.then => @setupService service
        current = current.then => return @config


  setupService: (service) ->
    @setupELB(service).then (elb) =>
      console.log 'ELB:', elb
      # @setupCNAME(service).then (cname) =>
      @setupAutoScalingGroup(service).then (scalingGroup) =>
        @registerTaskDefinition(service.task).then (taskDef) =>
          @upsertService(service)

  # ELB Management
  setupELB: (service) ->
    console.log "setupELB(#{service.name})"
    unless service.nodes.ELB?
      return new Promise (resolve) -> resolve()

    @findELB(service).then (elb) =>
      console.log 'findELB done. Response:', elb
      return @createELB(service) unless elb?
      @updateELB(service)

  findELB: (service) ->
    console.log "findELB(#{service.name})"
    params =
      LoadBalancerNames: ["#{@config.cluster}-elb-#{service.name}"]

    console.log 'params:', params

    @elb.describeLoadBalancersAsync(params).then (response) ->
      console.log 'describeLoadBalancers response:', response
      return null if response.LoadBalancerDescriptions.length is 0
      console.log "ELB found:", response.LoadBalancerDescriptions[0]
      _.extend service.nodes.ELB,
        id: response.LoadBalancerDescriptions[0].DNSName
        name: response.LoadBalancerDescriptions[0].LoadBalancerName
    .catch (err) -> return null

  createELB: (service) ->
    console.log "createELB(#{service.name})"
    params =
      LoadBalancerName: "#{@config.cluster}-elb-#{service.name}"
      Subnets: [@config.subnet.id]

    _.extend params, service.nodes.ELB.config

    console.log 'createELB params:', params

    @elb.createLoadBalancerAsync(params).then (response) =>
      console.log 'ELB created', response.DNSName
      @findELB service

  updateELB: (service) ->
    console.log "updateELB(#{service.name})"
    params =
      LoadBalancerName: "#{@config.cluster}-elb-#{service.name}"

    @elb.deleteLoadBalancerAsync(params).then (response) =>
      console.log "ELB Deleted. Re-creating it."
      @createELB service

  setupCNAME: (service) ->

  findCNAME: (service) ->

  createCNAME: (service) ->

  updateCNAME: (service) ->

  setupAutoScalingGroup: (service) ->
    console.log "setupAutoScalingGroup(#{service.name})"

    @setupLaunchConfiguration(service).then (launchConfig) =>
      service.nodes.launchConfig = launchConfig

      @findAutoScalingGroup(service).then (ag) =>
        return @createAutoScalingGroup(service) unless ag?
        @updateAutoScalingGroup(service)

  findAutoScalingGroup: (service) ->
    console.log "findAutoScalingGroup(#{service.name})"
    params =
      AutoScalingGroupNames: ["#{@config.cluster}-auto-scaling-#{service.name}"]

    @autoscaling.describeAutoScalingGroupsAsync(params).then (response) ->
      return null if response.AutoScalingGroups.length is 0
      console.log "AG found:", response.AutoScalingGroups[0]
      return service.nodes.AutoScalingGroup = response.AutoScalingGroups[0]

  createAutoScalingGroup: (service) ->
    console.log "createAutoScalingGroup(#{service.name})"
    params =
      AutoScalingGroupName: "#{@config.cluster}-auto-scaling-#{service.name}"
      MaxSize: service.nodes.max
      MinSize: service.nodes.min
      DesiredCapacity: service.nodes.desired
      LaunchConfigurationName: service.nodes.launchConfig.LaunchConfigurationName
      VPCZoneIdentifier: "#{@config.subnet.id}"

    if service.nodes.ELB?
      params.LoadBalancerNames = [service.nodes.ELB.name]

    console.log 'request params:', params

    @autoscaling.createAutoScalingGroupAsync(params).then (response) ->
      console.log "Autoscaling group created. response:", response
      response

  updateAutoScalingGroup: (service) ->
    console.log "updateAutoScalingGroup(#{service.name})"
    params =
      AutoScalingGroupName: "#{@config.cluster}-auto-scaling-#{service.name}"
      MaxSize: service.nodes.max
      MinSize: service.nodes.min
      DesiredCapacity: service.nodes.desired
      LaunchConfigurationName: service.nodes.launchConfig.LaunchConfigurationName
      VPCZoneIdentifier: "#{@config.subnet.id}"

    # if service.nodes.ELB?
    #   params.LoadBalancerNames = [service.nodes.ELB.id]

    @autoscaling.updateAutoScalingGroupAsync(params).then (response) =>
      console.log "Autoscaling group updated. response:", response
      @findAutoScalingGroup(service).then (ag) =>
        console.log 'updated AG:', ag
        if service.nodes.ELB?
          unless ag.LoadBalancerNames?[0] is service.nodes.ELB.id
            attachParams =
              AutoScalingGroupName: "#{@config.cluster}-auto-scaling-#{service.name}"
              LoadBalancerNames: [service.nodes.ELB.name]

            @autoscaling.attachLoadBalancersAsync(attachParams).then =>
              @findAutoScalingGroup service



  # Auto-scaling Launch Configurations
  setupLaunchConfiguration: (service) ->
    console.log "setupLaunchConfiguration(#{service.name})"

    @findLaunchConfiguration(service).then (launchConfig) =>
      return @createLaunchConfiguration(service) unless launchConfig?
      # @updateLaunchConfiguration(service)
      launchConfig

  findLaunchConfiguration: (service) ->
    console.log "findLaunchConfiguration(#{service.name})"
    params =
      LaunchConfigurationNames: ["#{@config.cluster}-launch-#{service.name}"]

    @autoscaling.describeLaunchConfigurationsAsync(params).then (response) ->
      return null if response.LaunchConfigurations.length is 0
      console.log "LaunchConfig found:", response.LaunchConfigurations[0]
      service.launchConfig = response.LaunchConfigurations[0]

  createLaunchConfiguration: (service) ->
    console.log "createLaunchConfiguration(#{service.name})"
    @extractUserData(service).then (userData) =>
      params =
        LaunchConfigurationName: "#{@config.cluster}-launch-#{service.name}"
        ImageId: service.nodes.ami
        UserData: userData
        InstanceType: service.nodes.instanceType
        InstanceMonitoring: {Enabled: false}

      @autoscaling.createLaunchConfigurationAsync(params).then (response) =>
        console.log "LaunchConfig created. response:", response
        @findLaunchConfiguration(service)


  updateLaunchConfiguration: (service) ->
    console.log "updateLaunchConfiguration(#{service.name})"
    params =
      LaunchConfigurationName: "#{@config.cluster}-launch-#{service.name}"

    @autoscaling.deleteLaunchConfigurationAsync(params).then (response) =>
      console.log "LaunchConfig deleted. re-creating.", response
      @createLaunchConfiguration(service)

  extractUserData: (service) ->
    console.log "extractUserData(#{service.name})"
    new Promise (resolve, reject) =>
      tpl = "#{path.resolve __dirname}/ecs_instance_userdata/#{service.name}.template"

      payload =
        config: @config
        env: process.env

      out = _.template fs.readFileSync(tpl), payload
      console.log "userData: \n#{out}"
      resolve new Buffer(out).toString 'base64'

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
      desiredCount: service.nodes.desired
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

config =
  region: 'us-east-1'
  cluster: 'flexion-18f'
  vpc:
    name: 'flexion-18f'
    cidr: '10.10.0.0/16'
  subnet:
    name: 'flexion-18f-subnet1'
    cidr: '10.10.1.0/24'
  services: [
    {
      name: 'node-server'
      nodes:
        # ami: 'ami-e1c33f8a'
        # instanceType: 't2.small'
        # min: 1
        # desired: 1
        max: 10
        ELB:
          config:
            Listeners: [{
              InstancePort: 80
              LoadBalancerPort: 80
              # TODO: Add SSL support
              Protocol: 'HTTP'
              InstanceProtocol: 'HTTP'
            }]
    }

    {
      name: 'nginx-static'
      nodes:
        ELB:
          config:
            Listeners: [{
              InstancePort: 80
              LoadBalancerPort: 80
              Protocol: 'HTTP'
              InstanceProtocol: 'HTTP'
            }]
    }

    {
      name: 'logstash'
      nodes:
        max: 1
    }
  ]

do (ecs = new ECSDeploy(config), services = []) ->
  # Remove this if the following environment variables are set:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN (optional)
  ecs.authenticate('deploy').fromProfile()

  ecs.initialize()
  inspect ecs.config

  ecs.deploy().then (config) ->
    console.log 'ECS deployment completed.', inspect config