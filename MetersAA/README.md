﻿
# About METERSAutomatedAudit
----

Organizations permitted to query FBI CJIS are assigned Originating Agency Identifiers (ORI) and Terminal IDs (TermID). Organizations are responsible for tracking the assignment of ORI and TermID pairs (DeviceID) to computers, and additionally, knowing the locations of these computers.

Using a masterlist that attributes DeviceIDs to a Physical Location, as well as Subnets to a Physical Location, __*METERSAutomatedAudit* will locate any ORI and TermID and state if it was or was not found at its registered location.__

![frontend homepage](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/index-masterlist_edited-60.png?raw=true)    

# Assumptions
----

- ORI and TermID pairs are 'registered' to a physical address. In other words, **you have a masterlist** which states that you expect to find these ORI and TermID pairs at this physical address.
- METERSAutomatedAudit will be installed on an **x64 version of Windows 10 Pro or its server equivalent**, and does not already have IIS installed
- The account context from which this code is executed will have **authentication rights to access the clients** via SMB admin shares:
>\\\MyMETERSComputer.domain.local\c$\Program Files\\...

  ## Disclaimer 
  The crawler portion of the application hinges on the Powershell cmdlet 'Test-Path' throwing an 'Access is denied' error if the account context does not have permissions to access a remote network location.
    If the crawler is executed using an Administrator account local to the computer, instead of an LDAP/AD account, the cmdlet 'Test-Path' will not throw an 'Access is denied' error.
    Instead, 'Test-Path' will falsely return 'False', which in terms of the program means that no ORI or TermID was found on the computer.
    
  __TLDR:__
    
  __Run the crawler (/crawler/stubForMETERSAA.ps1) using an LDAP/AD account.__

# Installing
----

## 0) Prerequisites

**Using an Administrator account**, the following must be installed on the Windows system running the METERSAutomatedAudit suite:

