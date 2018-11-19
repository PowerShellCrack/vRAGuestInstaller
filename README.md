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
Does exactly as the Darwin scritp above does but instead uses the bulletin SYSTEMS account (no password required). Fully automated

## UninstallAgent.bat
This script will remove the old Agents if they exists and delete their folders. SHould be ran before any other if doing a cleanup
It will also remove the Darwin account. However since the Darwin account was running as a service, it is considered to be in use even thought the active service has been removed. So there will be a residula folder residing in C:\Users folder. The InstallAgentAsDarwin.bat scritp will clean that up before creating a new Darwin account. 

## InstallUpdatesOnly.bat
