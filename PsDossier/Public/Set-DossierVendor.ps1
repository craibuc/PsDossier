function Set-DossierVendor {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [string]$Name,

        [Parameter()]
        [string]$VendorNumber
    )

    # make a copy of Dictionary
    $Fields = @{} + $PSBoundParameters

    # remove the information
    $Fields.Remove('ServerInstance')
    $Fields.Remove('Database')
    $Fields.Remove('Credential')

    $Predicate = [pscustomobject]@{
        UPDATE = "UPDATE  $Database..Vendor"
        SET = @()
    }

    if ( $Name ) { $Predicate.SET += "Name = '$Name'" }
    if ( $VendorNumber ) { $Predicate.SET += "VendorNumber = '$VendorNumber'" }
    $Predicate.SET += "audit_ModifiedDate = GetDate()"

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential

}