- [Powershell version 7 or greater](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2)
- [Powershell module 'PSSQLite'](https://www.powershellgallery.com/packages/PSSQLite/1.1.0)
    * METERSAutomatedAudit should install this on its own but it does not hurt to manually install it
- [Nmap](https://nmap.org/download)
- [Python 3](https://www.python.org/downloads/)
    * During installation of Python 3, select 'Custom installation' and  make sure you check the following:
        * Install launcher for all users (recommended)
        * Add Python 3.XX to PATH
        * pip
        * Python test suite
        * py launcher & for all users (requires elevation)
        * Install for all users
        * Associate files with Python (requires the py launcher)
        * Create shortcuts for install applications
        * Add Python to environment variables
        * Precompile standard library
and lastly, make sure the 'Customize install location' is accessible to all users (ex. *C:\Program Files\Python3XX*)

## 1) Update Powershell Execution Policy
The initialization scripts and crawler portion of the application are written in Powershell. To ensure the scripts execute, you'll want to update the Powershell Execution Policy to *RemoteSigned.* Open an x64 version of the Powershell console and execute the following: 
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

For more information, see the following:

https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.2

## 2) Download and Extract
Download MetersAutomatedAudit and extract its contents to the root of C:\ . The file paths should be as follows:
> C:\MetersAA\

> C:\MetersAA\crawler\

> C:\MetersAA\frontend\

**The application *MUST* be extracted to the above location otherwise the proceeding initialization script will fail.**

## 3) Run RUNME.ps1 (only on initial setup)

From an x64 version of the Powershell console, navigate to the *MetersAA* directory and execute the *RUNME.ps1* script. 

> .\RUNME.ps1

This will install + configure Microsoft's IIS Web Server, which serves the front end portion of the application, and additionally initialize the front end database.

You will be asked to create a user to manage the front end application. **Remember these credentials for the next step.**

After the script completes, **you'll need to start the IIS webserver and MetersAutomatedAudit site.**

Using an administrator account, open Internet Information Services (IIS) Manager.  First start the server then start the site.
For help, use the following: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/jj635851(v=ws.11)

To verify that everything completed successfully, visit the website *http://localhost/* . You should see a simple web page with the text **METERS Device IDs List** at the top:

![empty homepage](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/metersaa_empty-page_edited-60.png?raw=true)

# Configuring (DO NOT SKIP)
----

## 4) Update database permissions

You'll want to ensure that the appropriate user accounts have permissions to read and write to the frontend's database (*\frontend\db.sqlite3*).

The simplest method is to grant 'Everyone' Read + Write permissions to the file:

![security permissions](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/db-sqlite3_security-permissions.PNG?raw=true)

**Failing to perform this step will result in errors in step 6.**

## 5) Update ALLOWED_HOSTS

To be able to access the frontend website from anywhere on the network, you'll need to update the *ALLOWED_HOSTS* array variable with the host computer's DNS name in **\frontend\mysite\settings.py**

For example:
> ALLOWED_HOSTS = ['localhost','127.0.0.1','MYCOMPUTERNAME01','MYCOMPUTERNAME01.domain.local']

After updating this variable, you should be able to access the frontend page from any computer in the network by visiting *http://MYCOMPUTERNAME01/* or *http://MYCOMPUTERNAME01.domain.local/*

## 6) Add a Location, a Subnet, and some Device Ids

The goal of *METERSAutomatedAudit* is to determine if a DeviceID is at the appropriate physical location. To do this, you must define the following:

- Physical Location
- Subnets of Physical Location
- DeviceIDs registered to Physical Location

This is done via the admin page: *http://localhost/admin*

![admin login](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/admin-login_edited-60.png?raw=true)

Using the credentials you created in Step 3, login to the admin page. On the left side you will see a section called **Masterlist**.

![admin post login](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/admin-post-login_edited-60.png?raw=true)

Click **Locations** then click the **Add Location** button in the upper-right corner. You will be presented with a series of text boxes. Enter a location name into the *Name* textbox and then click the **Save** button in the lower-right corner.

![locations](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/admin_location-add_edited-60.png?raw=true)

Now that a location has been defined, we need to define the Subnets tied to it.

In the **Masterlist** section, click **Subnets** then click the **Add Subnet** button in the upper-right corner. You will be presented with an *IP address* textbox and a *Location* drop-down. In the textbox, enter a subnet. For example:
> 172.2.2.*

This field will be used by the Nmap program to scan the subnet for active clients. In theory, any subnet string understood by Nmap should work in this field. However, the application was developed using the star (*) syntax.

In the drop-down, select the Location you previously created then click the **Save** button in the lower-right corner.

![subnets](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/admin_subnet-add_edited-60.png?raw=true)

Lastly, we need to assign DeviceIDs to a Location.

In the **Masterlist** section, click **Device ids** then click the **Add Device ID** button in the upper-right corner. You will be presented with a series of editable fields. 

In the *ORI* textbox, enter the ORI of a DeviceID registered to the location you previously created.

In the *Term ID* textbox, enter the TermID associated with the ORI you just entered.

In the *Location* drop-down, select the location you previously created.

Set the *Date* and *Time* fields, then click the **Save** button in the lower-right corner.

![deviceid](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/admin_deviceid-add_edited-60.png?raw=true)

Now that the masterlist has been defined, we need to verify the crawler's configuration.

## 7) Update crawler's config.json

The crawler's configuration file, **\crawler\config.json**, contains the following:
```
{
  "pathToNmapExecutable": "C:\Program Files (x86)\Nmap\nmap.exe",
  "nmapResultFilterRegex": "",
  "stateTwoLetterAbbreviation": "MD",
  "boolUsingDjangoFrontEnd": "True"
}
```
It may already be correct, however, you must __verify/correct the path to the Nmap executable.__

**At this point the program should function but it is strongly advised that you update the fields *nmapResultFilterRegex* and *stateTwoLetterAbbreviation*.**

### nmapResultFilterRegex

Hosts to scan are calculated from the nmap command **nmap -sn subnet** and return a result like:

> Nmap scan report for METERSTERM001.domain.local (172.2.2.58)
Host is up (0.0010s latency).
MAC Address: 02:00:00:00:00:00 (Unknown)
Nmap scan report for 172.2.2.59 (172.2.2.59)
Host is up (0.0010s latency).
MAC Address: 01:00:00:00:00:00 (Unknown)

If *nmapResultFilterRegex* is not set, all active hosts in the subnet will be searched for ORIs and TermIDs. Any ORIs and TermIDs found will be associated with the host IP address.

The issue is that in a DHCP networking environment, host IP addresses will change; over time the information logged in the database will not be correct.

By setting *nmapResultFilterRegex* with a Regular Expression (RegEx), the set of active hosts searched will only be those whose DNS names match the RegEx statement, and the information logged will be associated with the host DNS names.    

To only look at hosts that conform to a naming like **METERS????.domain.local**, we set *nmapResultFilterRegex* as such:
>nmapResultFilterRegex = "\s(METERS).*\.domain\.local"

### stateTwoLetterAbbreviation
*METERSAutomatedAudit* looks at two sources for an ORI and TermID. If not found in the first source, then it looks to the second source, using positions 1 and 2 of an ORI as a point of reference. Positions 1 and 2 correlate to the state or country in which an organization is physically located.

The config uses 'MD' (a.k.a. Maryland, USA) as the default. If this is not changed to the state/country of your ORIs, then the query to the second source will always result in a 'not found'.   

## 8) Add additional credentials to credentials.json (OPTIONAL)
During execution of the crawler, if the account context from which the script is run does not have the appropriate authentication to iterate an active host, the host will be entered into a secondary
processing queue.

If hosts exist in the secondary processing queue, and a **/crawler/credentials.json** file exists, then the crawler will attempt to iterate those hosts with the credentials found in credentials.json.

There should already exist the file **/crawler/__credentials.json**. Simply edit the file with your additional credentials and then rename it to **credentials.json**. 

# Running the program
----

Open an **x64 version of the Powershell 7 console**. Within the console window, browse to the crawler directory within the MetersAA folder:
> cd C:\MetersAA\crawler\

Once there, simply execute the script **stubForMETERSAA.ps1**:
> .\stubForMETERSAA.ps1

During execution the following will occur:

1. all subnets defined in your masterlist from *Step 6* will be obtained by the crawler from *http://localhost/masterlist/subnets/*
2. For each subnet, Nmap will look for active hosts. If a RegEx was defined in *\crawler\config.json*, active hosts will be narrowed down to DNS names matching the RegEx:

    ![nmap scan](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/metersaa_nmap_07012022-1348_edited-60.png?raw=true)

3. Using the authorization of the account running the script, hosts will be scanned for an ORI and TermID. If the account is authorized to access the host, the scan results will be logged to the database. If the account is not authorized (i.e. 'Access is denied.'), the host will be marked to be re-scanned using different credentials.
    
    ![parallel execution](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/metersaa_parallel-returns_07012022-1349_edited-60.png?raw=true)

4. If any hosts have been marked to be re-scanned, and credentials have been provided in *\crawler\credentials.json*, then hosts will be re-scanned using these credentials. **Any hosts that are not able to be scanned using these credentials will be logged to *\crawler\logs\credentials-unknown.txt*.**
5. After steps 2 thru 4 have been completed for a subnet, the information in the database will be mirrored to the **front end's** database.
    
    ![mirroring](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/metersaa_database-mirroring_07012022-1350_edited-60.png?raw=true)

The script will stop executing once all subnets from the masterlist have been scanned.

The program flow is described by the diagram below:

![workflow diagram](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/meters-automated-audit-workflow_07052022-1317.png?raw=true) 

If you refresh the webpage *http://localhost* or *http://localhost/masterlist/* you should see something like the following:

![masterlist homepage](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/index-masterlist_edited-60.png?raw=true)

The results are interpreted as follows:

- **yellow row** = DeviceID was found on a computer at a location that does not match the location to which the DeviceID is registered
- *grey row* = DeviceID was not found anywhere
- white row = DeviceID was found on a computer at the location matching the location to which the DeviceID is registered

# Closing Comments
----
A single run of the crawler will likely not capture all DeviceID information, as active hosts on a network will vary over time.

To gain an accurate accounting of DeviceIDs within your organization, you will need to run the crawler (*/crawler/stubForMetersAA.ps1*) at various times during a day over a period of days/weeks/months.

The easiest way to do this is by making a *Scheduled Task* that will run the crawler script via Powershell 7 at various times of day.

![task scheduler](https://github.com/b-mf-a/METERSAA/blob/main/MetersAA/images/task-scheduler_edited-60.png?raw=true)
