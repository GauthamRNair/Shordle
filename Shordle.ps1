
# So users can add a paramter when running the file
param(
    [switch]$Random,
    [switch]$Hard
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Enumerate the tile values so I can compare them(like Green > Gray)
enum Result { Gray = 0; Yellow = 1; Green = 2 }

$answersPath = Join-Path $PSScriptRoot "data\answers.txt"
$guessesPath = Join-Path $PSScriptRoot "data\guesses.txt"

$answers = Get-Content $answersPath | ForEach-Object { $_.Trim().ToLower() }
$guesses = Get-Content $guessesPath | ForEach-Object { $_.Trim().ToLower() }

$valid = [System.Collections.Generic.HashSet[string]]::new()
$valid.UnionWith([string[]]$answers)
$valid.UnionWith([string[]]$guesses)

# Start date to compare today with
$start = (Get-Date -Year 2026 -Month 1 -Day 1).Date

$days = ((Get-Date).Date - $start).Days

if ($Random) {
    $secret = $answers | Get-Random
} else {
    $index = $days % $answers.Count
    $secret = $answers[$index]
}


function Get-Score {
    param([string]$Guess, [string]$Answer)

    # Start off with all tiles as gray
    $result = @([Result]::Gray) * 5

    $counts = @{}
    foreach ($c in $Answer.ToCharArray()) {
        $k = [string]$c
        $counts[$k] += 1 # Maps each character with its count
    }

    for ($i = 0; $i -lt 5; $i++) {
        if ($Guess[$i] -eq $Answer[$i]) {
            $result[$i] = [Result]::Green
            $counts[[string]$Guess[$i]] -= 1 # Don't consider greens in the counts
        }
    }

    for ($i = 0; $i -lt 5; $i++) {
        if ($result[$i] -eq [Result]::Green) { continue }
        $k = [string]$Guess[$i]
        if ($counts[$k] -gt 0) {
            $result[$i] = [Result]::Yellow # Any unconsidered counted letter will be turned yellow(left ones turn yellow first)
            $counts[$k] -= 1
        }
    }

    return ,$result
}

