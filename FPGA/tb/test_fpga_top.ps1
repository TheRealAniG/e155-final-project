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
        ../../tb/pixel_pll_model.sv ../../tb/tb_fpga_top.sv -do 'onbreak {quit -code 1}; onerror {quit -code 1}; run -all; quit -f' 2>&1 | Tee-Object -Variable simulationOutput
    if ($LASTEXITCODE -ne 0 -or $simulationOutput -match '\*\* (Fatal|Error):|Errors:\s*[1-9]' -or !($simulationOutput -match 'PASS:')) {
        throw "VGA top checks failed (exit $LASTEXITCODE); inspect simulator output"
    }
} finally {
    Pop-Location
}
