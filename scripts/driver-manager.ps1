# Driver Manager
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== DRIVER MANAGER ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Must run as admin for most operations
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Write-Host "[1] List all installed drivers" -ForegroundColor Cyan
Write-Host "[2] List third-party (non-Microsoft) drivers" -ForegroundColor Cyan
Write-Host "[3] List drivers by type" -ForegroundColor Cyan
Write-Host "[4] Show driver details for a device" -ForegroundColor Cyan
Write-Host "[5] Find outdated drivers" -ForegroundColor Cyan
Write-Host "[6] Backup all third-party drivers" -ForegroundColor Cyan
Write-Host "[7] List problem devices (Device Manager errors)" -ForegroundColor Cyan
Write-Host "[8] Show recently installed/updated drivers" -ForegroundColor Cyan
Write-Host "[9] Show driver version summary" -ForegroundColor Cyan
Write-Host "[10] Export driver list to CSV" -ForegroundColor Cyan
Write-Host "[Q] Return to main menu" -ForegroundColor Gray
Write-Host ""

if (-not $isAdmin) {
    Write-Host "NOTE: Running without Administrator rights." -ForegroundColor DarkYellow
    Write-Host "      Backup and some details will be view-only." -ForegroundColor DarkYellow
    Write-Host ""
}

$drvChoice = Read-Host "Select option"

