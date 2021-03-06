# AzureSiteRecovery
Scripts related to ASR

ASRTestFailover.ps1 - Script that hardcodes the Subscription ID, Recovery Services Vault, Recovery Plan, and then performs the following:
1. Initiate Test Failover for a single Recovery Plan
2. Prompts to clean up the Test Failover for the Recovery Plan
3. Clean up Recovery Plan

ASRTestFailover-2-Plans.ps1 - Script that hardcodes the Subscription ID, 1 VM that needs to be shutdown, 2 VNets that are peered, Recovery Services Vault, Recovery Plan, and then performs the following:

1. Shutdown VM
2. Delete VNet peering
3. Initiate Test Failover for 2 Recovery Plans
4. Prompts to clean up the Test Failover for the Recovery Plan
5. Clean up Recovery Plan
6. Recreate VNet peering
7. Restart VM that was shutdown

Universal-ASRTestFailover.ps1 - Script that performs the following:
1. Prompts user to log into Azure with Connect-AzAccount
2. Lists the subscriptions available and prompts user to select the one with Recovery Services Vault
3. Lists the Recovery Services Vaults available and prompts the user to select the Recovery Services Vault
4. Lists the Recovery Plans in the Recovery Services Vault and prompts the user to select the Recovery Plan to recover
5. Lists the available VNets for the Recovery Plan and prompts the user to select the VNet for the Test Failover
6. Starts failover of recovery plan
7. Wait until failover is complete
8. Prompts user if more Recovery Plans should be repeated
9. Repeats step #6 if step #10 is yes
10. Prompts user to test failed over servers and proceed to cleanup when ready
11. Proceed to clean up executed Recovery Plans
