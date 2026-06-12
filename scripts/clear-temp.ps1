Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== CLEARING TEMP FILES ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$paths = @(
    "$env:TEMP",
    "C:\Windows\Temp",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Prefetch"
)

$totalFiles = 0

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Cleaning: $path" -ForegroundColor Gray
        $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        $totalFiles += $items.Count
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Done." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Emptying Recycle Bin..." -ForegroundColor Gray
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleaned $totalFiles files" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Pause
