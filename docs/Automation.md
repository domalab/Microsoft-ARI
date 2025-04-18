<br/>

# Azure Resource Inventory Automation Account v3.6

<br/>

<br/>

### This section explains how to create an Automation Account to run Azure Resource Inventory automatically.  

<br/>

<br/>

## What is required to run ARI as an Automation Account?

<br/>

<br/>

#### 1) Azure Automation Account
#### 2) Azure Storage Account
#### 3) Azure Blob Container inside the Storage Account

<br/>

<br/>

## These are the steps you have to do after creating the Automation Account:

<br/>

<br/>

### On the Automation Account, enable the System Assigned Identity:

<br/>

<p align="center">
<img src="images/ARIAUT_Identity.png">
</p>

<br/>

#### This will create an identity in Entra ID.

#### Now we are going to use that identity to give the following permissions to the Automation Account:

#### 1) Reader in the Management Group (for the script to be able to read all resources from Azure):

<br/>

<p align="center">
<img src="images/AUTv4Tenant.png">
</p>

<br/>

#### 2) Storage Blob Data Contributor to the Storage Account

<br/>

<p align="center">
<img src="images/AUTv4STGPerm.png">
</p>

<br/>

### Now, back to the Automation Account, switch to the new Runtime Environment Experience:

<br/>

<p align="center">
<img src="images/ARIAUT_Runtime.png">
</p>

<br/>

### Now, create a new Runtime Environment Experience:

<br/>

<p align="center">
<img src="images/ARIAUT_NewRunTime.png">
</p>

<br/>

### The only tested (and supported) version was __7.4__:

<br/>


### In the "Packages" pane, import the following Modules from Gallery:

<br/>

<p align="center">
<img src="images/ARIAUT_RuntimePackages.png">
</p>

<br/>

#### 1) "AzureResourceInventory"
#### 2) "ImportExcel"
#### 3) "Az.ResourceGraph"
#### 4) "Az.Accounts"
#### 5) "Az.Storage"
#### 6) "Az.Compute"
#### 7) "Az.CostManagement" (This is only necessary when using the -IncludeCosts)

<br/>


### After the Runtime finishes adding all the modules, create a Powershell Runbook:

<br/>

<p align="center">
<img src="images/ARIAUT_Runbook.png">
</p>

<br/>

### Now just add the "Invoke-ARI" command line inside the runbook:


<br/>


<p align="center">
<img src="images/ARIAUT_Runbookcmd.png">
</p>

<br/>

````
NOTE: Make sure to select the Runtime Environment you created.
````

<br/>

The line must contain the following parameters:

````
-TenantID
-Automation
-StorageAccount
-StorageContainer
````

<br/>


i.e: 

**Invoke-ARI -TenantID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" -Automation -StorageAccount "stgaccari001" -StorageContainer "reports"**


<br/>

The parameter "StorageAccount" is used to choose the Storage Account where the report will be placed and the "StorageContainer" parameter is used to choose the container within that Storage Account where the report will be placed.

<br/>

<br/>

#### Hit Save and Publish and you are ready to go.

<br/>

