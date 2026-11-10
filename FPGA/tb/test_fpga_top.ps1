param(
    [string]$Qrun = 'C:\lscc\radiant\2026.1\questasim\win64\qrun.exe'
)
$ErrorActionPreference = 'Stop'
$fpgaRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $fpgaRoot 'sim/top'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $outputDir
try {
    $rtlSources = @(Get-ChildItem ../../rtl -Filter *.sv | ForEach-Object { $_.FullName })
    & $Qrun -batch -sv -top tb_fpga_top @rtlSources `
        ../../tb/tb_fpga_top.sv -do 'run -all; quit -f'
    if ($LASTEXITCODE -ne 0) { throw "VGA top checks failed: $LASTEXITCODE" }
} finally {
    Pop-Location
}
