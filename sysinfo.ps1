Clear-Host
Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Yellow
Write-Host ""

$cs = Get-ComputerInfo

Write-Host "Hostname:           " -NoNewline; Write-Host $cs.CsName -ForegroundColor Green
Write-Host "Manufacturer:       " -NoNewline; Write-Host $cs.CsManufacturer -ForegroundColor Green
Write-Host "Model:              " -NoNewline; Write-Host $cs.CsModel -ForegroundColor Green
Write-Host "OS:                 " -NoNewline; Write-Host $cs.WindowsProductName -ForegroundColor Green
Write-Host "Version:            " -NoNewline; Write-Host $cs.WindowsVersion -ForegroundColor Green
Write-Host "Build:              " -NoNewline; Write-Host $cs.OsHardwareAbstractionLayer -ForegroundColor Green
Write-Host "BIOS Version:       " -NoNewline; Write-Host $cs.BiosVersion -ForegroundColor Green
Write-Host "BIOS Date:          " -NoNewline; Write-Host $cs.BiosReleaseDate -ForegroundColor Green
Write-Host "Total RAM:          " -NoNewline; Write-Host "$([math]::Round($cs.CsTotalPhysicalMemory/1GB, 2)) GB" -ForegroundColor Green
Write-Host "Last Boot:          " -NoNewline; Write-Host $cs.OsLastBootUpTime -ForegroundColor Green
Write-Host "Logged in User:     " -NoNewline; Write-Host $env:USERNAME -ForegroundColor Green

Write-Host ""
Write-Host "=== CPU ===" -ForegroundColor Yellow
Get-CimInstance Win32_Processor | ForEach-Object {
    Write-Host "Name:               " -NoNewline; Write-Host $_.Name -ForegroundColor Green
    Write-Host "Cores:              " -NoNewline; Write-Host $_.NumberOfCores -ForegroundColor Green
    Write-Host "Logical Processors: " -NoNewline; Write-Host $_.NumberOfLogicalProcessors -ForegroundColor Green
}

Write-Host ""
Write-Host "=== DISKS ===" -ForegroundColor Yellow
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeGB = [math]::Round($_.FreeSpace/1GB, 2)
    $totalGB = [math]::Round($_.Size/1GB, 2)
    $usedGB = $totalGB - $freeGB
    Write-Host "$($_.DeviceID) Total: ${totalGB}GB | Used: ${usedGB}GB | Free: ${freeGB}GB" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== NETWORK ===" -ForegroundColor Yellow
Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -notlike "*Loopback*" | ForEach-Object {
    Write-Host "$($_.InterfaceAlias): $($_.IPAddress)" -ForegroundColor Green
}

Write-Host ""
Pause
