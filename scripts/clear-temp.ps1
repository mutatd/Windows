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

$totalDeleted = 0
$totalFiles = 0

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Cleaning: $path" -ForegroundColor Gray
        
        $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        $fileCount = $items.Count
        $totalFiles += $fileCount
        
        # Actually delete and capture what succeeds
        $deletedSize = 0
        foreach ($item in $items) {
            try {
                $itemSize = $item.Length
                Remove-Item $item.FullName -Force -ErrorAction Stop
                $deletedSize += $itemSize
            } catch {
                # File in use or locked - skip silently
            }
        }
        
        $totalDeleted += $deletedSize
        $deletedMB = [math]::Round($deletedSize/1MB, 2)
        Write-Host "  Removed $fileCount files ($deletedMB MB)" -ForegroundColor Green
        
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
$totalMB = [math]::Round($totalDeleted/1MB, 2)
Write-Host "Total files deleted: $totalFiles" -ForegroundColor Yellow
Write-Host "Total space freed: $totalMB MB" -ForegroundColor Yellow
if ($totalMB -eq 0) {
    Write-Host "(Most temp files are currently in use by running processes)" -ForegroundColor DarkGray
}
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Pause
