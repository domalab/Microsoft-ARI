<#
.Synopsis
Inventory for Azure Advisor Scores

.DESCRIPTION
This script consolidates information for Azure Advisor Scores.
Excel Sheet Name: Advisor Scores

.Link
https://github.com/microsoft/ARI/Modules/Analytics/AdvisorScore.ps1

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

    $AdvisorScores = $Resources | Where-Object { $_.TYPE -eq 'Microsoft.Advisor/advisorScore' }

    if($AdvisorScores)
        {
            $tmp = @()

            foreach ($1 in $AdvisorScores) {
                $ResUCount = 1
                $sub1 = $SUB | Where-Object { $_.Id -eq $1.subscriptionId }
                $data = $1.PROPERTIES
                
                if ($data.scores) {
                    foreach ($score in $data.scores) {
                        $obj = @{
                            'ID'                      = $1.id;
                            'Subscription'            = $sub1.Name;
                            'Category'                = $score.category;
                            'Score'                   = $score.score;
                            'Score Type'              = $score.scoreType;
                            'Potential Score'         = $score.potentialScore;
                            'Impact'                  = $score.impact;
                            'Last Updated Time'       = $score.lastUpdatedTime;
                            'Resource U'              = $ResUCount;
                        }
                        $tmp += $obj
                        if ($ResUCount -eq 1) { $ResUCount = 0 } 
                    }
                }
            }
            $tmp
        }
}
Else {
    if ($SmaResources.AdvisorScore) {

        $TableName = ('AdvisorScoreTable_'+($SmaResources.AdvisorScore.id | Select-Object -Unique).count)

        $condtxt = @()
        # Conditional formatting for score values
        # Low scores are bad, high scores are good (0-100 scale)
        $condtxt += New-ConditionalText -Range D:D -ConditionalType LessThan -ConditionValue 30 -BackgroundColor RedPink
        $condtxt += New-ConditionalText -Range D:D -ConditionalType Between -ConditionValue 30 -SecondConditionValue 70 -BackgroundColor Yellow
        $condtxt += New-ConditionalText -Range D:D -ConditionalType GreaterThan -ConditionValue 70 -BackgroundColor LightGreen
        
        # Impact highlighting
        $condtxt += New-ConditionalText High -Range F:F -BackgroundColor Coral
                        
        $Style = New-ExcelStyle -HorizontalAlignment Center -AutoSize -NumberFormat 0

        $Exc = New-Object System.Collections.Generic.List[System.Object]
        $Exc.Add('Subscription')
        $Exc.Add('Category')
        $Exc.Add('Score')
        $Exc.Add('Score Type')
        $Exc.Add('Potential Score')
        $Exc.Add('Impact')
        $Exc.Add('Last Updated Time')

        $ExcelVar = $SmaResources.AdvisorScore 

        $ExcelVar | 
        ForEach-Object { [PSCustomObject]$_ } | Select-Object -Unique $Exc | 
        Export-Excel -Path $File -WorksheetName 'Advisor Scores' -AutoSize -MaxAutoSizeRows 100 -TableName $TableName -TableStyle $tableStyle -ConditionalText $condtxt -Style $Style
    }
    
}
