<#
.SYNOPSIS
Retrieves EXTERNAL R/O documents from Dossier, excluding credit cards

.NOTES
Includes:
Dossier..Document.Type = 'EXTERNAL R/O'
#>
function Get-DossierRepairOrder {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [string]$Database = 'Custom',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [Nullable[DateTime]]$FromDate,

        [Parameter()]
        [Nullable[DateTime]]$ToDate,

        [Parameter()]
        [ValidateSet('OPEN','CLOSED')]
        [string]$Status = 'CLOSED',

        [Parameter()]
        [string]$VendorNumber,

        [Parameter()]
        [string]$InvoiceNumber,

        [Parameter()]
        [switch]$NotExported
    )

    $Predicate = [pscustomobject]@{
        SELECT = 
            "SELECT  
                    d.ID, d.[Status], d.[Type], d.DateOfRecord, d.Notes, d.FormID RONumber, d.Invoice InvoiceNumber
                    ,s.Name SiteName
                    ,v.Name VendorName, v.VendorNumber
                    ,bm.Name BillingMethod
                    ,cd.Type CostType, cd.[Description] CostDescription, cd.VmrsSystem, cd.Cost, cd.TaxCost
                    ,ex.ExportDate, ex.ReportName, ex.UserName
            FROM    Dossier..Document d
            LEFT OUTER JOIN Dossier..Site s on d.SiteID=s.ID
            LEFT OUTER JOIN Dossier..Vendor v on d.VendorID=v.ID
            LEFT OUTER JOIN Dossier..BillingMethod bm ON d.BillingMethodID=bm.ID
            LEFT OUTER JOIN Dossier..CostDetail cd ON d.ID = cd.DocID
            LEFT OUTER JOIN 
            (
                SELECT  
                        -- de.ID, 
                        de.ExportDate
                        ,r.Name ReportName
                        ,ua.Name UserName
                        -- ,deit.Name ExportType
                        ,dei.ItemID
                FROM    Dossier..DataExport de
                INNER JOIN Dossier..Report r on de.ReportID=r.ID
                INNER JOIN Dossier..UserAccount ua on de.UserID=ua.ID
                INNER JOIN Dossier..DataExportItemType deit ON de.ItemTypeID=deit.ID
                INNER JOIN Dossier..DataExportItem dei on de.ID=dei.DataExportID
            ) ex on d.ID = ex.ItemID"
        WHERE = "WHERE 1=1 AND d.Type='EXTERNAL R/O'"
        ORDER_BY = "ORDER BY VendorName, Invoice"
    }

    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND d.DateOfRecord >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND d.DateOfRecord <= '$ToDate'" }
    if ( $Status ) { $Predicate.WHERE += "`r`nAND d.Status = '$Status'" }
    if ( $VendorNumber ) { $Predicate.WHERE += "`r`nAND V.VendorNumber = '$VendorNumber'" }
    if ( $InvoiceNumber ) { $Predicate.WHERE += "`r`nAND d.Invoice = '$InvoiceNumber'" }
    if ( $NotExported ) { $Predicate.WHERE += "`r`nAND ex.ExportDate IS NULL" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential | Group-Object -Property VendorNumber,InvoiceNumber | ForEach-Object {

        $VendorNumber,$InvoiceNumber = $_.Name -split ', '

        $Message = "Processing Vendor #$VendorNumber/Invoice #$InvoiceNumber..."
        Write-Debug $Message

        # create object w/ desired graph
        $RepairOrder = [pscustomobject]@{
            ID = $_.Group[0].ID
            DateOfRecord = $_.Group[0].DateOfRecord
            VendorNumber = $_.Group[0].VendorNumber
            InvoiceNumber = $_.Group[0].InvoiceNumber
            RONumber = $_.Group[0].RONumber
            Notes = $_.Group[0].Notes | nz
            SiteName = $_.Group[0].SiteName
            BillingMethod = $_.Group[0].BillingMethod | nz
            ExportDate = $_.Group[0].ExportDate | nz
            ReportName = $_.Group[0].ReportName | nz
            UserName = $_.Group[0].UserName | nz
            CostDetails = @()
        } 

        # add all lineitems
        $_.Group | ForEach-Object {

            $RepairOrder.CostDetails += [pscustomobject]@{
                CostType = $_.CostType
                CostDescription = $_.CostDescription | nz
                VmrsSystem = $_.VmrsSystem | nz
                Cost = $_.Cost
                TaxCost = $_.TaxCost
            }

        }

        $RepairOrder

    } # /ForEach-Object

}