# vRAGuestInstaller
Install guest agent on vRA 7.4/7.5 automatically....sort of

## REASON
Each time ther is an issue with deploying a blueprint its always something with the template. For instance, vRA is upgraded or certs have changed and the agents need to be updated. 
Also each month the templates need to updated with the latest patches. 

I wrote a few scripts to automate and solve these issues quickly. 

Be sure the read the [README.md](scripts/README.md) in the scripts folder

## SCRIPTS
**InstallAgentAsDarwin.bat**

This script id designed to install the VRA Guest Agent and VRA Appd Agent using the script provide by vRA (with little modification )
 1. Change the variables in the top section of the script for vRA App, mgr and cert thumb prints
 2. Copy entire project and sub folder to c: drive. 
 3. Right click this InstallAgentAsDarwin.bat and select runas administrator
 4. Type in Darwins password
 5. shutdown when done
 
### Process: 

The script prompts in the beginning for the Darwin's password. After that it will auto create the account and ensure no residual account profiles exists (if deleted before).
It also set the local account to not expire and as a administrator
If all variables are correct, script will download and install the agents
After completed, it prompts to be shutdown. If left alone for 30sec, it will auto shutdown

**InstallAgentAsSYSTEM.bat**

Does exactly as the Darwin script above does but instead uses the bulletin SYSTEMS account (no password required). Fully automated

### Additions

In addition to the above script installing the agents, it also copied a vbscript to a scripts folder folder for vRA Guest Agent. This script I wrote to manage local user accounts settings and passwords. Its has a bunch of switches that allow you to automatically add user to admin groups and administer the admin account. This is especially useful during vRA deployment. 

To do this:
 - create a property for each business group (bg.security.group) that is the same as an AD security group. 
 - create a property definition for setting the windows password (windows.os.password)
 - create a Property group:

        VirtualMachine.Software0.Name = UserAndGroupControl
        VirtualMachine.Customize.WaitComplete = True
        VirtualMachine.Software0.ScriptPath = cscript c:\VRMGuestAgent\scripts\UserAndGroupControl.vbs /admin:newadmin /password:{windows.os.password} /group:{bg.security.group} /user:{Owner}
        VirtualMachine.Admin.UseGuestAgent = True

 - Use the /admin switch to configure the admin account name based on what the vm has (eg. newadmin)
 - in the blueprint, add the windows password property, with show in request enabled, to the virtual machine custom properties. 
 - in the blueprint, add the UserAndGroupControl property group to the virtual machine property group section. 
 - in the blueprint, configure the VM so it joins the domain (cloneSpec)
 - Publish and Entitle the blueprint
 - Request the item, and if done correctly the password and security group will be passed during deployment, changing the load admin password and adding the group. 
 - If you need to debug the UserAndGroupControl vbscript, use the /debug switch. The log is place right next to the script and will display the password in plain text. 


**UninstallAgent.bat**

 1. Change the variables in the top section of the script for fqdn and wsus info
 
This script will remove the old Agents if they exists and delete their folders. Should be ran before any other if doing a cleanup
It will also remove the Darwin account. However since the Darwin account was running as a service, it is considered to be in use even thought the active service has been removed. So there will be a residual folder residing in C:\Users folder. The InstallAgentAsDarwin.bat script will clean that up before creating a new Darwin account. 

**InstallUpdatesOnly.bat**

this script installs updates from WSUS point. It will also install PowerShell 5.1 on Windows 7, 8 , 8.1, 2012 and 2012r2. Unlike typical scripts where registry key are set. 
This one use LGPO.exe to build the WSUS pointer locally. I did this so that it can be viewed and changed via gpedit.msc. There are a few prerequisites that must be done. 
 - Follow the [README.md](Updates/README.md) in the Updates folder