switch ($drvChoice.ToUpper()) {
    '1' {
        Clear-Host
        Write-Host "=== ALL INSTALLED DRIVERS ===" -ForegroundColor Yellow
        Write-Host ""
        
        $drivers = Get-CimInstance Win32_PnPSignedDriver | 
            Select-Object DeviceName, DriverProviderName, DriverVersion, DriverDate, IsSigned |
            Sort-Object DeviceName
        
        if ($drivers.Count -eq 0) {
            Write-Host "No driver information available." -ForegroundColor Gray
        } else {
            $drivers | Format-Table -AutoSize -Wrap
            Write-Host ""
            Write-Host "Total drivers: $($drivers.Count)" -ForegroundColor Cyan
            Write-Host "Signed drivers: $(($drivers | Where-Object { $_.IsSigned }).Count)" -ForegroundColor Cyan
            Write-Host "Unsigned drivers: $(($drivers | Where-Object { -not $_.IsSigned }).Count)" -ForegroundColor Yellow
        }
        Pause
    }
    '2' {
        Clear-Host
        Write-Host "=== THIRD-PARTY DRIVERS (Non-Microsoft) ===" -ForegroundColor Yellow
        Write-Host ""
        
        $thirdPartyDrivers = Get-CimInstance Win32_PnPSignedDriver | 
            Where-Object { $_.DriverProviderName -ne 'Microsoft' -and $_.DriverProviderName -notlike '*Microsoft*' } |
            Select-Object DeviceName, DriverProviderName, DriverVersion, DriverDate |
            Sort-Object DriverProviderName, DeviceName
        
        if ($thirdPartyDrivers.Count -eq 0) {
            Write-Host "No third-party drivers found." -ForegroundColor Gray
        } else {
            Write-Host "Found $($thirdPartyDrivers.Count) third-party drivers:" -ForegroundColor Cyan
            Write-Host ""
            $thirdPartyDrivers | Format-Table -AutoSize -Wrap
            Write-Host ""
            Write-Host "Providers:" -ForegroundColor Cyan
            $thirdPartyDrivers | Group-Object DriverProviderName | 
                Sort-Object Count -Descending | 
                Select-Object Count, Name | 
                Format-Table -AutoSize
        }
        Pause
    }
    '3' {
        Clear-Host
        Write-Host "=== DRIVERS BY DEVICE TYPE ===" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "Select category:" -ForegroundColor Cyan
        Write-Host "  [1] Display adapters (GPU)" -ForegroundColor Yellow
        Write-Host "  [2] Network adapters" -ForegroundColor Yellow
        Write-Host "  [3] Audio devices" -ForegroundColor Yellow
        Write-Host "  [4] Storage controllers" -ForegroundColor Yellow
        Write-Host "  [5] Printers" -ForegroundColor Yellow
        Write-Host "  [6] Bluetooth devices" -ForegroundColor Yellow
        Write-Host "  [7] USB controllers & hubs" -ForegroundColor Yellow
        Write-Host "  [8] Input devices (keyboard/mouse)" -ForegroundColor Yellow
        Write-Host "  [9] Chipset / System devices" -ForegroundColor Yellow
        Write-Host "  [10] Unknown devices" -ForegroundColor Yellow
        Write-Host ""
        
        $catChoice = Read-Host "Select"
        
        $categoryFilter = switch ($catChoice) {
            '1' { 'Display' }
            '2' { 'Net' }
            '3' { 'Audio|Sound|Media' }
            '4' { 'Storage|SCSI|IDE|NVMe|RAID' }
            '5' { 'Printer|Print' }
            '6' { 'Bluetooth|BLE' }
            '7' { 'USB|Universal Serial Bus' }
            '8' { 'Keyboard|Mouse|HID|Input|Pointer' }
            '9' { 'Chipset|System|PCI|Motherboard|LPC|SMBus|Memory Controller' }
            '10' { 'Unknown' }
        }
        
        if ($categoryFilter) {
            Clear-Host
            Write-Host "=== DRIVERS: $(([ordered]@{'1'='Display Adapters';'2'='Network Adapters';'3'='Audio Devices';'4'='Storage Controllers';'5'='Printers';'6'='Bluetooth';'7'='USB';'8'='Input Devices';'9'='Chipset/System';'10'='Unknown Devices'})[$catChoice]) ===" -ForegroundColor Yellow
            Write-Host ""
            
            $filteredDrivers = Get-CimInstance Win32_PnPSignedDriver | 
                Where-Object { $_.DeviceClass -match $categoryFilter -or $_.DeviceName -match $categoryFilter } |
                Select-Object DeviceName, DriverProviderName, DriverVersion, DriverDate, DeviceClass |
                Sort-Object DeviceName
            
            if ($filteredDrivers.Count -eq 0) {
                Write-Host "No drivers found in this category." -ForegroundColor Gray
            } else {
                Write-Host "Count: $($filteredDrivers.Count)" -ForegroundColor Cyan
                Write-Host ""
                $filteredDrivers | Format-Table -AutoSize -Wrap
            }
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red
        }
        Pause
    }
    '4' {
        Clear-Host
        Write-Host "=== DEVICE DRIVER DETAILS ===" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "How would you like to search?" -ForegroundColor Cyan
        Write-Host "  [1] Search by device name keyword" -ForegroundColor Yellow
        Write-Host "  [2] List all devices and pick" -ForegroundColor Yellow
        Write-Host ""
        $searchChoice = Read-Host "Select"
        
        switch ($searchChoice) {
            '1' {
                $keyword = Read-Host "Enter device name keyword (e.g. 'NVIDIA', 'Realtek', 'Intel')"
                $results = Get-CimInstance Win32_PnPSignedDriver | 
                    Where-Object { $_.DeviceName -like "*$keyword*" } |
                    Select-Object DeviceName, DriverProviderName, DriverVersion, DriverDate |
                    Sort-Object DeviceName
                
                if ($results.Count -eq 0) {
                    Write-Host "No devices found matching '$keyword'." -ForegroundColor Gray
                    Pause
                    break
                }
                
                Write-Host ""
                Write-Host "Matching devices:" -ForegroundColor Cyan
                $i = 1
                foreach ($dev in $results) {
                    Write-Host "  [$i] $($dev.DeviceName) ($($dev.DriverProviderName))" -ForegroundColor Yellow
                    $i++
                }
                Write-Host ""
                $devNum = Read-Host "Enter number for details (or 0 to cancel)"
                
                if ($devNum -match '^\d+$' -and [int]$devNum -gt 0 -and [int]$devNum -le $results.Count) {
                    $selected = $results[[int]$devNum - 1]
                    Clear-Host
                    Write-Host "=== DRIVER DETAILS ===" -ForegroundColor Yellow
                    Write-Host ""
                    $fullDetails = Get-CimInstance Win32_PnPSignedDriver | 
                        Where-Object { $_.DeviceName -eq $selected.DeviceName } |
                        Select-Object DeviceName, Description, DeviceClass, DriverProviderName, 
                                      DriverVersion, DriverDate, InfName, IsSigned, 
                                      @{N='HardwareID';E={$_.HardwareID}},
                                      @{N='CompatibleID';E={$_.CompatibleID}}
                    
                    if ($fullDetails) {
                        foreach ($detail in $fullDetails) {
                            Write-Host "Device Name:      $($detail.DeviceName)" -ForegroundColor Cyan
                            Write-Host "Description:      $($detail.Description)" -ForegroundColor Cyan
                            Write-Host "Device Class:     $($detail.DeviceClass)" -ForegroundColor Cyan
                            Write-Host "Provider:         $($detail.DriverProviderName)" -ForegroundColor Cyan
                            Write-Host "Driver Version:   $($detail.DriverVersion)" -ForegroundColor Cyan
                            Write-Host "Driver Date:      $($detail.DriverDate)" -ForegroundColor Cyan
                            Write-Host "INF File:         $($detail.InfName)" -ForegroundColor Cyan
                            Write-Host "Signed:           $($detail.IsSigned)" -ForegroundColor $(if ($detail.IsSigned) { "Green" } else { "Red" })
                            Write-Host ""
                            Write-Host "Hardware IDs:" -ForegroundColor DarkYellow
                            if ($detail.HardwareID) {
                                foreach ($hwid in $detail.HardwareID) {
                                    Write-Host "  $hwid" -ForegroundColor Gray
                                }
                            }
                            Write-Host ""
                            Write-Host "Compatible IDs:" -ForegroundColor DarkYellow
                            if ($detail.CompatibleID) {
                                foreach ($cid in $detail.CompatibleID) {
                                    Write-Host "  $cid" -ForegroundColor Gray
                                }
                            }
                        }
                    }
                }
            }
            '2' {
                $allDevices = Get-CimInstance Win32_PnPSignedDriver | 
                    Select-Object DeviceName | 
                    Sort-Object DeviceName
                
                Write-Host ""
                Write-Host "All devices (showing first 50):" -ForegroundColor Cyan
                $i = 1
                foreach ($dev in ($allDevices | Select-Object -First 50)) {
                    Write-Host "  [$i] $($dev.DeviceName)" -ForegroundColor Yellow
                    $i++
                }
                if ($allDevices.Count -gt 50) {
                    Write-Host "  ... and $($allDevices.Count - 50) more (use search for specific device)" -ForegroundColor Gray
                }
                Write-Host ""
                $devNum = Read-Host "Enter number for details (or 0 to cancel)"
                
                if ($devNum -match '^\d+$' -and [int]$devNum -gt 0 -and [int]$devNum -le 50) {
                    $selected = $allDevices[[int]$devNum - 1]
                    Clear-Host
                    Write-Host "=== DRIVER DETAILS ===" -ForegroundColor Yellow
                    Write-Host ""
                    $fullDetails = Get-CimInstance Win32_PnPSignedDriver | 
                        Where-Object { $_.DeviceName -eq $selected.DeviceName } |
                        Select-Object DeviceName, Description, DeviceClass, DriverProviderName, 
                                      DriverVersion, DriverDate, InfName, IsSigned,
                                      @{N='HardwareID';E={$_.HardwareID}},
                                      @{N='CompatibleID';E={$_.CompatibleID}}
                    
                    if ($fullDetails) {
                        foreach ($detail in $fullDetails) {
                            Write-Host "Device Name:      $($detail.DeviceName)" -ForegroundColor Cyan
                            Write-Host "Description:      $($detail.Description)" -ForegroundColor Cyan
                            Write-Host "Device Class:     $($detail.DeviceClass)" -ForegroundColor Cyan
                            Write-Host "Provider:         $($detail.DriverProviderName)" -ForegroundColor Cyan
                            Write-Host "Driver Version:   $($detail.DriverVersion)" -ForegroundColor Cyan
                            Write-Host "Driver Date:      $($detail.DriverDate)" -ForegroundColor Cyan
                            Write-Host "INF File:         $($detail.InfName)" -ForegroundColor Cyan
                            Write-Host "Signed:           $($detail.IsSigned)" -ForegroundColor $(if ($detail.IsSigned) { "Green" } else { "Red" })
                            Write-Host ""
                            if ($detail.HardwareID) {
                                Write-Host "Hardware IDs:" -ForegroundColor DarkYellow
                                foreach ($hwid in $detail.HardwareID) {
                                    Write-Host "  $hwid" -ForegroundColor Gray
                                }
                            }
                        }
                    }
                }
            }
        }
        Pause
    }
    '5' {
        Clear-Host
        Write-Host "=== POTENTIALLY OUTDATED DRIVERS ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Checking driver dates... (drivers older than 2 years are flagged)" -ForegroundColor Cyan
        Write-Host ""
        
        $twoYearsAgo = (Get-Date).AddYears(-2)
        
        $oldDrivers = Get-CimInstance Win32_PnPSignedDriver | 
            Where-Object { 
                $_.DriverDate -ne $null -and 
                $_.DriverDate -lt $twoYearsAgo -and
                $_.DriverProviderName -ne 'Microsoft' -and
                $_.DriverProviderName -notlike '*Microsoft*'
            } |
            Select-Object DeviceName, DriverProviderName, DriverVersion, DriverDate |
            Sort-Object DriverDate
        
        if ($oldDrivers.Count -eq 0) {
            Write-Host "No outdated third-party drivers found. All drivers are recent." -ForegroundColor Green
        } else {
            Write-Host "Found $($oldDrivers.Count) drivers older than 2 years:" -ForegroundColor Yellow
            Write-Host ""
            $oldDrivers | Format-Table -AutoSize -Wrap
            Write-Host ""
            Write-Host "NOTE: Old drivers aren't necessarily problematic." -ForegroundColor Gray
            Write-Host "      Only update if you're experiencing issues." -ForegroundColor Gray
            Write-Host "      Check manufacturer websites for newer versions." -ForegroundColor Gray
        }
        Pause
    }
    '6' {
        Clear-Host
        Write-Host "=== BACKUP THIRD-PARTY DRIVERS ===" -ForegroundColor Yellow
        Write-Host ""
        
        if (-not $isAdmin) {
            Write-Host "ERROR: Driver backup requires Administrator privileges." -ForegroundColor Red
            Write-Host "Please restart PowerShell as Administrator." -ForegroundColor Yellow
            Pause
            break
        }
        
        Write-Host "This will export all third-party (non-Microsoft) drivers to a folder." -ForegroundColor Cyan
        Write-Host "Useful for clean Windows installations or driver restoration." -ForegroundColor Cyan
        Write-Host ""
        
        $defaultPath = "$env:USERPROFILE\Desktop\DriverBackup_$(Get-Date -Format 'yyyyMMdd')"
        Write-Host "Default backup location:" -ForegroundColor Gray
        Write-Host "  $defaultPath" -ForegroundColor Gray
        Write-Host ""
        
        $backupPath = Read-Host "Enter backup folder path (press Enter for default)"
        if (-not $backupPath) { $backupPath = $defaultPath }
        
        if (Test-Path $backupPath) {
            Write-Host "WARNING: Folder already exists." -ForegroundColor Yellow
            $overwrite = Read-Host "Overwrite contents? (y/N)"
            if ($overwrite -ne 'y') {
                Write-Host "Cancelled." -ForegroundColor Yellow
                Pause
                break
            }
        }
        
        try {
            Write-Host ""
            Write-Host "Exporting drivers. This may take several minutes..." -ForegroundColor Yellow
            Write-Host ""
            
            # Use DISM to export drivers
            $dismArgs = "/online /export-driver /destination:`"$backupPath`""
            $process = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -NoNewWindow -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                $driverCount = (Get-ChildItem $backupPath -Recurse -Filter "*.inf").Count
                Write-Host ""
                Write-Host "Driver backup complete!" -ForegroundColor Green
                Write-Host "Location: $backupPath" -ForegroundColor Cyan
                Write-Host "INF files exported: $driverCount" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "To restore on a new Windows install:" -ForegroundColor Gray
                Write-Host "  1. Open Device Manager" -ForegroundColor Gray
                Write-Host "  2. Right-click device -> Update driver" -ForegroundColor Gray
                Write-Host "  3. Browse my computer for drivers" -ForegroundColor Gray
                Write-Host "  4. Point to this backup folder" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  Or use PowerShell:" -ForegroundColor Gray
                Write-Host "  pnputil /add-driver `"$backupPath\*.inf`" /subdirs /install" -ForegroundColor Gray
            } else {
                Write-Host ""
                Write-Host "Driver export failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            }
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    '7' {
        Clear-Host
        Write-Host "=== PROBLEM DEVICES (Device Manager Errors) ===" -ForegroundColor Yellow
        Write-Host ""
        
        $problemDevices = Get-CimInstance Win32_PnPEntity | 
            Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Unknown' -and $_.ConfigManagerErrorCode -ne 0 } |
            Select-Object Name, Status, 
                @{N='ErrorCode';E={$_.ConfigManagerErrorCode}},
                @{N='ErrorDescription';E={
                    switch ($_.ConfigManagerErrorCode) {
                        1  { "Device not configured correctly (Code 1)" }
                        3  { "Driver may be corrupted (Code 3)" }
                        9  { "Windows cannot identify device (Code 9)" }
                        10 { "Device cannot start (Code 10)" }
                        12 { "Not enough resources (Code 12)" }
                        14 { "Device requires restart (Code 14)" }
                        16 { "Cannot identify all resources (Code 16)" }
                        18 { "Reinstall drivers (Code 18)" }
                        19 { "Registry corrupted (Code 19)" }
                        21 { "Device being removed (Code 21)" }
                        22 { "Device is disabled (Code 22)" }
                        24 { "Device not present/malfunctioning (Code 24)" }
                        28 { "Drivers not installed (Code 28)" }
                        29 { "Device disabled by firmware (Code 29)" }
                        31 { "Device not working properly (Code 31)" }
                        32 { "Driver disabled in registry (Code 32)" }
                        33 { "Resources unavailable (Code 33)" }
                        34 { "Cannot configure device (Code 34)" }
                        35 { "Firmware missing (Code 35)" }
                        36 { "IRQ conflict (Code 36)" }
                        37 { "Driver failed (Code 37)" }
                        38 { "Driver already loaded, retry (Code 38)" }
                        39 { "Driver missing/corrupted (Code 39)" }
                        40 { "Service key missing (Code 40)" }
                        41 { "Driver loaded but device not found (Code 41)" }
                        42 { "Duplicate device, restart required (Code 42)" }
                        43 { "Device reported problems, stopped (Code 43)" }
                        44 { "Application/service stopped device (Code 44)" }
                        45 { "Device not connected (Code 45)" }
                        46 { "Device not accessible, restart (Code 46)" }
                        47 { "Safe removal prepared but not removed (Code 47)" }
                        48 { "Driver blocked by policy (Code 48)" }
                        49 { "Registry too large (Code 49)" }
                        52 { "Driver not digitally signed (Code 52)" }
                        default { "Unknown error (Code $($_.ConfigManagerErrorCode))" }
                    }
                }},
                DeviceID |
            Sort-Object ErrorCode
        
        if ($problemDevices.Count -eq 0) {
            Write-Host "No problem devices detected. Everything looks good!" -ForegroundColor Green
        } else {
            Write-Host "Found $($problemDevices.Count) device(s) with issues:" -ForegroundColor Red
            Write-Host ""
            
            foreach ($dev in $problemDevices) {
                Write-Host "Device: " -NoNewline -ForegroundColor Cyan
                Write-Host $dev.Name -ForegroundColor Yellow
                Write-Host "  $($dev.ErrorDescription)" -ForegroundColor Red
                Write-Host "  Device ID: $($dev.DeviceID)" -ForegroundColor Gray
                Write-Host ""
            }
            
            Write-Host "Suggested fixes:" -ForegroundColor Gray
            Write-Host "  - Right-click device in Device Manager -> Update driver" -ForegroundColor Gray
            Write-Host "  - Right-click -> Uninstall device, then restart" -ForegroundColor Gray
            Write-Host "  - Download driver from manufacturer website" -ForegroundColor Gray
            Write-Host "  - Run Windows Update to find driver updates" -ForegroundColor Gray
        }
        Pause
    }
    '8' {
        Clear-Host
        Write-Host "=== RECENTLY INSTALLED/UPDATED DRIVERS ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Checking driver installation history..." -ForegroundColor Cyan
        Write-Host ""
        
        # Check driver INF files by date
        $driverStore = "$env:SystemRoot\System32\DriverStore\FileRepository"
        if (Test-Path $driverStore) {
            $recentDriverFolders = Get-ChildItem $driverStore -Directory |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 30
            
            Write-Host "Recently modified driver packages (last 30):" -ForegroundColor Cyan
            Write-Host ""
            
            foreach ($folder in $recentDriverFolders) {
                $infFile = Get-ChildItem $folder.FullName -Filter "*.inf" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($infFile) {
                    $infContent = Get-Content $infFile.FullName -ErrorAction SilentlyContinue
                    $driverProvider = ($infContent | Select-String 'DriverVer=' | Select-Object -First 1) -replace '.*DriverVer=.*,', ''
                    
                    Write-Host "  $($folder.Name.Split('_')[0])" -ForegroundColor Yellow -NoNewline
                    Write-Host " - $($folder.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
                    if ($driverProvider) {
                        Write-Host "    $driverProvider" -ForegroundColor DarkGray
                    }
                }
            }
        } else {
            Write-Host "Driver store not accessible." -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Driver install events from Event Log:" -ForegroundColor Cyan
        Write-Host ""
        
        $driverEvents = Get-WinEvent -LogName "Microsoft-Windows-Kernel-PnP/Configuration" -MaxEvents 20 -ErrorAction SilentlyContinue |
            Where-Object { $_.Id -eq 401 -or $_.Id -eq 410 } |
            Select-Object TimeCreated, Id, Message |
            Sort-Object TimeCreated -Descending
        
        if ($driverEvents.Count -gt 0) {
            foreach ($event in $driverEvents) {
                $action = if ($event.Id -eq 401) { "INSTALLED" } else { "UPDATED" }
                $deviceName = ($event.Message -split "`n")[0] -replace '.*Device ', ''
                Write-Host "  $($event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray -NoNewline
                Write-Host " [$action] " -ForegroundColor $(if ($event.Id -eq 401) { "Green" } else { "Yellow" }) -NoNewline
                Write-Host $deviceName -ForegroundColor Cyan
            }
        } else {
            Write-Host "  No recent driver events found." -ForegroundColor Gray
        }
        Pause
    }
    '9' {
        Clear-Host
        Write-Host "=== DRIVER VERSION SUMMARY ===" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "=== KEY SYSTEM DRIVERS ===" -ForegroundColor Cyan
        Write-Host ""
        
        # Graphics
        Write-Host "Graphics Drivers:" -ForegroundColor Yellow
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" }
        foreach ($g in $gpu) {
            Write-Host "  $($g.Name)" -ForegroundColor Cyan
            Write-Host "    Driver Version: $($g.DriverVersion)" -ForegroundColor Gray
            Write-Host "    Driver Date:    $($g.DriverDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Network
        Write-Host "Network Drivers:" -ForegroundColor Yellow
        $net = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true -and $_.Name -notlike "*Microsoft*" -and $_.Name -notlike "*WAN*" }
        foreach ($n in $net) {
            $netDriver = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*$($n.Name)*" } | Select-Object -First 1
            Write-Host "  $($n.Name)" -ForegroundColor Cyan
            if ($netDriver) {
                Write-Host "    Version: $($netDriver.DriverVersion) | Date: $($netDriver.DriverDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
            }
        }
        Write-Host ""
        
        # Audio
        Write-Host "Audio Drivers:" -ForegroundColor Yellow
        $audio = Get-CimInstance Win32_SoundDevice | Where-Object { $_.Name -notlike "*Microsoft*" -and $_.Name -notlike "*High Definition Audio*" }
        foreach ($a in $audio) {
            $audioDriver = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*$($a.Name)*" } | Select-Object -First 1
            Write-Host "  $($a.Name)" -ForegroundColor Cyan
            if ($audioDriver) {
                Write-Host "    Version: $($audioDriver.DriverVersion) | Date: $($audioDriver.DriverDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
            }
        }
        Write-Host ""
        
        # Chipset / Storage
        Write-Host "Storage Controllers:" -ForegroundColor Yellow
        $storage = Get-CimInstance Win32_IDEController
        foreach ($s in $storage) {
            $storDriver = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceID -like "*$($s.PNPDeviceID)*" } | Select-Object -First 1
            Write-Host "  $($s.Name)" -ForegroundColor Cyan
            if ($storDriver) {
                Write-Host "    Version: $($storDriver.DriverVersion) | Date: $($storDriver.DriverDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
            }
        }
        
        # Also NVMe if present
        $nvme = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'SCSIAdapter' -and $_.DeviceName -like '*NVMe*' }
        foreach ($n in $nvme) {
            Write-Host "  $($n.DeviceName)" -ForegroundColor Cyan
            Write-Host "    Version: $($n.DriverVersion) | Date: $($n.DriverDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
        }
        
        Pause
    }
    '10' {
        Clear-Host
        Write-Host "=== EXPORT DRIVER LIST TO CSV ===" -ForegroundColor Yellow
        Write-Host ""
        
        $exportPath = "$env:USERPROFILE\Desktop\Drivers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        
        Write-Host "Export options:" -ForegroundColor Cyan
        Write-Host "  [1] All drivers" -ForegroundColor Yellow
        Write-Host "  [2] Third-party drivers only" -ForegroundColor Yellow
        Write-Host "  [3] Problem devices only" -ForegroundColor Yellow
        Write-Host ""
        $exportChoice = Read-Host "Select"
        
        try {
            switch ($exportChoice) {
                '1' {
                    Get-CimInstance Win32_PnPSignedDriver | 
                        Select-Object DeviceName, Description, DeviceClass, DriverProviderName, 
                                      DriverVersion, DriverDate, InfName, IsSigned |
                        Sort-Object DeviceClass, DeviceName |
                        Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                }
                '2' {
                    Get-CimInstance Win32_PnPSignedDriver | 
                        Where-Object { $_.DriverProviderName -ne 'Microsoft' -and $_.DriverProviderName -notlike '*Microsoft*' } |
                        Select-Object DeviceName, DeviceClass, DriverProviderName, 
                                      DriverVersion, DriverDate, InfName, IsSigned |
                        Sort-Object DeviceClass, DriverProviderName |
                        Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                }
                '3' {
                    Get-CimInstance Win32_PnPEntity | 
                        Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Unknown' -and $_.ConfigManagerErrorCode -ne 0 } |
                        Select-Object Name, Status, @{N='ErrorCode';E={$_.ConfigManagerErrorCode}}, DeviceID |
                        Sort-Object ErrorCode |
                        Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                }
                default {
                    Write-Host "Invalid selection." -ForegroundColor Red
                    Pause
                    break
                }
            }
            Write-Host "Driver list exported to:" -ForegroundColor Green
            Write-Host "  $exportPath" -ForegroundColor Yellow
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    'Q' { break }
    default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep 1 }
}
