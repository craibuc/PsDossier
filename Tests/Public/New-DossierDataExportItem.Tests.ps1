# /PsDossier
$ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

$PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"
# $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

# New-DossierDataExportItem.ps1
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

# . /PsDossier/PsDossier/Public/New-DossierDataExportItem.ps1
. (Join-Path $PublicPath $sut)

Describe "New-DossierDataExportItem" -Tag 'unit' {

    Context "" {

        It "does something useful" {
            $false | Should -Be $true
        }
    
    }

}