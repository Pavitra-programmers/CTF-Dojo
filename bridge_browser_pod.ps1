param(
    [int]$Port = 8080
)

Write-Host "[*] Setting up bridge for port $Port into openrind-browser-pod containers..."

$routeOutput = wsl -d openrind-desktop-openshell ip route show default 2>$null
if ($routeOutput -match 'default via (\d+\.\d+\.\d+\.\d+)') {
    $gw = $matches[1]
} else {
    $gw = "172.18.32.1"
}

Write-Host "[*] Host gateway IP detected as: $gw"

$containers = (wsl -d openrind-desktop-openshell docker ps --filter "name=openrind-browser-pod" --format "{{.Names}}") -split '\r?\n' | Where-Object { $_ -match '\S' }

if (-not $containers) {
    Write-Host "[!] No running browser-pod containers found."
    return
}

$nodeScript = "const net=require('net'); const s=net.createServer(c=>{ const t=net.connect($Port, '$gw'); c.pipe(t).pipe(c); c.on('error',()=>t.destroy()); t.on('error',()=>c.destroy()); }); s.listen($Port, '127.0.0.1').on('error',()=>{});"

foreach ($c in $containers) {
    Write-Host "  -> Forwarding inside: $c"
    wsl -d openrind-desktop-openshell docker exec -d $c node -e $nodeScript
}

Write-Host "[+] Port $Port successfully forwarded! Claude can now access http://localhost:$Port in agent-browser."
