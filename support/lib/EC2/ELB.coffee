AWSResource = require '../aws_resource'
Promise = require 'bluebird'
_ = require 'lodash'

module.exports = class ELB extends AWSResource
  setup: (service) ->
    return Promise.resolve() unless service.nodes.ELB?
    super.then (ELBData = {}) ->
      _.extend service.nodes.ELB, ELBData

  find: (service) ->
    @log "ELB.find(#{service.name})"
    params =
      LoadBalancerNames: ["#{@config.cluster}-elb-#{service.name}"]

    @sdk.elb.describeLoadBalancersAsync(params).then (response) =>
      return null if response.LoadBalancerDescriptions.length is 0
      @log "ELB #{@config.cluster}-elb-#{service.name} found"

      {
        id: response.LoadBalancerDescriptions[0].DNSName
        name: response.LoadBalancerDescriptions[0].LoadBalancerName
      }

    .catch (err) -> return null

  create: (service) ->
    @log "ELB.create(#{service.name})"
    params =
      LoadBalancerName: "#{@config.cluster}-elb-#{service.name}"
      Subnets: [@config.subnet.id]

    _.extend params, service.nodes.ELB.config or {}

    @sdk.elb.createLoadBalancerAsync(params).then (response) =>
      @log "ELB #{response.DNSName} created."
      @find service
