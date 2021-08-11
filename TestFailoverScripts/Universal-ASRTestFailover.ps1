Write-Host "Starting DR Test Failover Script..."

Connect-AzAccount

#List Subscriptions

$SubscriptionList = Get-AzSubscription

Write-Host "There are $($SubscriptionList.count) subscriptions in this tenant"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $SubscriptionName in $SubscriptionList)
    {
        #$SubscriptionName = $SubscriptionName
        Write-Host " [$($index)] Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"
        $index++
    }


#Check to see selection is within range of subscriptions
Do 
    { 
        "`n"
        [Int]$SubscriptionSelection = Read-Host "Please enter the number for the subscription with the resources to Test Failover"
        #Check if invalid value is entered
        if ($SubscriptionSelection -gt $SubscriptionList.count -or $SubscriptionSelection -lt 1){
            Write-Host "Please enter a valid selection:"
            $index = 1
            foreach ( $SubscriptionName in $SubscriptionList)
                {
                    Write-Host " [$($index)] Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"
                    $index++
                }
        }
    }
    Until ($SubscriptionSelection -le $SubscriptionList.count -and $SubscriptionSelection -ge 1)

# Select Recovery Plan

#Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$SubscriptionSelection--
$SubscriptionName = $SubscriptionList[$SubscriptionSelection]
"`n"
Write-Host "Subscription ""Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"" selected."

$subscriptionID = $SubscriptionName.Id

Set-AzContext -SubscriptionId $subscriptionID

$removeVNetPeering = read-host "Does a VNet peering need to be removed? [Y] Yes or [N] No"
"`n"

While(-not($removeVNetPeering -eq 'yes') -and -not($removeVNetPeering -eq 'y') -and -not($removeVNetPeering -eq 'no') -and -not($removeVNetPeering -eq 'n')){
    $removeVNetPeering = read-host "Please enter [Y] Yes or [N] No"
}

if ($removeVNetPeering -eq 'yes' -or $removeVNetPeering -eq 'y'){
    
        #Declare variables and obtain value for DR production VNet
        $DRVNetName = read-host "Please enter the DR VNet name (e.g. vnet-prod-canadaeast)"
        $DRVnetRG = read-host "Please enter the resource group the DR VNet resides in (e.g. Canada-East-Prod)"
        $DRVNetPeerName = read-host "Please enter the DR VNet peering name (e.g. DR-to-Prod)"
        $DRVNetObj = Get-AzVirtualNetwork -Name $DRVNetName
        $DRVNetID = $DRVNetObj.ID

        #Declare variables for Production VNet
        $ProdVNetName = read-host "Please enter the Production VNet name (e.g. Bermuda-Prod-vnet)"
        $ProdVnetRG = read-host "Please enter the resource group the Production VNet resides in (e.g. Bermuda-Prod)"
        $ProdVNetPeerName = read-host "Please enter the DR VNet peering name (e.g. Prod-to-DR)"
        $ProdVNetObj = Get-AzVirtualNetwork -Name $ProdVNetName
        $ProdVNetID = $ProdVNetObj.ID

        # Remove the DR VNet's peering to production 
        Write-Host "Removing VNet peering between Production and DR environment"
        Remove-AzVirtualNetworkPeering -Name $DRVNetPeerName -VirtualNetworkName $DRVNetName -ResourceGroupName $DRVnetRG -force
        Remove-AzVirtualNetworkPeering -Name $ProdVNetPeerName -VirtualNetworkName $ProdVNetName -ResourceGroupName $ProdVnetRG -force

    }elseif ($removeVNetPeering -eq 'no' -or $removeVNetPeering -eq 'n'){
  
  }

  $ShutdownVM = Read-Host -Prompt 'Do you need to power down any VMs? [Y] Yes or [N] No'
  "`n"

  While(-not($ShutdownVM -eq 'yes') -and -not($ShutdownVM -eq 'y') -and -not($ShutdownVM -eq 'no') -and -not($ShutdownVM -eq 'n')){
    $ShutdownVM = read-host "Please enter [Y] Yes or [N] No"
}

