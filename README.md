# pcf-automation-aws-paving

This repo contains a concourse pipeline and tasks to automatically deploy Pivotal Container Service on AWS, including paving the environment using Terraform.
This utilizes the Control Plane Terraform Concourse, which securely links credentials stored in credhub.
It is using a fork of [terraforming-aws](https://github.com/voor/terraforming-aws), which modifies some behaviors for PKS and [Platform Automation](http://docs-platform-automation.cfapps.io/platform-automation/v2.0/index.html) to do so.

# Reqirements

* AWS account
* Pivotal Network account
* Private Git Repository
* three private S3 Buckets
* concourse
* a Route53 hosted zone on AWS

# Credentials

To keep it secure and easily deployable on Control Plane Concourse installation, the pipeline currently gets most of its credentials from a `credhub-secrets.yml` file and customization from a `variables.yml` file.
Copy the `credhub-secrets-template.yml` and `variables-template.yml` file to `credhub-secrets.yml` and `variables.yml`, then modify the appropriate items.

For more information on getting a running installation of Concourse properly configured with CredHub, see [Control Plane](https://github.com/voor/terraforming-aws/blob/large-changes/terraforming-control-plane/README.md)

## Adding Credentials to CredHub

Login to the `credhub` cli using the client credentials from Control Plane, then proceed to import the file:

```
credhub login --client-name=concourse_to_credhub --client-secret=${CONCOURSE_TO_CREDHUB_CLIENT_SECRET}
...
```

# Deploy Pipline

```
# Login from web UI, this usually works a lot easier and is more secure anyway.
fly --target control-plane login --concourse-url ${control_plane_domain}
fly --target control-plane set-pipeline -p pcf-platform-automation -c pipeline.yml -l variables.yml --verbose
fly --target control-plane unpause-pipeline -p pcf-platform-automation
```
