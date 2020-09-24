# /PsDossier
$ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

# /PsDossier/PsDossier/Public
$PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"

# /PsDossier/Tests/Fixtures/
# $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

# Set-DossierVendor.ps1
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

# . /PsDossier/PsDossier/Public/Set-DossierVendor.ps1
. (Join-Path $PublicPath $sut)

Describe "Set-DossierVendor" -Tag 'unit' {
    It "does something useful" {
        $false | Should -Be $true
    }
}