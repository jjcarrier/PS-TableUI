[System.ConsoleColor]$DefaultBackgroundColor = $Host.UI.RawUI.BackgroundColor

# Example of a custom script block
$DummyScriptBlock = {
    param($currentSelections, $selectedIndex)

    Clear-Host
    Write-Output  "The currenntly selected index is: $selectedIndex"
    Write-Output "`n[Press ENTER to return.]"
    [Console]::CursorVisible = $false
    $cursorPos = $host.UI.RawUI.CursorPosition
    while ($host.ui.RawUI.ReadKey().VirtualKeyCode -ne [ConsoleKey]::Enter) {
        $host.UI.RawUI.CursorPosition = $cursorPos
        [Console]::CursorVisible = $false
    }
}

<#
.DESCRIPTION
    Shows a user-interface based on an array of objects. This interface allows
    a user to select zero or more items from this selection. The provided
    reference is updated with an array of booleans indicating which items in
    the array were selected.
#>
function Show-TableUI
{
    [CmdletBinding()]
    param (
        # The array of objects that will be presented in the table UI.
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Table,

        # An array of booleans indicating which items were selected.
        # IMPORTANT: This array will be set to $null if the user aborts the selection.
        [Parameter(Mandatory)]
        [ref]$Selections,

        # The title of the table, indicating what action will be performed after making the selections.
        [Parameter()]
        [string]$Title = 'Make Selections',

        # This is the member that will be displayed in the selection list. If not specified, the first NoteProperty member will be used.
        [Parameter()]
        [string]$DefaultMemberToShow,

        # These are the members to show when an item is currenlty selected. Order determines arrangement in UI.
        # If not specified, all (NoteProperty) members will be displayed.
        [Parameter()]
        [string[]]$SelectedItemMembersToShow = $null,

        # The decription of what the ENTER key does. Should be filled to 60-characters.
        [Parameter()]
        [string]$EnterKeyDescription = "Press ENTER to show selection details.                      ",

        # The script to execute whenn the ENNTER key is pressed. After completion, the screen will be redrawn by the TableUI.
        [Parameter()]
        [scriptblock]$EnterKeyScript = $DummyScriptBlock
    )

    <#
    .DESCRIPTION
        Restore the UI's background color to the state it was in when the script
        was called.
    #>
    function Restore-BackgroundColor
    {
        $Host.UI.RawUI.BackgroundColor = $script:DefaultBackgroundColor
    }

    <#
    .DESCRIPTION
        Set the UI background color.
    #>
    function Set-BackgroundColor
    {
        param (
            # The background color to apply.
            [System.ConsoleColor]$BackgroundColor
        )

        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    }

    <#
    .DESCRIPTION
        Write to standard output with the specified foreground color.
    #>
    function Write-ColorOutput
    {
        param (
            # The foreground color to apply.
            [System.ConsoleColor]$ForegroundColor
        )
        # Save the current color
        $fc = $host.UI.RawUI.ForegroundColor

        # Set the new color
        $host.UI.RawUI.ForegroundColor = $ForegroundColor

        if ($args) {
            Write-Output $args
        } else {
            $input | Write-Output
        }

        # Restore the original color
        $host.UI.RawUI.ForegroundColor = $fc
    }

    <#
    .DESCRIPTION
        Write to standard output with DarkGray background color.
    #>
    function Write-Highlighted
    {
        param (
            # The message to display.
            [string]$Message
        )

        Set-BackgroundColor Blue
        Write-ColorOutput White $Message
        Restore-BackgroundColor
    }

    <#
    .DESCRIPTION
        Show the selectable items.
    #>
    function Show-SelectionMenu
    {
        param (
            [string]$Title,
            [string[]]$SelectionItems,
            [int]$SelectionIndex,
            [bool[]]$Selections
        )

        Clear-Host
        Write-Output "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
        Write-Output "$Title"
        Write-Output "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"

        for ($i = 0; $i -lt $SelectionItems.Count; $i++)
        {
            $selectedChar = " "
            if ($Selections[$i]) { $selectedChar = "*" }

            $lineContent = "[$selectedChar]: $($SelectionItems[$i])"

            if ($i -eq $SelectionIndex) {
                Write-Highlighted $lineContent
            } else {
                Write-Output $lineContent
            }
        }
    }

    <#
    .DESCRIPTION
        Show the currently selected item.
    #>
    function Show-SelectedItem
    {
        param (
            [PSCustomObject[]]$SelectionItems,
            [int]$SelectionIndex,
            [string[]]$MembersToShow
        )

        Write-Output "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
        Write-Output "Current Selection ($($selectionIndex+1) of $($SelectionItems.Count))"
        Write-Output "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
        if ($null -eq $MembersToShow) {
            $MembersToShow = $SelectionItems[$SelectionIndex] | Get-Member -MemberType NoteProperty | ForEach-Object { $_.$DefaultMemberToShow }
        }

        $SelectionItems[$SelectionIndex] | Format-List -Property $MembersToShow
    }

    <#
    .DESCRIPTION
        Show the UI control information.
    #>
    function Show-SelectionMenuControls
    {
        param (
            # Decription should be filled to 60-characters.
            [string]$EnterKeyDescription = "Press ENTER to show selection details.                      "
        )
        Write-Output "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
        Set-BackgroundColor DarkGray
        Write-ColorOutput White "Press (PAGE) UP or (PAGE) DOWN to navigate selection.       "
        Write-ColorOutput White "Press SPACE to toggle selection.                            "
        Write-ColorOutput White "Press 'A' to select all.                                    "
        Write-ColorOutput White "Press 'N' to select none.                                   "
        Write-ColorOutput White $EnterKeyDescription
        Write-ColorOutput White "Press 'C' to finish selections and continue operation.      "
        Write-ColorOutput White "Press ESC or 'Q' to quit now and cancel operation.          "
        Restore-BackgroundColor
    }

    if ([string]::IsNullOrWhiteSpace($DefaultMemberToShow)) {
        $DefaultMemberToShow = ($Table[0] | Get-Member -MemberType NoteProperty)[0].Name
    }

    [char]$currentKey = [char]0
    [char]$selectAll ='a'
    [char]$selectNone ='n'
    [char]$continue = 'c'
    [char]$quitKey = 'q'

    $Selections.Value = @($Table) | ForEach-Object { $false }
    [int]$selectionIndex = 0
    [int]$windowStartIndex = 0

    if ($null -eq $SelectedItemMembersToShow)
    {
        $SelectedItemMembersToShow = ($Table[0] | Get-Member -MemberType NoteProperty).Name
    }

    while ($currentKey -ne $continue)
    {
        [int]$numStandardMenuLines = 22 # Count is based on 'Show-' calls below
        [int]$windowedSpan = $Host.UI.RawUI.WindowSize.Height - $numStandardMenuLines
        if ($windowedSpan -le 0) { $windowedSpan = 1 }

        $windowedSelectionItems = @($Table.$DefaultMemberToShow)[$windowStartIndex..($windowStartIndex+$windowedSpan-1)]
        $windowedSelectionIndex = $selectionIndex - $windowStartIndex
        $windowedSelections = @($Selections.Value)[$windowStartIndex..($windowStartIndex+$windowedSpan-1)]
        $numItemsToUpgrade = 0
        $Selections.Value | ForEach-Object { if ($_ -eq $true) { $numItemsToUpgrade++ } }
        $selectionMenuTitle = "$Title (Selected $($numItemsToUpgrade) of $($Table.Count))"

        [Console]::CursorVisible = $false
        Show-SelectionMenu -Title $selectionMenuTitle -SelectionItems $windowedSelectionItems -SelectionIndex $windowedSelectionIndex -Selections $windowedSelections
        Show-SelectionMenuControls -EnterKeyDescription $EnterKeyDescription
        Show-SelectedItem -SelectionItems $Table -SelectionIndex $selectionIndex -MembersToShow $SelectedItemMembersToShow

        $key = $host.ui.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        if ($key.ControlKeyState.HasFlag([System.Management.Automation.Host.ControlKeyStates]::LeftCtrlPressed) -or
            $key.ControlKeyState.HasFlag([System.Management.Automation.Host.ControlKeyStates]::RightCtrlPressed))
        {
            continue
        }

        $currentKey = [char]$key.VirtualKeyCode
        switch ($currentKey)
        {
            # Navigate up
            { $_ -eq [ConsoleKey]::UpArrow } {
                if ($selectionIndex -gt 0) {
                    $selectionIndex--
                }
            }

            # Navigate down
            { $_ -eq [ConsoleKey]::DownArrow } {
                if ($selectionIndex -lt $Table.Count - 1) {
                    $selectionIndex++
                }
            }

            # Navigate up by one page
            { $_ -eq [ConsoleKey]::PageUp } {
                if ($selectionIndex - $windowedSpan -ge 0) {
                    $selectionIndex -= $windowedSpan
                } else {
                    $selectionIndex = 0
                }
            }

            # Navigate down by one page
            { $_ -eq [ConsoleKey]::PageDown } {
                if ($selectionIndex + $windowedSpan -le $Table.Count - 1) {
                    $selectionIndex += $windowedSpan
                } else {
                    $selectionIndex = $Table.Count - 1
                }
            }

            # Toggle selected item
            { $_ -eq [ConsoleKey]::Spacebar } {
                if ($Selections.Value.Count -gt 1) {
                    $Selections.Value[$selectionIndex] = -not $Selections.Value[$selectionIndex]
                } else {
                    $Selections.Value = -not $Selections.Value
                }
            }

            # Select all items
            $selectAll { $Selections.Value = $Selections.Value | ForEach-Object { $true } }

            # Deselect all items
            $selectNone { $Selections.Value = $Selections.Value | ForEach-Object { $false } }

            # Execute the ENTER script block for the selected item
            { $_ -eq [ConsoleKey]::Enter } {
                Invoke-Command -ScriptBlock $EnterKeyScript -ArgumentList @(@($Selections.Value), $selectionIndex)
            }

            # Abort operation
            { ($_ -eq [ConsoleKey]::Escape) -or ($_ -eq $quitKey) } {
                Write-Output "`nAborted."
                $currentKey = $continue
                $Selections.Value = $null
            }
        }

        if ($selectionIndex -lt $windowStartIndex) {
            $windowStartIndex = $selectionIndex
        } elseif ($selectionIndex - $windowStartIndex -ge $windowedSpan) {
            $windowStartIndex = $selectionIndex - $windowedSpan + 1
        }
    }
}
