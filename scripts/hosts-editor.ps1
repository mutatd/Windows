# Hosts File Editor
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== HOSTS FILE EDITOR ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Must run as admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This tool requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator." -ForegroundColor Yellow
    Pause
    return
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupFolder = "$env:USERPROFILE\Documents\HostsBackup"

Write-Host "[1] View current hosts file" -ForegroundColor Cyan
Write-Host "[2] Backup hosts file" -ForegroundColor Cyan
Write-Host "[3] Add an entry" -ForegroundColor Cyan
Write-Host "[4] Remove an entry" -ForegroundColor Cyan
Write-Host "[5] Block common tracking/ad domains" -ForegroundColor Cyan
Write-Host "[6] Restore from backup" -ForegroundColor Cyan
Write-Host "[7] Clear all custom entries (reset to default)" -ForegroundColor Cyan
Write-Host "[8] Flush DNS cache" -ForegroundColor Cyan
Write-Host "[Q] Return to main menu" -ForegroundColor Gray
Write-Host ""

$hostsChoice = Read-Host "Select option"

switch ($hostsChoice.ToUpper()) {
    '1' {
        Clear-Host
        Write-Host "=== HOSTS FILE CONTENTS ===" -ForegroundColor Yellow
        Write-Host "File: $hostsPath" -ForegroundColor Gray
        Write-Host ""
        Get-Content $hostsPath | ForEach-Object {
            if ($_ -match '^\s*#' -or $_ -match '^\s*$') {
                Write-Host $_ -ForegroundColor DarkGray
            } else {
                Write-Host $_ -ForegroundColor Yellow
            }
        }
        Write-Host ""
        $entryCount = (Get-Content $hostsPath | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }).Count
        Write-Host "Active entries: $entryCount" -ForegroundColor Cyan
        Pause
    }
    '2' {
        Clear-Host
        Write-Host "=== BACKUP HOSTS FILE ===" -ForegroundColor Yellow
        Write-Host ""
        if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
        $backupFile = "$backupFolder\hosts_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $hostsPath $backupFile -Force
        Write-Host "Backup created:" -ForegroundColor Green
        Write-Host "  $backupFile" -ForegroundColor Yellow
        Pause
    }
    '3' {
        Clear-Host
        Write-Host "=== ADD HOSTS ENTRY ===" -ForegroundColor Yellow
        Write-Host ""
        $domain = Read-Host "Enter domain to redirect (e.g. example.com)"
        $ip = Read-Host "Enter IP address (e.g. 127.0.0.1, or 0.0.0.0 to block)"
        if ($domain -and $ip) {
            # Check if already exists
            $existing = Get-Content $hostsPath | Select-String "\s+$([regex]::Escape($domain))$"
            if ($existing) {
                Write-Host "Entry already exists:" -ForegroundColor Yellow
                Write-Host "  $existing" -ForegroundColor Cyan
                $overwrite = Read-Host "Overwrite? (y/N)"
                if ($overwrite -ne 'y') {
                    Write-Host "Cancelled." -ForegroundColor Yellow
                    Pause
                    break
                }
                # Remove old entry
                $content = Get-Content $hostsPath | Where-Object { $_ -notmatch "\s+$([regex]::Escape($domain))$" }
                $content | Set-Content $hostsPath -Force
            }
            # Create backup first
            if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
            Copy-Item $hostsPath "$backupFolder\hosts_pre_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
            # Add entry
            Add-Content $hostsPath "`n$ip`t$domain"
            Write-Host "Added: $ip -> $domain" -ForegroundColor Green
            # Flush DNS
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed." -ForegroundColor Cyan
        } else {
            Write-Host "Invalid input." -ForegroundColor Red
        }
        Pause
    }
    '4' {
        Clear-Host
        Write-Host "=== REMOVE HOSTS ENTRY ===" -ForegroundColor Yellow
        Write-Host ""
        $entries = Get-Content $hostsPath | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
        if ($entries.Count -eq 0) {
            Write-Host "No custom entries to remove." -ForegroundColor Gray
            Pause
            break
        }
        Write-Host "Current entries:" -ForegroundColor Cyan
        $i = 1
        foreach ($entry in $entries) {
            Write-Host "  [$i] $entry" -ForegroundColor Yellow
            $i++
        }
        Write-Host ""
        $removeNum = Read-Host "Enter number to remove (or 0 to cancel)"
        if ($removeNum -match '^\d+$' -and [int]$removeNum -gt 0 -and [int]$removeNum -le $entries.Count) {
            $selected = $entries[[int]$removeNum - 1]
            # Backup
            if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
            Copy-Item $hostsPath "$backupFolder\hosts_pre_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
            # Remove
            $escapedEntry = [regex]::Escape($selected.Trim())
            $content = Get-Content $hostsPath | Where-Object { $_.Trim() -ne $selected.Trim() }
            $content | Set-Content $hostsPath -Force
            Write-Host "Removed: $selected" -ForegroundColor Green
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed." -ForegroundColor Cyan
        }
        Pause
    }
    '5' {
        Clear-Host
        Write-Host "=== BLOCK TRACKING/AD DOMAINS ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This will add entries to block common tracking and advertising domains." -ForegroundColor Cyan
        Write-Host "These domains will be redirected to 0.0.0.0 (nowhere)." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "This includes domains from:" -ForegroundColor Gray
        Write-Host "  - Google Analytics / DoubleClick" -ForegroundColor Gray
        Write-Host "  - Facebook tracking pixels" -ForegroundColor Gray
        Write-Host "  - Common ad networks" -ForegroundColor Gray
        Write-Host "  - Microsoft telemetry (optional extras)" -ForegroundColor Gray
        Write-Host ""
        
        $trackingDomains = @(
            "doubleclick.net", "googlesyndication.com", "googleadservices.com",
            "google-analytics.com", "googletagmanager.com", "googletagservices.com",
            "facebook.net", "fbcdn.net", "facebook.com",
            "amazon-adsystem.com", "scorecardresearch.com",
            "adsrvr.org", "adnxs.com", "criteo.com", "criteo.net",
            "outbrain.com", "taboola.com", "quantserve.com", "addthis.com"
        )
        
        Write-Host "Base tracking domains to block:" -ForegroundColor Yellow
        foreach ($d in $trackingDomains) {
            Write-Host "  $d" -ForegroundColor Yellow
        }
        Write-Host ""
        
        $confirmBlock = Read-Host "Add these to hosts file? (y/N)"
        if ($confirmBlock -eq 'y') {
            # Backup
            if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
            Copy-Item $hostsPath "$backupFolder\hosts_pre_blocklist_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
            
            $added = 0
            $existingCount = 0
            foreach ($domain in $trackingDomains) {
                $check = Get-Content $hostsPath | Select-String "\s+$([regex]::Escape($domain))$"
                if ($check) {
                    $existingCount++
                } else {
                    Add-Content $hostsPath "0.0.0.0`t$domain"
                    $added++
                }
            }
            Write-Host ""
            Write-Host "Added $added new entries. $existingCount already existed." -ForegroundColor Green
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed." -ForegroundColor Cyan
            
            Write-Host ""
            Write-Host "TIP: You can verify blocking by pinging a blocked domain." -ForegroundColor Gray
            Write-Host "     It should resolve to 0.0.0.0" -ForegroundColor Gray
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        Pause
    }
    '6' {
        Clear-Host
        Write-Host "=== RESTORE FROM BACKUP ===" -ForegroundColor Yellow
        Write-Host ""
        if (-not (Test-Path $backupFolder)) {
            Write-Host "No backup folder found." -ForegroundColor Gray
            Pause
            break
        }
        $backups = Get-ChildItem $backupFolder -Filter "hosts_*" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -eq 0) {
            Write-Host "No backup files found." -ForegroundColor Gray
            Pause
            break
        }
        Write-Host "Available backups:" -ForegroundColor Cyan
        $j = 1
        foreach ($bkp in $backups) {
            Write-Host "  [$j] $($bkp.Name) - $($bkp.LastWriteTime)" -ForegroundColor Yellow
            $j++
        }
        Write-Host ""
        $bkpNum = Read-Host "Enter number to restore (or 0 to cancel)"
        if ($bkpNum -match '^\d+$' -and [int]$bkpNum -gt 0 -and [int]$bkpNum -le $backups.Count) {
            $selectedBkp = $backups[[int]$bkpNum - 1]
            Copy-Item $selectedBkp.FullName $hostsPath -Force
            Write-Host "Hosts file restored from backup." -ForegroundColor Green
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed." -ForegroundColor Cyan
        }
        Pause
    }
    '7' {
        Clear-Host
        Write-Host "=== RESET HOSTS FILE TO DEFAULT ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This will remove ALL custom entries and restore the default Windows hosts file." -ForegroundColor Red
        Write-Host ""
        $resetConfirm = Read-Host "Type 'RESET' to confirm"
        if ($resetConfirm -eq 'RESET') {
            # Backup first
            if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
            Copy-Item $hostsPath "$backupFolder\hosts_before_reset_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
            # Write default
            $defaultHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
"@
            $defaultHosts | Set-Content $hostsPath -Force -Encoding ASCII
            Write-Host "Hosts file reset to default." -ForegroundColor Green
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed." -ForegroundColor Cyan
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        Pause
    }
    '8' {
        Clear-Host
        Write-Host "=== FLUSH DNS CACHE ===" -ForegroundColor Yellow
        Write-Host ""
        ipconfig /flushdns
        Write-Host "DNS cache flushed successfully." -ForegroundColor Green
        Pause
    }
    'Q' { break }
    default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep 1 }
}
