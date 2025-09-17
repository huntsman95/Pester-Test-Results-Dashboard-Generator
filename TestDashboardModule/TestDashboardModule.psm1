function New-TestDashboard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$InputXml,

        [string]$TemplatePath = ".\dashboard-template.eps",

        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    # Load EPS module
    Import-Module EPS

    # Use the path directly (works for both string paths and FileInfo objects converted to string)
    $XmlFilePath = $InputXml

    # Load and parse the NUnit XML
    if (-not (Test-Path $XmlFilePath)) {
        Write-Error "NUnit XML file not found: $XmlFilePath"
        return
    }

    [xml]$xml = Get-Content $XmlFilePath

    # Extract test data
    $testResults = $xml.'test-results'
    $totalTests = [int]$testResults.total
    $failedTests = [int]$testResults.failures
    $skippedTests = [int]$testResults.skipped
    $errors = [int]$testResults.errors
    $passedTests = $totalTests - $failedTests - $skippedTests - $errors

    # Get individual test cases
    $testCases = $xml.SelectNodes("//test-case") | ForEach-Object {
        $parts = $_.name -split '\.'
        $mainCategory = $parts[0]
        $subCategory = if ($parts.Count -ge 2) { $parts[1] } else { "General" }
        $failureMessage = if ($_.failure) { $_.failure.message } else { $null }
        $testStackTrace = if ($_.failure) { $_.failure.'stack-trace' } else { $null }
        [PSCustomObject]@{
            FullName = $_.name
            DisplayName = if ($_.description) { $_.description } else { $_.name }
            Result = switch ($_.result) {
                "Success" { "Passed" }
                "Failure" { "Failed" }
                default { $_.result }
            }
            Time = [double]$_.time
            MainCategory = $mainCategory
            SubCategory = $subCategory
            FailureMessage = $failureMessage
            StackTrace = $testStackTrace
        }
    }

    # Group tests by main category
    $mainCategories = $testCases | Group-Object MainCategory | Sort-Object Name

    # Calculate pass/fail counts for each main category
    $globalTestCounter = 0
    $mainCategoriesWithStats = $mainCategories | ForEach-Object {
        $categoryTests = $_.Group
        $passedCount = ($categoryTests | Where-Object { $_.Result -eq "Passed" }).Count
        $failedCount = ($categoryTests | Where-Object { $_.Result -eq "Failed" }).Count
        $hasFailures = $failedCount -gt 0

        # Assign test IDs to all tests in this category
        $testsWithIds = $categoryTests | ForEach-Object {
            $globalTestCounter++
            [PSCustomObject]@{
                FullName = $_.FullName
                DisplayName = $_.DisplayName
                Result = $_.Result
                Time = $_.Time
                MainCategory = $_.MainCategory
                SubCategory = $_.SubCategory
                FailureMessage = $_.FailureMessage
                StackTrace = $_.StackTrace
                TestId = "test-" + $globalTestCounter
            }
        }

        [PSCustomObject]@{
            Name = $_.Name
            Group = $testsWithIds
            PassedCount = $passedCount
            FailedCount = $failedCount
            HasFailures = $hasFailures
            TotalCount = $_.Count
        }
    }

    # Collect all failed tests with category information
    $failedTestsSummary = @()
    foreach ($category in $mainCategoriesWithStats) {
        if ($category.HasFailures) {
            $failedTestsInCategory = $category.Group | Where-Object { $_.Result -eq "Failed" }
            foreach ($failedTest in $failedTestsInCategory) {
                $failedTestsSummary += [PSCustomObject]@{
                    TestName = $failedTest.DisplayName
                    CategoryName = $category.Name
                    CategoryId = "collapse-" + $category.Name.Replace(" ", "").Replace(".", "")
                    TestId = $failedTest.TestId
                    FailureMessage = $failedTest.FailureMessage
                    StackTrace = $failedTest.StackTrace
                }
            }
        }
    }

    # Prepare data for template
    $data = @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        SkippedTests = $skippedTests
        PassRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
        MainCategories = $mainCategoriesWithStats
        FailedTestsSummary = $failedTestsSummary
        GeneratedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $bindings = @{
        data = $data
    }

    # Generate HTML from template
    Invoke-EpsTemplate -Path $TemplatePath -Binding $bindings | Out-File $OutputPath -Encoding UTF8

    Write-Verbose "Dashboard generated: $OutputPath"
    return $OutputPath
}