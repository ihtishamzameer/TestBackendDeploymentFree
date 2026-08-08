param(
    [string]$TrxPath = ".\TestResults\test-results.trx",
    [string]$OutputDirectory = ".\TestResults\Report"
)

if (-not (Test-Path $TrxPath)) {
    Write-Error "TRX file not found: $TrxPath"
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

[xml]$trx = Get-Content $TrxPath

$results = @($trx.TestRun.Results.UnitTestResult)

$total = $results.Count
$passed = @($results | Where-Object { $_.outcome -eq "Passed" }).Count
$failed = @($results | Where-Object { $_.outcome -eq "Failed" }).Count
$skipped = @($results | Where-Object { $_.outcome -eq "NotExecuted" }).Count

$runDate = $trx.TestRun.Times.start
$runFinish = $trx.TestRun.Times.finish

$successRate = if ($total -gt 0) {
    [math]::Round(($passed / $total) * 100, 2)
}
else {
    0
}

$overallStatus = if ($failed -eq 0 -and $total -gt 0) {
    "All Tests Passed"
}
elseif ($failed -gt 0) {
    "Tests Failed"
}
else {
    "No Tests Found"
}

$overallClass = if ($failed -eq 0 -and $total -gt 0) {
    "success"
}
elseif ($failed -gt 0) {
    "danger"
}
else {
    "warning"
}

$rows = foreach ($result in $results) {

    $testName = [System.Net.WebUtility]::HtmlEncode($result.testName)
    $outcome = $result.outcome
    $duration = $result.duration

    $errorMessage = ""

    if ($result.Output -and $result.Output.ErrorInfo -and $result.Output.ErrorInfo.Message) {
        $errorMessage = [System.Net.WebUtility]::HtmlEncode(
            $result.Output.ErrorInfo.Message
        )
    }

    switch ($outcome) {

        "Passed" {
            $statusClass = "passed"
            $statusIcon = "✓"
        }

        "Failed" {
            $statusClass = "failed"
            $statusIcon = "×"
        }

        "NotExecuted" {
            $statusClass = "skipped"
            $statusIcon = "–"
        }

        default {
            $statusClass = "other"
            $statusIcon = "?"
        }
    }

    @"
<tr>
    <td>
        <div class="test-name">
            <span class="test-icon $statusClass">$statusIcon</span>
            <span>$testName</span>
        </div>
    </td>

    <td>
        <span class="badge $statusClass">
            $outcome
        </span>
    </td>

    <td>
        <span class="duration">
            $duration
        </span>
    </td>

    <td>
        $(if ($errorMessage) {
            "<span class='error-text'>$errorMessage</span>"
        }
        else {
            "<span class='no-error'>—</span>"
        })
    </td>
</tr>
"@
}

$html = @"
<!DOCTYPE html>

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>Test01 | Automated Test Report</title>

<style>

/* ================================
   GLOBAL
================================ */

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    font-family:
        Inter,
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        Roboto,
        Arial,
        sans-serif;

    background: #f4f7fb;
    color: #172033;
}

/* ================================
   HEADER
================================ */

.header {
    background:
        linear-gradient(
            135deg,
            #111827 0%,
            #1e293b 55%,
            #334155 100%
        );

    color: white;
    padding: 42px 50px;
}

.header-content {
    max-width: 1250px;
    margin: auto;

    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 30px;
}

.brand {
    display: flex;
    align-items: center;
    gap: 16px;
}

.logo {
    width: 58px;
    height: 58px;

    border-radius: 16px;

    display: flex;
    align-items: center;
    justify-content: center;

    background: rgba(255,255,255,.12);

    border: 1px solid rgba(255,255,255,.18);

    font-size: 26px;
    font-weight: 800;
}

.header h1 {
    margin: 0;
    font-size: 30px;
    font-weight: 750;
    letter-spacing: -0.5px;
}

.header p {
    margin: 6px 0 0;
    color: #cbd5e1;
    font-size: 14px;
}

.status {
    padding: 12px 20px;
    border-radius: 999px;

    font-weight: 700;
    font-size: 14px;

    display: flex;
    align-items: center;
    gap: 8px;
}

