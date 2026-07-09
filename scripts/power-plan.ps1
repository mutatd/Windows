# Power Plan Manager
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== POWER PLAN MANAGER ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] Show current power plan" -ForegroundColor Cyan
Write-Host "[2] List all power plans" -ForegroundColor Cyan
Write-Host "[3] Switch to High Performance" -ForegroundColor Cyan
Write-Host "[4] Switch to Balanced" -ForegroundColor Cyan
Write-Host "[5] Switch to Power Saver" -ForegroundColor Cyan
Write-Host "[6] Enable Ultimate Performance (hidden plan)" -ForegroundColor Cyan
Write-Host "[7] Show advanced sleep/hibernate settings" -ForegroundColor Cyan
Write-Host "[8] Disable sleep timeout (always on)" -ForegroundColor Cyan
Write-Host "[9] Export current power plan" -ForegroundColor Cyan
Write-Host "[10] Import a power plan" -ForegroundColor Cyan
Write-Host "[Q] Return to main menu" -ForegroundColor Gray
Write-Host ""

$ppChoice = Read-Host "Select option"

switch ($ppChoice.ToUpper()) {
    '1' {
        Clear-Host
        Write-Host "=== CURRENT POWER PLAN ===" -ForegroundColor Yellow
        Write-Host ""
        $active = powercfg /getactivescheme
        Write-Host "$active" -ForegroundColor Cyan
        Pause
    }
    '2' {
        Clear-Host
        Write-Host "=== ALL POWER PLANS ===" -ForegroundColor Yellow
        Write-Host ""
        powercfg /list
        Write-Host ""
        $active = powercfg /getactivescheme
        Write-Host "Current: " -NoNewline -ForegroundColor Yellow
        Write-Host ($active -split ':\s+')[1] -ForegroundColor Green
        Pause
    }
    '3' {
        Clear-Host
        Write-Host "=== HIGH PERFORMANCE ===" -ForegroundColor Yellow
        Write-Host ""
        $guid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        powercfg /setactive $guid
        Write-Host "Switched to High Performance." -ForegroundColor Green
        Pause
    }
    '4' {
        Clear-Host
        Write-Host "=== BALANCED ===" -ForegroundColor Yellow
        Write-Host ""
        $guid = "381b4222-f694-41f0-9685-ff5bb260df2e"
        powercfg /setactive $guid
        Write-Host "Switched to Balanced." -ForegroundColor Green
        Pause
    }
    '5' {
        Clear-Host
        Write-Host "=== POWER SAVER ===" -ForegroundColor Yellow
        Write-Host ""
        $guid = "a1841308-3541-4fab-bc81-f71556f20b4a"
        powercfg /setactive $guid
        Write-Host "Switched to Power Saver." -ForegroundColor Green
        Pause
    }
    '6' {
        Clear-Host
        Write-Host "=== ULTIMATE PERFORMANCE ===" -ForegroundColor Yellow
        Write-Host ""
        $exists = powercfg /list | Select-String "Ultimate Performance"
        if ($exists) {
            Write-Host "Ultimate Performance plan already exists." -ForegroundColor Cyan
            $confirm = Read-Host "Switch to it now? (y/N)"
            if ($confirm -eq 'y') {
                $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
                powercfg /setactive $guid
                Write-Host "Switched to Ultimate Performance." -ForegroundColor Green
            }
        } else {
            Write-Host "Ultimate Performance plan not found. Attempting to enable..." -ForegroundColor Yellow
            $result = powercfg -duplicatescheme "e9a42b02-d5df-448d-aa00-03f14749eb61" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Ultimate Performance plan enabled and set as active." -ForegroundColor Green
            } else {
                Write-Host "Could not enable Ultimate Performance. It may not be available on this device." -ForegroundColor Red
                Write-Host "Note: This plan is typically only available on Windows 10/11 Pro for Workstations." -ForegroundColor Gray
            }
        }
        Pause
    }
    '7' {
        Clear-Host
        Write-Host "=== SLEEP & HIBERNATE SETTINGS ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Current AC power settings:" -ForegroundColor Cyan
        powercfg /query SCHEME_CURRENT SUB_SLEEP
        Write-Host ""
        Write-Host "Hibernate status:" -ForegroundColor Cyan
        powercfg /availablesleepstates
        Write-Host ""
        Write-Host "Battery report option:" -ForegroundColor Gray
        Write-Host "  Run: powercfg /batteryreport" -ForegroundColor Gray
        Pause
    }
    '8' {
        Clear-Host
        Write-Host "=== DISABLE SLEEP TIMEOUT ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This will set the display and sleep timeouts to 'Never' on AC power." -ForegroundColor Cyan
        $confirm = Read-Host "Apply? (y/N)"
        if ($confirm -eq 'y') {
            powercfg -change -monitor-timeout-ac 0
            powercfg -change -standby-timeout-ac 0
            powercfg -change -hibernate-timeout-ac 0
            Write-Host "Sleep and display timeouts set to Never (on AC power)." -ForegroundColor Green
            Write-Host "NOTE: This will prevent your PC from sleeping automatically." -ForegroundColor Yellow
        }
        Pause
    }
    '9' {
        Clear-Host
        Write-Host "=== EXPORT POWER PLAN ===" -ForegroundColor Yellow
        Write-Host ""
        $active = powercfg /getactivescheme
        $guidMatch = [regex]::Match($active, '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})')
        if ($guidMatch.Success) {
            $guid = $guidMatch.Groups[1].Value
            $exportPath = "$env:USERPROFILE\Desktop\PowerPlan_$(Get-Date -Format 'yyyyMMdd').pow"
            powercfg /export "$exportPath" $guid
            Write-Host "Power plan exported to:" -ForegroundColor Green
            Write-Host "  $exportPath" -ForegroundColor Yellow
        } else {
            Write-Host "Could not determine active power plan." -ForegroundColor Red
        }
        Pause
    }
    '10' {
        Clear-Host
        Write-Host "=== IMPORT POWER PLAN ===" -ForegroundColor Yellow
        Write-Host ""
        $importPath = Read-Host "Enter full path to .pow file"
        if (Test-Path $importPath) {
            powercfg /import "$importPath"
            Write-Host "Power plan imported." -ForegroundColor Green
        } else {
            Write-Host "File not found." -ForegroundColor Red
        }
        Pause
    }
    'Q' { break }
    default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep 1 }
}
