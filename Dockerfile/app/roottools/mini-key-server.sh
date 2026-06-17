#!/bin/bash
# mini-key-server.sh — SSH私钥 Web 下载服务（轻量版）
# 端口: 8880（来自 ufw 已放行端口）
PORT=8880
DOWNLOAD_DIR=/aspnmy/wwwroot/ssh_key
TRACK_DIR=/aspnmy/wwwroot/.downloads
MAX=2
mkdir -p "$DOWNLOAD_DIR" "$TRACK_DIR"

handle() {
    local m p q e f n
    read -r m p _ </dev/stdin
    while IFS= read -r line; do [ -z "${line//$'\r'/}" ] && break; done
    q="${p#*\?}"; p="${p%%\?*}"
    case "$p" in
        /get)
            e=$(echo "$q" | sed 's/.*email=//;s/&.*//' | python3 -c "import sys,urllib.parse;print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || echo "$q" | sed 's/email=//;s/&.*//')
            [ -z "$e" ] && { printf "HTTP/1.1 400\r\n\r\n"; return; }
            f=$(ls "$DOWNLOAD_DIR"/*_"$e" 2>/dev/null|head -1)
            [ -z "$f" ] && { printf "HTTP/1.1 404\r\n\r\nKey not found\n"; return; }
            n=$(cat "$TRACK_DIR/$e" 2>/dev/null||echo 0)
            [ "$n" -ge "$MAX" ] && { rm -f "$f" "$TRACK_DIR/$e"; printf "HTTP/1.1 410\r\n\r\nDeleted\n"; return; }
            echo $((n+1))>"$TRACK_DIR/$e"
            s=$(stat -c%s "$f")
            printf "HTTP/1.1 200\r\nContent-Type: application/x-pem-file\r\nContent-Disposition: attachment; filename=\"%s\"\r\nContent-Length: %d\r\n\r\n" "$(basename "$f")" "$s"
            cat "$f"
            [ $((n+1)) -ge "$MAX" ] && rm -f "$f" "$TRACK_DIR/$e"
            ;;
        *)  printf "HTTP/1.1 200\r\nContent-Type: text/html\r\n\r\n<html><h2>SSH Key Download</h2><form action=/get><input name=email placeholder=user@e.com><button>Download</button></form><p>Max $MAX downloads per key.</p></html>\n"
            ;;
    esac
}

echo "Key server on :$PORT"
while true; do handle | nc -l -p $PORT -w 1 2>/dev/null; done
