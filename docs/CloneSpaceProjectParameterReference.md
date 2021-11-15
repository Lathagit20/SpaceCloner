# CloneSpaceProject.ps1 Parameter Reference

`CloneSpaceProject.ps1` is a script which uses a reverse lookup to determine all the items to clone.  `CloneSpace.ps1` expects you to know all the items (environments, step templates, variable sets, etc.) associated with a project.  `CloneSpaceProject.ps1` was written with the assumption you don't know all the ins and outs of a project.  It will look at the list of projects you provide it and determine what are all the items required for a clone to work.  It will then call the `CloneSpace.ps1` at the end with all the parameters filled out for you.

The script `CloneSpaceProject.ps1` accepts the following parameters.

## Source Information
- `SourceOctopusUrl`: the base URL of the source Octopus Server.  For example, https://samples.octopus.app.  This can be the same as the destination.
- `SourceOctopusApiKey`: the API key to access the source Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  That service account user must have read permissions.
- `SourceSpaceName`: the name of the space you wish to copy from.

## Destination Information
- `DestinationOctopusUrl`: the base URL of the destination Octopus Server. For example, https://codeaperture.octopus.app.  This can be the same as the source.
- `DestinationOctopusApiKey`: the API key to access the destination Octopus Server.  Recommend using the API key of a [service account](https://octopus.com/docs/security/users-and-teams/service-accounts) user.  Recommend that the service account has `Space Manager` permissions.
- `DestinationSpaceName`: the name of the space you wish to copy to.

## Items To Clone

All the items to clone parameters allow for the following filters:
- `all`: special keyword which will clone everything
- Wildcards: use AWS* to pull in all items starting with AWS
- Specific item names: pass in specific item names to clone that item and only that item

You can provide a comma-separated list of items.  For example, setting the `VariableSetsToClone` to "AWS*,Global,Notification" will clone all variable sets which start with AWS, along with the global and notification variable sets.  

You must specify items to clone.  By default, nothing is cloned.  If you wish to skip an item, you can exclude it from the parameter list OR set the value to an empty string "".  

- `ProjectsToClone`: The list of projects to clone.
- `CertificatesToClone`: The list of certificates to clone.  No support for `all` or wildcards.  Format: `[CertificateName1]::[Password01],[CertificateName2]::[Password02]`, for example `MyCert::Password!`.  

## Items to Exclude / Include

The list of items to include might be longer than a list to exclude.  On the flip side of that, the list of items to exclude might be longer than the list of items to include.  You can provide either or parameters.

**Please Note**: You cannot have both a exclude and include parameter specified.  You have to pick to include or exclude items (or leave it alone.)

All the items to exclude / include parameters allow for the following filters:
- `all`: special keyword which will clone everything
- Wildcards: use AWS* to pull in all items starting with AWS
- Specific item names: pass in specific item names to clone that item and only that item

Environments
- `EnvironmentsToInclude`: The list of environments to include from this clone. The default is `all`.
- `EnvironmentsToExclude`: The list of environments to exclude from this clone. The default is `$null`.

Workers
- `WorkersToInclude`: The list of workers to include from this clone. The default is `all`.
- `WorkersToExclude`: The list of workers to exclude from this clone. The default is `$null`.

Targets
- `TargetsToInclude`: The list of targets to include from this clone. The default is `all`.
- `TargetsToExclude`: The list of targets to exclude from this clone. The default is `$null`.

Tenants
- `TenantsToInclude`: The list of tenants to include from this clone. The default is `all`.
- `TenantsToExclude`: The list of tenants to exclude from this clone. The default is `$null`.

Channels
- `ChannelsToInclude`: The list of channels to include from this clone. The default is `all`.
- `ChannelsToExclude`: The list of channels to exclude from this clone. The default is `$null`.

## Scoping Match Options

Imagine if your source instance had the environments `Development` and `Test` while the destination only had `Production`.  You have a step scoped to only run on `Development`.  When that step is cloned over what should it do?

You can have variables, deployment process steps, or infrastructure items (workers, accounts, targets), scoped to a variety of items.  The scope matching options tell the space cloner how to handle when a mismatch like this occurs.  The options are:

- `ErrorUnlessExactMatch`: An **Error** will be thrown unless an exact match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` AND `Test`.
- `SkipUnlessExactMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless an exact match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` AND `Test`.
- `ErrorUnlessPartialMatch`: An **Error** will be thrown unless a partial match on the scoping is found.  For example, the source has `Development` and `Test`, an error will be thrown unless the destination has `Development` OR `Test`.
- `SkipUnlessPartialMatch`: The item (variable, account, step, etc.) will be excluded or skipped unless a partial match is found. For example, the source has `Development` and `Test`, the item will be skipped unless `Development` OR `Test`.
- `IgnoreMismatch`: The item will be cloned regardless of matching.
- `IgnoreMismatchOnNewLeaveExistingAlone`: The item will be cloned when it is new and scoping doesn't match.  Otherwise it will leave that already exists alone.

The process scoping parameters are:
- `ProcessEnvironmentScopingMatch`: How to handle when a step in a deployment or runbook process is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `ProcessChannelScopingMatch`: How to handle when a step in a deployment or runbook process is scoped to to 1 to N Channels in the source but not all Channels are in the destination.  Default is `SkipUnlessPartialMatch`.
- `ProcessTenantTagsScopingMatch`: How to handle when a step in a deployment or runbook process is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.

The variable scoping parameters are:
- `VariableChannelScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Channels in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableEnvironmentScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableProcessOwnerScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment or Runbooks in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableActionScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment Steps in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableMachineScopingMatch`: How to handle when a variable in a project or library variable set is scoped to 1 to N Deployment Targets in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableTenantTagsScopingMatch`: How to handle when a step in a project or library variabe set is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableAccountScopingMatch`: How to handle when a variable in a project or library variable set is scoped to an Account in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableCertificateScopingMatch`: How to handle when a variable in a project or library variable set is scoped to an Certificate in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.

The infrastructure scoping parameters are:
- `InfrastructureEnvironmentScopingMatch`: How to handle when a Deployment Target or Account is scoped to 1 to N Environments in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `InfrastructureTenantScopingMatch`: How to handle when a Deployment Target or Account is scoped to 1 to N Tenants in the source but not all environments are in the destination.  Default is `SkipUnlessPartialMatch`.
- `VariableTenantTagsScopingMatch`: How to handle when a Deployment Target or Account is scoped to to 1 to N Tenant Tags in the source but not all Tenant Tags are in the destination.  Default is `SkipUnlessPartialMatch`.

See more how this works in the [how matching works page](HowMatchingWorks.md).

## Options

The values for these options are either `True`, `False` or `null`.  Null will cause the default parameter to be used.

- `OverwriteExistingCustomStepTemplates`: Indicates if existing custom step templates (not community step templates) should be overwritten.  Useful when you make a change to a step template, you want to move over to another instance.  Defaults to `false`.
- `OverwriteExistingLifecyclesPhases`: Indicates you want to overwrite the phases on existing lifecycles.  This is useful when you have an updated lifecycle you want to be applied another space/instance.  You will want to leave this to false if the destination lifecycle has different phases.  The default is `false`.
- `OverwriteExistingVariables`: Indicates if all existing variables (except sensitive variables) should be overwritten.  The default is `false`.  Options are `true`, `false`, or `AddNewWithDefaultValue`. See more how this works in the [how matching works page](HowMatchingWorks.md).
- `CloneProjectChannelRules`: Indicates if the project channel rules should be cloned and overwrite existing channel rules.  The default is `false`.
- `CloneProjectDeploymentProcess`: Indicates if the project deployment process should be cloned.  Set this to `false` to only clone project runbooks.  The default is `true`.
- `CloneProjectRunbooks`: Indicates if project runbooks should be cloned.  Set this to `false` to only clone the project deployment process.  The default is `true`.
- `CloneProjectVersioningReleaseCreationSettings`: Indicates if the same versioning rules will be applied to the project.  The default is `false`.
- `ClonePackages`: Indicates if any packages should be cloned.  Set this to `false` to skip cloning packages.  The defualt is `true`.
- `CloneTeamUserRoleScoping`: Indicates if the space teams should have their scoping cloned.  Will use the same teams based on parameter `SpaceTeamsToClone`.  The default is`false`.
- `CloneTenantVariables`: Indicates if tenant variables should be cloned.  The default is`false`.
- `IgnoreVersionCheckResult`: Indicates if the script should ignore version checks rules and proceed with the clone.  This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `SkipPausingWhenIgnoringVersionCheckResult`: When `IgnoreVersionCheckResult` is set to true the script will pause for 20 seconds when it detects a difference to let you cancel.  You can skip that check by setting this to `true`. This should only be used for cloning to test instances of Octopus Deploy.  The default is `false`.
- `ProcessCloningOption`: Tells the cloner how to handle the situation where steps are in a destination runbook or deployment process but not in the source.  Options are `KeepAdditionalDestinationSteps` or `SourceOnly`.  The default is `KeepAdditionalDestinationSteps`. See more how this works in the [how matching works page](HowMatchingWorks.md).
- `WhatIf`: Set to `$true` if you want to see everything this script will do without it actually doing the work.  Set to `$false` to have it do the work.  Defaults to `$false`.