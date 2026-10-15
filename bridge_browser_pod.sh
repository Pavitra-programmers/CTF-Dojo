#!/usr/bin/env bash
PORT="${1:-8080}"
echo "[*] Setting up bridge for port ${PORT} into openrind-browser-pod containers..."
wsl -d openrind-desktop-openshell -- sh -c "
GW=\$(ip route show default | cut -d' ' -f3)
containers=\$(docker ps --filter 'name=openrind-browser-pod' --format '{{.Names}}')
for c in \$containers; do
  echo \"  -> Forwarding inside: \$c\"
  docker exec -d \"\$c\" node -e \"const net=require('net'); const s=net.createServer(src=>{ const dst=net.connect(${PORT}, '\$GW'); src.pipe(dst).pipe(src); src.on('error',()=>dst.destroy()); dst.on('error',()=>src.destroy()); }); s.listen(${PORT}, '127.0.0.1').on('error',()=>{});\"
done
"
echo "[+] Port ${PORT} forwarded! Claude can now access http://localhost:${PORT} in agent-browser."
