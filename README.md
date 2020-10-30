# powershell-azfunc-app
For testing CI/CD for an Azure function app using Github Actions and Terraform

Because there is no Approval Gateway similar to Azure DevOps [Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops), I am using branches as an approval gateway.

As I'd rather use trunk based development, the branches that deploy promotion to higher environments is solely for containing environment configuration files and triggering an on PR of the branch.

You'll see the stage_config branch does not contain any history of the master branch.

Please see [stage_config](https://github.com/jontreynes/powershell-azfunc-app/tree/stage_config) for more information.