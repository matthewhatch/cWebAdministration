<#
    Summary
    =======
    Custom DSC Resource Modeled after cAppPool, inteded to allow for us to not pass AppPool Credentials
    and add the enable 32-bit Mode

    Revision History
    ================
    7/28/2014 - Initial Version (Matt Hatch)

#>

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
SetTargetResourceInstallwhatIfMessage=Trying to create AppPool "{0}".
SetTargetResourceUnInstallwhatIfMessage=Trying to remove AppPool "{0}".
AppPoolNotFoundError=The requested AppPool "{0}" is not found on the target machine.
AppPoolDiscoveryFailureError=Failure to get the requested AppPool "{0}" information from the target machine.
AppPoolCreationFailureError=Failure to successfully create the AppPool "{0}".
AppPoolRemovalFailureError=Failure to successfully remove the AppPool "{0}".
AppPoolUpdateFailureError=Failure to successfully update the properties for AppPool "{0}".
AppPoolCompareFailureError=Failure to successfully compare properties for AppPool "{0}".
AppPoolStateFailureError=Failure to successfully set the state of the AppPool {0}.
'@
}
function Get-TargetResource
{
<<<<<<< HEAD
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name
	)
        $getTargetResourceResult = $null;

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        $AppPools = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name

        if ($AppPools.count -eq 0) # No AppPool exists with this name.
        {
            $ensureResult = "Absent";
        }
        elseif ($AppPools.count -eq 1) # A single AppPool exists with this name.
        {
            $ensureResult = "Present"
            [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
            if($PoolConfig.add.processModel.userName){
                $AppPoolPassword = $PoolConfig.add.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $PoolConfig.add.processModel.userName,$AppPoolPassword   
            }else{
                $AppPoolCred = $null
            }
        }
        else # Multiple AppPools with the same name exist. This is not supported and is an error
        {
            $errorId = "AppPoolDiscoveryFailure"; 
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.AppPoolUpdateFailureError) -f ${Name} 
            $exception = New-Object System.InvalidOperationException $errorMessage 
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord);
        }

        # Add all Website properties to the hash table
        $getTargetResourceResult = @{
    	                                Name = $PoolConfig.add.name; 
                                        Ensure = $ensureResult;
                                        autoStart = $PoolConfig.add.autoStart;
                                        managedRuntimeVersion = $PoolConfig.add.managedRuntimeVersion;
                                        managedPipelineMode = $PoolConfig.add.managedPipelineMode;
                                        startMode = $PoolConfig.add.startMode;
                                        identityType = $PoolConfig.add.processModel.identityType;
                                        userName = $PoolConfig.add.processModel.userName;
                                        password = $AppPoolCred
                                        loadUserProfile = $PoolConfig.add.processModel.loadUserProfile;
                                        Enable32Bit = $PoolConfig.Add.Enable32BitAppOnWin64

                                    }
        
        return $getTargetResourceResult;
=======
    [OutputType([Systems.Collections.HashTable])]
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

        $getTargetResourceResult = $null;

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        Write-Verbose "Getting AppPool $Name details"
        $AppPools = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name

        if ($AppPools.count -eq 0) # No AppPool exists with this name.
        {
            Write-Verbose "App Pool is Absent"
            $ensureResult = "Absent";
        }
        elseif ($AppPools.count -eq 1) # A single AppPool exists with this name.
        {
            Write-Verbose "App Pool is Present"
            $ensureResult = "Present"

            [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
            if(!([string]::IsNullOrEmpty($PoolConfig.add.processModel.userName))){
                $AppPoolPassword = $PoolConfig.add.processModel.password | ConvertTo-SecureString -AsPlainText -Force
                $AppPoolCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $PoolConfig.add.processModel.userName,$AppPoolPassword
            }
            else{
                $AppPoolCred =$null
            }

        }
        else # Multiple AppPools with the same name exist. This is not supported and is an error
        {
            $errorId = "AppPoolDiscoveryFailure"; 
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.AppPoolUpdateFailureError) -f ${Name} 
            $exception = New-Object System.InvalidOperationException $errorMessage 
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord);
        }

        # Add all Website properties to the hash table
        $getTargetResourceResult = @{
    	                                Name = $PoolConfig.add.name; 
                                        Ensure = $ensureResult;
                                        autoStart = $PoolConfig.add.autoStart;
                                        managedRuntimeVersion = $PoolConfig.add.managedRuntimeVersion;
                                        managedPipelineMode = $PoolConfig.add.managedPipelineMode;
                                        startMode = $PoolConfig.add.startMode;
                                        identityType = $PoolConfig.add.processModel.identityType;
                                        userName = $PoolConfig.add.processModel.userName;
                                        password = $AppPoolCred
                                        loadUserProfile = $PoolConfig.add.processModel.loadUserProfile;
					                    Enabled32Bit = $PoolConfig.Add.Enable32BitAppOnWin64;
                                    }
        
        Write-Output $getTargetResourceResult;
