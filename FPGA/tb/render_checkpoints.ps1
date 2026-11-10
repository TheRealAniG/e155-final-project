param(
    [string]$Qrun = 'C:\lscc\radiant\2026.1\questasim\win64\qrun.exe'
)
$ErrorActionPreference = 'Stop'
$fpgaRoot = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $fpgaRoot 'sim/checkpoints'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $outputDir
try {
    & $Qrun -batch -sv -top tb_checkpoint_arches `
        ../../rtl/car_sprite.sv ../../rtl/checkpoint_arches.sv ../../rtl/race_scene.sv `
        ../../tb/tb_checkpoint_arches.sv -do 'run -all; quit -f'
    if ($LASTEXITCODE -ne 0) { throw "Checkpoint checks failed: $LASTEXITCODE" }
    & $Qrun -batch -sv -top tb_physics_frames '-gFRAMES=9' `
        '-gPOSES=../../tb/checkpoint_poses.txt' `
        ../../rtl/lab2_ta_counter.sv ../../rtl/vga_timing.sv `
        ../../rtl/car_sprite.sv ../../rtl/checkpoint_arches.sv ../../rtl/race_scene.sv `
        ../../tb/tb_physics_frames.sv -do 'run -all; quit -f'
    if ($LASTEXITCODE -ne 0) { throw "Checkpoint rendering failed: $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Output "Checkpoint previews: $outputDir/physics_0000.ppm through physics_0008.ppm"
