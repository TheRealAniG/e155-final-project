param(
    [int]$Frames = 180,
    [string]$Qrun = 'C:\lscc\radiant\2026.1\questasim\win64\qrun.exe'
)
$ErrorActionPreference = 'Stop'
if ($Frames -lt 1) { throw 'Frames must be positive' }
$fpgaRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $fpgaRoot 'sim/physics'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $outputDir
try {
    & $Qrun -batch -sv -top tb_physics_frames "-gFRAMES=$Frames" `
        ../../rtl/lab2_ta_counter.sv ../../rtl/vga_timing.sv `
        ../../rtl/car_sprite.sv ../../rtl/checkpoint_arches.sv ../../rtl/race_scene.sv `
        ../../tb/tb_physics_frames.sv -do 'run -all; quit -f'
    if ($LASTEXITCODE -ne 0) { throw "Questa failed: $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Output "Frames written to $outputDir"
