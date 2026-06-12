# IT Toolkit Menu
# Edit this file on GitHub anytime - no need to reflash Arduino

Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows Controller"

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         Windows Controller v1.0" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] System Information Summary"
    Write-Host "  [2] Clear Temp Files & Recycle Bin"
    Write-Host "  [3] Flush DNS & Reset Network"
    Write-Host "  [4] Check Disk Health (All Drives)"
    Write-Host "  [5] Windows Update History"
    Write-Host "  [6] List Installed Software"
    Write-Host "  [7] Check Uptime & Last Reboot"
    Write-Host "  [8] Kill Unresponsive Processes Menu"
    Write-Host "  [9] Quick Network Diagnostics"
    Write-Host "  [10] Export Wi-Fi Passwords"
    Write-Host "  [11] Check BitLocker Status"
    Write-Host "  [12] Generate Battery Report (Laptop)"
    Write-Host ""
    Write-Host "  [R] Refresh Script from GitHub"
    Write-Host "  [Q] Quit"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

# Function definitions
function Get-SystemInfo {
    Clear-Host
    Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Yellow
    $cs = Get-ComputerInfo
    Write-Host "Hostname:           " -NoNewline; Write-Host $cs.CsName -ForegroundColor Green
    Write-Host "Manufacturer:       " -NoNewline; Write-Host $cs.CsManufacturer -ForegroundColor Green
    Write-Host "Model:              " -NoNewline; Write-Host $cs.CsModel -ForegroundColor Green
    Write-Host "OS:                 " -NoNewline; Write-Host $cs.WindowsProductName -ForegroundColor Green
    Write-Host "Version:            " -NoNewline; Write-Host $cs.WindowsVersion -ForegroundColor Green
    Write-Host "BIOS Version:       " -NoNewline; Write-Host $cs.BiosVersion -ForegroundColor Green
    Write-Host "Total RAM:          " -NoNewline; Write-Host "$([math]::Round($cs.CsTotalPhysicalMemory/1GB, 2)) GB" -ForegroundColor Green
    Write-Host "Last Boot:          " -NoNewline; Write-Host $cs.OsLastBootUpTime -ForegroundColor Green
    Write-Host "Logged in User:     " -NoNewline; Write-Host $env:USERNAME -ForegroundColor Green
    Write-Host ""
    Pause
}

function Clear-TempFiles {
    Clear-Host
    Write-Host "=== CLEANING TEMP FILES ===" -ForegroundColor Yellow
    $paths = @(
        "$env:TEMP",
        "C:\Windows\Temp",
        "$env:LOCALAPPDATA\Temp"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Cleaning: $path" -ForegroundColor Gray
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Host "Emptying Recycle Bin..." -ForegroundColor Gray
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Done!" -ForegroundColor Green
    Pause
}

function Reset-NetworkStack {
    Clear-Host
    Write-Host "=== RESETTING NETWORK ===" -ForegroundColor Yellow
    Write-Host "Flushing DNS..." -ForegroundColor Gray
    ipconfig /flushdns | Out-Null
    Write-Host "Releasing IP..." -ForegroundColor Gray
    ipconfig /release | Out-Null
    Write-Host "Renewing IP..." -ForegroundColor Gray
    ipconfig /renew | Out-Null
    Write-Host "Resetting Winsock..." -ForegroundColor Gray
    netsh winsock reset | Out-Null
    Write-Host "Resetting IP stack..." -ForegroundColor Gray
    netsh int ip reset | Out-Null
    Write-Host "Done! Reboot recommended." -ForegroundColor Green
    Pause
}

function Get-DiskHealth {
    Clear-Host
    Write-Host "=== DISK HEALTH ===" -ForegroundColor Yellow
    Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size | 
        Format-Table -AutoSize
    Pause
}

function Get-UpdateHistory {
    Clear-Host
    Write-Host "=== WINDOWS UPDATE HISTORY (Last 20) ===" -ForegroundColor Yellow
    Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20 | 
        Format-Table HotFixID, Description, InstalledOn -AutoSize
    Pause
}

function Get-InstalledSoftware {
    Clear-Host
    Write-Host "=== INSTALLED SOFTWARE ===" -ForegroundColor Yellow
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher |
        Sort-Object DisplayName | Format-Table -AutoSize
    Pause
}

function Get-UptimeInfo {
    Clear-Host
    Write-Host "=== UPTIME & REBOOT INFO ===" -ForegroundColor Yellow
    $lastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    Write-Host "Last Reboot: " -NoNewline; Write-Host $lastBoot -ForegroundColor Green
    Write-Host "Uptime:      " -NoNewline; Write-Host "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== RECENT SHUTDOWN EVENTS ===" -ForegroundColor Yellow
    Get-WinEvent -FilterHashtable @{LogName='System'; ID=1074,1076,6006,6008} -MaxEvents 10 |
        Select-Object TimeCreated, Id, Message | Format-Table -Wrap
    Pause
}

function Get-WiFiPasswords {
    Clear-Host
    Write-Host "=== WI-FI PROFILES & PASSWORDS ===" -ForegroundColor Yellow
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        $profile = ($_ -split ":")[1].Trim()
        $details = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content"
        $password = if ($details) { ($details -split ":")[1].Trim() } else { "N/A" }
        [PSCustomObject]@{ Profile = $profile; Password = $password }
    }
    $profiles | Format-Table -AutoSize
    Pause
}

function Get-BitLockerStatus {
    Clear-Host
    Write-Host "=== BITLOCKER STATUS ===" -ForegroundColor Yellow
    Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, EncryptionPercentage, ProtectionStatus |
        Format-Table -AutoSize
    Pause
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "`nSelect option"
    
    switch ($choice.ToUpper()) {
        '1'  { Get-SystemInfo }
        '2'  { Clear-TempFiles }
        '3'  { Reset-NetworkStack }
        '4'  { Get-DiskHealth }
        '5'  { Get-UpdateHistory }
        '6'  { Get-InstalledSoftware }
        '7'  { Get-UptimeInfo }
        '8'  { Write-Host "Coming soon..." -ForegroundColor DarkYellow; Start-Sleep 2 }
        '9'  { Write-Host "Coming soon..." -ForegroundColor DarkYellow; Start-Sleep 2 }
        '10' { Get-WiFiPasswords }
        '11' { Get-BitLockerStatus }
        '12' { powercfg /batteryreport; Write-Host "Report saved to C:\battery-report.html" -ForegroundColor Green; Start-Sleep 2 }
        'R'  { 
            Write-Host "Refreshing script from GitHub..." -ForegroundColor Yellow
            irm https://raw.githubusercontent.com/USER/REPO/main/toolkit.ps1 | iex
            return # Exit current instance, new one takes over
        }
        'Q'  { Write-Host "Exiting..." -ForegroundColor Yellow }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'Q')
