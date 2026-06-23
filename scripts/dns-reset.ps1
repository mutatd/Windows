# DNS Flush & Reset
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        DNS Flush & Reset" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "WARNING: Administrator privileges recommended for full functionality" -ForegroundColor Yellow
    Write-Host ""
}

do {
    Write-Host "  [1] Flush DNS Cache"
    Write-Host "  [2] Reset DNS to DHCP"
    Write-Host "  [3] Set Google DNS (8.8.8.8 / 8.8.4.4)"
    Write-Host "  [4] Set Cloudflare DNS (1.1.1.1 / 1.0.0.1)"
    Write-Host "  [5] View Current DNS Settings"
    Write-Host "  [6] Display DNS Cache"
    Write-Host "  [7] Complete Network Reset"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nFlushing DNS Cache..." -ForegroundColor Yellow
            try {
                ipconfig /flushdns
                Write-Host "DNS cache flushed successfully!" -ForegroundColor Green
                
                # Also clear DNS client cache
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                Write-Host "DNS client cache cleared." -ForegroundColor Green
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nResetting DNS to DHCP..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
                    foreach ($adapter in $adapters) {
                        Write-Host "Resetting $($adapter.Name)..." -ForegroundColor White
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
                    }
                    Write-Host "DNS reset to automatic (DHCP)!" -ForegroundColor Green
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '3' {
            Write-Host "`nSetting Google DNS servers..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
                    foreach ($adapter in $adapters) {
                        Write-Host "Setting DNS for $($adapter.Name)..." -ForegroundColor White
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("8.8.8.8", "8.8.4.4")
                    }
                    Write-Host "Google DNS set successfully!" -ForegroundColor Green
                    Write-Host "Primary: 8.8.8.8" -ForegroundColor Gray
                    Write-Host "Secondary: 8.8.4.4" -ForegroundColor Gray
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '4' {
            Write-Host "`nSetting Cloudflare DNS servers..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
                    foreach ($adapter in $adapters) {
                        Write-Host "Setting DNS for $($adapter.Name)..." -ForegroundColor White
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1", "1.0.0.1")
                    }
                    Write-Host "Cloudflare DNS set successfully!" -ForegroundColor Green
                    Write-Host "Primary: 1.1.1.1" -ForegroundColor Gray
                    Write-Host "Secondary: 1.0.0.1" -ForegroundColor Gray
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '5' {
            Write-Host "`nCurrent DNS Settings:" -ForegroundColor Yellow
            Write-Host "=====================" -ForegroundColor Cyan
            $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
            foreach ($adapter in $adapters) {
                Write-Host "`nAdapter: $($adapter.Name)" -ForegroundColor White
                $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4
                Write-Host "DNS Servers:" -ForegroundColor Gray
                foreach ($server in $dns.ServerAddresses) {
                    Write-Host "  - $server" -ForegroundColor Gray
                }
            }
            Pause
        }
        '6' {
            Write-Host "`nDNS Cache Contents:" -ForegroundColor Yellow
            Write-Host "===================" -ForegroundColor Cyan
            try {
                $cache = Get-DnsClientCache
                $total = $cache.Count
                Write-Host "Total cached entries: $total" -ForegroundColor Yellow
                Write-Host "`nShowing first 20 entries:" -ForegroundColor Gray
                $cache | Select-Object -First 20 | Format-Table Entry, RecordName, RecordType, TimeToLive -AutoSize
                
                if ($total -gt 20) {
                    Write-Host "`n... and $($total - 20) more entries" -ForegroundColor Gray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '7' {
            Write-Host "`nComplete Network Reset" -ForegroundColor Yellow
            Write-Host "======================" -ForegroundColor Cyan
            $confirm = Read-Host "This will reset all network settings. Continue? (Y/N)"
            if ($confirm.ToUpper() -eq 'Y') {
                if (-not $isAdmin) {
                    Write-Host "This requires Administrator privileges!" -ForegroundColor Red
                } else {
                    Write-Host "Releasing IP address..." -ForegroundColor Yellow
                    ipconfig /release | Out-Null
                    
                    Write-Host "Renewing IP address..." -ForegroundColor Yellow
                    ipconfig /renew | Out-Null
                    
                    Write-Host "Flushing DNS..." -ForegroundColor Yellow
                    ipconfig /flushdns | Out-Null
                    
                    Write-Host "Resetting Winsock..." -ForegroundColor Yellow
                    netsh winsock reset | Out-Null
                    
                    Write-Host "Resetting TCP/IP..." -ForegroundColor Yellow
                    netsh int ip reset | Out-Null
                    
                    Write-Host "`nNetwork reset complete!" -ForegroundColor Green
                    Write-Host "A system restart is recommended." -ForegroundColor Yellow
                    
                    $restart = Read-Host "`nRestart now? (Y/N)"
                    if ($restart.ToUpper() -eq 'Y') {
                        Restart-Computer -Force
                    }
                }
            } else {
                Write-Host "Reset cancelled." -ForegroundColor Gray
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
