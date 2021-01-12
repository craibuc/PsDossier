<#
.SYNOPSIS
Replace characters in the Dossier..Document.Invoice field with 

.PARAMETER ServerInstance
.PARAMETER Database
.PARAMETER Credential

#>

function Repair-DossierDocumentInvoiceNumber {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [string]$Pattern = '[<>:"\/\\\|\?\*]',

        [Parameter()]
        [string]$Replacement = '-'
    )

    # correct the invoice #
    $Query = 
@"
UPDATE  $Database..Document
SET     Invoice = Replace(Invoice, Substring(Invoice, PATINDEX('%$Pattern%',Invoice), 1), '$Replacement')
WHERE   1=1
AND     PATINDEX('%$Pattern%',Invoice) > 0
"@
    Write-Debug $Query

    if ( $PSCmdlet.ShouldProcess('UPDATE Document','Invoke-Sqlcmd'))
    {
        Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential
    }

}