#!/bin/bash
# mini-key-server.sh — 轻量 SSH 私钥 Web 下载服务
# 端口: 6280, 目录: /aspnmy/wwwroot/ssh_key/
# 用法: bash mini-key-server.sh
set -e ; trap "" ERR

DOWNLOAD_DIR="${DOWNLOAD_DIR:-/aspnmy/wwwroot/ssh_key}"
TRACK_DIR="${TRACK_DIR:-/aspnmy/wwwroot/.downloads}"
PORT="${PORT:-6280}"
MAX_DOWNLOADS=2

mkdir -p "$DOWNLOAD_DIR" "$TRACK_DIR"

response_401() { printf "HTTP/1.1 401 Unauthorized\r\nContent-Type: text/plain\r\n\r\nInvalid email\n"; }
response_404() { printf "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nKey not found\n"; }
response_429() { printf "HTTP/1.1 429 Too Many Requests\r\nContent-Type: text/plain\r\n\r\nDownload limit reached\n"; }
response_200() {
    local file="$1"
    local size=$(stat -c%s "$file")
    printf "HTTP/1.1 200 OK\r\nContent-Type: application/x-pem-file\r\nContent-Disposition: attachment; filename=\"%s\"\r\nContent-Length: %d\r\n\r\n" "$(basename "$file")" "$size"
    cat "$file"
}

list_keys() {
    local html="<html><head><meta charset='utf-8'><title>SSH Key Download</title></head><body>"
    html+="<h2>SSH Private Key Download</h2>"
    html+="<p>Enter your email to download your private key.</p>"
    html+="<form method='get' action='/get'><input name='email' placeholder='user@example.com'><button type='submit'>Download</button></form>"
    html+="<p style='color:gray;font-size:12px'>Keys are deleted after $MAX_DOWNLOADS downloads.</p>"
    html+="</body></html>"
    local len=${#html}
    printf "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\n\r\n%s" "$len" "$html"
}

handle_request() {
    local method path query email keyfile downloads
    read -r method path _ </dev/stdin
    # Parse headers
    while IFS= read -r line; do
        [ -z "${line//$'\r'/}" ] && break
    done

    # Extract query string
    query="${path#*\?}"
    path="${path%%\?*}"

    if [ "$path" = "/" ] || [ "$path" = "/index.html" ]; then
        list_keys
        return
    fi

    if [ "$path" = "/get" ]; then
        email=$(echo "$query" | sed -n 's/.*email=\([^&]*\).*/\1/p' | python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || echo "$query" | sed 's/email=//;s/&.*//')
        
        [ -z "$email" ] && { response_401; return; }

        # Find key file matching email
        keyfile=$(ls "$DOWNLOAD_DIR"/*_"$email" 2>/dev/null | head -1)
        [ -z "$keyfile" ] && { response_404; return; }

        # Track downloads
        local track_file="$TRACK_DIR/$(basename "$email")"
        downloads=$(cat "$track_file" 2>/dev/null || echo 0)
        
        if [ "$downloads" -ge "$MAX_DOWNLOADS" ]; then
            rm -f "$keyfile" "$track_file"
            response_429
            return
        fi

        echo $((downloads + 1)) > "$track_file"
        response_200 "$keyfile"

        # Delete after max downloads
        if [ $((downloads + 1)) -ge "$MAX_DOWNLOADS" ]; then
            rm -f "$keyfile" "$track_file" 2>/dev/null
        fi
        return
    fi

    response_404
}

# Main loop
echo "Key server starting on port $PORT..."
mkdir -p "$DOWNLOAD_DIR" "$TRACK_DIR"
while true; do
    handle_request | nc -l -p "$PORT" -q 1 2>/dev/null || true
done
