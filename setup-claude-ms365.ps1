# setup the folder for config.json in powershell
$claudeDir = "$env:APPDATA\Claude"
$configFile = "$claudeDir\claude_desktop_config.json"
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

if (Test-Path $configFile) {
    Write-Host "WARNING: $configFile already exists. Not overwriting it." -ForegroundColor Yellow
    Write-Host "Open it manually and merge in the ms365 entry if needed."
} else {
    $json = @"
{
  "mcpServers": {
    "ms365": {
      "command": "npx",
      "args": ["-y", "@softeria/ms-365-mcp-server", "--org-mode"]
    }
  }
}
"@
    Set-Content -Path $configFile -Value $json -Encoding UTF8
    Write-Host "Config written to $configFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next: add the Filesystem connector via Claude Desktop's Connectors UI if you want local file access." -ForegroundColor Cyan
Write-Host "Then fully quit and restart Claude Desktop, and try an ms365 tool to trigger sign-in." -ForegroundColor Cyan
