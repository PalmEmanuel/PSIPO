using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)



# 1. Get previously saved IPOs filings from storage table
# 2. Get S-1 filings from RSS feed
# 3. Compare the two lists, select only unique new ones
# 4. Return the results through the output binding

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
