function Copy-OctopusProcessStepAction
{
    param(
        $sourceAction,
        $sourceChannelList,
        $destinationChannelList,
        $matchingAction,
        $sourceData,
        $destinationData,
        $CloneScriptOptions
    )            

    $action = Copy-OctopusObject -ItemToCopy $sourceAction -ClearIdValue $true -SpaceId $null   

    Write-OctopusChangeLog "          - ActionType: $($action.ActionType)"
    Write-OctopusChangeLog "          - IsDisabled: $($action.IsDisabled)"
    Write-OctopusChangeLog "          - IsRequired: $($action.IsRequired)"
    Write-OctopusChangeLog "          - Run Condition: $($action.Condition)" 
    
    $canProceed = Convert-OctopusActionEnvironmentScoping -action $action -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -matchingAction $matchingAction
    if ($canProceed -eq $false)
    {
        return $null
    }

    $canProceed = Convert-OctopusActionChannelScoping -action $action -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -matchingAction $matchingAction
    if ($canProceed -eq $false)
    {
        return $null
    }

    $canProceed = Convert-OctopusActionTenantTagScoping -action $action -sourceData $sourceData -destinationData $destinationData -CloneScriptOptions $CloneScriptOptions -matchingAction $matchingAction
    if ($canProceed -eq $false)
    {
        return $null
    }   
    
    Convert-OctopusProcessActionWorkerPoolId -action $action -sourceData $sourceData -destinationData $destinationData                
    Convert-OctopusProcessActionExecutionContainerFeedId -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusProcessActionStepTemplate -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusProcessActionManualIntervention -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusProcessActionFeedId -action $action -sourceData $sourceData -destinationData $destinationData  
    Convert-OctopusPackageList -item $action -sourceData $sourceData -destinationData $destinationData          
    Convert-OctopusSinglePackageProprty -action $action -sourceData $sourceData -destinationData $destinationData
    Convert-OctopusActionIdsForMatchingActionId -action $action -matchingAction $matchingAction   
    Convert-OctopusDeployAReleaseStep -action $action -sourceData $sourceData -destinationData $destinationData    
    
    Write-OctopusPackagesToChangeLog -action $action -destinationData $destinationData

    return $action    
}

function Convert-OctopusActionEnvironmentScoping
{
    param (
        $action,
        $sourceData,
        $destinationData,
        $CloneScriptOptions,        
        $matchingAction
    )

    if ($null -ne $matchingAction -and $CloneScriptOptions.ProcessEnvironmentScopingMatch.ToLower().Trim() -eq "ignoremismatchonnewleaveexistingalone")
    {
        $action.Environments = @($matchingAction.Environments)
        Write-OctopusChangeLog "          - Environment Scoping: Left Alone"
        $action.ExcludedEnvironments = @($matchingAction.ExcludedEnvironments)
        Write-OctopusChangeLog "          - Excluded Environment Scoping: Left Alone"
    }
    else
    {        
        $environmentMatch = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $action.Environments -MatchingOption $CloneScriptOptions.ProcessEnvironmentScopingMatch -IdListName "$($Action.Name) Environment Scoping"
        if ($environmentMatch.CanProceed -eq $false)
        {
            return $false
        }

        $action.Environments = @($environmentMatch.NewIdList)
        Write-OctopusChangeLogListDetails -idList $action.Environments -destinationList $DestinationData.EnvironmentList -listType "Environments" -prefixSpaces "         "
        
        $excludeEnvironmentMatch = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.EnvironmentList -DestinationList $DestinationData.EnvironmentList -IdList $action.ExcludedEnvironments -MatchingOption $CloneScriptOptions.ProcessEnvironmentScopingMatch -IdListName "$($Action.Name) Exclude Environment Scoping"
        if ($excludeEnvironmentMatch.CanProceed -eq $false)
        {
            return $false
        }

        $action.ExcludedEnvironments = @($excludeEnvironmentMatch.NewIdList)
        Write-OctopusChangeLogListDetails -idList $action.ExcludedEnvironments -destinationList $DestinationData.EnvironmentList -listType "Excluded Environments" -prefixSpaces "         "
    }

    return $true
}

