<#
    .SYNOPSIS
    The purpose of this function is to get a list of Virtual Machines that NSX-T knows about.
    .DESCRIPTION
    The purpose of this function is to get a list of Virtual Machines that NSX-T knows about.
    .NOTES
    Author: W. Kyle Setchel
    .PARAMETER NSXTServer
    This is the NSXT's server URL or IP address. No need for anything else with it.
    .PARAMETER Credentials
    This is a PSCredential object. Might support API Key later.
    .PARAMETER SearchTerm
    This is the Virtual Machine you want to search for. To get info back on it.
    .PARAMETER ResourceType
    This is the Type of device you are searching for. Even though this function focuses on VMs, you can actually specify a different ResourceType. 
    .PARAMETER LogFileName
    This is the log file name. Default value matches the function name.
   .PARAMETER LogFolderPath
    This is the path to the log file. Default value is to put it in the environment temp directory.
    .EXAMPLE
    Search-NSXTVM -NSXTServer "NSXMGR.contoso.local" -Credentials $Creds -SearchTerm "TestVM" -ResourceType "VirtualMachine"
    This function will return a PowerShell object of all VMs that this NSXT Manager knows about, and information about those VMs.
#>
function Search-NSXTVM () {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$NSXTServer,
            
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,

        [Parameter(Mandatory)]
        [string]$ResourceType,

        [Parameter(Mandatory)]
        [string]$SearchTerm,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFolderPath = "$env:temp",

        [Parameter(Mandatory = $false)]
        [string]$LogFileName = "Search-NSXT-VM.log"
    )


    $RMethod = "Get"

    $APIUrl = "policy/api/v1/search/query?query=resource_type" + ":" + $ResourceType + " AND " + $SearchTerm
    #$APIUrl = "policy/api/v1/search/query?query=" + $SearchTerm
    $FullUrl = "https://" + $NSXTServer + "/" + $APIUrl

    $B64_Creds = [Convert]::toBase64String([System.Text.Encoding]::UTF8.GetBytes("$($Credentials.UserName):$($Credentials.GetNetworkCredential().Password)"))
    $header = @{Authorization = "Basic $B64_Creds" }


    $Response = Invoke-WebRequest -Method $RMethod -Uri $FullUrl -Headers $header -ContentType 'application/json'
    $CResponse = $Response | ConvertFrom-Json

    $ObjectArray = @()

    if ($Response.StatusCode -ne 200) { return $Response }
    if (($Response.StatusCode -eq 200) -and ($CResponse.result_count -eq 0)) { return "0" }
    

    $returncount = 0
    ForEach ($r in $CResponse.results) {
        $returncount++
        $Object = [PSCustomObject]@{
            VM_Name       = $r.display_name
            Security_Tags = $r.Tags
            Resource_Type = $r.Resource_Type
            Guest_Info    = $r.Guest_Info
            Host_id       = $r.Host_id
            External_id   = $r.External_id
            Compute_IDs   = $r.Compute_IDs
            Source        = $r.source
            Power_State   = $r.Power_State
            Type          = $r.Type
            ReturnCount   = $returncount
             
    
        }
        $ObjectArray += $Object
    }

    return $ObjectArray

}

#$Return = Search-NSXTVM -NSXTServer "NSXMGR.contoso.local" -Credentials $NSXCreds -ResourceType "VirtualMachine" -SearchTerm "TestVM"