AWSResource = require '../aws_resource'

module.exports = class TaskDefinition extends AWSResource
  find: (task) ->
    @log "TaskDefinition.find(#{task.name})"
    Promise.resolve()

  create: (task) ->
    console.log "TaskDefinition.create(#{task.name})"
    params =
      containerDefinitions: task.config
      family: task.name

    @sdk.ecs.registerTaskDefinitionAsync(params).then (response) =>
      if (taskDef = response.taskDefinition)?
        @log "TaskDefinition registered."
        task.id = "#{taskDef.family}:#{taskDef.revision}"
        taskDef
