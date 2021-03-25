BeforeAll {

    # directories
    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsDossier/Public/"

    # SUT
    $sut = (Split-Path -Leaf $PsCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $sut)

}

Describe "New-DossierDataExportItem" -Tag 'unit' {

    Context "Parameter validation" {
        BeforeAll { $Command = Get-Command "New-DossierDataExportItem" }

        Context "ServerInstance" {
            BeforeAll { $ParameterName='ServerInstance' }
            it 'is a string' {              
                $Command | Should -HaveParameter $ParameterName -Type string
            }
            it 'is mandatory' {              
                $Command | Should -HaveParameter $ParameterName -Mandatory
            }    
        }

        Context "Database" {
            BeforeAll { $ParameterName='Database' }
            it 'is a string' {              
                $Command | Should -HaveParameter $ParameterName -Type string
            }
            it 'is optional' {              
                $Command | Should -HaveParameter $ParameterName -Not -Mandatory
            }    
        }

        Context "Credential" {
            BeforeAll { $ParameterName='Credential' }
            it 'is a pscredential' {              
                $Command | Should -HaveParameter $ParameterName -Type pscredential
            }
            it 'is mandatory' {              
                $Command | Should -HaveParameter $ParameterName -Mandatory
            }    
        }

        Context "DataExportID" {
            BeforeAll { $ParameterName='DataExportID' }
            it 'is a int' {              
                $Command | Should -HaveParameter $ParameterName -Type int
            }
            it 'is mandatory' {              
                $Command | Should -HaveParameter $ParameterName -Mandatory
            }    
        }

        Context "ItemID" {
            BeforeAll { $ParameterName='ItemID' }
            it 'is a int[]' {              
                $Command | Should -HaveParameter $ParameterName -Type int[]
            }
            it 'is mandatory' {              
                $Command | Should -HaveParameter $ParameterName -Mandatory
            }    
        }

        Context "ItemModified" {
            BeforeAll { $ParameterName='ItemModified' }
            it 'is a bool' {              
                $Command | Should -HaveParameter $ParameterName -Type bool
            }
            it 'is mandatory' {              
                $Command | Should -HaveParameter $ParameterName -Not -Mandatory
            }    
        }

    }

    Context "Usage" {

        BeforeAll {
            $Authentication = @{
                ServerInstance='0.0.0.0'
                Database = 'Dossier'
                Credential = [pscredential]::new('user',('password' | ConvertTo-SecureString -AsPlainText))
            }
        }

        Context "when an ItemID is supplied" {

            It "inserts one row" {
                # arrange
                Mock Invoke-SqlCmd {}

                # act
                New-DossierDataExportItem @Authentication -DataExportID 100 -ItemID 1000

                # assert
                Should -Invoke Invoke-SqlCmd -Times 1 -Exactly
            }

        }

        Context "when mulitple ItemID are supplied" {

            It "inserts a row for each ItemID" {
                # arrange
                Mock Invoke-SqlCmd {}
                $ItemID = 1000,2000

                # act
                New-DossierDataExportItem @Authentication -DataExportID 100 -ItemID $ItemID

                # assert
                Should -Invoke Invoke-SqlCmd -Times 1 -Exactly -ParameterFilter {
                    $Query -like "*VALUES (100,$($ItemID[0]),0)"
                }
                Should -Invoke Invoke-SqlCmd -Times 1 -Exactly -ParameterFilter {
                    $Query -like "*VALUES (100,$($ItemID[1]),0)"
                }
            }

        }

    }

}