
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

# Tests: imma uncomment late. for checking
# Get-Score "babes" "abbey"   # Yellow Yellow Green Green Gray
# Get-Score "eerie" "crane"   # Gray Gray Gray Gray Green


# ---------- Step 5: Draw function ----------

function Show-Board {
param($History)

Clear-Host
foreach ($row in $History) {
    for ($i = 0; $i -lt 5; $i++) {
        # Pick the tile color from the score.
        switch ($row.Result[$i]) {
            ([Result]::Green)  { $color = "DarkGreen" }
            ([Result]::Yellow) { $color = "DarkYellow" }
            default            { $color = "DarkGray" }
        }

        $letter = $row.Guess[$i].ToString().ToUpper()

        # One tile, then a one-space gap. -NoNewline keeps the row together.
        Write-Host " $letter " -BackgroundColor $color -ForegroundColor White -NoNewline
        Write-Host ""   # end of the row
    }
}


# ---------- Step 6: Game loop ----------

# Each entry is one guess: its text and its 5 results.
$history = [System.Collections.Generic.List[object]]::new()
$won = $false
while ($history.Count -lt 6) {
    Show-Board $history
        $guess = (Read-Host "Guess").Trim().ToLower()

        # Must be exactly 5 letters a-z.
        if ($guess -notmatch '^[a-z]{5}$') {
        Write-Host "5 letters only" -ForegroundColor Red        
        Start-Sleep 1
        continue    }

        # Must be a real word from the lists.
        if (-not $valid.Contains($guess)) {
        Write-Host "Not in word list" -ForegroundColor Red        
        Start-Sleep 1
        continue    }

        $res = Get-Score $guess $secret    
        $history.Add([PSCustomObject]@{ Guess = $guess; Result = $res })
            # All green means the guess is the answer, so just compare.
            if ($guess -eq $secret) {
                $won = $true
                break
            }
        }

        # Final board, then the result.
        Show-Board $history
        if ($won) {
            Write-Host "Got it in $($history.Count)" -ForegroundColor Green} else {
            Write-Host "The word was $($secret.ToUpper())" -ForegroundColor Red}

            Write-Host "The word was $($secret.ToUpper())" -ForegroundColor Red}