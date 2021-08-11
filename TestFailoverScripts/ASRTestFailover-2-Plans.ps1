Connect-AzAccount

Set-AzContext -SubscriptionId "53ea69af-xxxx-xxxx-xxxx-e517fea02f8b"

#Shutdown SVRDC2
Write-Host "Shutting down SVRDC2 VM in DR"
$DRDCName = "SVRDC2"
$DRDCRG = "Canada-East-Prod"
Stop-AzVM -ResourceGroupName $DRDCRG -Name $DRDCName -force

#Declare variables for DR production VNet
$DRVNetName = "vnet-prod-canadaeast"
$DRVnetRG = "Canada-East-Prod"
$DRVNetPeerName = "DR-to-Prod"
$DRVNetObj = Get-AzVirtualNetwork -Name $DRVNetName
$DRVNetID = $DRVNetObj.ID

#Declare variables for Production VNet
$ProdVNetName = "London-Prod-vnet"
$ProdVnetRG = "London-Prod"
$ProdVNetPeerName = "Prod-to-DR"
$ProdVNetObj = Get-AzVirtualNetwork -Name $ProdVNetName
$ProdVNetID = $ProdVNetObj.ID

# Remove the DR VNet's peering to production 
Write-Host "Removing VNet peering between Production and DR environment"
Remove-AzVirtualNetworkPeering -Name $DRVNetPeerName -VirtualNetworkName $DRVNetName -ResourceGroupName $DRVnetRG -force
Remove-AzVirtualNetworkPeering -Name $ProdVNetPeerName -VirtualNetworkName $ProdVNetName -ResourceGroupName $ProdVnetRG -force

#Failover Test for Domain Controllers Plan

$RSVaultName = "rsv-asr-canada-east"
$ASRRecoveryPlanName = "Domain-Controllers"
$TestFailoverVNetName = "vnet-prod-canadaeast"

$vault = Get-AzRecoveryServicesVault -Name $RSVaultName

Set-AzRecoveryServicesAsrVaultContext -Vault $vault

$RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $ASRRecoveryPlanName

$TFOVnet = Get-AzVirtualNetwork -Name $TestFailoverVNetName

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

if($Job_TFOState.state -eq "Failed"){
   Write-host("The test failover job failed. Script terminating.")
   Exit
}else {
   
#Failover Test for Remaining Servers

    $ASRRecoveryPlanName = "DR-Servers"

    $RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $ASRRecoveryPlanName

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
    
    if($Job_TFOState.state -eq "Failed"){
       Write-host("The test failover job failed. Script terminating.")
       Exit
    }else {

    Read-Host -Prompt "Test failover has completed. Please check ASR Portal, test VMs and press enter to perform cleanup..."

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
    Write-Host "Cleanup status for $($Job_TFO.TargetObjectName) is $($Job_TFOCleanupState.state)"
    Start-Sleep 5;
} while (($Job_TFOCleanupState.state -eq "InProgress") -or ($Job_TFOCleanupState.state -eq "NotStarted"))

$ASRRecoveryPlanName = "Domain-Controller"

$RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $ASRRecoveryPlanName

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
    Write-Host "Cleanup status for $($ASRRecoveryPlanName) is $($Job_TFOCleanupState.state)"
    Start-Sleep 5;
} while (($Job_TFOCleanupState.state -eq "InProgress") -or ($Job_TFOCleanupState.state -eq "NotStarted"))

Write-Host "Test failover cleanup completed."

}
}

#Create the DR VNet's peering to production 
Write-Host "Recreating VNet peering between Production and DR environment after failover testing"
Add-AzVirtualNetworkPeering -Name $DRVNetPeerName -VirtualNetwork $DRVNetObj -RemoteVirtualNetworkId $ProdVNetID -AllowForwardedTraffic
Add-AzVirtualNetworkPeering -Name $ProdVNetPeerName -VirtualNetwork $ProdVNetObj -RemoteVirtualNetworkId $DRVNetID -AllowForwardedTraffic

#Power On SVRDC2
Write-Host "Powering on SVRDC2 VM in DR after testing"
Start-AzVM -ResourceGroupName $DRDCRG -Name $DRDCName
