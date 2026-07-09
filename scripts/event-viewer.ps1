# Event Log Analyst
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== EVENT LOG ANALYST ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] Critical & Error events - last 24 hours" -ForegroundColor Cyan
Write-Host "[2] Critical & Error events - last 7 days" -ForegroundColor Cyan
Write-Host "[3] Application crashes - last 7 days" -ForegroundColor Cyan
Write-Host "[4] System warnings - last 24 hours" -ForegroundColor Cyan
Write-Host "[5] Recent BSOD/Bugcheck events" -ForegroundColor Cyan
Write-Host "[6] Service failures" -ForegroundColor Cyan
Write-Host "[7] Security audit failures" -ForegroundColor Cyan
Write-Host "[8] Export filtered events to CSV" -ForegroundColor Cyan
Write-Host "[9] Show event log sizes" -ForegroundColor Cyan
Write-Host ""
Write-Host "[B] Return to main menu" -ForegroundColor Gray
Write-Host ""

$evChoice = Read-Host "Select option"

switch ($evChoice.ToUpper()) {
    '1' {
        Clear-Host
        Write-Host "=== CRITICAL & ERROR EVENTS (Last 24 Hours) ===" -ForegroundColor Yellow
        Write-Host ""
        $since = (Get-Date).AddHours(-24)
        $errors = Get-EventLog -LogName System -EntryType Error -After $since -ErrorAction SilentlyContinue
        $critical = Get-EventLog -LogName System -EntryType Error -After $since -ErrorAction SilentlyContinue | Where-Object { $_.EntryType -eq 'Critical' }
        
        if ($errors.Count -eq 0) {
            Write-Host "No errors found in the last 24 hours. Great!" -ForegroundColor Green
        } else {
            Write-Host "System Errors: $($errors.Count)" -ForegroundColor Red
            Write-Host ""
            $errors | Select-Object TimeGenerated, EntryType, Source, Message -First 20 |
                Format-Table -AutoSize -Wrap
            if ($errors.Count -gt 20) {
                Write-Host "... showing first 20 of $($errors.Count) errors" -ForegroundColor Gray
            }
        }
        Write-Host ""
        # Also check Application log
        $appErrors = Get-EventLog -LogName Application -EntryType Error -After $since -ErrorAction SilentlyContinue
        if ($appErrors.Count -gt 0) {
            Write-Host "Application Errors: $($appErrors.Count)" -ForegroundColor Red
            Write-Host ""
            $appErrors | Select-Object TimeGenerated, Source, Message -First 10 |
                Format-Table -AutoSize -Wrap
        }
        Pause
    }
    '2' {
        Clear-Host
        Write-Host "=== CRITICAL & ERROR EVENTS (Last 7 Days) ===" -ForegroundColor Yellow
        Write-Host ""
        $since = (Get-Date).AddDays(-7)
        $sysErrors = Get-EventLog -LogName System -EntryType Error -After $since -ErrorAction SilentlyContinue
        $appErrors = Get-EventLog -LogName Application -EntryType Error -After $since -ErrorAction SilentlyContinue
        
        Write-Host "System Log:" -ForegroundColor Cyan
        if ($sysErrors.Count -eq 0) {
            Write-Host "  No errors" -ForegroundColor Green
        } else {
            Write-Host "  Errors: $($sysErrors.Count)" -ForegroundColor Red
            $sysErrors | Group-Object Source | Sort-Object Count -Descending |
                Select-Object Count, Name | Format-Table -AutoSize
        }
        Write-Host ""
        Write-Host "Application Log:" -ForegroundColor Cyan
        if ($appErrors.Count -eq 0) {
            Write-Host "  No errors" -ForegroundColor Green
        } else {
            Write-Host "  Errors: $($appErrors.Count)" -ForegroundColor Red
            $appErrors | Group-Object Source | Sort-Object Count -Descending |
                Select-Object Count, Name | Format-Table -AutoSize
        }
        Pause
    }
    '3' {
        Clear-Host
        Write-Host "=== APPLICATION CRASHES (Last 7 Days) ===" -ForegroundColor Yellow
        Write-Host ""
        $since = (Get-Date).AddDays(-7)
        $crashes = Get-EventLog -LogName Application -EntryType Error -After $since -ErrorAction SilentlyContinue |
            Where-Object { $_.EventID -eq 1000 -or $_.EventID -eq 1026 -or $_.Source -like "*Crash*" -or $_.Source -like "*AppError*" }
        
        if ($crashes.Count -eq 0) {
            Write-Host "No application crashes detected in the last 7 days." -ForegroundColor Green
        } else {
            Write-Host "Application crashes detected: $($crashes.Count)" -ForegroundColor Red
            Write-Host ""
            $crashes | Select-Object TimeGenerated, Source, EventID, Message -First 15 |
                Format-Table -AutoSize -Wrap
        }
        
        Write-Host ""
        Write-Host "NOTE: For more detailed crash analysis, check:" -ForegroundColor Gray
        Write-Host "  Event Viewer -> Windows Logs -> Application" -ForegroundColor Gray
        Write-Host "  Reliability Monitor: Run 'perfmon /rel'" -ForegroundColor Gray
        Pause
    }
    '4' {
        Clear-Host
        Write-Host "=== SYSTEM WARNINGS (Last 24 Hours) ===" -ForegroundColor Yellow
        Write-Host ""
        $since = (Get-Date).AddHours(-24)
        $warnings = Get-EventLog -LogName System -EntryType Warning -After $since -ErrorAction SilentlyContinue
        
        if ($warnings.Count -eq 0) {
            Write-Host "No warnings found. Great!" -ForegroundColor Green
        } else {
            Write-Host "System warnings: $($warnings.Count)" -ForegroundColor Yellow
            Write-Host ""
            $warnings | Select-Object TimeGenerated, Source, EventID, Message -First 20 |
                Format-Table -AutoSize -Wrap
        }
        Pause
    }
    '5' {
        Clear-Host
        Write-Host "=== RECENT BSOD / BUGCHECK EVENTS ===" -ForegroundColor Yellow
        Write-Host ""
        $bsods = Get-EventLog -LogName System -Source "Microsoft-Windows-WER-SystemErrorReporting" -ErrorAction SilentlyContinue |
            Where-Object { $_.EventID -eq 1001 }
        $bugchecks = Get-EventLog -LogName System -ErrorAction SilentlyContinue |
            Where-Object { $_.EventID -eq 41 -and $_.Source -eq "Microsoft-Windows-Kernel-Power" }
        
        if ($bsods.Count -eq 0 -and $bugchecks.Count -eq 0) {
            Write-Host "No BSOD or unexpected shutdown events found." -ForegroundColor Green
        } else {
            if ($bsods.Count -gt 0) {
                Write-Host "Bugcheck (BSOD) events: $($bsods.Count)" -ForegroundColor Red
                Write-Host ""
                $bsods | Select-Object TimeGenerated, Message -First 5 |
                    Format-List
            }
            if ($bugchecks.Count -gt 0) {
                Write-Host "Unexpected shutdowns (Kernel-Power): $($bugchecks.Count)" -ForegroundColor Red
                Write-Host ""
                $bugchecks | Select-Object TimeGenerated, Message -First 5 |
                    Format-List
            }
        }
        Write-Host ""
        Write-Host "For BSOD dump files, check:" -ForegroundColor Gray
        Write-Host "  C:\Windows\Minidump" -ForegroundColor Gray
        Write-Host "  C:\Windows\MEMORY.DMP" -ForegroundColor Gray
        Pause
    }
    '6' {
        Clear-Host
        Write-Host "=== SERVICE FAILURES ===" -ForegroundColor Yellow
        Write-Host ""
        $since = (Get-Date).AddDays(-7)
        $svcFailures = Get-EventLog -LogName System -Source "Service Control Manager" -After $since -ErrorAction SilentlyContinue |
            Where-Object { $_.EventID -eq 7031 -or $_.EventID -eq 7034 -or $_.EventID -eq 7000 -or $_.EventID -eq 7009 }
        
        if ($svcFailures.Count -eq 0) {
            Write-Host "No service failures detected in the last 7 days." -ForegroundColor Green
        } else {
            Write-Host "Service failures: $($svcFailures.Count)" -ForegroundColor Red
            Write-Host ""
            $svcFailures | Select-Object TimeGenerated, EventID, Message -First 15 |
                Format-Table -AutoSize -Wrap
        }
        Pause
    }
    '7' {
        Clear-Host
        Write-Host "=== SECURITY AUDIT FAILURES ===" -ForegroundColor Yellow
        Write-Host ""
        $since = (Get-Date).AddDays(-1)
        try {
            $auditFails = Get-EventLog -LogName Security -EntryType FailureAudit -After $since -ErrorAction Stop |
                Where-Object { $_.EventID -eq 4625 }
            if ($auditFails.Count -eq 0) {
                Write-Host "No failed login attempts in the last 24 hours." -ForegroundColor Green
            } else {
                Write-Host "Failed login attempts: $($auditFails.Count)" -ForegroundColor Red
                Write-Host ""
                $auditFails | Group-Object { $_.ReplacementStrings[5] } |
                    Sort-Object Count -Descending |
                    Select-Object @{N='Source IP';E={$_.Name}}, Count -First 20 |
                    Format-Table -AutoSize
            }
        } catch {
            Write-Host "Cannot read Security log. You may need to run as Administrator." -ForegroundColor Red
            Write-Host "Security auditing may also be disabled on this system." -ForegroundColor Gray
        }
        Pause
    }
    '8' {
        Clear-Host
        Write-Host "=== EXPORT FILTERED EVENTS ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Select log to export:" -ForegroundColor Cyan
        Write-Host "  [1] System errors (last 7 days)" -ForegroundColor Yellow
        Write-Host "  [2] Application errors (last 7 days)" -ForegroundColor Yellow
        Write-Host "  [3] All errors and warnings (last 24 hours)" -ForegroundColor Yellow
        Write-Host ""
        $exportChoice = Read-Host "Select"
        $exportPath = "$env:USERPROFILE\Desktop\EventLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $events = @()
        
        switch ($exportChoice) {
            '1' { $events = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-7) -ErrorAction SilentlyContinue }
            '2' { $events = Get-EventLog -LogName Application -EntryType Error -After (Get-Date).AddDays(-7) -ErrorAction SilentlyContinue }
            '3' { 
                $sysEv = Get-EventLog -LogName System -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Where-Object { $_.EntryType -match 'Error|Warning' }
                $appEv = Get-EventLog -LogName Application -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Where-Object { $_.EntryType -match 'Error|Warning' }
                $events = $sysEv + $appEv
            }
        }
        
        if ($events.Count -gt 0) {
            $events | Select-Object TimeGenerated, EntryType, Source, EventID, Message |
                Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Exported $($events.Count) events to:" -ForegroundColor Green
            Write-Host "  $exportPath" -ForegroundColor Yellow
        } else {
            Write-Host "No events to export." -ForegroundColor Gray
        }
        Pause
    }
    '9' {
        Clear-Host
        Write-Host "=== EVENT LOG SIZES ===" -ForegroundColor Yellow
        Write-Host ""
        $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue |
            Where-Object { $_.RecordCount -gt 0 } |
            Select-Object LogName, RecordCount, IsEnabled, LogMode, @{N='MaxSizeMB';E={[math]::Round($_.MaximumSizeInBytes / 1MB, 2)}} |
            Sort-Object RecordCount -Descending
        
        $logs | Format-Table -AutoSize
        Write-Host ""
        $totalEvents = ($logs | Measure-Object RecordCount -Sum).Sum
        Write-Host "Total events across all logs: $totalEvents" -ForegroundColor Cyan
        Pause
    }
    'B' { break }
    default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep 1 }
}
