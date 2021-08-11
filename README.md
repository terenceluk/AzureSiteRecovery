# AzureSiteRecovery
Scripts related to ASR

ASRTestFailover.ps1 - Script that hardcodes the Subscription ID, Recovery Services Vault, Recovery Plan, and then performs the following:
1. Failover VNet to recover a single Recovery Plan
2. Prompts to clean up the Test Failover for the Recovery Plan
3. Clean up Recovery Plan

Universal-ASRTestFailover.ps1 - Script that performs the following:
1. Prompts user to log into Azure with Connect-AzAccount
2. Lists the subscriptions available and prompts user to select the one with Recovery Services Vault
3. Prompts to ask whether any VNet peerings need to be removed and removes them
4. Prompts to ask whether VMs need to be shutdown and shuts them down
5. Lists the Recovery Services Vaults available and prompts the user to select the Recovery Services Vault
6. Lists the Recovery Plans in the Recovery Services Vault and prompts the user to select the Recovery Plan to recover
7. Lists the available VNets for the Recovery Plan and prompts the user to select the VNet for the Test Failover
8. Starts failover of recovery plan
9. Wait until failover is complete
10. Prompts user if more Recovery Plans should be repeated
11. Repeats step #6 if step #10 is yes
12. Prompts user to test failed over servers and proceed to cleanup when ready
13. Proceed to clean up executed Recovery Plans
14. Recreate the deleted VNet
15. Restart the shutdown VMs
