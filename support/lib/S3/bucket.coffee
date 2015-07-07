fs = require 'fs'
AWSResource = require '../aws_resource'
JSZip = require 'jszip'

module.exports = class Bucket extends AWSResource
  find: (bucket) ->
    @log "Bucket.find(#{bucket.name})"

    @sdk.s3.listBuckets_Async().then (response) ->
      for s3bucket in response.Buckets
        return s3bucket if s3bucket.Name is bucket.name
      return null

  create: (bucket) ->
    @log "Bucket.create(#{bucket.name})"
    params =
      Bucket: bucket.name

    @sdk.s3.createBucket_Async(params).then (response) =>
      @log 'Bucket created', response.Location
      response.Location

  upload: (bucket, file) ->
    console.log "Uploading file #{file.key} to bucket #{bucket.Name}"
    content = fs.readFileSync file.path
    content = @compress content if file.compress is true

    params =
      Bucket: bucket.Name
      Key: file.key
      Body: content

    @sdk.s3.upload_Async(params).then (response) ->
      console.log 'upload complete', response.Location
      file.location = response.Location

  compress: (content) ->
    zip = new JSZip()
    zip.file 'fn.js', content
    zip.generate type: 'nodebuffer'
