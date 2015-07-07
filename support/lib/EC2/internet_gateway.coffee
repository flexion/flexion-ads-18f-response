AWSResource = require '../aws_resource'

module.exports = class InternetGateway extends AWSResource
  setup: ->
    super.then (id) =>
      @config.vpc.gateway = id

  find: (service) ->
    @log 'InternetGateway.find'
    params =
      Filters: [{
        Name: 'attachment.vpc-id'
        Values:  [@config.vpc.id]
      }]

    @sdk.ec2.describeInternetGatewaysAsync(params).then (response) ->
      return null if response.InternetGateways.length is 0
      response.InternetGateways[0].InternetGatewayId

  create: (service) ->
    @log 'InternetGateway.create'
    @sdk.ec2.createInternetGatewayAsync({}).then (response) =>
      id = response.InternetGateway.InternetGatewayId

      # Attach gateway to VPC
      params =
        InternetGatewayId: id
        VpcId: @config.vpc.id

      @sdk.ec2.attachInternetGatewayAsync(params).then (response) -> id
