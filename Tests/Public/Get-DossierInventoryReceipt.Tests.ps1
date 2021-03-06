BeforeAll {

    # /PsDossier
    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}

Describe "Get-DossierInventoryReceipt" -Tag 'unit' {

    Context "Parameter Validation" {

        BeforeAll {
            $Command = Get-Command "Get-DossierInventoryReceipt"
        }

        $Parameters = @(
            @{Name='ServerInstance';Type='string';Mandatory=$true}
            @{Name='Database';Type='string';Mandatory=$false}
            @{Name='Credential';Type='pscredential';Mandatory=$true}
            @{Name='FromDate';Type='[nullable[datetime]]';Mandatory=$false}
            @{Name='ToDate';Type='[nullable[datetime]]';Mandatory=$false}
            @{Name='Status';Type='string';Mandatory=$false}
            @{Name='VendorNumber';Type='string';Mandatory=$false}
            @{Name='InvoiceNumber';Type='string';Mandatory=$false}
            @{Name='NotExported';Type='switch';Mandatory=$false}
        )

        Context 'Type' {
            it '<Name> is a <Type>' -TestCases $Parameters {
                param($Name, $Type, $Mandatory)
              
                $Command | Should -HaveParameter $Name -Type $type
            }    
        }

        Context 'Type' {
            it '<Name> mandatory is <Mandatory>' -TestCases $Parameters {
                param($Name, $Type, $Mandatory)
              
                if ($Mandatory) { $Command | Should -HaveParameter $Name -Mandatory }
                else { $Command | Should -HaveParameter $Name -Not -Mandatory }
            }    
        }
    
    }

    Context "Usage" {

        BeforeAll {
            # create a PsCredential
            $SecureString = ConvertTo-SecureString 'Password' -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('UserName', $SecureString)
    
            $Expected = @{
                ServerInstance = '0.0.0.0'
                Database = 'Dossier'
                Credential = $Credential    
            }
    
            $PSDefaultParameterValues['Get-DossierInventoryReceipt:ServerInstance'] = $Expected.ServerInstance
            $PSDefaultParameterValues['Get-DossierInventoryReceipt:Database'] = $Expected.Database
            $PSDefaultParameterValues['Get-DossierInventoryReceipt:Credential'] = $Expected.Credential   
        }
    
        BeforeEach {
            # arrange
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt
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

    Context "FromDate" {

        It "adds a FromDate filter to the WHERE clause" {
            # arrange
            $FromDate = '9/1/2020'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt -FromDate $FromDate

            # assert
            Should -Invoke Invoke-Sqlcmd -ParameterFilter {
                Write-Debug $query 

                $Query -like "*AND IADOC.OkToPayDate >= '$( ([datetime]$FromDate).ToString('MM/dd/yyyy HH:mm:ss') )'*"
            }
        }

    }

    Context "ToDate" {

        It "adds a ToDate filter to the WHERE clause" {
            # arrange
            $ToDate = '9/1/2020'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt -ToDate $ToDate

            # assert
            Should -Invoke Invoke-Sqlcmd -ParameterFilter {
                Write-Debug $query 

                $Query -like "*AND IADOC.OkToPayDate <= '$( ([datetime]$ToDate).ToString('MM/dd/yyyy HH:mm:ss') )'*"
            }
        }

    }

    Context "Status" {

        It "adds a Status filter to the WHERE clause" {
            # arrange
            $Status = 'CLOSED'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt -Status $Status

            # assert
            Should -Invoke Invoke-Sqlcmd -ParameterFilter {
                $Query -like "*AND IADOC.Status = '$Status'*"
            }
        }

    }

    Context "VendorNumber" {

        It "adds a VendorNumber filter to the WHERE clause" {
            # arrange
            $VendorNumber = 'ABC123'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt -VendorNumber $VendorNumber

            # assert
            Should -Invoke Invoke-Sqlcmd -ParameterFilter {
                $Query -like "*AND V.VendorNumber = '$VendorNumber'*"
            }
        }

    }

    Context "InvoiceNumber" {

        It "adds a InvoiceNumber filter to the WHERE clause" {
            # arrange
            $InvoiceNumber = 'INV-1234'
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt -InvoiceNumber $InvoiceNumber

            # assert
            Should -Invoke Invoke-Sqlcmd -ParameterFilter {
                $Query -like "*AND IADOC.InvoiceNumber = '$InvoiceNumber'*"
            }
        }

    }

    Context "NotExported" {

        It "adds a InvoiceNumber filter to the WHERE clause" {
            # arrange
            Mock Invoke-Sqlcmd {}

            # act
            Get-DossierInventoryReceipt -NotExported

            # assert
            Should -Invoke Invoke-Sqlcmd -ParameterFilter {
                $Query -like "*AND ex.ExportDate IS NULL*"
            }
        }

    }

}