.status.success {
    background: rgba(34,197,94,.16);
    color: #86efac;
    border: 1px solid rgba(134,239,172,.25);
}

.status.danger {
    background: rgba(239,68,68,.16);
    color: #fca5a5;
    border: 1px solid rgba(252,165,165,.25);
}

.status.warning {
    background: rgba(245,158,11,.16);
    color: #fcd34d;
    border: 1px solid rgba(252,211,77,.25);
}

/* ================================
   MAIN
================================ */

.container {
    max-width: 1250px;
    margin: -25px auto 60px;
    padding: 0 25px;
}

/* ================================
   SUMMARY CARDS
================================ */

.summary {
    display: grid;

    grid-template-columns:
        repeat(4, 1fr);

    gap: 18px;

    margin-bottom: 25px;
}

.card {
    background: white;

    border-radius: 16px;

    padding: 22px;

    border: 1px solid #e7ebf2;

    box-shadow:
        0 8px 25px rgba(15,23,42,.06);

    transition:
        transform .2s ease,
        box-shadow .2s ease;
}

.card:hover {
    transform: translateY(-3px);

    box-shadow:
        0 14px 35px rgba(15,23,42,.10);
}

.card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;

    margin-bottom: 12px;
}

.card-title {
    color: #64748b;

    font-size: 13px;

    font-weight: 650;

    text-transform: uppercase;

    letter-spacing: .7px;
}

.card-icon {
    width: 38px;
    height: 38px;

    border-radius: 10px;

    display: flex;
    align-items: center;
    justify-content: center;

    font-weight: 800;
    font-size: 17px;
}

.icon-total {
    background: #eef2ff;
    color: #4f46e5;
}

.icon-passed {
    background: #ecfdf5;
    color: #16a34a;
}

.icon-failed {
    background: #fef2f2;
    color: #dc2626;
}

.icon-skipped {
    background: #fffbeb;
    color: #d97706;
}

.card-value {
    font-size: 30px;

    font-weight: 800;

    letter-spacing: -1px;

    color: #0f172a;
}

.card-subtitle {
    margin-top: 4px;

    color: #94a3b8;

    font-size: 12px;
}

/* ================================
   SUCCESS RATE
================================ */

.success-section {
    background: white;

    border-radius: 16px;

    padding: 25px;

    border: 1px solid #e7ebf2;

    box-shadow:
        0 8px 25px rgba(15,23,42,.06);

    margin-bottom: 25px;
}

.success-header {
    display: flex;

    justify-content: space-between;

    align-items: center;

    margin-bottom: 15px;
}

.success-title {
    font-weight: 750;
    font-size: 16px;
}

.success-value {
    font-size: 24px;
    font-weight: 800;
}

.progress {
    width: 100%;

    height: 12px;

    background: #e9eef5;

    border-radius: 999px;

    overflow: hidden;
}

.progress-bar {
    height: 100%;

    width: $successRate%;

    background:
        linear-gradient(
            90deg,
            #16a34a,
            #22c55e
        );

    border-radius: 999px;

    transition: width .8s ease;
}

/* ================================
   DETAILS
================================ */

.info-grid {
    display: grid;

    grid-template-columns:
        repeat(3, 1fr);

    gap: 18px;

    margin-bottom: 25px;
}

.info-box {
    background: white;

    border: 1px solid #e7ebf2;

    border-radius: 14px;

    padding: 18px 20px;
}

.info-label {
    color: #94a3b8;

    font-size: 11px;

    text-transform: uppercase;

    letter-spacing: .7px;

    font-weight: 700;
}

.info-value {
    margin-top: 6px;

    color: #334155;

    font-size: 14px;

    font-weight: 600;

    word-break: break-word;
}

/* ================================
   TEST RESULTS
================================ */

.results-card {
    background: white;

    border-radius: 16px;

    border: 1px solid #e7ebf2;

    box-shadow:
        0 8px 25px rgba(15,23,42,.06);

    overflow: hidden;
}

