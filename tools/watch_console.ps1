[CmdletBinding()]
param(
    [string]$LogFile = (Join-Path $env:USERPROFILE "Zomboid\console.txt"),
    [switch]$All,
    [ValidateRange(0, 10000)]
    [int]$Tail = 0,
    [string]$Filter = "pzlinux|lua|error|exception|stack trace|stacktrace|callstack|traceback|rejected|rollback|refund"
)

if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    Write-Error "Project Zomboid console log not found: $LogFile"
    Write-Host "Use -LogFile to provide another path."
    exit 1
}

Write-Host "Following Project Zomboid log: $LogFile"
Write-Host "Press Ctrl+C to stop."

Get-Content -LiteralPath $LogFile -Wait -Tail $Tail | ForEach-Object {
    if ($All -or $_ -match $Filter) {
        $_
    }
}
