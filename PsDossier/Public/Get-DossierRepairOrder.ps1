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
        [string]$InvoiceNumber
    )

    $Predicate = [pscustomobject]@{
        SELECT = 
            "SELECT  
                    d.ID, d.[Status], d.[Type], d.DateOfRecord, d.Notes, d.FormID RONumber, d.Invoice InvoiceNumber
                    ,s.Name SiteName
                    ,v.Name VendorName, v.VendorNumber
                    ,bm.Name BillingMethod
                    ,cd.Type CostType, cd.[Description] CostDescription, cd.Cost, cd.TaxCost
            FROM    Dossier..Document d
            LEFT OUTER JOIN Dossier..Site s on d.SiteID=s.ID
            LEFT OUTER JOIN Dossier..Vendor v on d.VendorID=v.ID
            LEFT OUTER JOIN Dossier..BillingMethod bm ON d.BillingMethodID=bm.ID
            LEFT OUTER JOIN Dossier..CostDetail cd ON d.ID = cd.DocID"
        WHERE = "WHERE 1=1 AND d.Type = 'EXTERNAL R/O'"
        ORDER_BY = "ORDER BY VendorName, InvoiceNumber"
    }

    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND d.DateOfRecord >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND d.DateOfRecord <= '$ToDate'" }
    if ( $Status ) { $Predicate.WHERE += "`r`nAND d.Status = '$Status'" }
    if ( $VendorNumber ) { $Predicate.WHERE += "`r`nAND V.VendorNumber = '$VendorNumber'" }
    if ( $InvoiceNumber ) { $Predicate.WHERE += "`r`nAND d.Invoice = '$InvoiceNumber'" }

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
            CostDetails = @()
        } 

        # add all lineitems
        $_.Group | ForEach-Object {

            $RepairOrder.CostDetails += [pscustomobject]@{
                CostType = $_.CostType
                CostDescription = $_.CostDescription | nz
                Cost = $_.Cost
                TaxCost = $_.TaxCost
            }

        }

        $RepairOrder

    } # /ForEach-Object

}