>>>>>>> origin/master
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[ValidateSet("true","false")]
		[System.String]
		$AutoStart = "true",

		[System.String]
		[ValidateSet("v4.0","v2.0","")]
        $managedRuntimeVersion = "v4.0",

		[ValidateSet("Integrated","Classic")]
		[System.String]
		$managedPipelineMode = "Integrated",

		[ValidateSet("AlwaysRunning","OnDemand")]
		[System.String]
		$startMode = "OnDemand",

		[ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
		[System.String]
		$identityType = "SpecificUser",

		[System.String]
		$userName,

		[System.Management.Automation.PSCredential]
		$Password,

		[ValidateSet("true","false")]
		[System.String]
		$loadUserProfile = "true",

		[ValidateSet("true","false")]
		[System.String]
		$Enable32Bit = "false"
	)

    $PSBoundParameters.Add("Update",$true)
    __testAppPool @PSBoundParameters

}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	
    param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[ValidateSet("true","false")]
		[System.String]
		$AutoStart = "true",

		[System.String]
		$managedRuntimeVersion = "v4.0",

		[ValidateSet("Integrated","Classic")]
		[System.String]
		$managedPipelineMode = "Integrated",

		[ValidateSet("AlwaysRunning","OnDemand")]
		[System.String]
		$startMode = "OnDemand",

		[ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
		[System.String]
		$identityType = "SpecificUser",

		[System.String]
		$userName,

		[System.Management.Automation.PSCredential]
		$Password,

		[ValidateSet("true","false")]
		[System.String]
		$loadUserProfile = "true",

		[ValidateSet("true","false")]
		[System.String]
		$Enable32Bit = "false"
	)

    __testAppPool @PSBoundParameters
}

