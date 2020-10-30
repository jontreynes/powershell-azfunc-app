# powershell-azfunc-app

# staging_config
Because there is no Approval Gateway similar to Azure DevOps [Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops), I am using this branch as an approval gateway.

As I'd rather use trunk based development, this branch is solely for containing staging configuration files and triggering an on PR of this branch.

You'll see this branch does not contain any history of the master branch.

Instead, there only exists configuration files for the infrastructure of the staging environment:
    stage.tfvars
    buildRef.json

> Creating buildRef.json can later be automated. There can a be post workflow after deploy to dev where the worfklow does the steps pseudo described below:
1. git checkout stage_config
1. git checkout -b stage_config/auto-pr-<github.sha>
1. cat '{"sha": "<github.sha"> }'
1. git commit -am "auto from <github.runId>"
1. git push upstream
1. create PR
