# Service Manager
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== SERVICE MANAGER ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Must run as admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This tool requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator." -ForegroundColor Yellow
    Pause
    return
}

Write-Host "[1] List all running services" -ForegroundColor Cyan
Write-Host "[2] List all stopped services" -ForegroundColor Cyan
Write-Host "[3] List all services set to Automatic" -ForegroundColor Cyan
Write-Host "[4] List third-party (non-Microsoft) services" -ForegroundColor Cyan
Write-Host "[5] Start a service" -ForegroundColor Cyan
Write-Host "[6] Stop a service" -ForegroundColor Cyan
Write-Host "[7] Disable a service" -ForegroundColor Cyan
Write-Host "[8] Set a service to Manual" -ForegroundColor Cyan
Write-Host "[9] Show service details" -ForegroundColor Cyan
Write-Host "[10] Apply 'Safe to Disable' performance preset" -ForegroundColor Cyan
Write-Host "[11] Export service list to CSV" -ForegroundColor Cyan
Write-Host "[Q] Return to main menu" -ForegroundColor Gray
Write-Host ""

$svcChoice = Read-Host "Select option"

switch ($svcChoice.ToUpper()) {
    '1' {
        Clear-Host
        Write-Host "=== RUNNING SERVICES ===" -ForegroundColor Yellow
        Write-Host ""
        Get-Service | Where-Object { $_.Status -eq 'Running' } | 
            Select-Object Name, DisplayName, StartType | 
            Sort-Object Name |
            Format-Table -AutoSize
        Write-Host "Count: $((Get-Service | Where-Object { $_.Status -eq 'Running' }).Count)" -ForegroundColor Cyan
        Pause
    }
    '2' {
        Clear-Host
        Write-Host "=== STOPPED SERVICES ===" -ForegroundColor Yellow
        Write-Host ""
        Get-Service | Where-Object { $_.Status -eq 'Stopped' } | 
            Select-Object Name, DisplayName, StartType | 
            Sort-Object Name |
            Format-Table -AutoSize
        Write-Host "Count: $((Get-Service | Where-Object { $_.Status -eq 'Stopped' }).Count)" -ForegroundColor Cyan
        Pause
    }
    '3' {
        Clear-Host
        Write-Host "=== SERVICES SET TO AUTOMATIC ===" -ForegroundColor Yellow
        Write-Host ""
        Get-Service | Where-Object { $_.StartType -eq 'Automatic' } | 
            Select-Object Name, DisplayName, Status | 
            Sort-Object Name |
            Format-Table -AutoSize
        Write-Host "Count: $((Get-Service | Where-Object { $_.StartType -eq 'Automatic' }).Count)" -ForegroundColor Cyan
        Pause
    }
    '4' {
        Clear-Host
        Write-Host "=== THIRD-PARTY SERVICES (Non-Microsoft) ===" -ForegroundColor Yellow
        Write-Host ""
        $thirdParty = Get-CimInstance Win32_Service | Where-Object { 
            $_.PathName -ne $null -and 
            $_.PathName -notlike '*\Windows\*' -and 
            $_.PathName -notlike '*\system32\*' -and
            $_.PathName -notlike '"C:\Windows\*' 
        }
        if ($thirdParty.Count -eq 0) {
            Write-Host "No third-party services found." -ForegroundColor Gray
        } else {
            $thirdParty | Select-Object Name, DisplayName, State, StartMode, PathName | 
                Sort-Object Name | Format-Table -AutoSize -Wrap
            Write-Host "Count: $($thirdParty.Count)" -ForegroundColor Cyan
        }
        Pause
    }
    '5' {
        Clear-Host
        Write-Host "=== START A SERVICE ===" -ForegroundColor Yellow
        Write-Host ""
        $svcName = Read-Host "Enter service name (e.g. 'wuauserv' for Windows Update)"
        try {
            Start-Service -Name $svcName -ErrorAction Stop
            Write-Host "Service '$svcName' started successfully." -ForegroundColor Green
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    '6' {
        Clear-Host
        Write-Host "=== STOP A SERVICE ===" -ForegroundColor Yellow
        Write-Host ""
        $running = Get-Service | Where-Object { $_.Status -eq 'Running' } | Sort-Object Name
        Write-Host "Currently running services:" -ForegroundColor Cyan
        $i = 1
        foreach ($svc in $running) {
            Write-Host "  [$i] $($svc.Name) - $($svc.DisplayName)" -ForegroundColor Yellow
            $i++
        }
        Write-Host ""
        $svcNum = Read-Host "Enter number to stop (or 0 to type a name manually)"
        if ($svcNum -match '^\d+$' -and [int]$svcNum -gt 0 -and [int]$svcNum -le $running.Count) {
            $selectedSvc = $running[[int]$svcNum - 1]
        } elseif ($svcNum -eq '0') {
            $manualName = Read-Host "Enter service name"
            $selectedSvc = Get-Service -Name $manualName -ErrorAction SilentlyContinue
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red
            Pause
            break
        }
        if ($selectedSvc) {
            try {
                Stop-Service -Name $selectedSvc.Name -Force -ErrorAction Stop
                Write-Host "Stopped: $($selectedSvc.DisplayName)" -ForegroundColor Green
            } catch {
                Write-Host "ERROR: $_" -ForegroundColor Red
            }
        }
        Pause
    }
    '7' {
        Clear-Host
        Write-Host "=== DISABLE A SERVICE ===" -ForegroundColor Yellow
        Write-Host ""
        $svcName = Read-Host "Enter service name to disable"
        Write-Host "WARNING: Disabling critical services can break Windows!" -ForegroundColor Red
        $confirm = Read-Host "Are you sure? (y/N)"
        if ($confirm -eq 'y') {
            try {
                Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
                Write-Host "Service '$svcName' set to Disabled." -ForegroundColor Green
            } catch {
                Write-Host "ERROR: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        Pause
    }
    '8' {
        Clear-Host
        Write-Host "=== SET SERVICE TO MANUAL ===" -ForegroundColor Yellow
        Write-Host ""
        $svcName = Read-Host "Enter service name to set to Manual"
        try {
            Set-Service -Name $svcName -StartupType Manual -ErrorAction Stop
            Write-Host "Service '$svcName' set to Manual." -ForegroundColor Green
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    '9' {
        Clear-Host
        Write-Host "=== SERVICE DETAILS ===" -ForegroundColor Yellow
        Write-Host ""
        $svcName = Read-Host "Enter service name"
        $svc = Get-CimInstance Win32_Service -Filter "Name='$svcName'" -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Host "Service not found." -ForegroundColor Red
        } else {
            Write-Host "Name:        $($svc.Name)" -ForegroundColor Cyan
            Write-Host "Display:     $($svc.DisplayName)" -ForegroundColor Cyan
            Write-Host "Status:      $($svc.State)" -ForegroundColor Cyan
            Write-Host "Start Mode:  $($svc.StartMode)" -ForegroundColor Cyan
            Write-Host "Path:        $($svc.PathName)" -ForegroundColor Cyan
            Write-Host "Description: $($svc.Description)" -ForegroundColor Cyan
            Write-Host "Start Name:  $($svc.StartName)" -ForegroundColor Cyan
            if ($svc.ProcessId -gt 0) {
                Write-Host "PID:         $($svc.ProcessId)" -ForegroundColor Cyan
            }
        }
        Pause
    }
    '10' {
        Clear-Host
        Write-Host "=== PERFORMANCE SERVICE PRESET ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This will disable the following non-essential services:" -ForegroundColor Cyan
        Write-Host ""
        $safeToDisable = @(
            @{Name="DiagTrack"; Desc="Diagnostics Tracking Service (Telemetry)"},
            @{Name="dmwappushservice"; Desc="Device Management WAP Push"},
            @{Name="MapsBroker"; Desc="Downloaded Maps Manager"},
            @{Name="lfsvc"; Desc="Geolocation Service"},
            @{Name="WSearch"; Desc="Windows Search (disables file indexing)"},
            @{Name="XblAuthManager"; Desc="Xbox Live Auth Manager"},
            @{Name="XblGameSave"; Desc="Xbox Live Game Save"},
            @{Name="XboxNetApiSvc"; Desc="Xbox Live Networking"},
            @{Name="XboxGipSvc"; Desc="Xbox Accessory Management"},
            @{Name="PrintNotify"; Desc="Printer Notifications"},
            @{Name="Fax"; Desc="Fax Service"},
            @{Name="TabletInputService"; Desc="Touch Keyboard Service"},
            @{Name="WMPNetworkSvc"; Desc="Windows Media Player Network Sharing"},
            @{Name="TrkWks"; Desc="Distributed Link Tracking Client"},
            @{Name="RemoteRegistry"; Desc="Remote Registry"},
            @{Name="RetailDemo"; Desc="Retail Demo Service"}
        )
        foreach ($svc in $safeToDisable) {
            Write-Host "  - $($svc.Name): $($svc.Desc)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "NOTE: Windows Search will be stopped but file search will still work (just slower)." -ForegroundColor Gray
        Write-Host "Xbox services only matter if you use Xbox app/Game Bar." -ForegroundColor Gray
        Write-Host ""
        $presetConfirm = Read-Host "Apply this preset? (y/N)"
        if ($presetConfirm -eq 'y') {
            foreach ($svc in $safeToDisable) {
                $existing = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
                if ($existing) {
                    try {
                        if ($existing.Status -eq 'Running') {
                            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                        }
                        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                        Write-Host "  Disabled: $($svc.Name)" -ForegroundColor Green
                    } catch {
                        Write-Host "  Skipped: $($svc.Name) - $_" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "  Not found: $($svc.Name)" -ForegroundColor DarkGray
                }
            }
            Write-Host ""
            Write-Host "Preset applied. Some changes require a restart." -ForegroundColor Green
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        Pause
    }
    '11' {
        Clear-Host
        Write-Host "=== EXPORT SERVICE LIST ===" -ForegroundColor Yellow
        Write-Host ""
        $exportPath = "$env:USERPROFILE\Desktop\Services_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        try {
            Get-CimInstance Win32_Service | Select-Object Name, DisplayName, State, StartMode, PathName, StartName, Description |
                Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Service list exported to:" -ForegroundColor Green
            Write-Host "  $exportPath" -ForegroundColor Yellow
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    'Q' { break }
    default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep 1 }
}
