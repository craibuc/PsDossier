BeforeAll {

    # /PsDossier
    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}
Describe "Repair-DossierDocumentInvoiceNumber" -Tag 'unit' {

    Context "Parameter Validation" {
        BeforeAll {
            $Command = Get-Command "Repair-DossierDocumentInvoiceNumber"
        }

        $Parameters = @(
            @{Name='ServerInstance';Type='string';Mandatory=$true}
            @{Name='Database';Type='string';Mandatory=$false}
            @{Name='Credential';Type='pscredential';Mandatory=$true}
            @{Name='Pattern';Type='string';Mandatory=$false}
            @{Name='Replacement';Type='string';Mandatory=$false}
        )

        Context "Type" {

            it '<Name> is a <Type>' -TestCases $Parameters {
                param($Name, $Type)
              
                $Command | Should -HaveParameter $Name -Type $type
            }
    
        }

        Context "Mandatory" {

            it '<Name> mandatory is <Mandatory>' -TestCases $Parameters {
                param($Name, $Mandatory)
              
                if ($Mandatory) { $Command | Should -HaveParameter $Name -Mandatory }
                else { $Command | Should -HaveParameter $Name -Not -Mandatory }
            }
    
        }
    
    }

    Context "when the default parameters are supplied" {

        BeforeAll {
            # arrange
            Mock Invoke-SqlCmd

            #
            $Expected = @{
                ServerInstance = '1.1.1.1'
                Database = 'Dossier'
                Credential = [pscredential]::new('username', (ConvertTo-SecureString 'password' -AsPlainText) )
                Pattern = '[<>:"\/\\\|\?\*]'
            }

        }

        BeforeEach {
            # act
            Repair-DossierDocumentInvoiceNumber @Expected
        }

        it "uses the expected ServerInstance" {
            # assert
            Should -Invoke Invoke-SqlCmd -ParameterFilter {
                $ServerInstance -eq $Expected.ServerInstance
            }
        }

        it "uses the expected Database" {
            # assert
            Should -Invoke Invoke-SqlCmd -ParameterFilter {
                $Database -eq $Expected.Database
            }
        }

        it "uses the expected Query" {
            # assert
            Should -Invoke Invoke-SqlCmd -ParameterFilter {
                $Query -like "*$( $Expected.Database )..Document*" 
                # -and $Query -like "*PATINDEX('%$( $Expected.Pattern )%',Invoice)*"
            }
        }

    }

}