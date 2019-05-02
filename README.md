# Platform Automation with Infrastructure Paving

This repo contains a [concourse](https://concourse-ci.org/) pipeline and tasks to automatically deploy [Pivotal Container Service (PKS)](https://pivotal.io/platform/pivotal-container-service) on AWS, including _optional_ paving the environment using Terraform.
This utilizes the Control Plane Concourse, which has also been paved by Terraform (see [here](https://github.com/voor/terraforming-aws/blob/large-changes/terraforming-control-plane/README.md) if you want to set that up), which securely links credentials stored in credhub.
It is using a fork of [terraforming-aws](https://github.com/voor/terraforming-aws), which modifies some behaviors for PKS and [Platform Automation](http://docs-platform-automation.cfapps.io/platform-automation/v2.0/index.html) to do so.

## Reqirements

* AWS account
* Pivotal Network account (specifically: `pivnet-api-token`)
* Private Git Repository (it's free on GitHub now!)
* three private S3 Buckets (one **needs** versioning enabled)
* Concourse (with [CredHub](https://docs.pivotal.io/p-concourse/4-x/credential-management.html#use-credhub) integration setup)
* a Route53 hosted zone on AWS (_optional_)

## Getting Started

**Start by forking this repository**; this is not a production ready repository, and you should not reference it directly in your pipelines.  There will be variables you can explicitly reference to the repositories, change those to reflect where you forked this and [terraforming-aws](https://github.com/voor/terraforming-aws) over to.

## Pave Concourse

You will need to head over to [terraforming control plane](https://github.com/voor/terraforming-aws/tree/remove-credentials-and-encourage-defaults/terraforming-control-plane) and start there.  This will get you your running Concourse, Credhub, UAA, and database all ready to go.

## Credentials

To keep it secure and easily deployable on Control Plane Concourse installation, the pipeline currently gets most of its credentials from a `credhub-secrets.yml` file and customization from a `variables.yml` file.
Copy the `credhub-secrets-template.yml` and `variables-template.yml` file to `credhub-secrets.yml` and `variables.yml`, then modify the appropriate items.

For more information on getting a running installation of Concourse properly configured with CredHub, see [Control Plane](https://github.com/voor/terraforming-aws/blob/large-changes/terraforming-control-plane/README.md)

### Adding Credentials to CredHub

Login to the `credhub` cli using the client credentials from Control Plane, then proceed to import the file:

```
credhub login -s ${CREDHUB_URL} --client-name=credhub_admin_client --client-secret=${CREDHUB_SECRET}
credhub import -f credhub-secrets.yml
```

## Deploy Pipline

```
# Login from web UI, this usually works a lot easier and is more secure anyway.
fly --target control-plane login --concourse-url ${control_plane_domain}
fly --target control-plane set-pipeline -p pcf-platform-automation -c pipeline.yml -l variables.yml --verbose
fly --target control-plane unpause-pipeline -p pcf-platform-automation
```
