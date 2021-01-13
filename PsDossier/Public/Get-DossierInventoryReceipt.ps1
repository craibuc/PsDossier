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
        [string]$InvoiceNumber
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
                ,IADTL.Quantity
                ,CAST(IADTL.PerUnitCost AS numeric(18,2)) PerUnitCost
                ,P.[Description] PartDescription, P.PartNumber, P.Tire
            FROM    $Database..InventoryAdjustmentDocument IADOC 
            INNER JOIN Dossier..InventoryAdjustmentDetail as IADTL ON IADOC.ID = IADTL.InvAdjDocID
            INNER JOIN Dossier..Part P ON IADTL.PartID = P.ID
            LEFT OUTER JOIN Dossier..Site S on IADOC.SiteID = S.ID
            LEFT OUTER JOIN Dossier..BillingMethod BM on IADOC.BillingMethodID = BM.ID
            LEFT OUTER JOIN Dossier..PurchaseOrder PO ON IADOC.POID = PO.ID
            LEFT OUTER JOIN Dossier..Vendor V ON IADOC.VendorID = V.ID"
        WHERE = "WHERE 1=1 AND IADOC.[Type]='RECEIPT' AND IADOC.OkToPay=1"
        ORDER = "ORDER BY VendorNumber, InvoiceNumber"
    }

    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND IADOC.OkToPayDate >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND IADOC.OkToPayDate <= '$ToDate'" }
    if ( $Status ) { $Predicate.WHERE += "`r`nAND IADOC.Status = '$Status'" }
    if ( $VendorNumber ) { $Predicate.WHERE += "`r`nAND V.VendorNumber = '$VendorNumber'" }
    if ( $InvoiceNumber ) { $Predicate.WHERE += "`r`nAND IADOC.InvoiceNumber = '$InvoiceNumber'" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential | Group-Object -Property VendorNumber,InvoiceNumber | ForEach-Object {

        $VendorNumber,$InvoiceNumber = $_.Name -split ', '

        $Message = "Processing Vendor #$VendorNumber/Invoice #$InvoiceNumber..."
        Write-Debug $Message

        # create object w/ desired graph
        $InventoryAdjustment = [pscustomobject]@{
            ID = $_.Group[0].ID
            DocDate = $_.Group[0].DocDate
            OkToPayDate = $_.Group[0].OkToPayDate
            Type = $_.Group[0].Type
            Status = $_.Group[0].Status
            VendorNumber = $_.Group[0].VendorNumber
            VendorName = $_.Group[0].VendorName
            InvoiceNumber = $_.Group[0].InvoiceNumber
            PONumber = $_.Group[0].PONumber
            Notes = $_.Group[0].Notes | nz
            TotalTax = $_.Group[0].TotalTax
            InventoryAdjustmentDetails = @()
        } 

        # add all lineitems
        $_.Group | ForEach-Object {

            $InventoryAdjustment.InventoryAdjustmentDetails += [pscustomobject]@{
                Quantity = $_.Quantity
                PerUnitCost = $_.PerUnitCost
                PartDescription = $_.PartDescription | nz
                PartNumber = $_.PartNumber
                Tire = [bool]$_.Tire
            }

        }

        $InventoryAdjustment

    }

}