if ($ShutdownVM -eq 'yes' -or $ShutdownVM -eq 'y'){
    
    $Response = 'Y'
    $ServerName = $Null
    $Serverlist = @()
    $WriteOutList = $Null
    
    Do 
    { 
        $ServerName = Read-Host 'Please type a Azure server name you like to shutdown'
        $Response = Read-Host 'Would you like to add additional servers to this list? (y/n)'
        $Serverlist += $ServerName
    }
    Until ($Response -eq 'n' -or $Response -eq 'no')
    
    foreach ( $server in $ServerList )
    {
        $serverRGName = Get-AzVM -name $server | Select-Object ResourceGroupName

        #Check to see if VM returns a RG, if not then notify and skip
        if ($serverRGName -eq $null){
            Write-Host "$server does not exist, skipping"
        }else {
            Write-Host "Shutting down $server VM"
            Stop-AzVM -ResourceGroupName $serverRGName.ResourceGroupName -Name $server -force   
        }
    }

    Write-Output $Serverlist

    #Shutdown Servers
    Write-Host "Shutting down BREAZDC2 VM in DR"
    $DRDCName = "BREAZDC2"
    $DRDCRG = "Canada-East-Prod"
    Stop-AzVM -ResourceGroupName $DRDCRG -Name $DRDCName -force
    
    }elseif ($ShutdownVM -eq 'no' -or $ShutdownVM -eq 'n'){
  
  }

#List Recovery Services Vault

$RecoveryServicesVaultList = Get-AzRecoveryServicesVault

Write-Host "There are $($RecoveryServicesVaultList.count) Recovery Services Vault in this subscription"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $RecoveryServicesVault in $RecoveryServicesVaultList)
    {
        Write-Host " [$($index)] $($RecoveryServicesVault.name)"
        $index++
    }

    "`n"

#Check to see selection is within range of subscriptions
Do 
    { 
        [Int]$RecoveryServicesVaultSelection = Read-Host "Please enter the number for the subscription with the resources to Test Failover"
        #Check if invalid value is entered
        if ($RecoveryServicesVaultSelection -gt $RecoveryServicesVaultList.count -or $RecoveryServicesVaultSelection -lt 1){
            Write-Host "Please enter a valid selection:"
            $index = 1
            foreach ( $RecoveryServicesVault in $RecoveryServicesVaultList)
                {
                    Write-Host " [$($index)] $($RecoveryServicesVault.name)"
                    $index++
                }
        }
    }
    Until ($RecoveryServicesVaultSelection -le $RecoveryServicesVaultList.count -and $RecoveryServicesVaultSelection -ge 1)

# Select Recovery Plan

#Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$RecoveryServicesVaultSelection--
$RecoveryServicesVault = $RecoveryServicesVaultList[$RecoveryServicesVaultSelection]
$RecoveryServicesVaultSelection++
Write-Host " [$($RecoveryServicesVaultSelection)] $($RecoveryServicesVault.name) selected."

$vault = $RecoveryServicesVault

#Retrieve list of Recovery Plans

Set-AzRecoveryServicesAsrVaultContext -Vault $vault

$RecoveryPlans = Get-AzRecoveryServicesAsrRecoveryPlan

# Begin looping the selection for failing over recovery plans until complete

# Array to keep track of test failover recovery plans executed
$testedRecoveryPlans = @()

Do
{
Write-Host "There are $($RecoveryPlans.count) recovery plans in this Recovery Services Vault"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $RecoveryPlanName in $RecoveryPlans )
    {
        $RecoveryPlanName = $RecoveryPlanName.FriendlyName
        Write-Host " [$($index)] $($RecoveryPlanName)"
        $index++
    }

    "`n"