function Convert-OctopusActionChannelScoping
{
    param (
        $action,
        $sourceData,
        $destinationData,
        $CloneScriptOptions,        
        $matchingAction
    )

    if ($null -ne $matchingAction -and $CloneScriptOptions.ProcessChannelScopingMatch.ToLower().Trim() -eq "ignoremismatchonnewleaveexistingalone")
    {
        $action.Channels = @($matchingAction.Channels)
        Write-OctopusChangeLog "          - Channel Scoping: Left Alone"        
    }
    else
    {        
        $channelMatch = Convert-SourceIdListToDestinationIdList -SourceList $SourceChannelList -DestinationList $destinationChannelList -IdList $action.Channels -MatchingOption $CloneScriptOptions.ProcessChannelScopingMatch -IdListName "$($Action.Name) Channel Scoping"
        if ($channelMatch.CanProceed -eq $false)
        {
            return $false
        }

        $action.Channels = @($channelMatch.NewIdList)
        Write-OctopusChangeLogListDetails -idList $action.Channels -destinationList $destinationChannelList -listType "Channels" -prefixSpaces "         "
    }

    return $true
}

function Convert-OctopusActionTenantTagScoping
{
    param (
        $action,
        $sourceData,
        $destinationData,
        $CloneScriptOptions,        
        $matchingAction
    )
    
    if ($null -ne $matchingAction -and $CloneScriptOptions.ProcessTenantTagScopingMatch.ToLower().Trim() -eq "ignoremismatchonnewleaveexistingalone")
    {
        $action.TenantTags = @($matchingAction.TenantTags)
        Write-OctopusChangeLog "          - Tenant Tag Scoping: Left Alone"        
    }
    else
    {        
        $tenantTagMatch = Convert-SourceTenantTagListToDestinationTenantTagList -tenantTagListToConvert $action.TenantTags -destinationDataTenantTagSets $destinationData.TenantTagList -matchingOption $CloneScriptOptions.ProcessTenantTagScopingMatch
        if ($tenantTagMatch.CanProceed -eq $false)
        {
            return $False
        }

        $action.TenantTags = @($tenantTagMatch.NewIdList)
        Write-OctopusChangeLogListDetails -idList $action.TenantTags -destinationList $DestinationData.TenantTags -listType "Tenant Tags" -prefixSpaces "         " -skipNameConversion $true
    }    

    return $true
}

function Convert-OctopusProcessActionWorkerPoolId
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if ((Test-OctopusObjectHasProperty -objectToTest $action -propertyName "WorkerPoolId"))
    {
        if ($null -ne $action.WorkerPoolId)
        {
            $action.WorkerPoolId = Convert-SourceIdToDestinationId -SourceList $SourceData.WorkerPoolList -DestinationList $DestinationData.WorkerPoolList -IdValue $action.WorkerPoolId -ItemName "$($action.Name) Worker Pool" -MatchingOption "ErrorUnlessExactMatch"                    
            Write-OctopusChangeLogListDetails -idList @($action.WorkerPoolId) -destinationList $DestinationData.WorkerPoolList -listType "Worker Pool Id" -prefixSpaces "         "
        }
    }
}

function Convert-OctopusProcessActionExecutionContainerFeedId
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if ((Test-OctopusObjectHasProperty -objectToTest $action -propertyName "Container"))
    {
        if ($null -ne $action.Container.FeedId)
        {
            $action.Container.FeedId = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $action.Container.FeedId -ItemName "$($action.Name) Execution Container Feed" -MatchingOption "ErrorUnlessExactMatch"           
            Write-OctopusChangeLogListDetails -idList @($action.Container.Image) -destinationList $DestinationData.FeedList -listType "Container Image Feed" -prefixSpaces "         " -skipNameConversion $true            
        }
    }
}

