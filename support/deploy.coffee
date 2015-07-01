ECSDeploy = require './lib/ecs_deploy'
path = require 'path'

config =
  templatesDir: path.join "#{path.resolve __dirname}", 'templates'
  region: 'us-east-1'
  cluster: 'flexion-18f'
  vpc:
    name: 'flexion-18f'
    cidr: '10.10.0.0/16'
  subnet:
    name: 'flexion-18f-subnet1'
    cidr: '10.10.1.0/24'
  services: [
    {
      name: 'node-server'
      nodes:
        # ami: 'ami-e1c33f8a'
        # instanceType: 't2.small'
        # min: 1
        # desired: 1
        max: 10
        ELB:
          config:
            Listeners: [{
              InstancePort: 80
              LoadBalancerPort: 80
              # TODO: Add SSL support
              Protocol: 'HTTP'
              InstanceProtocol: 'HTTP'
            }]
    }

    {
      name: 'nginx-static'
      nodes:
        ELB:
          config:
            Listeners: [{
              InstancePort: 80
              LoadBalancerPort: 80
              Protocol: 'HTTP'
              InstanceProtocol: 'HTTP'
            }]
    }

    {
      name: 'logstash'
      nodes:
        max: 1
    }
  ]



do (ecs = new ECSDeploy(config), services = []) ->
  # Remove this if the following environment variables are set:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN (optional)
  ecs.authenticate('deploy').fromProfile()

  ecs.initialize()

  ecs.deploy().then (config) ->
    console.log 'ECS deployment completed'
    # fs.writeFileSync 'deployment.json', JSON.stringify(ecs.config, null, 2)
