<#
.SYNOPSIS Create a new Dossier..DataExport record

.PARAMETER ServerInstance
.PARAMETER Database
.PARAMETER Credential
.PARAMETER ReportID
.PARAMETER ItemTypeID
.PARAMETER UserID
.PARAMETER ExportDate

#>
function New-DossierDataExport {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database='Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [int]$ReportID, # Accounts Payable: Parts [198]

        [Parameter(Mandatory)]
        [int]$ItemTypeID, # Part Receipt [1]

        [Parameter(Mandatory)]
        [int]$UserID, # Unknown [-1]

        [Parameter(Mandatory)]
        [datetime]$ExportDate
    )
    
    begin {}
    
    process {

        $Query = 
            "INSERT INTO Dossier..DataExport(ReportID,ItemTypeID,UserID,ExportDate)
            OUTPUT INSERTED.ID
            VALUES ($ReportID,$ItemTypeID,$UserID,'$ExportDate')"
        Write-Debug $Query

        if ($PSCmdlet.ShouldProcess("ReportID: $ReportID/ItemTypeID: $ItemTypeID/UserID: $UserID/ExportDate: $ExportDate",'Invoke-Sqlcmd'))
        {
            $Result = Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential

            # return primary key
            $Result.ID    
        }

    }
    
    end {}

}