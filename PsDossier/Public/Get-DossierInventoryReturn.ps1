function Get-DossierInventoryReturn {

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
        [string]$AuthorizationNumber,

        [Parameter()]
        [switch]$NotExported
    )
    
    $Predicate = [pscustomobject]@{
        SELECT = 
            "SELECT  IADOC.ID, IADOC.[Type], IADOC.Status, IADOC.AuthorizationNumber, IADOC.InvoiceNumber
                ,IADOC.DocDate
                ,IADOC.Notes, IADOC.TotalTax
                ,V.VendorNumber, V.Name VendorName
                ,PO.PONumber
                ,BM.Name BillingMethod
                ,S.Name SiteName
                ,IADTL.Quantity
                ,CAST(IADTL.PerUnitCredit AS numeric(18,2)) PerUnitCredit
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
        WHERE = "WHERE 1=1 AND IADOC.[Type]='RETURN'"
        ORDER = "ORDER BY VendorNumber, AuthorizationNumber"
    }

    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND IADOC.DocDate >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND IADOC.DocDate <= '$ToDate'" }
    if ( $Status ) { $Predicate.WHERE += "`r`nAND IADOC.Status = '$Status'" }
    if ( $VendorNumber ) { $Predicate.WHERE += "`r`nAND V.VendorNumber = '$VendorNumber'" }
    if ( $AuthorizationNumber ) { $Predicate.WHERE += "`r`nAND IADOC.AuthorizationNumber = '$AuthorizationNumber'" }
    if ( $NotExported ) { $Predicate.WHERE += "`r`nAND ex.ExportDate IS NULL" }
    
    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query    

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential | Group-Object -Property VendorNumber,AuthorizationNumber | ForEach-Object {

        $VendorNumber,$AuthorizationNumber = $_.Name -split ', '

        $Message = "Processing Vendor #$VendorNumber/Invoice #$AuthorizationNumber..."
        Write-Debug $Message

        # create object w/ desired graph
        $InventoryAdjustment = [pscustomobject]@{
            ID = $_.Group[0].ID
            DocDate = $_.Group[0].DocDate
            Type = $_.Group[0].Type
            Status = $_.Group[0].Status
            VendorNumber = $_.Group[0].VendorNumber
            VendorName = $_.Group[0].VendorName
            AuthorizationNumber = $_.Group[0].AuthorizationNumber
            PONumber = $_.Group[0].PONumber
            Notes = $_.Group[0].Notes | nz
            TotalTax = $_.Group[0].TotalTax
            InventoryAdjustmentDetails = @()
        } 

        # add all lineitems
        $_.Group | ForEach-Object {

            $InventoryAdjustment.InventoryAdjustmentDetails += [pscustomobject]@{
                Quantity = $_.Quantity
                PerUnitCredit = $_.PerUnitCredit
                PartDescription = $_.PartDescription | nz
                PartNumber = $_.PartNumber
                Tire = [bool]$_.Tire
            }

        }

        $InventoryAdjustment

    }

}