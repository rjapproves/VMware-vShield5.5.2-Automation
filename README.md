VMware-vShield5.5.2-Automation
==============================

vShield 5.5.2 Deployment Automation Using PowerCli + Restful API.

++++++
Notice == Script tested on ESXi 5.5 running vCenter 5.5 Update 2. No guarantees. Ensure you run it on test environment before executing in production. Owner assumes ZERO liability.
++++++

Introduction
============

The Script allows you to deploy vShield Appliance to a vCenter and also configures it with the vCenter.

It uses Powershell+PowerCLI to deploy the vShield Appliance and then uses the Restful API to configure it.

Prerequisites
=============

1. vShield Appliance OVA File.
2. Powershell version 4.0
3. PowerCli version 5.8 Release 1
4. Network able to access vCenter and vShield IP's. 

Parts
=====
a. config.xml
b. vShield-deploy.ps1

Execution Method
================

Follow the below steps to properly execute the file.

1. Ensure config.xml and vShield-deploy.ps1 are in the same folder.
2. Populate config.xml with all the info as per your vcenter and vshield info. This allows you to configure your inputs before you execute the script.
3. Execute the script once config.xml is configured.

Contents Config.xml
===================
```xml
<?xml version="1.0"?>
<MasterConfig>

<vcenterconfig>
<vcenter>VCENTER-FQDN</vcenter>
<vcusername>USERNAME FOR VCENTER</vcusername>
<vcpassword>PASSWORD FOR VCENTER USER</vcpassword>
</vcenterconfig>

<Config>
<vsmovalocation>LOCATION OF VSHIELD APPLIANCE OVA FILE</vsmovalocation>
<MgmtNetwork>MANAGEMENT NETWORK FOR VSHIELD APPLIANCE</MgmtNetwork>
<ClusterName>CLUSTER TO DEPLOY VSHIELD APPLIANCE</ClusterName>
<pmpassword>PRIVILEGED USER PASSWORD</pmpassword>
<userpassword>USER PASSWORD</userpassword>
<vAppName>VSHIELD APPLIANCE NAME FQDN</vAppName>
<vsmip>VSHIELD APPLIANCE IP</vsmip>
<vsmnetmask>NETMASK</vsmnetmask>
<vsmgateway>GATEWAY</vsmgateway>
<vsmhostname>VSHIELD APPLIANCE HOSTNAME</vsmhostname>
<vsmvCenteruser>VSHIELD-VCENTER USER NAME</vsmvCenteruser>
<vsmvCenterpass>VSHIELD-VCENTER PASSWORD</vsmvCenterpass>
<primarydns>PRIMARY DNS FOR VSHIELD</primarydns>
<secondarydns>SECONDARY DNS FOR VSHIELD</secondarydns>
<timeserverinfo>NTP TIME SERVER</timeserverinfo>
</Config>

</MasterConfig>
```
Known Issues
============

1. Once vshield appliance is deployed and ip'd - script cannot reach the restful api and times out.
Solution - The powershell box where the script executes should be able to reach both the vcenter and the vshield appliance. It should be on the same network. A terminal server will be best in these situations.

2. Script errors at "Configuring vShield now.."
Solution - Ensure your DNS can reach the vcenter server. If you use an IP then ensure vShield can reach the vcenter server on that ip.

Other Issues
============

1. Unable to reset Admin password - There seems to be an issue with the restful api and a VMware ticket has been raised. 
2. No new user addition - Additional users functionality has not yet been added.

