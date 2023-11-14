# The overall width of the UI.
[int]$UIWidth = 80
[int]$UIWidthMin = 54

# Frame buffer to mitigate re-draw flicker.
[string[]]$FrameBuffer = @('')

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
    Clears the frame buffer.
#>
function Clear-Frame
{
    $script:FrameBuffer = @('')
}

<#
.DESCRIPTION
    Writes the frame buffer to output.
#>
function Show-Frame
{
    Clear-Host
    $script:FrameBuffer | ForEach-Object {
        Write-Output $_
    }
}

<#
.DESCRIPTION
    Writes a top-bar to the frame buffer.
#>
function Write-FrameTopBar
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth
    )

    $script:FrameBuffer += "┌$('─' * ($Width - 2))┐"
}

<#
.DESCRIPTION
    Writes a middle-bar to the frame buffer.
#>
function Write-FrameMiddleBar
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth
    )

    $script:FrameBuffer += "├$('─' * ($Width - 2))┤"
}

<#
.DESCRIPTION
    Writes a bottom-bar to the frame buffer.
#>
function Write-FrameBottomBar
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth
    )

    $script:FrameBuffer += "└$('─' * ($Width - 2))┘"
}

<#
.DESCRIPTION
    Writes content to the frame buffer.
#>
function Write-FrameContent
{
    param (
        # The width of the overall UI. The content will take up $Width - 4.
        [int]$Width = $UIWidth,

        # The data to write to the current line.
        [string]$Content,

        # ANSI string that is responsible for setting the text styling for
        # the content. The frame/bars are not affected by this setting.
        [string]$AnsiiFormat = ''
    )

    # Account for 4-characters consisting of leading and trailing pipe + space characters
    if ($Content.Length -gt ($Width - 4)) {
        # Truncate to fit width (account for additional ellipsis)
        $Content = "$($Content.Substring(0, $Width - 4 - 1))…"
    } else {
        # Pad the tail to fit $Width
        $Content = $Content + (' ' * (($Width - 4) - $Content.Length))
    }

    if ([string]::IsNullOrWhiteSpace($AnsiiFormat)) {
        $script:FrameBuffer += "│ $Content │"
    } else {
        $script:FrameBuffer += "│$AnsiiFormat $Content $($PSStyle.Reset)│"
    }
}

<#
.DESCRIPTION
    Write the frame data for the UI title bar.
#>
function Write-FrameTitle
{
    param (
        # The message to show. WIll be automatically truncated if it does
        # not fit within the contrains set by $UIWidth.
        [string]$Content,

        # ANSI string that is responsible for setting the text styling for
        # the content. The frame/bars are not affected by this setting.
        [string]$AnsiiFormat = ''
    )

    Write-FrameTopBar
    if ([string]::IsNullOrWhiteSpace($AnsiiFormat)) {
        Write-FrameContent -Content $Content
    } else {
        Write-FrameContent -Content "$AnsiFormat$Content$($PSStyle.Reset)"
    }
    Write-FrameMiddleBar
}

<#
.DESCRIPTION
    Write the frame data for the title of the selected item section.
#>
function Write-FrameSelectedItemTitle
{
    param (
        # The message to show. WIll be automatically truncated if it does
        # not fit within the contrains set by $Width.
        [string]$Content,

        # ANSI string that is responsible for setting the text styling for
        # the content. The frame/bars are not affected by this setting.
        [string]$AnsiiFormat = ''
    )

    Write-FrameMiddleBar
    Write-FrameContent -Content $Content -AnsiiFormat $AnsiiFormat
    Write-FrameMiddleBar
}

<#
.DESCRIPTION
    Write the frame data for the selectable items.
