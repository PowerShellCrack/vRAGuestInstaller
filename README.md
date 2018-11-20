# vRAGuestInstaller
Install guest agent on vRA 7.4/7.5 automatically....sort of

Be sure the read the README.md in the scripts folder

# Reason
Each time I have tempalte issues or we've upgrade vRA or certs have changed we need to update the agents in out Templates. 
On top of that we also need to update the templates to the latest patches. So I wrote a few batch files to launch on the desktop or in command line. 

## InstallAgentAsDarwin.bat
This script id designed to install the VRA Guest Agent and VRA Appd Agent using the script provide by vRA (with little modification )
 1. Change the variable in the top section of the script for vRA App, mgr and cert thumbprints
 2. Copy entire project and subfolder to c: drive. 
 3. Right click this InstallAgentAsDarwin.bat and select runas administrator
 4. Type in Darwins password
 5. shutdown when done
 
The script prompts in the beginning for the Darwin's password. After that it will auto create the account and ensure no residual account profiles exists (if deleted before).
It also set the local account to not expire and as a administrator
If all variables are correct, script will download and install the agents
After completed, it promtps to be shutdown. If left alone for 30sec, it will auto shutdown

## InstallAgentAsSYSTEM.bat
Does exactly as the Darwin script above does but instead uses the bulletin SYSTEMS account (no password required). Fully automated

In addition to the above script installing the agents, it also copied a vbscript to a scripts folder folder for vRA Guest Agent. This script I wrote to manage local user accounts settings and passwords. Its has a bunch of switches that allow you to automatically add user to admin groups and administer the admin account. This is especially useful during vRA deployment. 

To do this
 - create a property for each business group (bg.security.group) that is the same as an AD security group. 
 - create a property definition for setting the windows password (windows.os.password)
 - create a Property group:

`
VirtualMachine.Software0.Name = UserAndGroupControl
VirtualMachine.Customize.WaitComplete = True
VirtualMachine.Software0.ScriptPath = cscript c:\VRMGuestAgent\scripts\UserAndGroupControl.vbs /admin:newadmin /password:{windows.os.password} /group:{bg.security.group} /user:{Owner}
VirtualMachine.Admin.UseGuestAgent = True
`

 - Use the /admin swithc to configure the admin account name based on what the vm has (eg. newadmin)
 - in the blueprint, add the windows password property, with show in request enabled, to the virtual machine custom properties. 
 - in the blueprint, add the UserAndGroupControl property group to the virtual machine property group section. 
 - in the blueprint, configure the VM so it joins the domain (cloneSpec)
 - Publish and Entitle the blueprint
 - Request the item, and if done correctly the password and security group will be passed during deployment, changing the load admin password and adding the group. 


## UninstallAgent.bat
This script will remove the old Agents if they exists and delete their folders. SHould be ran before any other if doing a cleanup
It will also remove the Darwin account. However since the Darwin account was running as a service, it is considered to be in use even thought the active service has been removed. So there will be a residula folder residing in C:\Users folder. The InstallAgentAsDarwin.bat scritp will clean that up before creating a new Darwin account. 

## InstallUpdatesOnly.bat
this script installs updates from WSUS point. It will also install PowerShell 5.1 on Windows 7, 8 , 8.1, 2012 and 2012r2. Unlike typical scripts where registry key are set. 
This one use LGPO.exe to build the WSUS pointer locally. I did this so that it can be viewed and changed via gpedit.msc. There are a few prerequisites that must be done. Follow the README.md in the Updates folder