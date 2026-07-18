# Creates %APPDATA%\Claude\claude_desktop_config.json for the ms365 MCP server.
#
# Points the ms365 server at the globally-installed .cmd binary, which is the
# reliable Windows setup (the npx-based config sometimes fails to load on restart).
#
# Prerequisite: run  npm install -g @softeria/ms-365-mcp-server  first, so that
# %APPDATA%\npm\ms-365-mcp-server.cmd exists. This script does NOT global-install for you.
#
# The filesystem server is NOT added here. It is added through Claude Desktop's
# Connectors UI (Customize > Connectors > Filesystem).

$claudeDir  = "$env:APPDATA\Claude"
$configFile = "$claudeDir\claude_desktop_config.json"
$ms365Cmd   = "$env:APPDATA\npm\ms-365-mcp-server.cmd"
$cmdEscaped = $ms365Cmd.Replace('\', '\\')   # escape backslashes for JSON

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

if (-not (Test-Path $ms365Cmd)) {
    Write-Host "NOTE: $ms365Cmd not found yet." -ForegroundColor Yellow
    Write-Host "      Run this first, then re-run this script:" -ForegroundColor Yellow
    Write-Host "      npm install -g @softeria/ms-365-mcp-server"
    Write-Host ""
}

if (Test-Path $configFile) {
    Write-Host "WARNING: $configFile already exists. Not overwriting it." -ForegroundColor Yellow
    Write-Host "Open it manually and merge this ms365 entry inside the existing mcpServers object:"
    Write-Host ""
    Write-Host "    `"ms365`": {"
    Write-Host "      `"command`": `"$cmdEscaped`","
    Write-Host "      `"args`": [`"--org-mode`"]"
    Write-Host "    }"
    Write-Host ""
    Write-Host "(Remember trailing commas between entries.)"
} else {
    $json = @"
{
  "mcpServers": {
    "ms365": {
      "command": "$cmdEscaped",
      "args": ["--org-mode"]
    }
  }
}
"@
    Set-Content -Path $configFile -Value $json -Encoding UTF8
    Write-Host "Config written to $configFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. If not done yet:  npm install -g @softeria/ms-365-mcp-server"
Write-Host "  2. Log in:           ms-365-mcp-server --login"
Write-Host "                       (device-code prompt, sign in with the T3T work account)"
Write-Host "  3. In Claude Desktop, add the Filesystem connector (Customize > Connectors),"
Write-Host "     pointing at the consultant's screenshots folder only."
Write-Host "  4. Fully quit and reopen Claude Desktop (quit completely, not just close the window)."
