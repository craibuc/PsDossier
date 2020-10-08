<#
.SYNOPSIS

.PARAMETER ServerIntance
The SQL Server instance.

.PARAMETER Database
The SQL Server database.

.PARAMETER Credential
The SQL Server credentials.

.PARAMETER Number
Get a Vendor by its `VendorNumber`.

.PARAMETER FromDate
Get Vendors that have been modified after this date.

.PARAMETER ToDate
Get Vendors that have been modified prior to this date.

#>
function Get-DossierVendor {

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName='None', Mandatory)]
        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        [Parameter(ParameterSetName='None', Mandatory)]
        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [pscredential]$Credential,

        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [string]$Number,

        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [datetime]$FromDate,

        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [datetime]$ToDate
    )
    
    $Predicate = [pscustomobject]@{
        SELECT = "SELECT v.*, s.Code RegionCode"
        FROM = "FROM $Database..Vendor v
        LEFT OUTER JOIN $Database..State s ON v.StateID=s.ID"
        WHERE = "WHERE 1=1"
        ORDER_BY = "ORDER BY Name"
    }

    if ( $Number ) { $Predicate.WHERE += "`r`nAND VendorNumber = '$Number'" }
    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND audit_ModifiedDate >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND audit_ModifiedDate <= '$ToDate'" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential

}