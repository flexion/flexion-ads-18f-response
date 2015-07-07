AWSResource = require '../aws_resource'

module.exports = class AutoScalingGroup extends AWSResource
  setup: ->
    super.then (vpcId) =>
      @config.vpc.id = vpcId

  find: ->
    @log 'VPC.find'
    params =
      MaxResults: 5
      Filters: [
        {Name: 'resource-type', Values: ['vpc']}
        {Name: 'key', Values: ['Name']}
        {Name: 'value', Values: [@config.vpc.name]}
      ]

    @sdk.ec2.describeTagsAsync(params).then (response) ->
      return null if response.Tags.length is 0
      response.Tags[0]?.ResourceId

  create: ->
    @log "VPC.create"
    params =
      CidrBlock: @config.vpc.cidr

    @sdk.ec2.createVpcAsync(params).then (response) =>
      if (id = response?.Vpc?.VpcId)?
        @log "Tagging VPC #{id} as #{@config.vpc.name}"
        tags =
          Resources: [id]
          Tags: [{
            Key: 'Name'
            Value: @config.vpc.name
          }]

        @sdk.ec2.createTagsAsync(tags).then (response) -> id
