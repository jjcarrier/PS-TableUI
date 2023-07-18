# TableUI PowerShell Module

![PSGallery](https://img.shields.io/powershellgallery/p/TableUI)

## Description

This is a simple, no frills UI that accepts an array of objects and displays
each entry in interactive list where the user can make selections for an
underlying operation.

The original scope of this tool was to provide a simple UI for selecting what
upgradable packages to install for `winget update` but has been expanded on
to be more general purpose.

## Installation

Download/install the module from `PSGallery`:

```pwsh
Install-Module -Name TableUI -Repository PSGallery
```

Add the module to your `$PROFILE`:

```pwsh
Import-Module TableUI
```

## Usage

`Show-TableUI`, it is best suited for working with arrays of `PSCustomObject`.
An array of dictionaries is __not suited__ for this cmdlet.

For example use this form (specifying `[PSCustomObject]`):

```pwsh
$tableData = @(
  [PSCustomObject]@{Name = 'Test A'; Version = '1.2.3'},
  [PSCustomObject]@{Name = 'Test B'; Version = '1.2.5'}
)
```

And __avoid__ this form:

```pwsh
$tableData = @(
  @{Name = 'Test A'; Version = '1.2.3'},
  @{Name = 'Test B'; Version = '1.2.5'}
)
```

This cmdlet works great with `ConvertFrom-` cmdlets, such as `ConvertFrom-Json`
where the data conveys an array of objects with its fields as `NoteProperties`.

With a valid array of objects the following call can be made, additional parameters such as
`-SelectedItemMembersToShow` can be added as needed.

```pwsh
$selections = @()
Show-TableUI -Table $tableData -Selections ([ref]$selections)
```

Here is an example of interfacing WinGet update with TableUI utilizing
`ConvertFrom-TextTable` module (also available in PSGallery).

```pwsh
$selections = @()
$tableData = winget update | ConvertFrom-TextTable
Show-TableUI -Table $tableData -Selections ([ref]$selections)
```

## Selection Details Script Block

A custom handler may be defined for the `ENTER` key by specifying the `-EnterKeyScript` parameter.
The assigned script block takes two parameters, the first is the array indicating the current
selections (passed by value). The second parameter is the currently selected index. Full access to
the currently selected object and other selections can be realized with appropriate scoping.
