<#
.Synopsis
Inventory for Azure Support Tickets

.DESCRIPTION
This script consolidates information for Azure Support Tickets.
Excel Sheet Name: Support Tickets

.Link
https://github.com/microsoft/ARI/Modules/Analytics/SupportTickets.ps1

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

    $SupportTickets = $Resources | Where-Object { $_.TYPE -eq 'microsoft.support/supporttickets' }

    if($SupportTickets)
        {
            $tmp = @()

            foreach ($1 in $SupportTickets) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                $Tags = if(![string]::IsNullOrEmpty($1.tags.psobject.properties)){$1.tags.psobject.properties}else{'0'}
                
                foreach ($Tag in $Tags) {
                    $obj = @{
                        'ID'                        = $1.id;
                        'Subscription'              = $sub1.Name;
                        'Resource Group'            = $1.RESOURCEGROUP;
                        'Support Ticket ID'         = $1.NAME;
                        'Title'                     = $data.title;
                        'Description'               = $data.description;
                        'Service'                   = $data.serviceId;
                        'Problem Classification'    = $data.problemClassificationId;
                        'Severity'                  = $data.severity;
                        'Status'                    = $data.status;
                        'Created Date'              = $data.createdDate;
                        'Modified Date'             = $data.modifiedDate;
                        'Contact Method'            = $data.contactDetails.contactMethod;
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
    if ($SmaResources.SupportTickets) {

        $TableName = ('SupportTable_'+($SmaResources.SupportTickets.id | Select-Object -Unique).count)

        $condtxt = @()
        $condtxt += New-ConditionalText Highest -Range H:H -BackgroundColor RedPink
        $condtxt += New-ConditionalText High -Range H:H -BackgroundColor Coral
        $condtxt += New-ConditionalText Open -Range I:I -BackgroundColor Yellow
                        
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Resource Group')
        $Exc.Add('Support Ticket ID')
        $Exc.Add('Title')
        $Exc.Add('Description')
        $Exc.Add('Service')
        $Exc.Add('Problem Classification')
        $Exc.Add('Severity')
        $Exc.Add('Status')
        $Exc.Add('Created Date')
        $Exc.Add('Modified Date')
        $Exc.Add('Contact Method')
        if($InTag)
            {
                $Exc.Add('Tag Name')
                $Exc.Add('Tag Value') 
            }

        $ExcelVar = $SmaResources.SupportTickets 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Support Tickets' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
    
}
