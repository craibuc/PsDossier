function nz
{
    param(
        [Parameter(Position=0,ValueFromPipeline)]
        [object]$InputObject
    )

    [System.DBNull]::Value.Equals($InputObject) ? $null : $InputObject
}