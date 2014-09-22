******************************************************************
******************************************************************
**Special thanks to Alan for guidance and fixing the ovf config!**
**Author: RJ Singh                                              **
**Version: v1.0                                                 **
**Date: 09/21/2014                                              **
**Licensing: MIT License Zero Liability Open Source             **
**Contact: admin@rjapproves.com                                 **
**Website: www.rjapproves.com                                   **
******************************************************************
******************************************************************
#Making sure snapin is in place
Add-PSSnapin Vmware.vimautomation.core

#Read the XML file and get the content
$xml = [XML](Get-Content config.xml)

#Populate the variables from the XML

$vsmovalocation = $xml.MasterConfig.config.vsmovalocation
$VMnetwork = $xml.Masterconfig.config.MgmtNetwork
$ClusterName = $xml.Masterconfig.config.ClusterName
$pmpassword = $xml.Masterconfig.config.pmpassword
$userpassword = $xml.Masterconfig.config.userpassword
$vAppName = $xml.Masterconfig.config.vAppName
$vsmip = $xml.Masterconfig.config.vsmip
$vsmnetmask = $xml.Masterconfig.config.vsmnetmask 
$vsmgateway = $xml.Masterconfig.config.vsmgateway
$vsmhostname = $xml.Masterconfig.config.vsmhostname
$vsmvCenteruser = $xml.Masterconfig.config.vsmvCenteruser
$vsmvCenterpass = $xml.Masterconfig.config.vsmvCenterpass
$primaryDns1 = $xml.Masterconfig.config.primarydns
$secondaryDns1 = $xml.Masterconfig.config.secondarydns
$timeserverinfo = $xml.Masterconfig.config.timeserverinfo

$vcenter = $xml.Masterconfig.vcenterconfig.vcenter
$vcenteruser = $xml.Masterconfig.vcenterconfig.vcusername
$vcenterpassword = $xml.Masterconfig.vcenterconfig.vcpassword

#Ignore selfsigned cert
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

#Connect to the vcenter where vShield Manager will be deployed
Write-host "Connecting to vcenter..."
connect-viserver -server $vcenter -protocol https -username $vcenteruser -password $vcenterpassword | Out-Null

#DNS Function to set dns in vshield
Function Set-vShieldDNS ($primaryDns, $secondaryDns) {
    $Body = @"
<vsmGlobalConfig xmlns="vmware.vshield.edge.2.0">
<dnsInfo>
<primaryDns>$($primaryDns)</primaryDns>
<secondaryDns>$($secondaryDns)</secondaryDns>
</dnsInfo>
</vsmGlobalConfig>
"@
    Calling-rest -URL "https://${vsmip}/api/2.0/global/config" -Body $Body
}

#Function to Configure vShield Appliance
Function Set-vShieldConfiguration ($vCenter, $Username, $Password, $timeserver) {
    $Body = @"
<vsmGlobalConfig xmlns="vmware.vshield.edge.2.0"> 
<ssoInfo>
<lookupServiceUrl>https://${vCenter}:7444/lookupservice/sdk</lookupServiceUrl>
<ssoAdminUserName>${Username}</ssoAdminUserName>
<ssoAdminPassword>${Password}</ssoAdminPassword>
</ssoInfo>
<vcInfo>
<ipAddress>${vCenter}</ipAddress>
<userName>${Username}</userName>
<password>${Password}</password>
</vcInfo>
<timeInfo>
<ntpServer>${timeserver}</ntpServer>
</timeInfo>  
</vsmGlobalConfig>
"@
   Calling-rest -URL "https://${vsmip}/api/2.0/global/config" -Body $Body
}

#Function to call Restful API - leaving the default password as admin/default with the key being passed in headers

Function Calling-rest($URL,$Body) {

$headers = @{"Content-Type"="application/xml";"Authorization"="Basic YWRtaW46ZGVmYXVsdA=="}
Invoke-RestMethod -Headers $headers -Uri $URL -Body $Body -Method Post
 } 

#Identify the right cluster and host to deploy vShield Manager vApp
$VMhost = Get-Cluster $ClusterName | Get-VMHost | Sort MemoryGB | Select -first 1
$datastore = $VMhost | Get-Datastore | Sort FreeSpaceGB -Descending | Select -first 1
$Network = Get-VirtualPortgroup -Name $VMnetwork -VMHost $VMhost

#Load the ovf specific configuration in the $ovfconfig file
$ovffile = $vsmovalocation  
$ovfconfig = Get-OvfConfiguration $ovffile  

#Populate the members properties of the ovf file.
$ovfconfig.common.vsm_cli_en_passwd_0.Value = $pmpassword
$ovfconfig.common.vsm_cli_passwd_0.Value = $userpassword
$ovfconfig.NetworkMapping.vsmgmt.Value = $VMnetwork

#Importing the vapp now and setting it to thin disk
Write-host "Importing vApp..."
Import-vapp -Source $ovffile -OVFConfiguration $ovfconfig -Name $vAppName -VMHost $VMhost -Datastore $datastore -Diskstorageformat thin

#Set the IP details for the vShield Manager vm -- Thank you Alan!
$key = "machine.id"  
$value = "ip_0={0}&gateway_0={1}&computerName={2}&netmask_0={3}&markerid=1&reconfigToken=1" -f $vsmip, $vsmgateway, $vsmhostname, $vsmnetmask  

#Adding the above key/value as an advanced setting to the vm
New-AdvancedSetting -Entity (Get-VM -Name $vAppName) -name $key -value $value -Confirm:$false
 
#Power on the vm
Write-Host "Powering on vShield vm..."
Start-vm $vAppName
Write-Host "Waiting for vmtools to be loaded..."
Sleep 300

#Set DNS configuration first
Write-Host "Configuring vShield DNS first..."
Set-vShieldDNS -primaryDns $primaryDns1 -secondaryDns $secondaryDns1

#Waiting for 30 seconds
sleep 30
Write-Host "Configuring vShield now.."
Set-vShieldConfiguration -vCenter $vcenter -Username $vsmvCenteruser -Password $vsmvCenterpass -timeserver $timeserverinfo
