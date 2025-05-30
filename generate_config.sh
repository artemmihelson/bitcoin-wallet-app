#!/bin/bash

# Prompt for API key
read -p "Enter Coincap API key: " API_KEY

# Create Config.plist
cat > Config.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CoincapApiKey</key>
    <string>${API_KEY}</string>
    <key>CoincapApiBaseUrl</key>
    <string>https://rest.coincap.io/v3/assets/bitcoin</string>
</dict>
</plist>
EOF

echo "✅ Config.plist generated successfully."