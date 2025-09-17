@{
    ModuleVersion     = '1.0.0'
    GUID              = 'e4ed9c60-4134-4eab-8b35-eb13ad5cfb40'
    Author            = 'Your Name'
    CompanyName       = 'Skryptek, LLC'
    Copyright         = '(c) 2025 Skryptek, LLC. All rights reserved.'
    Description       = 'Module for generating test dashboards from NUnit XML.'
    PowerShellVersion = '5.1'
    RequiredModules   = @('EPS')
    FunctionsToExport = @('New-TestDashboard')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Testing', 'Dashboard', 'NUnit', 'Pester')
            LicenseUri   = ''
            ProjectUri   = ''
            IconUri      = ''
            ReleaseNotes = ''
        }
    }
}
