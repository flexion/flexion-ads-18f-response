#!/bin/bash
yum install -y aws-cli
aws s3 cp s3://<%= config.bucket %>/<%= service.name %>.config /etc/ecs/ecs.config