#>
function Write-FrameSelectionItems
{
    param (
        # The title to display.
        [string]$Title,

        # An array of strings to be displayed in the selection region of the UI.
        [string[]]$SelectionItems,

        # The index of the currently highlighted item in the list of selectable items.
        [int]$SelectionIndex,

        # The state of the selections made by the user.
        [bool[]]$Selections,

        # The vertical span (text rows) of the windowed view of the UI.
        [int]$WindowedSpan
    )

    Write-FrameTitle -Content $Title

    for ($i = 0; $i -lt $SelectionItems.Count; $i++)
    {
        $selectedChar = " "
        if ($Selections[$i]) { $selectedChar = '•' }

        if ($i -eq $SelectionIndex) {
            $lineContent = "[$selectedChar] $($SelectionItems[$i])"
            Write-FrameContent -Content $lineContent -AnsiiFormat "$($PSStyle.Background.BrightBlue)$($PSStyle.Foreground.BrightWhite)"
        } else {
            $lineContent = " $selectedChar  $($SelectionItems[$i])"
            Write-FrameContent -Content $lineContent
        }
    }

    if ($UIFit -eq 'Fill')
    {
        $padRows = $WindowedSpan - $SelectionItems.Count
        while ($padRows -gt 0)
        {
            Write-FrameContent -Content ''
            $padRows--
        }
    }
}

<#
.DESCRIPTION
    Write the frame data for the currently selected item.
#>
function Write-FrameSelectedItem
{
    param (
        # An array of objects containing the selectable items.
        [PSCustomObject[]]$SelectionItems,

        # The index of the currently highlighted item in the list of selectable items.
        [int]$SelectionIndex,

        # An array of strings representing the members to show for the currently selected/highlighted item.
        [string[]]$MembersToShow
    )

    Write-FrameSelectedItemTitle -Content "Current Selection ($($selectionIndex+1) of $($SelectionItems.Count))"
    if ($null -eq $MembersToShow) {
        $MembersToShow = $SelectionItems[$SelectionIndex] | Get-Member -MemberType NoteProperty | ForEach-Object { $_.$DefaultMemberToShow }
    }

    $maxMemberName = ($MembersToShow | Measure-Object -Property Length -Maximum).Maximum + 1
    # The special formatting characters result in additional non-printable characters that need to be accounted for.
    $ansiFormat = $PSStyle.Foreground.Green
    $ansiFormatAlt = $PSStyle.Foreground.BrightBlack
    $widthCorrection = $ansiFormat.Length + $PSStyle.Reset.Length
    $MembersToShow | ForEach-Object {
        if (-not([string]::IsNullOrWhiteSpace(($SelectionItems[$SelectionIndex].$_)))) {
            Write-FrameContent -Width ($UIWidth + $widthCorrection) -Content "$ansiFormat$_$(' ' * ($maxMemberName - $_.Length)): $($PSStyle.Reset)$($SelectionItems[$SelectionIndex].$_ -join ', ')"
        } else {
            Write-FrameContent -Width ($UIWidth + $widthCorrection) -Content "$ansiFormatAlt$_$(' ' * ($maxMemberName - $_.Length)): $($PSStyle.Reset)"
        }
    }

    Write-FrameBottomBar
}

<#
.DESCRIPTION
    Gets the start index for the windows list view.
#>
function Get-WindowStartIndex {
    param (
        # The vertical span (text rows) of the windowed view of the UI.
        [int]$WindowSpan,

        # The index of the currently highlighted item in the list of selectable items.
        [int]$SelectionIndex,

        # The total number of items in the selection list.
        [int]$SelectionCount
    )

    # Calculate the ideal start index to center the selection.
    $windowStartIndex = $SelectionIndex - [Math]::Floor($WindowSpan / 2)

    # Adjust the start index if it's near the start or end of the list.
    if ($windowStartIndex -lt 0) {
        $windowStartIndex = 0
    } elseif ($windowStartIndex + $WindowSpan -gt $SelectionCount) {
        $windowStartIndex = $SelectionCount - $WindowSpan

        if ($windowStartIndex -lt 0) {
            $windowStartIndex = 0
        }
    }

    return $windowStartIndex
}

<#
.DESCRIPTION
    Wrapper to handle setting buffer width depending on OS.

.OUTPUTS
    $True if the requested width failed, and should be rehandled in another
    call.
