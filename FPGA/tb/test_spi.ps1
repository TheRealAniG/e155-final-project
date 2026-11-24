param([string]$Qrun = 'C:\lscc\radiant\2026.1\questasim\win64\qrun.exe')
$ErrorActionPreference = 'Stop'
$outputDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'sim/spi'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $outputDir
try {
    $sources = @(Get-ChildItem ../../rtl -Filter *.sv | ForEach-Object { $_.FullName })
    foreach ($top in @('tb_spi_pose', 'tb_fpga_top')) {
        & $Qrun -batch -sv -top $top @sources ../../tb/pixel_pll_model.sv "../../tb/$top.sv" -do 'onbreak {quit -code 1}; onerror {quit -code 1}; run -all; quit -f' 2>&1 | Tee-Object -Variable simulationOutput
        if ($LASTEXITCODE -ne 0 -or $simulationOutput -match '\*\* (Fatal|Error):|Errors:\s*[1-9]' -or !($simulationOutput -match 'PASS:')) {
            throw "$top failed (exit $LASTEXITCODE); inspect simulator output"
        }
    }
} finally { Pop-Location }
