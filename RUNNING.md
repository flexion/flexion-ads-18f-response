# Installing and running this project
## Introduction
There are several methods for installing and running this project on your own or a hosted machine.  This document describes three: a lightweight local method using the grunt runner, using Docker locally and finally using an automated provisioning process to Amazon EC2.

## Dev Setup - Quickstart
This section describes a quick process for getting the project running in a local environment.  You will need git, [npm](https://www.npmjs.com) (node package manager) and [bower](http://bower.io) (a tool for package management) to get started.  Platform-specific instructions for installing those tools can be found at their.  The grunt task runner will be automatically installed as a part of the npm and bower provisioningprocess.  With those tools installed, the steps to get the project running locally are:
 
```
git clone https://github.com/flexion/flexion-ads-18f-response.git
git checkout develop
git pull
npm install
bower install
grunt serve
```

This should initiate a running copy of the project on port 9000, and on some environments spawn a browser pointing at the site.

## Running locally with Docker
To run the app locally in a [Docker](https://www.docker.com) container you will need a local installation of Docker. Depending on your platform this may be native or may require you to use a solution like Boot2Docker.

With Docker installed, obtain a copy of the project and run the following:
```
git clone https://github.com/flexion/flexion-ads-18f-response.git
git checkout develop
git pull
docker build -t flexion-18f .
```
This will download the required dependencies and build a docker image from the project's Dockerfile.  You can then run the following to create a running container:
```
docker run -d -p 127.0.0.1:9000:9000 -i --name flexion-18f flexion-18f 
docker run -d -p 127.0.0.1:80:80 -i --name flexion-18f flexion-18f 
```
If necessary you may need to map some ports to expose the running application.

## Provisioning an Amazon EC2 instance

### Prerequisites:

* IAM user 'deploy' with all access rights (needs to create VPC, gateway, etc.)
* ECS key pair named 'AWS Eastern'

### Setup:

* Create ``~/.aws/credentials`` with IAM user's key id & secret

```
[deploy]
aws_access_key_id = blah
aws_secret_access_key = blah
```

* Run ``coffee support/deploy.coffee``

This creates necessary infrastructure templates that CloudFormation uses to create resources. You will run into an error creating the S3 bucket if your bucket name overlaps with any other S3 bucket in any organization, globally ... pick something unique. // TODO: indicate where to change.
* In AWS -> CloudFormation, create two stacks, cf_base (creates network infrastructure) and cf_node_server (creates deployment)

*Note:* You will run into errors if you are at the AWS limit of VPCs or Internet gateways in your organization. Either request an increase or delete at least one of each. 

Create cf_base and let it finish before creating cf_node_server. When both stacks have setup successfully, the containers will be running and the associated ELB address will be serving the site. Create a CNAME in your DNS to point at the ELB and you're done!

### Updating:

Until this is automated, the process of updating the site involves updating the task definition in ECS to point to a new version in Docker Hub.

* Access AWS ECS -> Task Definitions
* Select the definition for the cluster (will be marked ACTIVE)
* Create new revision
* JSON -> edit ``image:`` to point to the new version, e.g.: ``user/repo:v_98`` => ``user/repo:v_102``
 * *Note:* This depends on your ``docker push`` creating versioned tags when you publish your container.
* => Create
* Navigate to the Service in your cluster, select => update and set the number of tasks to 0 to remove the old version
* => Update Service
* Select the service => update and set the number of tasks to 1 (or higher) to setup the new version
* => Update Service

Once ECS has cycled through and started the new revised task definition, the ELB will update to point at the new container instance and be available - this typically takes a couple minutes.

