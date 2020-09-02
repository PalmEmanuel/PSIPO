# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Connect to table using the connection string in the application setting AzureWebJobsStorage
$Context = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
$Table = Get-AzStorageTable -Context $Context
# Read all previously stored S1 filings
$StoredS1s = Get-AzTableRow -Table $Table.CloudTable -PartitionKey 'IPO' | Select-Object Name,Link,Time,Id

# Get all recent S1 filings from SEC
$Results = Invoke-RestMethod 'https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&type=S-1&output=atom'
# Filter out anything not matching exactly S1, create hashtables with properties
$RecentS1s = $Results | Where-Object { $_.category.term -eq 'S-1' } | ForEach-Object {
    @{
        # Use regex to get only the company name from the title
        Name = $_.title -creplace '.+ - (.+) \(.+\) \(.+\)', '$1'
        Link = $_.link.href
        Time = Get-Date $_.updated -Format 'yyyy-MM-dd hh:mm:ss'
        Id   = $_.id
    }
}

# Add all new S1 filings to table not already there
foreach ($S1 in $RecentS1s.Where({ $_.Id -notin $StoredS1s.Id })) {
    $S1 | ConvertTo-Json | Write-Host

    $null = Add-AzTableRow -Table $Table.CloudTable -PartitionKey 'IPO' -RowKey $S1.Id -Property $S1
}