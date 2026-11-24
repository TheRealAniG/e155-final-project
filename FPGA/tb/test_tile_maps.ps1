param([string]$Qrun = 'C:\lscc\radiant\2026.1\questasim\win64\qrun.exe')
$ErrorActionPreference = 'Stop'
$fpgaRoot = Split-Path $PSScriptRoot -Parent
& (Join-Path $fpgaRoot 'tools/generate_maps.ps1') -Check
$outputDir = Join-Path $fpgaRoot 'sim/tile_maps'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $outputDir
try {
    $rtlSources = @(Get-ChildItem ../../rtl -Filter *.sv | ForEach-Object { $_.FullName })
    foreach ($top in @('tb_tile_map', 'tb_sprite_pipeline', 'tb_checkpoint_arches', 'tb_vga_timing', 'tb_fpga_top')) {
        & $Qrun -batch -sv -top $top @rtlSources "../../tb/$top.sv" -do 'onbreak {quit -code 1}; onerror {quit -code 1}; run -all; quit -f'
        if ($LASTEXITCODE -ne 0) { throw "$top failed: $LASTEXITCODE" }
    }
} finally {
    Pop-Location
}
