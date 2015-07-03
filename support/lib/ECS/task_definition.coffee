_ = require 'lodash'
AWSResource = require '../aws_resource'

module.exports = class TaskDefinition extends AWSResource
  find: (id) ->
    @log "TaskDefinition.find(#{id})"
    params =
      taskDefinition: id

    @sdk.ecs.describeTaskDefinition_Async(params).then (response) ->
      response.taskDefinition


  create: (task) ->
    params = _.pick task, ['containerDefinitions', 'family', 'volumes']
    console.log "TaskDefinition.create()", params

    @sdk.ecs.registerTaskDefinition_Async(params).then (response) =>
      if (taskDef = response.taskDefinition)?
        @log "TaskDefinition registered."
        task.id = "#{taskDef.family}:#{taskDef.revision}"
        taskDef
