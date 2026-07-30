export WEBUI_NAME="Arcade"
export CORS_ALLOW_ORIGIN="http://localhost:5173;http://localhost:8080;https://test-arcade.rbsdev.net;https://arcade.rbsprod.net"
PORT="${PORT:-8080}"
# Restore the ORIGINAL 0.9.2 default secret key so existing sessions and OAuth/SSO
# (which were encrypted with this key) keep working. 0.11.0 requires it be set explicitly.
export WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-t0p-s3cr3t}"
uvicorn open_webui.main:app --port $PORT --host 0.0.0.0 --forwarded-allow-ips "${FORWARDED_ALLOW_IPS:-*}" --reload
