#Requires -Version 6.0

# $PSVersionTable.PSVersion.Major -lt 6

$charDot = '*'
$charEllipsis = '~'
$charHorizontalLine = '-'
$charVerticalLine = '|'
$charTopLeftCorner = '+'
$charTopRightCorner = '+'
$charBottomLeftCorner = '+'
$charBottomRightCorner = '+'
$charLeftTee = '+'
$charRightTee = '+'
$charTopTee = '+'
$charBottomTee = '+'
$charCross = '+'
$charDoubleVerticalLine = ':'
$charDoubleDownAndLeft = '+'
$charDoubleUpAndLeft = '+'
$charDoubleDownAndRight = '+'
$charDoubleUpAndRight = '+'
$charDoubleVerticalAndRight = ':'
$charDoubleVerticalAndLeft = ':'

function Edit-UICharsForCompat {
    param (
        [string]$InputString
    )

    $replacementTable = @{
        '•' = $charDot
        '…' = $charEllipsis
        '─' = $charHorizontalLine
        '│' = $charVerticalLine
        '┌' = $charTopLeftCorner
        '┐' = $charTopRightCorner
        '└' = $charBottomLeftCorner
        '┘' = $charBottomRightCorner
        '├' = $charLeftTee
        '┤' = $charRightTee
        '┬' = $charTopTee
        '┴' = $charBottomTee
        '┼' = $charCross
        '║' = $charDoubleVerticalLine
        '╢' = $charDoubleVerticalAndRight
        '╟' = $charDoubleVerticalAndLeft
        '╖' = $charDoubleDownAndLeft
        '╜' = $charDoubleUpAndLeft
        '╓' = $charDoubleDownAndRight
        '╙' = $charDoubleUpAndRight
    }

    $outputString = $InputString

    foreach ($key in $replacementTable.Keys) {
        $outputString = $outputString.Replace($key, $replacementTable[$key])
    }

    return $outputString
}

$scriptContent = Get-Content -Path ".\TableUI.psm1" -Raw
$modifiedScriptContent = Edit-UICharsForCompat -InputString $scriptContent

$pattern = "\[ArgumentCompletions\([^\)]*\)\]"

$modifiedScriptContent = [regex]::Replace($modifiedScriptContent, $pattern, "")
$modifiedScriptContent = '$IsWindows = $true' + "`r`n" + $modifiedScriptContent
Set-Content -Path ".\TableUICompat.psm1" -Value $modifiedScriptContent
