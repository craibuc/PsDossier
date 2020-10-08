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

    BeforeAll {
        # create a PsCredential
        $SecureString = ConvertTo-SecureString 'Password' -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ('UserName', $SecureString)

        $Expected = @{
            ServerInstance = '0.0.0.0'
            Database = 'Dossier'
            Credential = $Credential    
        }

        $PSDefaultParameterValues['Set-DossierVendor:ServerInstance'] = $Expected.ServerInstance
        $PSDefaultParameterValues['Set-DossierVendor:Database'] = $Expected.Database
        $PSDefaultParameterValues['Set-DossierVendor:Credential'] = $Expected.Credential   
    }

    Context "Parameter Validation" {
        BeforeAll {
            $Command = Set-Command "Set-DossierVendor"
        }

        $Parameters = @(
            @{Name='ServerInstance';Type='string';Mandatory=$true}
            @{Name='Database';Type='string';Mandatory=$false}
            @{Name='Credential';Type='pscredential';Mandatory=$true}
        )

        it 'is a <Type>' -TestCases $Parameters {
            param($Name, $Type, $Mandatory)
          
            $Command | Should -HaveParameter $Name -Type $type
        }

        it 'mandatory is <Mandatory>' -TestCases $Parameters {
            param($Name, $Type, $Mandatory)
          
            if ($Mandatory) { $Command | Should -HaveParameter $Name -Mandatory }
            else { $Command | Should -HaveParameter $Name -Not -Mandatory }
        }
    
    }

    Context "Database connection" {
        BeforeEach {
            # arrange
            Mock Invoke-Sqlcmd {}

            # act
            Set-DossierVendor
        }

        It "uses the specified ServerInstance" {
            # assert
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter {
                $ServerInstance -eq $Expected.ServerInstance
            }
        }

        It "uses the specified Database" {
            # assert
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter {
                $Database -eq $Expected.Database
            }
        }

        It "uses the specified Credentail" {
            # assert
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter {
                $Credentail -eq $Expected.Credentail
            }
        }
    }

}