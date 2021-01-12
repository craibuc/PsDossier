<#
.SYNOPSIS Updates a Dossier..InventoryAdjustmentDocument record

.PARAMETER ServerInstance
.PARAMETER Database
.PARAMETER Credential
.PARAMETER ID
.PARAMETER InvoiceNumber

#>
function Set-DossierInventoryAdjustmentDocument {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database='Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [int]$ID,

        [Parameter()]
        [string]$InvoiceNumber
    )
    
    begin {}
    
    process {

        $Query = 
            "UPDATE Dossier..InventoryAdjustmentDocument
            SET     InvoiceNumber='$InvoiceNumber'
            WHERE   ID=$ID"
        Write-Debug $Query

        if ($PSCmdlet.ShouldProcess("ID: $ID/InvoiceNumber: $InvoiceNumber",'Invoke-Sqlcmd'))
        {
            Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential
        }

    }
    
    end {}

}