function Convert-OctopusProcessActionStepTemplate
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Template.Id")
    {      
        $action.Properties.'Octopus.Action.Template.Id' = Convert-SourceIdToDestinationId -SourceList $sourceData.StepTemplates -DestinationList $destinationData.StepTemplates -IdValue $action.Properties.'Octopus.Action.Template.Id'  -ItemName "$($action.Name) Step Template" -MatchingOption "ErrorUnlessExactMatch"

        if ($null -ne $action.Properties.'Octopus.Action.Template.Id')                                  
        {            
            Write-OctopusChangeLogListDetails -idList @($action.Properties.'Octopus.Action.Template.Id') -destinationList $DestinationData.StepTemplates -listType "Step Template" -prefixSpaces "         "
        }        
        
        $stepTemplate = Get-OctopusItemById -ItemList $destinationData.StepTemplates -ItemId $action.Properties.'Octopus.Action.Template.Id'
        $action.Properties.'Octopus.Action.Template.Version' = $stepTemplate.Version

        foreach ($parameter in $stepTemplate.Parameters)
        {                                
            if ((Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName $parameter.Name))
            {
                $controlType = $parameter.DisplaySettings.'Octopus.ControlType'
                Write-OctopusVerbose "$($parameter.Name) is control type is $controlType"
                
                if ($controlType -eq "Package")
                {
                    $feedInformation = $action.Properties.$($parameter.Name) | ConvertFrom-Json
                    $feedInformation.FeedId = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $feedInformation.FeedId -ItemName "$($action.Name) Package Parameter" -MatchingOption "ErrorUnlessExactMatch"

                    $action.Properties.$($parameter.Name) = $feedInformation | ConvertTo-Json
                }    
                elseif ($controlType -eq "Sensitive")            
                {
                    if ((Test-OctopusObjectHasProperty -objectToTest $action.Properties.$($parameter.Name) -propertyName "HasValue"))
                    {
                        Write-OctopusPostCloneCleanUp "Set $($parameter.Name) in $($action.Name) to Dummy Value"
                        $action.Properties.$($parameter.Name).NewValue = "DUMMY VALUE"
                        $action.Properties.$($parameter.Name).HasValue = $true
                    }                    
                }
            }            
        }
    }
}

function Convert-OctopusProcessActionManualIntervention
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Manual.ResponsibleTeamIds")
    {
        $manualInterventionSourceTeamIds = @($action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' -split ",")
        $manualInterventionDestinationTeamIds = Convert-SourceIdListToDestinationIdList -SourceList $SourceData.TeamList -DestinationList $DestinationData.TeamList -IdList $manualInterventionSourceTeamIds -MatchingOption "IgnoreMismatch" -IdListName "$($Action.Name) Manual Intervention Teams"

        $newTeamIds = @($manualInterventionDestinationTeamIds.NewIdList)
        if ($newTeamIds.Count -eq 0)
        {
            Write-OctopusPostCloneCleanUp "Unable to find matching teams for $($action.Name), converting responsible team to built in team 'team-managers'"                                        
            $action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' = "team-managers"
        }
        else
        {
            $action.Properties.'Octopus.Action.Manual.ResponsibleTeamIds' = ($newTeamIds -join ",")
        } 
                        
        Write-OctopusChangeLogListDetails -idList $newTeamIds -destinationList $DestinationData.TeamList -listType "Manual Intervention Teams" -prefixSpaces "         "
    }
}

