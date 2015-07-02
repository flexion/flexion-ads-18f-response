path = require 'path'
fs = require 'fs'
_ = require 'lodash'
SDK = require 'aws-sdk'
Promise = require 'bluebird'

camelize = (str) ->
  RE = /\_([a-zA-Z])/g
  str.replace RE, (substr, match) ->
    match?.toUpperCase() or ''

capitalize = (str) -> str.charAt(0).toUpperCase() + str.slice 1

module.exports = class AWSHelper
  constructor: (@config = {}) ->
    root = path.resolve(__dirname)
    excludes = ['aws', 'aws_resource', 'ecs_deploy']
    id = capitalize camelize path.basename root

    @sdk = @promisifySDK()
    deps = @importTree {}, root, excludes
    _.extend this, deps[id]

  promisifySDK: ->
    out = {}
    opts = {suffix: "_Async"}

    apis = [
      'ECS'
      'ELB'
      'Route53'
      'EC2'
      'AutoScaling'
      'Lambda'
      'CloudFormation'
      'S3'
    ]

    for api in apis
      out[api.toLowerCase()] = new Promise.promisifyAll new SDK[api](), opts

    out

  importTree: (tree, filename, excludes) ->
    basename = path.basename filename, '.coffee'
    key = capitalize camelize basename
    return if basename in excludes

    if fs.statSync(filename).isFile()
      klass = require(filename)
      tree[key] = new klass(@config, @sdk)
    else
      tree[key] = {}

      for node in fs.readdirSync(filename)
        @importTree tree[key], path.join(filename, node), excludes

    tree