#>
function Set-BufferWidth
{
    param (
        # The width to set the buffer to (in characters).
        [int]$Width
    )

    $redraw = $False

    if ($IsWindows) {
        $ErrorActionPreferenceBackup = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        try {
            # This may fail if window is widened right before this statement
            # executes as the buffer width must always be at least the
            # window width.
            [Console]::BufferWidth = $Width
        } catch [System.Management.Automation.SetValueInvocationException] {
            # Ignore the error and tell the caller to retry after determining
            # whether the buffer width is still valid for the current window
            # width.
            $redraw = $True
        } finally {
            $ErrorActionPreference = $ErrorActionPreferenceBackup
        }

    } else {
        # While this is not equivalent to setting the buffer width,
        # it still appears to help eliminate unwanted flickering
        # when the width is smaller than the minimum width.
        stty cols $Width
    }

    return $redraw
}

<#
.DESCRIPTION
    Write the frame data for the user controls.
#>
function Write-FrameControls
{
    param (
        # Decription should be filled to 60-characters.
        [string]$EnterKeyDescription,

        # When set, only the help key is shown
        [switch]$Minimize
    )

    Write-FrameMiddleBar

    if ($Minimize) {
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press '?' to show the controls menu."
    } else {
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content 'Press (PAGE) UP or (PAGE) DOWN to navigate selection.'
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content $EnterKeyDescription
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content 'Press SPACE to toggle selection.'
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press 'A' to select all, 'N' to select none."
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press 'C' to finish selections and continue operation."
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press '?' to minimize the controls menu."
        Write-FrameContent -AnsiiFormat "$($PSStyle.Background.BrightBlack)" -Content "Press ESC or 'Q' to quit now and cancel operation."
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
        [Parameter(Mandatory, ValueFromPipeline)]
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
        [string]$EnterKeyDescription = 'Press ENTER to show selection details.',

        # The script to execute whenn the ENNTER key is pressed. After completion, the screen will be redrawn by the TableUI.
        [Parameter()]
        [scriptblock]$EnterKeyScript = $DummyScriptBlock,

        # Specifies the format that the -Selections should be in. The default is an array of Booleans.
        [Parameter()]
        [ArgumentCompletions('Booleans', 'Indices', 'Items')]
        [string]$SelectionFormat = 'Booleans',

        # Specifies how the UI should be sized/fit in the window space.
        # 'Fill' will draw the UI to fill the viewable space (blank lines will be added at the end of the item selection subwindow to fill the vertical space).
        # 'FillWidth' will draw the UI to fill the width space (blank lines will not be added at the end of the item selection subwindow to fill the vertical space).
        # 'FitStandard' will use the standard 80 column width (blank lines will not be added at the end of the item selection subwindow to fill the vertical space).
        [Parameter()]
        [ArgumentCompletions('Fill', 'FillWidth', 'Standard')]
        [string]$UIFit = 'Fill'
    )

    begin
    {
        $TableItems = @()
    }

    process
    {
        $TableItems += $Table
    }

    end
    {
        $Selections.Value = $null
        $EnterKeyDescription = $EnterKeyDescription.TrimEnd()

        if ([string]::IsNullOrWhiteSpace($DefaultMemberToShow)) {
            $DefaultMemberToShow = ($TableItems | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -First 1).Name
        }

        $key = New-Object ConsoleKeyInfo
        [char]$currentKey = [char]0
        [char]$selectAll ='a'
        [char]$selectNone ='n'
        [char]$continue = 'c'
        [char]$quitKey = 'q'
        [char]$helpKey = '?'
        [char]$helpKeyAlt = '/'

        $tempSelections = @($TableItems) | ForEach-Object { $false }
        [int]$selectionIndex = 0
        [int]$windowStartIndex = 0
        $helpMinimized = $false

        if ($null -eq $SelectedItemMembersToShow) {
            $SelectedItemMembersToShow = ($TableItems | Select-Object -First 1 | Get-Member -MemberType NoteProperty).Name
        }

        [Console]::TreatControlCAsInput = $true
        [int]$windowedSpan = $Host.UI.RawUI.WindowSize.Height - $numStandardMenuLines
        $redraw = $true
        $runLoop = $true

        while ($runLoop)
        {
            [int]$numStandardMenuLines = 17 + $SelectedItemMembersToShow.Count # Count is based on 'Frame' drawing calls below
            if ($helpMinimized) {
                $numStandardMenuLines -= 6
            }

            $UIWidthLast = $UIWidth
            $windowedSpanLast = $windowedSpan

            $windowDimensions = $Host.UI.RawUI.WindowSize
            $windowedSpan = $windowDimensions.Height - $numStandardMenuLines

            if ($UIFit -eq 'Fill' -or $UIFit -eq 'FillWidth') {
                if ($windowDimensions.Width -ge $UIWidthMin) {
                    $UIWidth = $windowDimensions.Width
                } else {
                    $UIWidth = $UIWidthMin
                }
            }

            if ($windowedSpan -le 0) { $windowedSpan = 1 }
            if (($windowedSpanLast -ne $windowedSpan) -or ($UIWidthLast -ne $UIWidth) -or ([Console]::BufferWidth -ne $UIWidth)) { $redraw = $true }

            $windowStartIndex = Get-WindowStartIndex -WindowSpan $windowedSpan -SelectionCount $TableItems.Count -SelectionIndex $selectionIndex
            $windowedSelectionItems = @($TableItems.$DefaultMemberToShow)[$windowStartIndex..($windowStartIndex+$windowedSpan-1)]
            $windowedSelectionIndex = $selectionIndex - $windowStartIndex
            $windowedSelections = @($tempSelections)[$windowStartIndex..($windowStartIndex+$windowedSpan-1)]
            $numItemsToUpgrade = 0
            $tempSelections | ForEach-Object { if ($_ -eq $true) { $numItemsToUpgrade++ } }
            $selectionMenuTitle = "$Title (Selected $($numItemsToUpgrade) of $($TableItems.Count))"

            if ($redraw) {
                $redraw = Set-BufferWidth -Width $UIWidth
                [Console]::CursorVisible = $false
                Clear-Frame
                Write-FrameSelectionItems -Title $selectionMenuTitle -SelectionItems $windowedSelectionItems -SelectionIndex $windowedSelectionIndex -Selections $windowedSelections -WindowedSpan $windowedSpan
                Write-FrameControls -EnterKeyDescription $EnterKeyDescription -Minimize:$helpMinimized
                Write-FrameSelectedItem -SelectionItems $TableItems -SelectionIndex $selectionIndex -MembersToShow $SelectedItemMembersToShow
                Show-Frame
            }

            if (-not([Console]::KeyAvailable)) {
                Start-Sleep -Milliseconds 10
                continue
            }

            $redraw = $true
            $key = [Console]::ReadKey($true)
            $currentKey = [char]$key.Key
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
                    if ($selectionIndex -lt $TableItems.Count - 1) {
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
                    if ($selectionIndex + $windowedSpan -le $TableItems.Count - 1) {
                        $selectionIndex += $windowedSpan
                    } else {
                        $selectionIndex = $TableItems.Count - 1
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
                { ($key.KeyChar -eq $helpKey) -or ($key.KeyChar -eq $helpKeyAlt) } { $helpMinimized = -not $helpMinimized }

                # Select all items
                $selectAll { $tempSelections = $tempSelections | ForEach-Object { $true } }

                # Deselect all items
                $selectNone { $tempSelections = $tempSelections | ForEach-Object { $false } }

                # Execute the ENTER script block for the selected item
                { $_ -eq [ConsoleKey]::Enter } {
                    Invoke-Command -ScriptBlock $EnterKeyScript -ArgumentList @(@($tempSelections), $selectionIndex)
                }

                # Abort operation
                { ($_ -eq [ConsoleKey]::Escape) -or ($_ -eq $quitKey) -or ((($_ -eq $continue) -and ($key.Modifiers -contains [ConsoleModifiers]::Control))) } {
                    Write-Output "`nAborted."
                    $tempSelections = $null
                    $runLoop = $false
                }

                { (($_ -eq $continue) -and ($key.Modifiers -notcontains [ConsoleModifiers]::Control)) } {
                    $runLoop = $false
                }
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
                Invoke-Command -ScriptBlock $transformSelectionScript -ArgumentList $index, $TableItems[$index], $_
                $index++
            }
        }
    }
}
