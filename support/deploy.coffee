ECSDeploy = require './lib/ecs_deploy'
path = require 'path'

config =
  resources: resources = path.join "#{path.resolve __dirname}", 'resources'

  region: 'us-east-1'

  S3:
    bucket:
      name: 'flexion-18f-deployment-assets'

    files: files =
      cf_base:
        key: "cf_base.template"
        path: "#{resources}/cf_base.json"
      cf_server:
        key: "cf_node_server.template"
        path: "#{resources}/cf_node_server.json"
      cf_lambda:
        compress: true
        key: "cf_lookup_lambda.zip"
        path: "#{resources}/cf_lookup_lambda.js"

  Stacks: [
    {name: 'flexion-18f-network', file: files.cf_base},
    {name: 'flexion-18f-app-server', file: files.cf_server}
  ]

do (ecs = new ECSDeploy(config), services = []) ->
  # Remove this if the following environment variables are set:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN (optional)
  ecs.authenticate('deploy').fromProfile()

  ecs.initialize()

  ecs.deploy().then (config) ->
    console.log 'ECS deployment completed'
    # fs.writeFileSync 'deployment.json', JSON.stringify(ecs.config, null, 2)
