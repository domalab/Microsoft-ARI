<#
.Synopsis
Inventory for Azure Outages

.DESCRIPTION
This script consolidates information for Azure Outages and Service Issues.
Excel Sheet Name: Outages

.Link
https://github.com/microsoft/ARI/Modules/Analytics/Outages.ps1

.COMPONENT
This powershell Module is part of Azure Resource Inventory (ARI)

.NOTES
Version: 1.0.0
First Release Date: 21st March, 2025
Authors: Claudio Merola

#>

<######## Default Parameters. Don't modify this ########>

param($SCPath, $Sub, $Intag, $Resources, $Retirements, $Task ,$File, $SmaResources, $TableStyle, $Unsupported)
If ($Task -eq 'Processing') {

    $Outages = $Resources | Where-Object { $_.TYPE -eq 'microsoft.resourcehealth/events' -and ($_.properties.eventType -eq 'Maintenance' -or $_.properties.eventType -eq 'ServiceIssue')}

    if($Outages)
        {
            $tmp = @()

            foreach ($1 in $Outages) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                
                foreach ($Tag in $Tags) {
                    $obj = @{
                        'ID'                        = $1.id;
                        'Subscription'              = $sub1.Name;
                        'Resource Group'            = $1.RESOURCEGROUP;
                        'Event Type'                = $data.eventType;
                        'Event Source'              = $data.eventSource;
                        'Title'                     = $data.title;
                        'Status'                    = $data.status;
                        'Impact Type'               = $data.impactType;
                        'Impact'                    = $data.impact;
                        'Start Time'                = $data.startTime;
                        'End Time'                  = $data.endTime;
                        'Last Update Time'          = $data.lastUpdateTime;
                        'Resource U'                = $ResUCount;
                        'Tag Name'                  = [string]$Tag.Name;
                        'Tag Value'                 = [string]$Tag.Value
                    }
                    $tmp += $obj
                    if ($ResUCount -eq 1) { $ResUCount = 0 } 
                }
            }
            $tmp
        }
}
Else {
    if ($SmaResources.Outages) {

        $TableName = ('OutagesTable_'+($SmaResources.Outages.id | Select-Object -Unique).count)

        $condtxt = @()
        $condtxt += New-ConditionalText ServiceIssue -Range D:D -BackgroundColor RedPink
        $condtxt += New-ConditionalText -Range I:I -ConditionalType ContainsText -ConditionalTextColor Brown -BackgroundColor Yellow
                        
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Event Type')
        $Exc.Add('Event Source')
        $Exc.Add('Title')
        $Exc.Add('Status')
        $Exc.Add('Impact Type')
        $Exc.Add('Impact')
        $Exc.Add('Start Time')
        $Exc.Add('End Time')
        $Exc.Add('Last Update Time')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.Outages 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Outages' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
    
}
