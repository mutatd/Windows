Clear-Host
Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Yellow
Write-Host ""

# Hostname and user
Write-Host "Hostname:           " -NoNewline; Write-Host $env:COMPUTERNAME -ForegroundColor Green
Write-Host "Logged in User:     " -NoNewline; Write-Host $env:USERNAME -ForegroundColor Green
Write-Host "Domain:             " -NoNewline; Write-Host $env:USERDOMAIN -ForegroundColor Green

Write-Host ""

# OS Info - use WMI instead, more consistent across versions
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "=== OS ===" -ForegroundColor Yellow
Write-Host "OS Name:            " -NoNewline; Write-Host $os.Caption -ForegroundColor Green
Write-Host "Version:            " -NoNewline; Write-Host $os.Version -ForegroundColor Green
Write-Host "Build:              " -NoNewline; Write-Host $os.BuildNumber -ForegroundColor Green
Write-Host "Architecture:       " -NoNewline; Write-Host $os.OSArchitecture -ForegroundColor Green
Write-Host "Install Date:       " -NoNewline; Write-Host $os.InstallDate -ForegroundColor Green
Write-Host "Last Boot:          " -NoNewline; Write-Host $os.LastBootUpTime -ForegroundColor Green
Write-Host "Uptime:             " -NoNewline
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Green

Write-Host ""

# Hardware
Write-Host "=== HARDWARE ===" -ForegroundColor Yellow
$cs = Get-CimInstance Win32_ComputerSystem
Write-Host "Manufacturer:       " -NoNewline; Write-Host $cs.Manufacturer -ForegroundColor Green
Write-Host "Model:              " -NoNewline; Write-Host $cs.Model -ForegroundColor Green
Write-Host "Total RAM:          " -NoNewline; Write-Host "$([math]::Round($cs.TotalPhysicalMemory/1GB, 2)) GB" -ForegroundColor Green

$bios = Get-CimInstance Win32_BIOS
Write-Host "BIOS Version:       " -NoNewline; Write-Host $bios.SMBIOSBIOSVersion -ForegroundColor Green

Write-Host ""

# CPU
Write-Host "=== CPU ===" -ForegroundColor Yellow
$cpu = Get-CimInstance Win32_Processor
Write-Host "Name:               " -NoNewline; Write-Host $cpu.Name -ForegroundColor Green
Write-Host "Cores:              " -NoNewline; Write-Host $cpu.NumberOfCores -ForegroundColor Green
Write-Host "Logical Processors: " -NoNewline; Write-Host $cpu.NumberOfLogicalProcessors -ForegroundColor Green

Write-Host ""

# Disks
Write-Host "=== DISKS ===" -ForegroundColor Yellow
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeGB = [math]::Round($_.FreeSpace/1GB, 2)
    $totalGB = [math]::Round($_.Size/1GB, 2)
    $usedGB = $totalGB - $freeGB
    $pctFree = [math]::Round(($_.FreeSpace/$_.Size)*100, 1)
    Write-Host "$($_.DeviceID) Total: ${totalGB}GB | Used: ${usedGB}GB | Free: ${freeGB}GB (${pctFree}%)" -ForegroundColor Green
}

Write-Host ""

# Network
Write-Host "=== NETWORK ===" -ForegroundColor Yellow
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.PrefixOrigin -ne "WellKnown" } | ForEach-Object {
    Write-Host "$($_.InterfaceAlias): $($_.IPAddress)" -ForegroundColor Green
}

# DNS servers
Write-Host ""
Write-Host "DNS Servers:" -ForegroundColor Yellow
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne "{}" } | ForEach-Object {
    Write-Host "  $($_.InterfaceAlias): $($_.ServerAddresses -join ', ')" -ForegroundColor Green
}

Write-Host ""
Pause
