_ = require 'lodash'
fs = require 'fs'
path = require 'path'
AWSResource = require '../aws_resource'

module.exports = class LaunchConfiguration extends AWSResource
  setup: (service) ->
    super.then (launchConfig) ->
      service.nodes.launchConfig = launchConfig

  find: (service) ->
    @log "LaunchConfiguration.find(#{service.name})"
    params =
      LaunchConfigurationNames: ["#{@config.cluster}-launch-#{service.name}"]

    @sdk.autoscaling.describeLaunchConfigurationsAsync(params).then (response) =>
      return null if response.LaunchConfigurations.length is 0
      @log "LaunchConfig found"
      response.LaunchConfigurations[0]

  create: (service) ->
    @log "LaunchConfiguration.create(#{service.name})"
    @extractUserData(service).then (userData) =>
      params =
        LaunchConfigurationName: "#{@config.cluster}-launch-#{service.name}"
        ImageId: service.nodes.ami
        UserData: userData
        InstanceType: service.nodes.instanceType
        InstanceMonitoring: {Enabled: false}

      @sdk.autoscaling.createLaunchConfigurationAsync(params).then (response) =>
        @log "LaunchConfig created."
        @find service

  extractUserData: (service) ->
    @log "LaunchConfiguration.extractUserData(#{service.name})"
    new Promise (resolve, reject) =>
      tpl = path.join @config.templatesDir,
        'launch_configs',
        "#{service.name}.template"

      payload =
        config: @config
        env: process.env

      out = _.template fs.readFileSync(tpl), payload
      resolve new Buffer(out).toString 'base64'
