# Network Diagnostics
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        Network Diagnostics" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

do {
    Write-Host "  [1] Network Adapter Information"
    Write-Host "  [2] IP Configuration"
    Write-Host "  [3] Test Internet Connectivity"
    Write-Host "  [4] Trace Route to Google"
    Write-Host "  [5] Open TCP Connections"
    Write-Host "  [6] Speed Test (Ping various servers)"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nNetwork Adapters:" -ForegroundColor Yellow
            Write-Host "=================" -ForegroundColor Cyan
            try {
                $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
                foreach ($adapter in $adapters) {
                    Write-Host "Name: $($adapter.Name)" -ForegroundColor White
                    Write-Host "Status: $($adapter.Status)" -ForegroundColor Green
                    Write-Host "Speed: $($adapter.LinkSpeed)" -ForegroundColor Gray
                    Write-Host "MAC: $($adapter.MacAddress)" -ForegroundColor Gray
                    Write-Host "Driver: $($adapter.DriverVersion)" -ForegroundColor Gray
                    Write-Host "---" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nIP Configuration:" -ForegroundColor Yellow
            Write-Host "================" -ForegroundColor Cyan
            try {
                $configs = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null }
                foreach ($config in $configs) {
                    Write-Host "Interface: $($config.InterfaceAlias)" -ForegroundColor White
                    Write-Host "IPv4: $($config.IPv4Address.IPAddress)" -ForegroundColor Green
                    Write-Host "Gateway: $($config.IPv4DefaultGateway.NextHop)" -ForegroundColor Gray
                    Write-Host "DNS Servers:" -ForegroundColor Gray
                    foreach ($dns in $config.DNSServer) {
                        Write-Host "  - $($dns.ServerAddresses)" -ForegroundColor Gray
                    }
                    Write-Host "---" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '3' {
            Write-Host "`nTesting Internet Connectivity..." -ForegroundColor Yellow
            $tests = @(
                @{Name="Google DNS"; Address="8.8.8.8"},
                @{Name="Cloudflare DNS"; Address="1.1.1.1"},
                @{Name="Google"; Address="google.com"},
                @{Name="Microsoft"; Address="microsoft.com"}
            )
            
            foreach ($test in $tests) {
                Write-Host "Testing $($test.Name)..." -ForegroundColor White -NoNewline
                try {
                    $result = Test-Connection -ComputerName $test.Address -Count 2 -Quiet -ErrorAction Stop
                    if ($result) {
                        Write-Host " SUCCESS" -ForegroundColor Green
                    } else {
                        Write-Host " FAILED" -ForegroundColor Red
                    }
                } catch {
                    Write-Host " FAILED" -ForegroundColor Red
                }
            }
            Pause
        }
        '4' {
            Write-Host "`nTracing route to google.com..." -ForegroundColor Yellow
            Write-Host "=================================" -ForegroundColor Cyan
            try {
                $trace = Test-NetConnection -ComputerName google.com -TraceRoute -ErrorAction Stop
                Write-Host "Ping: $($trace.PingSucceeded)" -ForegroundColor $(if($trace.PingSucceeded){'Green'}else{'Red'})
                if ($trace.Latency) {
                    Write-Host "Latency: $($trace.Latency)ms" -ForegroundColor White
                }
                Write-Host "`nHops:" -ForegroundColor Yellow
                $hopCount = 0
                if ($trace.TraceRoute) {
                    foreach ($hop in $trace.TraceRoute) {
                        $hopCount++
                        Write-Host "$hopCount`: $hop" -ForegroundColor White
                    }
                } else {
                    Write-Host "No trace route data available" -ForegroundColor Gray
                }
            } catch {
                Write-Host "Error: Unable to trace route - $_" -ForegroundColor Red
            }
            Pause
        }
        '5' {
            Write-Host "`nActive TCP Connections:" -ForegroundColor Yellow
            Write-Host "=======================" -ForegroundColor Cyan
            try {
                $connections = Get-NetTCPConnection | Where-Object State -eq 'Established' | 
                    Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, 
                    @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name}}
                
                if ($connections) {
                    foreach ($conn in $connections) {
                        Write-Host "Local: $($conn.LocalAddress):$($conn.LocalPort)" -ForegroundColor White
                        Write-Host "Remote: $($conn.RemoteAddress):$($conn.RemotePort)" -ForegroundColor Gray
                        Write-Host "Process: $($conn.Process)" -ForegroundColor Gray
                        Write-Host "---" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "No active established connections found" -ForegroundColor Gray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nSpeed Test (Ping Response Times):" -ForegroundColor Yellow
            Write-Host "=================================" -ForegroundColor Cyan
            
            # Get gateway safely
            try {
                $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop | Select-Object -First 1).NextHop
            } catch {
                $gateway = $null
            }
            
            $targets = @(
                @{Name="Local Gateway"; Address=$gateway},
                @{Name="Google DNS"; Address="8.8.8.8"},
                @{Name="Cloudflare"; Address="1.1.1.1"},
                @{Name="AWS"; Address="amazon.com"},
                @{Name="Azure"; Address="azure.microsoft.com"}
            )
            
            foreach ($target in $targets) {
                if ($target.Address) {
                    Write-Host "Testing $($target.Name)..." -ForegroundColor White
                    try {
                        $pingResult = Test-Connection -ComputerName $target.Address -Count 4 -ErrorAction Stop
                        $stats = $pingResult | Measure-Object -Property ResponseTime -Average -Minimum -Maximum
                        
                        Write-Host "  Min: $($stats.Minimum)ms" -ForegroundColor Gray
                        Write-Host "  Max: $($stats.Maximum)ms" -ForegroundColor Gray
                        Write-Host "  Avg: $([math]::Round($stats.Average, 2))ms" -ForegroundColor $(if($stats.Average -lt 50){'Green'}elseif($stats.Average -lt 100){'Yellow'}else{'Red'})
                        Write-Host ""
                    } catch {
                        Write-Host "  FAILED - Could not reach server" -ForegroundColor Red
                        Write-Host ""
                    }
                }
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
