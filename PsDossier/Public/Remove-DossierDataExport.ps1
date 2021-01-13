<#
.SYNOPSIS 
Removes a Dossier..DataExport record

.PARAMETER ServerInstance
.PARAMETER Database
.PARAMETER Credential

.PARAMETER ID
Dossier..DataExport.ID

#>
function Remove-DossierDataExport {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ServerInstance,

        [Parameter()]
        [string]$Database='Dossier',

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [int[]]$ID
    )
    
    begin {}
    
    process {

        $Query = "DELETE FROM $Database..DataExport WHERE ID IN ( $( $ID -join ',' ) )"
        Write-Debug $Query

        if ($PSCmdlet.ShouldProcess("DELETE - ID: $ID",'Invoke-Sqlcmd'))
        {
            Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance -Database $Database -Credential $Credential
        }

    }
    
    end {}

}