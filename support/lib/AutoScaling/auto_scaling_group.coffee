AWSResource = require '../aws_resource'

module.exports = class AutoScalingGroup extends AWSResource
  setup: (service) ->
    super.then (group) ->
      service.nodes.AutoScalingGroup = group

  find: (service) ->
    @log "AutoScalingGroup.find(#{service.name})"
    params =
      AutoScalingGroupNames: ["#{@config.cluster}-auto-scaling-#{service.name}"]

    @sdk.autoscaling.describeAutoScalingGroupsAsync(params).then (response) =>
      return null if response.AutoScalingGroups.length is 0
      @log "AutoScalingGroup found"
      response.AutoScalingGroups[0]

  create: (service) ->
    @log "AutoScalingGroup.create(#{service.name})"
    params =
      AutoScalingGroupName: "#{@config.cluster}-auto-scaling-#{service.name}"
      MaxSize: service.nodes.max
      MinSize: service.nodes.min
      DesiredCapacity: service.nodes.desired
      LaunchConfigurationName: service.nodes.launchConfig.LaunchConfigurationName
      VPCZoneIdentifier: "#{@config.subnet.id}"

    if service.nodes.ELB?
      params.LoadBalancerNames = [service.nodes.ELB.name]

    @sdk.autoscaling.createAutoScalingGroupAsync(params).then (response) =>
      @log "Autoscaling group created."
      @find service
