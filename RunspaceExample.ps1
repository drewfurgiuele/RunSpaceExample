$computers = @("SQLSERVERA","SQLSERVERB","SQLSERVERC","SQLSERVERA","SQLSERVERB","SQLSERVERC","SQLSERVERA","SQLSERVERB","SQLSERVERC","SQLSERVERA","SQLSERVERB","SQLSERVERC","SQLSERVERA","SQLSERVERB","SQLSERVERC")

$runspacePool = [RunspaceFactory]::CreateRunspacePool(1, 4)
$runspacePool.ApartmentState = "MTA"
$runspacePool.Open()

$codeContainer = {
    Param(
        [string] $ComputerName
    )
    $processes = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process}
    return $processes
}

$threads = @()

$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
Foreach ($c in $computers)
{

    $runspaceObject = [PSCustomObject] @{
        Runspace = [PowerShell]::Create()
        Invoker = $null
    }
    $runspaceObject.Runspace.RunSpacePool = $runspacePool
    $runspaceObject.Runspace.AddScript($codeContainer) | Out-Null
    $runspaceObject.Runspace.AddArgument($c) | Out-Null
    $runspaceObject.Invoker = $runspaceObject.Runspace.BeginInvoke()
    $threads += $runspaceObject
    $elapsed = $StopWatch.Elapsed
    Write-Host "Finished creating runspace for $c. Elapsed time: $elapsed"
}
$elapsed = $StopWatch.Elapsed
Write-Host "Finished creating all runspaces. Elapsed time: $elapsed"

while ($threads.Invoker.IsCompleted -contains $false) {}
$elapsed = $StopWatch.Elapsed
Write-Host "All runspaces completed. Elapsed time: $elapsed"

$threadResults = @()
Foreach ($t in $threads)
{
    $threadResults += $t.Runspace.EndInvoke($t.Invoker)
    $t.Runspace.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()
