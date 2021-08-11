Connect-AzAccount

Set-AzContext -SubscriptionId "adae0952-xxxx-xxxx-xxxx-2b8ef42c9bbb"

$RSVaultName = "rsv-us-eus-contoso-asr"
$ASRRecoveryPlanName = "Recover-Domain-Controllers"
$TestFailoverVNetName = "vnet-us-eus-dr"

$vault = Get-AzRecoveryServicesVault -Name $RSVaultName

Set-AzRecoveryServicesAsrVaultContext -Vault $vault

$RecoveryPlan = Get-AzRecoveryServicesAsrRecoveryPlan -FriendlyName $ASRRecoveryPlanName

$TFOVnet = Get-AzVirtualNetwork -Name $TestFailoverVNetName

$TFONetwork= $TFOVnet.Id

#Start test failover of recovery plan

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

#Start test failover cleanup of recovery plan

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

Write-Host "Test failover cleanup completed."

}
