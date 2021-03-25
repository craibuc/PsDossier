<#
.SYNOPSIS Create a new Dossier..DataExportItem record

.PARAMETER ServerInstance
.PARAMETER Database
.PARAMETER Credential
.PARAMETER DataExportID
.PARAMETER ItemID
.PARAMETER ItemModified

#>
function New-DossierDataExportItem {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database='Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [int]$DataExportID,

        [Parameter(Mandatory)]
        [int[]]$ItemID,

        [Parameter()]
        [bool]$ItemModified
    )
    
    begin {}
    
    process {

        foreach($Item in $ItemID) {

            $Query = "INSERT INTO Dossier..DataExportItem(DataExportID,ItemID,ItemModified) VALUES ($DataExportID,$Item,$([int]$ItemModified))"
            Write-Debug $Query

            if ($PSCmdlet.ShouldProcess("DataExportID: $DataExportID/ItemID: $ItemID/ItemModified: $ItemModified",'Invoke-Sqlcmd'))
            {
                Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential
            }

        }

    }
    
    end {}

}