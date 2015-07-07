AWSResource = require '../aws_resource'

module.exports = class Subnet extends AWSResource
  setup: ->
    super.then (id) =>
      @config.subnet.id = id

  find: (service) ->
    @log 'Subnet.find'
    params =
      Filters: [{
        Name: 'vpc-id'
        Values: [@config.vpc.id]
      }]

    @sdk.ec2.describeSubnetsAsync(params).then (response) ->
      return null if response.Subnets.length is 0
      response.Subnets[0].SubnetId

  create: (service) ->
    @log 'Subnet.create'
    params =
      CidrBlock: @config.subnet.cidr
      VpcId: @config.vpc.id

    @sdk.ec2.createSubnetAsync(params).then (response) =>
      if (id = response?.Subnet?.SubnetId)?
        @log "Tagging subnet #{id}"

        tags =
          Resources: [id]
          Tags: [{
            Key: 'Name'
            Value: @config.subnet.name
          }]

        @sdk.ec2.createTagsAsync(tags).then (response) -> id