.results-header {
    padding: 23px 25px;

    border-bottom: 1px solid #e7ebf2;

    display: flex;

    justify-content: space-between;

    align-items: center;
}

.results-title {
    font-size: 18px;

    font-weight: 750;
}

.results-count {
    font-size: 12px;

    color: #64748b;

    background: #f1f5f9;

    padding: 7px 12px;

    border-radius: 999px;

    font-weight: 650;
}

.table-wrapper {
    overflow-x: auto;
}

table {
    width: 100%;

    border-collapse: collapse;

    min-width: 850px;
}

thead {
    background: #f8fafc;
}

th {
    padding: 14px 20px;

    text-align: left;

    color: #64748b;

    font-size: 11px;

    text-transform: uppercase;

    letter-spacing: .7px;

    font-weight: 750;
}

td {
    padding: 17px 20px;

    border-top: 1px solid #edf0f4;

    font-size: 13px;

    vertical-align: middle;
}

tbody tr {
    transition: background .15s ease;
}

tbody tr:hover {
    background: #f8fafc;
}

/* ================================
   TEST NAME
================================ */

.test-name {
    display: flex;

    align-items: center;

    gap: 12px;

    font-weight: 600;

    color: #334155;
}

.test-icon {
    width: 30px;
    height: 30px;

    border-radius: 9px;

    display: flex;

    align-items: center;
    justify-content: center;

    font-size: 15px;

    font-weight: 800;
}

.test-icon.passed {
    background: #ecfdf5;
    color: #16a34a;
}

.test-icon.failed {
    background: #fef2f2;
    color: #dc2626;
}

.test-icon.skipped {
    background: #fffbeb;
    color: #d97706;
}

/* ================================
   BADGES
================================ */

.badge {
    display: inline-flex;

    align-items: center;

    padding: 6px 10px;

    border-radius: 999px;

    font-size: 11px;

    font-weight: 750;
}

.badge.passed {
    background: #ecfdf5;
    color: #15803d;
}

.badge.failed {
    background: #fef2f2;
    color: #b91c1c;
}

.badge.skipped {
    background: #fffbeb;
    color: #b45309;
}

.badge.other {
    background: #f1f5f9;
    color: #475569;
}

.duration {
    color: #64748b;

    font-family:
        "Cascadia Code",
        Consolas,
        monospace;

    font-size: 12px;
}

.error-text {
    color: #b91c1c;

    font-size: 12px;

    line-height: 1.5;
}

.no-error {
    color: #cbd5e1;
}

/* ================================
   FOOTER
================================ */

.footer {
    text-align: center;

    color: #94a3b8;

    font-size: 12px;

    padding: 28px 0;
}

.footer strong {
    color: #64748b;
}

/* ================================
   RESPONSIVE
================================ */

@media (max-width: 900px) {

    .summary {
        grid-template-columns:
            repeat(2, 1fr);
    }

    .info-grid {
        grid-template-columns: 1fr;
    }

    .header-content {
        flex-direction: column;

        align-items: flex-start;
    }
}

@media (max-width: 550px) {

    .header {
        padding: 30px 25px;
    }

    .container {
        margin-top: -15px;
    }

    .summary {
        grid-template-columns: 1fr;
    }
}

/* ================================
   PRINT / PDF
================================ */

@media print {

    body {
        background: white;
    }

    .header {
        print-color-adjust: exact;
        -webkit-print-color-adjust: exact;
    }

    .card,
    .success-section,
    .info-box,
    .results-card {
        box-shadow: none;
    }

    .card:hover {
        transform: none;
    }

    .results-card {
        break-inside: avoid;
    }

    tbody tr:hover {
        background: transparent;
    }

}

</style>

</head>

<body>

<!-- ================================
     HEADER
================================ -->

<header class="header">

<div class="header-content">

    <div class="brand">

        <div class="logo">
            ✓
        </div>

        <div>

            <h1>
                Test01 Automated Test Report
            </h1>

            <p>
                .NET 8 • xUnit • Integration Testing
            </p>

        </div>

    </div>

    <div class="status $overallClass">

        <span>
            $(if ($failed -eq 0 -and $total -gt 0) { "✓" } else { "!" })
        </span>

        $overallStatus

    </div>

