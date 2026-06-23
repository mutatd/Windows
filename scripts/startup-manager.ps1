# Startup Program Manager
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      Startup Program Manager" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

do {
    Write-Host "  [1] List All Startup Programs"
    Write-Host "  [2] List Registry Startup Items"
    Write-Host "  [3] List Startup Folder Items"
    Write-Host "  [4] List Scheduled Tasks (Startup)"
    Write-Host "  [5] Disable Specific Startup Program"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nAll Startup Programs (High Impact):" -ForegroundColor Yellow
            Write-Host "=================================" -ForegroundColor Cyan
            try {
                $startup = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, User, Location
                $count = 0
                foreach ($item in $startup) {
                    $count++
                    Write-Host "[$count] $($item.Name)" -ForegroundColor White
                    Write-Host "    Command: $($item.Command)" -ForegroundColor Gray
                    Write-Host "    User: $($item.User)" -ForegroundColor Gray
                    Write-Host "    Location: $($item.Location)" -ForegroundColor Gray
                    Write-Host "---" -ForegroundColor DarkGray
                }
                if ($count -eq 0) {
                    Write-Host "No startup programs found." -ForegroundColor Green
                } else {
                    Write-Host "Total: $count startup programs" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nRegistry Startup Items:" -ForegroundColor Yellow
            Write-Host "=======================" -ForegroundColor Cyan
            $paths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
            )
            
            foreach ($path in $paths) {
                Write-Host "`n$path" -ForegroundColor Cyan
                try {
                    $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                    if ($items) {
                        $items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                            Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
                        }
                    } else {
                        Write-Host "  (empty)" -ForegroundColor Gray
                    }
                } catch {
                    Write-Host "  (not accessible)" -ForegroundColor Gray
                }
            }
            Pause
        }
        '3' {
            Write-Host "`nStartup Folder Items:" -ForegroundColor Yellow
            Write-Host "======================" -ForegroundColor Cyan
            $startupFolders = @(
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
                "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup"
            )
            
            foreach ($folder in $startupFolders) {
                Write-Host "`n$folder" -ForegroundColor Cyan
                if (Test-Path $folder) {
                    $items = Get-ChildItem -Path $folder -ErrorAction SilentlyContinue
                    if ($items) {
                        foreach ($item in $items) {
                            Write-Host "  $($item.Name)" -ForegroundColor White
                        }
                    } else {
                        Write-Host "  (empty)" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "  (folder not found)" -ForegroundColor Gray
                }
            }
            Pause
        }
        '4' {
            Write-Host "`nScheduled Tasks (At Startup):" -ForegroundColor Yellow
            Write-Host "=============================" -ForegroundColor Cyan
            try {
                $tasks = Get-ScheduledTask | Where-Object { 
                    $_.Triggers | Where-Object { $_.CimClass.CimClassName -match 'BootTrigger|LogonTrigger|StartupTrigger' }
                } | Select-Object TaskName, State, TaskPath
                
                foreach ($task in $tasks) {
                    Write-Host "Name: $($task.TaskName)" -ForegroundColor White
                    Write-Host "Path: $($task.TaskPath)" -ForegroundColor Gray
                    Write-Host "State: $($task.State)" -ForegroundColor $(if($task.State -eq 'Ready'){'Green'}else{'Yellow'})
                    Write-Host "---" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '5' {
            Write-Host "`nDisable Startup Program" -ForegroundColor Yellow
            Write-Host "=======================" -ForegroundColor Cyan
            $startup = Get-CimInstance Win32_StartupCommand
            $count = 0
            foreach ($item in $startup) {
                $count++
                Write-Host "[$count] $($item.Name)" -ForegroundColor White
            }
            
            if ($count -gt 0) {
                $selection = Read-Host "`nEnter number to disable (0 to cancel)"
                if ($selection -match '^\d+$' -and [int]$selection -gt 0 -and [int]$selection -le $count) {
                    $selected = $startup[[int]$selection - 1]
                    Write-Host "Disabling: $($selected.Name)" -ForegroundColor Yellow
                    try {
                        # Backup to text file
                        $backup = @"
Name: $($selected.Name)
Command: $($selected.Command)
User: $($selected.User)
Location: $($selected.Location)
Disabled: $(Get-Date)
"@
                        $backup | Out-File "$env:TEMP\startup_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                        Write-Host "Backup saved to TEMP folder" -ForegroundColor Gray
                        
                        Disable-CimInstance -InputObject $selected
                        Write-Host "Successfully disabled!" -ForegroundColor Green
                    } catch {
                        Write-Host "Error disabling: $_" -ForegroundColor Red
                        Write-Host "Try running as Administrator" -ForegroundColor Yellow
                    }
                }
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