#Check to see selection is within range of recovery plans
Do 
    { 
        [Int]$RecoveryPlanSelection = Read-Host "Please enter the number for the recovery plan to Test Failover"
        #Check if invalid value is entered
        if ($RecoveryPlanSelection -gt $RecoveryPlans.count -or $recoveryPlanSelection -lt 1){
            Write-Host "Please enter a valid selection:"
            $index = 1
            foreach ( $RecoveryPlanName in $RecoveryPlans )
                {
                    $RecoveryPlanName = $RecoveryPlanName.FriendlyName
                    Write-Host " [$($index)] $($RecoveryPlanName)"
                    $index++
                }
        }
    }
    Until ($RecoveryPlanSelection -le $RecoveryPlans.count -and $RecoveryPlanSelection -ge 1)

# Select Recovery Plan

#Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$RecoveryPlanSelection--
$RecoveryPlanName = $RecoveryPlans[$RecoveryPlanSelection]
Write-Host "Recovery Plan ""$($RecoveryPlanName.FriendlyName)"" selected."
"`n"

# Add this recovery plan to an array for cleanup later
$testedRecoveryPlans += $RecoveryPlanName.FriendlyName

#Retrieve list of VNets

$VNetList = Get-AzVirtualNetwork

Write-Host "There are $($VNetList.count) Virtual Networks in this subscription"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $VNet in $VNetList )
    {
        $VNetName = $VNet.Name
        Write-Host " [$($index)] $($VNetName)"
        $index++
    }

    "`n"
#Check to see selection is within range of recovery plans
Do 
    { 
        [Int]$VNetSelection = Read-Host "Please enter the number for the VNet for failover servers"
        #Check if invalid value is entered
        if ($VNetSelection -gt $VNetList.count -or $VNetSelection -lt 1){
            Write-Host "Please enter a valid selection:"
            $index = 1
            foreach ( $VNet in $VNetList)
                {
                    $VNetName = $VNet.Name
                    Write-Host " [$($index)] $($VNetName)"
                    $index++
                }
        }
    }
    Until ($VNetSelection -le $VNetList.count -and $VNetSelection -ge 1)

# Select VNet

#Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$VNetSelection--
$VNetName = $VNetList[$VNetSelection]
Write-Host "Virtual Network ""$($VNetName.Name)"" selected."
"`n"

$TestFailoverVNetName = $VNetName

  #Starting Recovery Plan Test Failover...
  Start-Sleep 2;
  $RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $RecoveryPlanName.FriendlyName

  $TFOVnet = Get-AzVirtualNetwork -Name $TestFailoverVNetName.Name
  
  $TFONetwork= $TFOVnet.Id
  
  $Job_TFO = Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $RecoveryPlan -Direction PrimaryToRecovery -AzureVMNetworkId $TFONetwork
  
  do {
      $Job_TFOState = Get-AzRecoveryServicesAsrJob -Job $Job_TFO | Select-Object State
      Clear-Host
      Write-Host "======== Monitoring Failover ========"
      Write-Host "Status will refresh every 5 seconds."
      try {
          
      }
      catch {
          Write-Host -ForegroundColor Red "ERROR - Unable to get status of Failover job"
          Write-Host -ForegroundColor Red "ERROR - " + $_
          log "ERROR" "Unable to get status of Failover job"
          log "ERROR" $_
          exit
      }
      Write-Host "Failover status for $($Job_TFO.TargetObjectName) is $($Job_TFOState.state)"
      Start-Sleep 5;
  } while (($Job_TFOState.state -eq "InProgress") -or ($Job_TFOState.state -eq "NotStarted"))

  $startRecoveryPlan = Read-Host "Do you want to run more Recovery Plans? [Y] Yes or [N] No"
}
  Until ($startRecoveryPlan -eq "n" -or $startRecoveryPlan -eq "no")

Read-Host -Prompt "Test failover has completed. Please check ASR Portal, test VMs and press enter to perform cleanup..."

$testedRecoveryPlans
