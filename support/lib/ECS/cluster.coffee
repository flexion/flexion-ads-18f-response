AWSResource = require '../aws_resource'

module.exports = class Cluster extends AWSResource
  find: (service) ->
    @log "Cluster.find"
    params = clusters: [@config.cluster]

    @sdk.ecs.describeClustersAsync(params).then (response) ->
      return null if response.clusters.length is 0
      response.clusters[0]

  create: (service) ->
    @log "Cluster.create"
    params = clusterName: "#{@config.cluster}"

    @sdk.ecs.createClusterAsync(params).then (response) =>
      @log 'Cluster created:'
      response.cluster
