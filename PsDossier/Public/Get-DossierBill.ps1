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
function Get-DossierBill {

    [CmdletBinding()]
    param (
        # [Parameter(Mandatory)]
        [Parameter(ParameterSetName='None', Mandatory)]
        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database = 'Dossier',

        # [Parameter(Mandatory)]
        [Parameter(ParameterSetName='None', Mandatory)]
        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [pscredential]$Credential,

        [Parameter(ParameterSetName='ByNumber', Mandatory)]
        [string]$Number,

        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [datetime]$FromDate,

        [Parameter(ParameterSetName='ByDate', Mandatory)]
        [datetime]$ToDate
    )
    
$Query = @"
    SELECT  IADOC.InvoiceNumber  as RECORDID
    ,PO.PONumber as DOCNUMBER
    --, V.Name as Name
    ,V.VendorNumber as VENDORID
    ,IADOC.DocDate as WHENPOSTED
    ,IADOC.DocDate  as WHENCREATED
    --, IADOC.SiteID as SiteID
    , IADOC.Notes as MEMO
    ,CASE 
        WHEN IADTL.UserCode is NOT NULL 
        THEN IADTL.UserCode 
        ELSE '5020100'
        END as ACCTNO
    ,IADTL.Quantity*PerUnitCost as TRX_AMOUNT
    --,IADOC.*
    --, IADOC.TotalTax
    --, IADOC.audit_BuiltDate BuiltDate
    ,CONCAT(IADTL.Quantity,' x ', Part.[Description],' [',Part.PartNumber,']' ) as ENTRYDESCRIPTION
FROM    dbo.InventoryAdjustmentDocument IADOC 
INNER JOIN dbo.InventoryAdjustmentDetail as IADTL  ON IADOC.ID = IADTL.InvAdjDocID
INNER JOIN dbo.Part  on IADTL.PartID = Part.ID
LEFT JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON IADOC.POID = PO.ID
LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON IADOC.VendorID = V.ID
WHERE   IADOC.[Type] = 'RECEIPT'
AND     IADOC.OkToPay = 1
AND     DocDate BETWEEN '$FromDate' AND '$ToDate'
"@

    $Predicate = [pscustomobject]@{
        SELECT = "SELECT v.*, s.Code RegionCode"
        FROM = "FROM $Database..Vendor v
        LEFT OUTER JOIN $Database..State s ON v.StateID=s.ID"
        WHERE = "WHERE 1=1"
        ORDER_BY = "ORDER BY Name"
    }

    if ( $Number ) { $Predicate.WHERE += "`r`nAND VendorNumber = '$Number'" }
    if ( $FromDate ) { $Predicate.WHERE += "`r`nAND audit_ModifiedDate >= '$FromDate'" }
    if ( $ToDate ) { $Predicate.WHERE += "`r`nAND audit_ModifiedDate <= '$ToDate'" }

    $Query = $Predicate.PsObject.Properties.Value -join "`r`n"
    Write-Debug $Query

    Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential

}