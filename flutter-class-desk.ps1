param(
  [ValidateSet('chrome', 'apk')]
  [string] $Target = 'chrome',
  [string] $Flutter = 'flutter'
)

# Read only the public API address. Do not pass secrets to the Flutter compiler.
$backendEnv = Join-Path $PSScriptRoot 'backend/.env'
$entry = Get-Content -LiteralPath $backendEnv -ErrorAction SilentlyContinue |
    Where-Object { $_ -match '^\s*CLASS_DESK_SYNC_URL\s*=' } |
    Select-Object -Last 1
$syncUrl = if ($entry) { ($entry -split '=', 2)[1].Trim().Trim('"', "'") } else { '' }
if ($syncUrl) {
  $address = $null
  if (-not [Uri]::TryCreate($syncUrl, [UriKind]::Absolute, [ref] $address) -or
      $address.UserInfo -or $address.Query -or $address.Fragment -or
      ($address.Scheme -ne 'https' -and
       ($address.Scheme -ne 'http' -or -not $address.IsLoopback))) {
    throw 'CLASS_DESK_SYNC_URL must be a public HTTPS API URL or an HTTP loopback URL.'
  }
  if ($Target -eq 'apk' -and $address.Scheme -ne 'https') { $syncUrl = '' }
}

Push-Location -LiteralPath $PSScriptRoot
try {
  if ($Target -eq 'chrome') {
    & $Flutter run -d chrome --web-port 8080 "--dart-define=CLASS_DESK_SYNC_URL=$syncUrl"
  } else {
    & $Flutter build apk --release "--dart-define=CLASS_DESK_SYNC_URL=$syncUrl"
  }
  $result = $LASTEXITCODE
} finally {
  Pop-Location
}
exit $result