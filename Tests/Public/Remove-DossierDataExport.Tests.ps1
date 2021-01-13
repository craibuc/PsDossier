BeforeAll {

    # /PsDossier
    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"

    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)

}
Describe "Remove-DossierDataExport" -Tag 'unit' {

    Context "Parameter Validation" {
        BeforeAll {
            $Command = Get-Command "Remove-DossierDataExport"
        }

        $Parameters = @(
            @{Name='ServerInstance';Type='string';Mandatory=$true}
            @{Name='Database';Type='string';Mandatory=$false}
            @{Name='Credential';Type='pscredential';Mandatory=$true}
            @{Name='ID';Type='int[]';Mandatory=$true}
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
                ID = 1,2,3
            }

        }

        BeforeEach {
            # act
            Remove-DossierDataExport @Expected
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
                $Query -like "*ID IN ( $( $Expected.ID -join ',' ) )*" 
            }
        }

    }

}