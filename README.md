# powershell-azfunc-app

# staging_config
Because there is no Approval Gateway similar to Azure DevOps [Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops), I am using this branch as an approval gateway.

As I'd rather use trunk based development, this branch is solely for containing staging configuration files and triggering an on PR of this branch.

You'll see this branch does not contain any history of the master branch.

Instead, there only exists configuration files for the infrastructure of the staging environment:
1. stage.tfvars
1. buildRef.json
1. appName.json
1. .github\CODEOWNERS               #todo
1. .github\workflows\cd_stage.yml
1. etc

## Improvements to automate
> Creating buildRef.json can later be automated. There can a be post workflow after deploy to dev where the worfklow does the steps pseudo described below:
1. git checkout stage_config
1. git checkout -b stage_config/auto-pr-<github.sha>
1. cat '{"sha": "<github.sha"> }'
1. git commit -am "auto from <github.runId>"
1. git push upstream
1. create PR

## Manual
As the Create PR from the Workflow Continuous Deployment on Dev is not automated, the manual workflow will be as follows:
1. Once CI and CD have ran on dev for the commit hash you'd like to move to stage, create a PR
1. In the pr, update buildRef.json. You can replace buildRef.json by downloading the [pipeline artifact](https://github.com/jontreynes/powershell-azfunc-app/actions?query=workflow%3A%22Continuous+Integration%22) from the CI Build Artifact named ref-build-package

# Note:
If you need to roll back to a previous build artifact, you may do that by updating the buildRef.json
