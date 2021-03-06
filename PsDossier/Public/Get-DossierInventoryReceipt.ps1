<#
.SYNOPSIS

.PARAMETER ServerIntance
The SQL Server instance.

.PARAMETER Database
The SQL Server database.

.PARAMETER Credential
The SQL Server credentials.

.PARAMETER Number
Get a Bill by its `VendorNumber`.

#>
function Get-DossierInventoryReceipt {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

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
            "SELECT  IADOC.ID, IADOC.[Type], IADOC.Status, IADOC.InvoiceNumber
                ,IADOC.DocDate, IADOC.OkToPayDate
                ,IADOC.Notes, IADOC.TotalTax
                ,V.VendorNumber, V.Name VendorName
                ,PO.PONumber
                ,BM.Name BillingMethod
                ,S.Name SiteName
                ,IADTL.Quantity, IADTL.PerUnitCost
                ,CAST(IADTL.Quantity * IADTL.PerUnitCost AS numeric(18,2)) LineItemAmount
                ,P.[Description] PartDescription, P.PartNumber, P.Tire
                ,ex.ExportDate, ex.ReportName, ex.UserName
            FROM    $Database..InventoryAdjustmentDocument IADOC 
            INNER JOIN Dossier..InventoryAdjustmentDetail as IADTL ON IADOC.ID = IADTL.InvAdjDocID
            INNER JOIN Dossier..Part P ON IADTL.PartID = P.ID
            LEFT OUTER JOIN Dossier..Site S on IADOC.SiteID = S.ID
            LEFT OUTER JOIN Dossier..BillingMethod BM on IADOC.BillingMethodID = BM.ID
            LEFT OUTER JOIN Dossier..PurchaseOrder PO ON IADOC.POID = PO.ID
            LEFT OUTER JOIN Dossier..Vendor V ON IADOC.VendorID = V.ID
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
            ) ex on IADOC.ID = ex.ItemID"
        WHERE = "WHERE 1=1 AND IADOC.[Type]='RECEIPT' AND IADOC.OkToPay=1"
        ORDER = "ORDER BY VendorNumber, InvoiceNumber"
    }

    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND IADOC.OkToPayDate >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND IADOC.OkToPayDate <= '$ToDate'" }
    if ( $Status ) { $Predicate.WHERE += "`r`nAND IADOC.Status = '$Status'" }
    if ( $VendorNumber ) { $Predicate.WHERE += "`r`nAND V.VendorNumber = '$VendorNumber'" }
    if ( $InvoiceNumber ) { $Predicate.WHERE += "`r`nAND IADOC.InvoiceNumber = '$InvoiceNumber'" }
    if ( $NotExported ) { $Predicate.WHERE += "`r`nAND ex.ExportDate IS NULL" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential | Group-Object -Property VendorNumber,InvoiceNumber | ForEach-Object {

        $VendorNumber,$InvoiceNumber = $_.Name -split ', '

        $Message = "Processing Vendor #$VendorNumber/Invoice #$InvoiceNumber..."
        Write-Debug $Message

        # create object w/ desired graph
        $InventoryAdjustment = [pscustomobject]@{
            # ID = $_.Group[0].ID
            DocDate = $_.Group[0].DocDate
            # OkToPayDate = $_.Group[0].OkToPayDate
            Type = $_.Group[0].Type
            Status = $_.Group[0].Status
            VendorNumber = $_.Group[0].VendorNumber
            VendorName = $_.Group[0].VendorName
            InvoiceNumber = $_.Group[0].InvoiceNumber
            PONumber = $_.Group[0].PONumber
            Notes = $_.Group[0].Notes | nz
            # TotalTax = $_.Group[0].TotalTax
            ExportDate = $_.Group[0].ExportDate | nz
            ReportName = $_.Group[0].ReportName | nz
            UserName = $_.Group[0].UserName | nz
            # InventoryAdjustmentDetails = @()
            Documents = @()
        } 

        $_.Group | Group-Object -Property ID | ForEach-Object {
        
            $Document = [pscustomobject]@{
                ID = $_.Name
                OkToPayDate = $_.Group[0].OkToPayDate
                TotalTax = $_.Group[0].TotalTax
                InventoryAdjustmentDetails = @()
            }
    
            # add all lineitems
            $_.Group | ForEach-Object {

                # $InventoryAdjustment.InventoryAdjustmentDetails += [pscustomobject]@{
                $Document.InventoryAdjustmentDetails += [pscustomobject]@{
                    Quantity = $_.Quantity
                    PerUnitCost = $_.PerUnitCost
                    LineItemAmount = $_.LineItemAmount
                    PartDescription = $_.PartDescription | nz
                    PartNumber = $_.PartNumber
                    Tire = [bool]$_.Tire
                }

            } # line items

            $InventoryAdjustment.Documents += $Document
    
        } # /documents

        $InventoryAdjustment

    }

}