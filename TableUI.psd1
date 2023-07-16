@{
    RootModule = 'TableUI.psm1'
    ModuleVersion = '1.0'
    GUID = 'b5eb9ef8-a2ef-40d4-a8d5-46d91ab7060e'
    Author = 'Jon Carrier'
    CompanyName = 'Unknown'
    Copyright = '(c) Jon Carrier. All rights reserved.'
    Description = 'A simple interface for making selections on an array of PS objects'

    # CompatiblePSEditions = @()
    # PowerShellVersion = ''
    # RequiredModules = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()

    FunctionsToExport = @()
    CmdletsToExport = @('Show-TableUI')
    VariablesToExport = '*'
    AliasesToExport = @()

    # ModuleList = @()
    # FileList = @()

    PrivateData = @{

        PSData = @{
            Tags = @('Table', 'Selection', 'UI')
            LicenseUri = 'https://github.com/jjcarrier/PS-TableUI/blob/main/LICENSE'
            ProjectUri = 'https://github.com/jjcarrier/PS-TableUI'
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @('TextTable')

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''
}