function Convert-OctopusProcessActionFeedId
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.Package.FeedId")
    {
        $action.Properties.'Octopus.Action.Package.FeedId' = Convert-SourceIdToDestinationId -SourceList $sourceData.FeedList -DestinationList $destinationData.FeedList -IdValue $action.Properties.'Octopus.Action.Package.FeedId' -ItemName "$($action.Name) Feed Id" -MatchingOption "ErrorUnlessExactMatch"
        Write-OctopusChangeLogListDetails -idList @($action.Properties.'Octopus.Action.Package.FeedId') -destinationList $DestinationData.FeedList -listType "Package Feed" -prefixSpaces "         "
        $packageId = $action.Properties.'Octopus.Action.Package.PackageId'
        Write-OctopusChangeLog "            - $packageId"
    }
}

function Convert-OctopusSinglePackageProprty
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    $actionScriptTypes = Get-OctopusScriptActionTypes

    if ($action.Packages.Count -eq 1 -and $actionScriptTypes -notcontains $action.ActionType)
    {
        $added = Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.Package.FeedId" -propertyValue $action.Packages[0].FeedId
        $added = Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.Package.PackageId" -propertyValue $action.Packages[0].PackageId
        $added = Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.Package.DownloadOnTentacle" -propertyValue "False"
    }
}

function Convert-OctopusActionIdsForMatchingActionId
{
    param(
        $action,
        $matchingAction
    )

    if ($null -ne $matchingAction)
    {
        Write-OctopusVerbose "The action $($action.Name) already exists, updating the Id"
        $action.Id = $matchingAction.Id

        Write-OctopusVerbose "Ensuring all the existing packages have Ids"
        foreach ($package in $action.Packages)    
        {
            foreach ($matchingActionPackage in $matchingAction.Packages)
            {
                if ($package.PackageId -eq $matchingActionPackage.PackageId)
                {
                    $packageHasNameProperty = Test-OctopusObjectHasProperty -objectToTest $package -propertyName "Name"

                    if ($packageHasNameProperty -eq $false -or ($packageHasNameProperty -eq $true -and $package.Name -eq $matchingActionPackage.Name))
                    {
                        $package.Id = $matchingActionPackage.Id
                        break
                    }                                        
                }
            }
        }
    }
}

function Convert-OctopusDeployAReleaseStep
{
    param (
        $action,
        $sourceData,
        $destinationData
    )

    if ($action.ActionType -ne "Octopus.DeployRelease")
    {
        return
    }

    $projectVariableUsed = $false
    foreach ($package in $action.Packages)
    {
        if ($package.PackageId -like "#{*")
        {
            $projectVariableUsed = $true
            Write-OctopusWarning "The package $($package.PackageId) appears to be a variable.  Unable to convert this over.  You will need to clean this up on the destination instance."
            Write-OctopusPostCloneCleanUp "The step $($action.Name) uses a project variable.  Please ensure that project variable is pointed to the right project id."

            continue
        }
        
        $package.PackageId = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $package.PackageId -ItemName "$($action.Name) Sub Project" -MatchingOption "ErrorUnlessExactMatch"
    }

    if ($projectVariableUsed -eq $true)
    {
        return
    }

    if (Test-OctopusObjectHasProperty -objectToTest $action.Properties -propertyName "Octopus.Action.DeployRelease.ProjectId")
    {
        $action.Properties.'Octopus.Action.DeployRelease.ProjectId' = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $action.Properties.'Octopus.Action.DeployRelease.ProjectId' -ItemName "$($action.Name) Deploy A Release Project Properties" -MatchingOption "ErrorUnlessExactMatch"
    }
    else
    {
        $added = Add-PropertyIfMissing -objectToTest $action.Properties -propertyName "Octopus.Action.DeployRelease.ProjectId" -propertyValue $action.Packages[0].PackageId
    }
}

function Write-OctopusPackagesToChangeLog
{
    param (
        $action,
        $destinationData
    )

    if ($action.Packages.Length -eq 0)
    {
        return
    }

    Write-OctopusChangeLog "          - Packages"
    foreach ($package in $action.Packages)
    {        
        $feed = Get-OctopusItemById -itemId $package.FeedId -itemList $destinationData.FeedList
        Write-OctopusChangeLog "            - $($package.PackageId) from $($feed.Name)"
    }    
}