Function __testAppPool{
    [CmdletBinding()]
    param
	(
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[ValidateSet("true","false")]
		[System.String]
		$AutoStart = "true",

		[System.String]
		$managedRuntimeVersion = "v4.0",

		[ValidateSet("Integrated","Classic")]
		[System.String]
		$managedPipelineMode = "Integrated",

		[ValidateSet("AlwaysRunning","OnDemand")]
		[System.String]
		$startMode = "OnDemand",

		[ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
		[System.String]
		$identityType = "SpecificUser",

		[System.String]
		$userName,

		[System.Management.Automation.PSCredential]
		$Password,

		[ValidateSet("true","false")]
		[System.String]
		$loadUserProfile = "true",

		[ValidateSet("true","false")]
		[System.String]
		$Enable32Bit = "false",

        [switch]$update
	)
    $DesiredConfigurationMatch = $true

    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }

    $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
    
    if($AppPool){
        [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
    }
    
    $Stop = $true

    Do
    {
        #Check Ensure
        if($Ensure -eq "Present" -and $AppPool -eq $null){
            if($update){
                try
                {
                    New-WebAppPool $Name
		            Wait-Event -Timeout 5
                    Stop-WebAppPool $Name
            
                    #Configure settings that have been passed
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /autoStart:$autoStart

                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeVersion:$managedRuntimeVersion
            
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedPipelineMode:$managedPipelineMode

                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /startMode:$startMode
            
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.identityType:$identityType
            
                    #set username and password if username is provided
                    if(!([string]::IsNullOrEmpty($username))){
                         & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.userName:$userName
                     
                        #set password if required
                        if($identityType -eq "SpecificUser" -and $Password){
                            $clearTextPassword = $Password.GetNetworkCredential().Password
                            & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.password:$clearTextPassword
                        }    
                    }
                

                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.loadUserProfile:$loadUserProfile
                
                    & $env:SystemRoot\System32\inetsrv\appcmd.exe set apppool $Name /enable32BitAppOnWin64:$Enable32Bit

                    Write-Verbose("successfully created AppPool $Name")
                
                    #Start site if required
                    if($autoStart -eq "true")
                    {
                        Start-WebAppPool $Name
                    }

                    Write-Verbose("successfully started AppPool $Name")
                }
                catch
                {
                    $errorId = "AppPoolCreationFailure"; 
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                    $errorMessage = $($LocalizedData.FeatureCreationFailureError) -f ${Name} ;
                    $exception = New-Object System.InvalidOperationException $errorMessage ;
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

                    $PSCmdlet.ThrowTerminatingError($errorRecord);
                }   
            }
            else{
                $DesiredConfigurationMatch = $false
                Write-Verbose("The Ensure state for AppPool $Name does not match the desired state.");
                break      
            }
        }
        
        if($Ensure -eq "Absent" -and $AppPool -ne $null){
            if($update){
                try
                {
                    $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
                    if($AppPool -ne $null)
                    {
                        Stop-WebAppPool $Name
                        Remove-WebAppPool $Name
        
                        Write-Verbose("Successfully removed AppPool $Name.")
                    }
                    else
                    {
                        Write-Verbose("AppPool $Name does not exist.")
                    }
                }
                catch
                {
                    $errorId = "AppPoolRemovalFailure"; 
                    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                    $errorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f ${Name} ;
                    $exception = New-Object System.InvalidOperationException $errorMessage ;
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

                    $PSCmdlet.ThrowTerminatingError($errorRecord);
                }
            }
            else{
                $DesiredConfigurationMatch = $false
                Write-Verbose("The Ensure state for AppPool $Name does not match the desired state.");
                break
            }
        }

        # Only check properties if $AppPool exists
        if ($AppPool -ne $null)
        {
            $UpdateNotRequired = $true
            #Check autoStart
            if($PoolConfig.add.autoStart -ne $autoStart){
                if($update){
                    Write-Verbose "updating autostart to $autoStart"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /autoStart:$autoStart
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("autoStart of AppPool $Name does not match the desired state.");
                    break
                }
            }

            #Check managedRuntimeVersion 
            if($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion){
                if($update){
                    Write-Verbose "updating managedRuntimeVersion to $managedRuntimeVersion"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeVersion:$managedRuntimeVersion   
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("managedRuntimeVersion of AppPool $Name does not match the desired state.");
                    break
                }
                
            }
            #Check managedPipelineMode 
            if($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode){
                if($update){
                    Write-Verbose "updating managedPipelineMode to $managedPipelineMode"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedPipelineMode:$managedPipelineMode              
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("managedPipelineMode of AppPool $Name does not match the desired state.");
                    break  
                }

            }
            #Check startMode 
            if($PoolConfig.add.startMode -ne $startMode){
                if($update){
                    Write-Verbose "updating start mode to $startMode"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /startMode:$startMode   
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("startMode of AppPool $Name does not match the desired state.");
                    break               
                }

            }
            #Check identityType 
            if($PoolConfig.add.processModel.identityType -ne $identityType){
                if($update){
                    Write-Verbose "updating identityType to $identityType"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.identityType:$identityType
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("identityType of AppPool $Name does not match the desired state.");
                    break
                }

            }
            #Check userName
            #Added Check if username is passed, if not skip the test - m.hatch 
            if ($PSBoundParameters.ContainsKey('username')){
                if($PoolConfig.add.processModel.userName -ne $userName){
                    if($update){
                         Write-Verbose "updating User Name to $userName"
                        $UpdateNotRequired = $false
                        & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.userName:$userName    
                    }
                    else{
                        $DesiredConfigurationMatch = $false
                        Write-Verbose("userName of AppPool $Name does not match the desired state.");
                        break
                    } 
                }
            }

            #Check password 
            if($identityType -eq "SpecificUser" -and $Password){
                $clearTextPassword = $Password.GetNetworkCredential().Password
                if($clearTextPassword -cne $PoolConfig.add.processModel.password){
                    if($update){
                         Write-Verbose "Updating Password"
                        $UpdateNotRequired = $false
                        & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.password:$clearTextPassword    
                    }
                    else{
                        $DesiredConfigurationMatch = $false
                        Write-Verbose("Password of AppPool $Name does not match the desired state.");
                        break
                    }                   
                    
                }

            }
            #Check loadUserProfile 
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                if($update){
                     Write-Verbose "updating loadUserProfile to $loadUserProfile"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.loadUserProfile:$loadUserProfile   
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("loadUserProfile of AppPool $Name does not match the desired state.");
                    break
                }

            }

            #check enabled32BitAppOnWin64
            if($PoolConfig.add.enable32BitAppOnWin64 -ne $Enable32Bit){
                if($update){
                     Write-Verbose "Updating Enable32Bit to $Enable32Bit"
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\System32\inetsrv\appcmd.exe set apppool $Name /enable32BitAppOnWin64:$Enable32Bit
                }
                else{
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("enable32BitAppOnWin64 of AppPool $Name does not match the desired state.");
                    break
                }
            }
        }

        $Stop = $false
    }
    While($Stop)   

    if($update -and $UpdateNotRequired)
    {
        Write-Verbose("AppPool $Name already exists and properties do not need to be udpated.");
    }
    else{
        return $DesiredConfigurationMatch
    }
    
}

Export-ModuleMember -Function *-TargetResource
