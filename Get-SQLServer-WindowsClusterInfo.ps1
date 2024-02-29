###################################################
# Get SQL Server Cluster Information on OS level
###################################################
 
Import-Module FailoverClusters
 
clear
function Get-SQLServer-WindowsClusterInfo
{
    param([string]$servername)
 
    if (Test-Connection -ComputerName $servername -Quiet -Count 1 -BufferSize 1)
    {
        $ClusterRegKey = $null
        $ClusterRegKey = Invoke-Command -Computer $servername -ScriptBlock {Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\Cluster -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
 
        if ($ClusterRegKey -eq $null)
        {
            Write-Output 'Standalone'
        }
        else
        {
            $WMIRootMSCluster = $null
            $WMIRootMSCluster = Invoke-Command -Computer $servername -ScriptBlock {Get-WMIObject -Class MSCluster_ResourceGroup -Namespace root\mscluster -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
 
            $ClusterResource = $null
            $ClusterResource = Get-Cluster -Name $servername | Get-ClusterResource -ErrorAction SilentlyContinue
 
            if (($WMIRootMSCluster -eq $null) -and ($ClusterResource -eq $null))
            {
                Write-Output 'Single Node Cluster'
            }
            elseif (($WMIRootMSCluster -ne $null) -and ($ClusterResource -eq $null))
            {
                Write-Output 'Check server, WMI shows that the server is clustered but PowerShell Get-Cluster command did not return results.'
            }
            else
            {
                $IsAGCount = ($ClusterResource | Where-Object ResourceType -eq 'SQL Server Availability Group').count
 
                if ($IsAGCount -eq 0)
                {
                    $ClusterOwnerNode = $null
                    $ClusterOwnerNode = $ClusterResource | Where-Object ResourceType -eq 'SQL Server' | Select-Object -ExpandProperty OwnerNode
 
                    if ($ClusterOwnerNode.count -eq 0)
                    {
                        $ClusterOwnerNode = $ClusterResource | Where-Object {($_.ResourceType -eq 'Network Name') -and ($_.OwnerGroup -eq 'Cluster Group') -and ($_.Name -eq 'Cluster Name')} | Select-Object -ExpandProperty OwnerNode
                    }
 
                    if ($servername.ToUpper() -eq $ClusterOwnerNode)
                    {
                        Write-Output 'Clustered (FCI): Active'
                    }
                    else
                    {
                        Write-Output 'Clustered (FCI): Passive'
                    }
                }
                else
                {
                    $IsFCIAGCount = $null
                    $IsFCIAGCount = ($ClusterResource | Where-Object { (($_.ResourceType -EQ 'Network Name') -and ($_.Name -Like 'SQL Network Name *')) -or ($_.ResourceType -eq 'SQL Server Availability Group')  } | Select-Object -ExpandProperty ResourceType -Unique).count
                    if ($IsFCIAGCount -eq 2)
                    {
                        $ClusterOwnerNode = $null
                        $ClusterOwnerNode = $ClusterResource | Where-Object ResourceType -eq 'SQL Server' | Select-Object -ExpandProperty OwnerNode
 
                        if ($ClusterOwnerNode.count -eq 0)
                        {
                            $ClusterOwnerNode = $ClusterResource | Where-Object {($_.ResourceType -eq 'Network Name') -and ($_.OwnerGroup -eq 'Cluster Group') -and ($_.Name -eq 'Cluster Name')} | Select-Object -ExpandProperty OwnerNode
                        }
 
                        if ($servername.ToUpper() -eq $ClusterOwnerNode)
                        {
                            Write-Output 'Clustered (FCI/AG): Active'
                        }
                        else
                        {
                            Write-Output 'Clustered (FCI/AG): Passive'
                        }
 
                    }
                    else
                    {
                        $ClusterOwnerNode = $null
                        $ClusterOwnerNode = $ClusterResource | Where-Object ResourceType -eq 'SQL Server Availability Group' | Select-Object -ExpandProperty OwnerNode -Unique
 
                        if ($ClusterOwnerNode.count -eq 1)
                        {
                            if ($servername.ToUpper() -eq $ClusterOwnerNode)
                            {
                                Write-Output 'Clustered (AG): Active'
                            }
                            else
                            {
                                Write-Output 'Clustered (AG): Passive'
                            }
                        }
                        else
                        {
                            Write-Output 'Multiple Availability Groups/Listener:'
 
                            $MultipleAGs = $null
                            $MultipleAGs = $ClusterResource | Where-Object ResourceType -eq 'SQL Server Availability Group' | Sort-Object Name
                            foreach ($MultipleAG in $MultipleAGs)
                            {
                                $MultipleAGName = $null
                                $MultipleAGName = $MultipleAG.Name
 
                                $ClusterOwnerNode = $null
                                $ClusterOwnerNode = $ClusterResource | Where-Object {($_.ResourceType -eq 'SQL Server Availability Group') -and ($_.Name -eq $MultipleAGName) } | Select-Object -ExpandProperty OwnerNode -Unique
 
                                if ($ClusterOwnerNode.count -eq 1)
                                {
                                    if ($servername.ToUpper() -eq $ClusterOwnerNode)
                                    {
                                        Write-Output "($MultipleAGName : Active)"
                                    }
                                    else
                                    {
                                        Write-Output "($MultipleAGName : Passive)"
                                    }
                                }
                           
                            }
                        }
                    }
                }
            }
        }
    }
    else
    {
        Write-Output 'Check server, PowerShell Test-Connection command failed.'
    }
}
