<#
.SYNOPSIS
Remove characters that are not valid for a file name from the invoice #.  

.PARAMETER ServerInstance
.PARAMETER Database
.PARAMETER Credential

.PARAMETER TableName
The table to be scrubbed.

.PARAMETER Pattern
The regular-expression pattern that indentifies invalid characters.

.PARAMETER Replacement
The character that will replace all instances of invalid characters.
#>

function Repair-DossierInvoiceNumber {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [ValidateSet('Document','InventoryAdjustmentDocument')]
        [string]$TableName,

        [Parameter()]
        [string]$Pattern = '[<>:"\/\\\|\?\*]',

        [Parameter()]
        [string]$Replacement = '-'
    )

    # correct the invoice #
    $Query = switch ($TableName ) {
        'Document' { 
            "UPDATE  $Database..Document
            SET     Invoice = Replace(Invoice, Substring(Invoice, PATINDEX('%$Pattern%',Invoice), 1), '$Replacement')
            WHERE   1=1
            AND     PATINDEX('%$Pattern%',Invoice) > 0"
        }
        'InventoryAdjustmentDocument' { 
            "UPDATE  $Database..InventoryAdjustmentDocument
            SET     InvoiceNumber = Replace(InvoiceNumber, Substring(InvoiceNumber, PATINDEX('%$Pattern%',InvoiceNumber), 1), '$Replacement')
            WHERE   1=1
            AND     PATINDEX('%$Pattern%',InvoiceNumber) > 0"
        }
    }
    Write-Debug $Query

    if ( $PSCmdlet.ShouldProcess('UPDATE Document','Invoke-Sqlcmd'))
    {
        Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential
    }

}