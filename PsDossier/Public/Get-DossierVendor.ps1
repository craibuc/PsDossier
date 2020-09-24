<#
.SYNOPSIS

.PARAMETER ServerIntance
The SQL Server instance.

.PARAMETER Database
The SQL Server database.

.PARAMETER Credential
The SQL Server credentials.

.PARAMETER ID
Get a Vendor by its `ID`.

.PARAMETER Name
Get a Vendor by its `Name`.

.PARAMETER Number
Get a Vendor by its `VendorNumber`.

#>
function Get-DossierVendor {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(ParameterSetName='ByID', Mandatory)]
        [int]$ID,

        [Parameter(ParameterSetName='ByName', Mandatory)]
        [string]$Name,

        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [string]$Number
    )
    
    $Predicate = [pscustomobject]@{
        SELECT = "SELECT *"
        FROM = "FROM $Database..Vendor"
        WHERE = "WHERE 1=1"
        ORDER_BY = "ORDER BY Name"
    }

    if ( $ID ) { $Predicate.WHERE += "`r`nAND ID = $ID" }
    if ( $Name ) { $Predicate.WHERE += "`r`nAND Name = '$Name'" }
    if ( $Number ) { $Predicate.WHERE += "`r`nAND Number = '$Number'" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential

}