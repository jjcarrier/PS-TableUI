[System.ConsoleColor]$DefaultBackgroundColor = $Host.UI.RawUI.BackgroundColor

# Example of a custom script block
$DummyScriptBlock = {
    param($currentSelections, $selectedIndex)

    Clear-Host
    Write-Output  "The currently selected index is: $selectedIndex"
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
    a user to select zero or more items from this selection. By default, the
    provided reference is updated with an array of Booleans indicating which
    items in the array were selected. This format can be change to indicate
    the selected index or item values via the -SelectionFormat option.
#>
function Show-TableUI
{
    [CmdletBinding()]
    param (
        # The array of objects that will be presented in the table UI.
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Table,

        # An array of Booleans indicating which items were selected.
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
        [string]$EnterKeyDescription = 'Press ENTER to show selection details.                      ',

        # The script to execute whenn the ENNTER key is pressed. After completion, the screen will be redrawn by the TableUI.
        [Parameter()]
        [scriptblock]$EnterKeyScript = $DummyScriptBlock,

        # Specifies the format that the -Selections should be in. The default is an array of Booleans.
        [Parameter()]
        [ArgumentCompletions('Booleans', 'Indices', 'Items')]
        [string]$SelectionFormat = 'Booleans'
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
            [System.ConsoleColor]$ForegroundColor,

            # Indicates that no new line should be added at the end of the message.
            [switch]$NoNewLine
        )
        # Save the current color
        $fc = $host.UI.RawUI.ForegroundColor

        # Set the new color
        $host.UI.RawUI.ForegroundColor = $ForegroundColor

        if ($args) {
            Write-Host -NoNewLine:$NoNewLine $args
        } else {
            $input | Write-Host -NoNewLine:$NoNewLine
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
        Write-Output '────────────────────────────────────────────────────────────'
        Write-Output "$Title"
        Write-Output '────────────────────────────────────────────────────────────'

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

        Write-Output '────────────────────────────────────────────────────────────'
        Write-Output "Current Selection ($($selectionIndex+1) of $($SelectionItems.Count))"
        Write-Output '────────────────────────────────────────────────────────────'
        if ($null -eq $MembersToShow) {
            $MembersToShow = $SelectionItems[$SelectionIndex] | Get-Member -MemberType NoteProperty | ForEach-Object { $_.$DefaultMemberToShow }
        }

        $maxMemberName = ($MembersToShow | Measure-Object -Property Length -Maximum).Maximum + 1
        $MembersToShow | ForEach-Object {
            if (-not([string]::IsNullOrWhiteSpace(($SelectionItems[$SelectionIndex].$_)))) {
                Write-ColorOutput Green -NoNewLine  "$_$(' ' * ($maxMemberName - $_.Length)): "
                Write-ColorOutput Gray ($SelectionItems[$SelectionIndex].$_ -join ', ')
            }
        }
    }

    <#
    .DESCRIPTION
        Show the UI control information.
    #>
    function Show-SelectionMenuControls
    {
        param (
            # Decription should be filled to 60-characters.
            [string]$EnterKeyDescription = 'Press ENTER to show selection details.                      ',

            # When set, only the help key is shown
            [switch]$Minimize
        )

        Write-Output '────────────────────────────────────────────────────────────'
        Set-BackgroundColor DarkGray

        if ($Minimize) {
            Write-ColorOutput White "Press '?' to show the controls control menu.                "
        } else {
            Write-ColorOutput White 'Press (PAGE) UP or (PAGE) DOWN to navigate selection.       '
            Write-ColorOutput White $EnterKeyDescription
            Write-ColorOutput White 'Press SPACE to toggle selection.                            '
            Write-ColorOutput White "Press 'A' to select all, 'N' to select none.                "
            Write-ColorOutput White "Press 'C' to finish selections and continue operation.      "
            Write-ColorOutput White "Press '?' to minimize this control menu.                    "
            Write-ColorOutput White "Press ESC or 'Q' to quit now and cancel operation.          "
        }

        Restore-BackgroundColor
    }

    $Selections.Value = $null

    if ([string]::IsNullOrWhiteSpace($DefaultMemberToShow)) {
        $DefaultMemberToShow = $Table | Select-Object -First | Get-Member -MemberType NoteProperty | Select-Object -First -Property Name
    }

    [char]$currentKey = [char]0
    [char]$selectAll ='a'
    [char]$selectNone ='n'
    [char]$continue = 'c'
    [char]$quitKey = 'q'
    [char]$helpKey = '?'
    [char]$helpKeyAlt = '/'

    $tempSelections = @($Table) | ForEach-Object { $false }
    [int]$selectionIndex = 0
    [int]$windowStartIndex = 0
    $helpMinimized = $false

    if ($null -eq $SelectedItemMembersToShow)
    {
        $SelectedItemMembersToShow = ($Table[0] | Get-Member -MemberType NoteProperty).Name
    }

    while ($currentKey -ne $continue)
    {
        [int]$numStandardMenuLines = 15 + $SelectedItemMembersToShow.Count # Count is based on 'Show-' calls below
        if ($helpMinimized) {
            $numStandardMenuLines -= 6
        }

        [int]$windowedSpan = $Host.UI.RawUI.WindowSize.Height - $numStandardMenuLines
        if ($windowedSpan -le 0) { $windowedSpan = 1 }

        $windowedSelectionItems = @($Table.$DefaultMemberToShow)[$windowStartIndex..($windowStartIndex+$windowedSpan-1)]
        $windowedSelectionIndex = $selectionIndex - $windowStartIndex
        $windowedSelections = @($tempSelections)[$windowStartIndex..($windowStartIndex+$windowedSpan-1)]
        $numItemsToUpgrade = 0
        $tempSelections | ForEach-Object { if ($_ -eq $true) { $numItemsToUpgrade++ } }
        $selectionMenuTitle = "$Title (Selected $($numItemsToUpgrade) of $($Table.Count))"

        [Console]::CursorVisible = $false
        Show-SelectionMenu -Title $selectionMenuTitle -SelectionItems $windowedSelectionItems -SelectionIndex $windowedSelectionIndex -Selections $windowedSelections
        Show-SelectionMenuControls -EnterKeyDescription $EnterKeyDescription -Minimize:$helpMinimized
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
                if ($tempSelections.Count -gt 1) {
                    $tempSelections[$selectionIndex] = -not $tempSelections[$selectionIndex]
                } else {
                    $tempSelections = -not $tempSelections
                }
            }

            # Toggle help
            { ($key.Character -eq $helpKey) -or ($key.Character -eq $helpKeyAlt) } { $helpMinimized = -not $helpMinimized }

            # Select all items
            $selectAll { $tempSelections = $tempSelections | ForEach-Object { $true } }

            # Deselect all items
            $selectNone { $tempSelections = $tempSelections | ForEach-Object { $false } }

            # Execute the ENTER script block for the selected item
            { $_ -eq [ConsoleKey]::Enter } {
                Invoke-Command -ScriptBlock $EnterKeyScript -ArgumentList @(@($tempSelections), $selectionIndex)
            }

            # Abort operation
            { ($_ -eq [ConsoleKey]::Escape) -or ($_ -eq $quitKey) } {
                Write-Output "`nAborted."
                $tempSelections = $null
                $currentKey = $continue
            }
        }

        if ($selectionIndex -lt $windowStartIndex) {
            $windowStartIndex = $selectionIndex
        } elseif ($selectionIndex - $windowStartIndex -ge $windowedSpan) {
            $windowStartIndex = $selectionIndex - $windowedSpan + 1
        }
    }

    if ($null -eq $tempSelections) {
        return
    }

    $transformSelectionScript = $null

    switch ($SelectionFormat)
    {
        { $_ -eq 'Booleans' } {
            $Selections.Value = $tempSelections
        }

        { $_ -eq 'Indices' } {
            $transformSelectionScript = {
                param($index, $item, $selected)
                if ($selected) {
                    $index
                }
            }
        }

        { $_ -eq 'Items' } {
            $transformSelectionScript = {
                param($index, $item, $selected)
                if ($selected) {
                    $item
                }
            }
        }
    }

    if ($null -ne $transformSelectionScript) {
        $index = 0
        $Selections.Value = $tempSelections | ForEach-Object {
            Invoke-Command -ScriptBlock $transformSelectionScript -ArgumentList $index, $tableData[$index], $_
            $index++
        }
    }
}
