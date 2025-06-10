#!/bin/bash

read -p "🔗 Enter the URL to monitor (e.g., https://example.com): " URL

# Validate URL
if [[ ! $URL =~ ^https?:// ]]; then
  echo "❌ URL must start with http:// or https://"
  exit 1
fi

echo "▶️ Monitoring started. Press Ctrl+C to quit."

# Infinite loop
while true; do
  # Get HTTP status code and capture curl errors
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL")
  CURL_EXIT=$?

  TIMESTAMP=$(date +%H:%M:%S)

  if [ $CURL_EXIT -ne 0 ]; then
    echo "[$TIMESTAMP] 🔴 ERROR: Unable to reach $URL (curl exit code: $CURL_EXIT)"
  elif [ "$RESPONSE" == "200" ]; then
    echo "[$TIMESTAMP] ✅ Site is UP (HTTP 200)"
  else
    echo "[$TIMESTAMP] ❌ Site returned HTTP status: $RESPONSE"
  fi

  sleep 1
done
