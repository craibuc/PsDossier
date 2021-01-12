<#
.SYNOPSIS
Get the data-export information for the specified item.

.PARAMETER ServerIntance
The SQL Server instance.

.PARAMETER Database
The SQL Server database.

.PARAMETER Credential
The SQL Server credentials.

.PARAMETER ItemID
The primary key of the item being exported (e.g. Dossier..InventoryAdjustmentDocument.ID)

#>
function Get-DossierDataExport {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [int[]]$ItemID
    )

    $Predicate = [pscustomobject]@{
        SELECT =
            "SELECT  
                de.ID, de.ExportDate
                ,r.Name ReportName
                ,ua.Name UserName
                ,deit.Name ExportType
                ,dei.ItemID
            FROM    Dossier..DataExport de
            INNER JOIN Dossier..Report r on de.ReportID=r.ID
            INNER JOIN Dossier..UserAccount ua on de.UserID=ua.ID
            INNER JOIN Dossier..DataExportItemType deit ON de.ItemTypeID=deit.ID
            INNER JOIN Dossier..DataExportItem dei on de.ID=dei.DataExportID"
        WHERE = "WHERE 1=1"
        ORDER_BY = "ORDER BY ExportDate"
    }

    if ( $ItemID ) { $Predicate.WHERE += "`r`nAND dei.ItemID IN ($( $ItemID -join ',' ))" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential

}