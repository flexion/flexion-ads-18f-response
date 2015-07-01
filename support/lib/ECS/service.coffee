AWSResource = require '../aws_resource'

module.exports = class Service extends AWSResource
  find: (service) ->
    @log "Service.find(#{service.name})"
    params =
      cluster: @config.cluster
      services: [service.name]

    @sdk.ecs.describeServicesAsync(params).then (response) ->
      return null if response.services.length is 0
      response.services[0]

  create: (service) ->
    @log "Service.create(#{service.name})"
    params =
      desiredCount: service.nodes.desired
      taskDefinition: service.task.id
      cluster: @config.cluster
      serviceName: service.name

    @sdk.ecs.createServiceAsync(params).then (response) =>
      @log "service #{service.name} created:"
      response.service
