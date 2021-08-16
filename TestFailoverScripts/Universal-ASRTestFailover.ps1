Write-Host "Starting DR Test Failover Script..."

# Connect to Azure tenant
Connect-AzAccount

#List Subscriptions

$SubscriptionList = Get-AzSubscription

Write-Host "There are $($SubscriptionList.count) subscriptions in this tenant"
# Starting at 1 rather than 0 so number will be shifted
$index = 1
foreach ( $SubscriptionName in $SubscriptionList)
    {
        Write-Host " [$($index)] Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"
        $index++
    }


# Ask to select subscription with number and check to see if the selection is within range of subscriptions
Do 
    { 
        "`n"
        [Int]$SubscriptionSelection = Read-Host "Please enter the number for the subscription with the resources to Test Failover"
        # Check if invalid value is entered
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


# Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$SubscriptionSelection--
$SubscriptionName = $SubscriptionList[$SubscriptionSelection]
"`n"
Write-Host "Subscription ""Name: $($SubscriptionName.name) | ID: $($SubscriptionName.Id) | State: $($SubscriptionName.state)"" selected."

$subscriptionID = $SubscriptionName.Id

Set-AzContext -SubscriptionId $subscriptionID

# List Recovery Services Vault

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

# Check to see selection is within range of subscriptions
Do 
    { 
        [Int]$RecoveryServicesVaultSelection = Read-Host "Please enter the number for the subscription with the resources to Test Failover"
        # Check if invalid value is entered
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

# Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$RecoveryServicesVaultSelection--
$RecoveryServicesVault = $RecoveryServicesVaultList[$RecoveryServicesVaultSelection]
$RecoveryServicesVaultSelection++
Write-Host " [$($RecoveryServicesVaultSelection)] $($RecoveryServicesVault.name) selected."

$vault = $RecoveryServicesVault

# Retrieve list of Recovery Plans

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
# Check to see selection is within range of recovery plans
Do 
    { 
        [Int]$RecoveryPlanSelection = Read-Host "Please enter the number for the recovery plan to Test Failover"
        # Check if invalid value is entered
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

# Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$RecoveryPlanSelection--
$RecoveryPlanName = $RecoveryPlans[$RecoveryPlanSelection]
Write-Host "Recovery Plan ""$($RecoveryPlanName.FriendlyName)"" selected."
"`n"

# Add this recovery plan to an array for cleanup later
$testedRecoveryPlans += $RecoveryPlanName.FriendlyName

# Retrieve list of VNets available for the failover test

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
# Check to see selection is within range of recovery plans
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

# Select VNet for the test failover

# Reduce the index number by 1 to shift the 1 back to 0, 2 to 1, and so on in the array
$VNetSelection--
$VNetName = $VNetList[$VNetSelection]
Write-Host "Virtual Network ""$($VNetName.Name)"" selected."
"`n"

$TestFailoverVNetName = $VNetName

  # Starting Recovery Plan Test Failover...
  Start-Sleep 2;
  $RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $RecoveryPlanName.FriendlyName

  $TFOVnet = Get-AzVirtualNetwork -Name $TestFailoverVNetName.Name
  
  $TFONetwork= $TFOVnet.Id
  
  $Job_TFO = Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $RecoveryPlan -Direction PrimaryToRecovery -AzureVMNetworkId $TFONetwork
  
# Provide Recovery Plan Test Failover Update every 5 seconds

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

foreach ($testedRecoveryPlanToCleanup in $testedRecoveryPlans)
    {
        $RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $testedRecoveryPlanToCleanup
        $Job_TFOCleanup = Start-AzRecoveryServicesAsrTestFailoverCleanupJob -RecoveryPlan $RecoveryPlan -Comment "Testing Completed"

        do {
            $Job_TFOCleanupState = Get-AzRecoveryServicesAsrJob -Job $Job_TFOCleanup | Select-Object State
            Clear-Host
            Write-Host "======== Monitoring Cleanup ========"
            Write-Host "Status will refresh every 5 seconds."
            try {
                
            }
            catch {
                Write-Host -ForegroundColor Red "ERROR - Unable to get status of cleanup job"
                Write-Host -ForegroundColor Red "ERROR - " + $_
                log "ERROR" "Unable to get status of cleanup job"
                log "ERROR" $_
                exit
            }
            Write-Host "Cleanup status for $($Job_TFOCleanup.TargetObjectName) is $($Job_TFOCleanupState.state)"
            Start-Sleep 5;
        } while (($Job_TFOCleanupState.state -eq "InProgress") -or ($Job_TFOCleanupState.state -eq "NotStarted")) 
    }

    "`n"

    Write-Host "Test failover cleanup completed."
