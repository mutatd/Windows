Clear-Host
Write-Host "=== CLEARING TEMP FILES ===" -ForegroundColor Yellow
Write-Host ""

$paths = @(
    "$env:TEMP",
    "C:\Windows\Temp",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Prefetch"
)

$totalFreed = 0

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Cleaning: $path" -ForegroundColor Gray
        $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        $sizeBefore = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        if ($sizeBefore) {
            $totalFreed += $sizeBefore
        }
        Write-Host "  Done." -ForegroundColor Green
    } else {
        Write-Host "Skipping: $path (not found)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Emptying Recycle Bin..." -ForegroundColor Gray
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "  Done." -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
$freedMB = [math]::Round($totalFreed/1MB, 2)
Write-Host "Total space freed: ${freedMB} MB" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Pause
