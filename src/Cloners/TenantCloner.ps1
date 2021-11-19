function Copy-OctopusTenants
{
    param(
        $sourceData,
        $destinationData,
        $CloneScriptOptions,
        $firstRun       
    )
    
    $filteredList = Get-OctopusFilteredList -itemList $sourceData.TenantList -itemType "Tenants" -filters $cloneScriptOptions.TenantsToClone

    Write-OctopusChangeLog "Tenants"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No tenants found to clone matching the filters"
        return
    }
    
    foreach($tenant in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of tenant $($tenant.Name)"
        
        $matchingTenant = Get-OctopusItemByName -ItemName $tenant.Name -ItemList $destinationData.TenantList

        if ($null -eq $matchingTenant)
        {
            Write-OctopusVerbose "The tenant $($tenant.Name) doesn't exist on the source, copying over."
            Write-OctopusChangeLog " - Add $($tenant.Name)"

            $tenantToAdd = Copy-OctopusObject -ItemToCopy $tenant -ClearIdValue $true -SpaceId $destinationData.SpaceId
            $tenantToAdd.Id = $null
            $tenantToAdd.SpaceId = $destinationData.SpaceId
            $tenantToAdd.ProjectEnvironments = @{}                        

            $destinationTenant = Save-OctopusTenant -Tenant $tenantToAdd -destinationData $destinationData
            $destinationData.TenantList = Update-OctopusList -itemList $destinationData.TenantList -itemToReplace $destinationTenant

            if ($CloneScriptOptions.CloneTenantLogos -eq $true)
            {
                Copy-OctopusItemLogo -sourceItem $tenant -destinationItem $destinationTenant -sourceData $SourceData -destinationData $DestinationData -CloneScriptOptions $CloneScriptOptions            
            }
        }
        elseif ($firstRun -eq $false)
        {
            Write-OctopusVerbose "Updating $($tenant.Name) projects"
            Write-OctopusChangeLog " - Update $($tenant.Name)"

            $projectFilteredList = Get-OctopusFilteredList -itemList $sourceData.ProjectList -itemType "Projects" -filters $cloneScriptOptions.ProjectsToClone
            $tenantToUpdate = Copy-OctopusObject -itemToCopy $matchingTenant -clearIdValue $false -spaceId $destinationData.SpaceId

            foreach ($sourceProject in $projectFilteredList)
            {
                $sourceProjectId = $sourceProject.Id
                if ($null -eq (Get-Member -InputObject $tenant.ProjectEnvironments -Name $sourceProjectId -MemberType Properties))
                {
                    continue
                }
                
                Write-OctopusVerbose "Attempting to match $sourceProjectId with source"
		        $matchingProjectId = Convert-SourceIdToDestinationId -SourceList $sourceData.ProjectList -DestinationList $destinationData.ProjectList -IdValue $sourceProjectId -ItemName "$($tenantToUpdate.Name) Project" -MatchingOption "IgnoreMismatch"

                if ($null -eq $matchingProjectId)
                {
                    Write-OctopusVerbose "The destination project does not exist.  Skipping this project."
                    continue
                }
                Write-OctopusVerbose "The project id for $sourceProjectId on the destination is $matchingProjectId"
                
                $scopedEnvironments = Convert-SourceIdListToDestinationIdList -SourceList $sourceData.EnvironmentList -DestinationList $destinationData.EnvironmentList -IdList $tenant.ProjectEnvironments.$sourceProjectId -MatchingOption "IgnoreMismatch" -IdListName "$($Tenant.Name) Project Environments"

                $added = Add-PropertyIfMissing -objectToTest $tenantToUpdate.ProjectEnvironments -propertyName $matchingProjectId -propertyValue @($scopedEnvironments.NewIdList)
                $tenantToUpdate.ProjectEnvironments.$matchingProjectId = @($scopedEnvironments.NewIdList)
            }

            $updatedTenant = Save-OctopusTenant -Tenant $tenantToUpdate -destinationData $destinationData
            $destinationData.TenantList = Update-OctopusList -itemList $destinationData.TenantList -itemToReplace $updatedTenant		        
        }
    }

    Write-OctopusSuccess "Tenants successfully cloned"    
}