</div>

</header>


<!-- ================================
     MAIN
================================ -->

<main class="container">


<!-- SUMMARY -->

<section class="summary">


<div class="card">

    <div class="card-header">

        <span class="card-title">
            Total Tests
        </span>

        <div class="card-icon icon-total">
            #
        </div>

    </div>

    <div class="card-value">
        $total
    </div>

    <div class="card-subtitle">
        Tests executed
    </div>

</div>


<div class="card">

    <div class="card-header">

        <span class="card-title">
            Passed
        </span>

        <div class="card-icon icon-passed">
            ✓
        </div>

    </div>

    <div class="card-value">
        $passed
    </div>

    <div class="card-subtitle">
        Successful tests
    </div>

</div>


<div class="card">

    <div class="card-header">

        <span class="card-title">
            Failed
        </span>

        <div class="card-icon icon-failed">
            ×
        </div>

    </div>

    <div class="card-value">
        $failed
    </div>

    <div class="card-subtitle">
        Tests requiring attention
    </div>

</div>


<div class="card">

    <div class="card-header">

        <span class="card-title">
            Skipped
        </span>

        <div class="card-icon icon-skipped">
            –
        </div>

    </div>

    <div class="card-value">
        $skipped
    </div>

    <div class="card-subtitle">
        Tests not executed
    </div>

</div>


</section>


<!-- SUCCESS RATE -->

<section class="success-section">

    <div class="success-header">

        <div class="success-title">
            Overall Success Rate
        </div>

        <div class="success-value">
            $successRate%
        </div>

    </div>

    <div class="progress">

        <div class="progress-bar"></div>

    </div>

</section>


<!-- RUN INFORMATION -->

<section class="info-grid">


<div class="info-box">

    <div class="info-label">
        Project
    </div>

    <div class="info-value">
        Test01.Tests
    </div>

</div>


<div class="info-box">

    <div class="info-label">
        Framework
    </div>

    <div class="info-value">
        .NET 8
    </div>

</div>


<div class="info-box">

    <div class="info-label">
        Test Framework
    </div>

    <div class="info-value">
        xUnit
    </div>

</div>


<div class="info-box">

    <div class="info-label">
        Test Run Started
    </div>

    <div class="info-value">
        $runDate
    </div>

</div>


<div class="info-box">

    <div class="info-label">
        Test Run Finished
    </div>

    <div class="info-value">
        $runFinish
    </div>

</div>


<div class="info-box">

    <div class="info-label">
        Source
    </div>

    <div class="info-value">
        test-results.trx
    </div>

</div>


</section>


<!-- TEST RESULTS -->

<section class="results-card">

    <div class="results-header">

        <div class="results-title">
            Test Results
        </div>

        <div class="results-count">
            $total test$(if ($total -ne 1) { "s" })
        </div>

    </div>


    <div class="table-wrapper">

        <table>

            <thead>

                <tr>

                    <th>
                        Test
                    </th>

                    <th>
                        Status
                    </th>

                    <th>
                        Duration
                    </th>

                    <th>
                        Error Details
                    </th>

                </tr>

            </thead>


            <tbody>

                $($rows -join "`n")

            </tbody>

        </table>

    </div>

</section>


<!-- FOOTER -->

<footer class="footer">

    Generated automatically from
    <strong>test-results.trx</strong>

    <br>

    Test01 • Automated Testing Report

</footer>


</main>

</body>

</html>
"@

$outputFile = Join-Path $OutputDirectory "test-report.html"

$html | Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================="
Write-Host "       TEST REPORT GENERATED"
Write-Host "========================================="
Write-Host ""
Write-Host "Total Tests : $total"
Write-Host "Passed      : $passed"
Write-Host "Failed      : $failed"
Write-Host "Skipped     : $skipped"
Write-Host "Success     : $successRate%"
Write-Host ""
Write-Host "HTML Report:"
Write-Host $outputFile
Write-Host ""