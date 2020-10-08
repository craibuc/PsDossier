# /PsDossier
$ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent

# /PsDossier/PsDossier/Public
$PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"

# /PsDossier/Tests/Fixtures/
# $FixturesDirectory = Join-Path $ProjectDirectory "/Tests/Fixtures/"

# Get-DossierVendor.ps1
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

# . /PsDossier/PsDossier/Public/Get-DossierVendor.ps1
. (Join-Path $PublicPath $sut)

Describe "Get-DossierVendor" -Tag 'unit' {

    BeforeAll {
        # create a PsCredential
        $SecureString = ConvertTo-SecureString 'Password' -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ('UserName', $SecureString)

        $Expected = @{
            ServerInstance = '0.0.0.0'
            Database = 'Dossier'
            Credential = $Credential    
        }

        $PSDefaultParameterValues['Get-DossierVendor:ServerInstance'] = $Expected.ServerInstance
        $PSDefaultParameterValues['Get-DossierVendor:Database'] = $Expected.Database
        $PSDefaultParameterValues['Get-DossierVendor:Credential'] = $Expected.Credential   
    }

    Context "Parameter Validation" {
        BeforeAll {
            $Command = Get-Command "Get-DossierVendor"
        }

        $Parameters = @(
            @{Name='ServerInstance';Type='string';Mandatory=$true}
            @{Name='Database';Type='string';Mandatory=$false}
            @{Name='Credential';Type='pscredential';Mandatory=$true}
            @{Name='Number';Type='string';Mandatory=$true}
            @{Name='FromDate';Type='datetime';Mandatory=$true}
            @{Name='ToDate';Type='datetime';Mandatory=$true}
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
            Get-DossierVendor
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

    Context "By Number" {

        It "adds a Number filter to the WHERE clause" {
            # arrange
            $Number = 'AC10000'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierVendor -Number $Number

            # assert
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter {
                $Query -like "*AND VendorNumber = '$Number'*"
            }
        }

    }

    Context "By Date" {

        It "adds a From/To date filter to the WHERE clause" {
            # arrange
            $FromDate = '9/1/2020'
            $ToDate = '9/30/2020'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierVendor -FromDate $FromDate -ToDate $ToDate

            # assert
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter {
                Write-Debug $query 

                $Query -like "*AND audit_ModifiedDate >= '$( ([datetime]$FromDate).ToString('MM/dd/yyyy HH:mm:ss') )'*" -and
                $Query -like "*AND audit_ModifiedDate <= '$( ([datetime]$ToDate).ToString('MM/dd/yyyy HH:mm:ss') )'*"
            }
        }

    }

}
