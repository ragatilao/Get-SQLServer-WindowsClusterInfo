Retrieve information about the SQL Server Windows cluster without establishing a connection to the database instance. This information will be collected at the server level using PowerShell.
1. Copy the function in PowerShell.
2. Run the function using the following command:
Get-SQLServer-WindowsClusterInfo -servername YourServerName

NOTE: Failover Cluster Module is required to use this function.
https://learn.microsoft.com/en-us/powershell/module/failoverclusters/?view=windowsserver2022-ps
