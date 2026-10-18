# DDF-LAB-02 external UART hardware comparison; Windows 10 / PowerShell 7.
# No Python/pyserial dependency. Protocol is documented in FIR_UART_README_EN.md.
param(
    [string]$Port = 'COM10',
    [ValidateRange(1,20000)][int]$RandomCount = 256,
    [int]$Seed = 20261018
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$hw = (Resolve-Path $PSScriptRoot).Path
$lab = (Resolve-Path (Join-Path $hw '..\..')).Path
$results = Join-Path $lab 'results'
$bitstream = Join-Path $hw 'build\fir_uart_v02\impl\pnr\fir_uart9k_v02.fs'
New-Item -ItemType Directory -Path $results -Force | Out-Null
$reportPath = Join-Path $results 'FIR_UART_V02_HARDWARE_REPORT.json'
$tracePath = Join-Path $results 'fir_uart_v02_hardware_trace.csv'
$script:serial = $null
$script:seq = 0
$script:recent = @()
$script:expectedLast = 0
$script:sampleCount = 0
$script:resetCount = 0
$script:holdCount = 0
$script:rows = New-Object 'System.Collections.Generic.List[object]'
$startUtc = [datetime]::UtcNow
$success = $false
$failure = $null
$bitstreamHash = $null
$rtlHash = $null

function Get-Xor([byte[]]$Bytes) {
    [int]$acc = 0
    foreach ($byte in $Bytes) { $acc = $acc -bxor [int]$byte }
    return [byte]$acc
}

function Invoke-Transaction {
    param(
        [ValidateRange(1,3)][int]$Op,
        [ValidateRange(0,4095)][int]$Data,
        [string]$Phase
    )
    [int]$thisSeq = $script:seq
    $script:seq = ($script:seq + 1) -band 255
    [byte[]]$part = @(
        0xA5, $Op, $thisSeq, (($Data -shr 8) -band 255), ($Data -band 255)
    )
    [byte[]]$packet = [byte[]]($part + [byte](Get-Xor $part))
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $script:serial.Write($packet, 0, $packet.Length)
    [byte[]]$response = New-Object byte[] 6
    $received = 0
    while ($received -lt $response.Length) {
        try {
            $amount = $script:serial.Read($response, $received, $response.Length - $received)
        } catch [System.TimeoutException] {
            throw "UART_TIMEOUT on $Port, seq=$thisSeq, op=$Op, received=$received/6. Check COM10 and FPGA firmware."
        }
        if ($amount -le 0) { throw "UART_READ_ERROR on seq=$thisSeq" }
        $received += $amount
    }
    $timer.Stop()
    [byte[]]$responseHead = @($response[0], $response[1], $response[2], $response[3], $response[4])
    $crc = Get-Xor $responseHead
    if ($response[0] -ne 0x5A -or $response[2] -ne $thisSeq -or
        $response[5] -ne $crc -or $response[1] -ne 0 -or
        (($response[3] -band 0xF0) -ne 0)) {
        throw ("UART_FRAME_FAIL seq={0} rx={1} calc_crc={2:X2}" -f `
            $thisSeq, ([BitConverter]::ToString($response)), [int]$crc)
    }

    # Independent host history; the 12-bit FPGA output is NOT trusted as oracle.
    if ($Op -eq 2) {
        $script:recent = @()
        $script:expectedLast = 0
        $script:resetCount++
    } elseif ($Op -eq 1) {
        $next = @($Data)
        for ($i=0; $i -lt [Math]::Min(3,$script:recent.Count); $i++) {
            $next += $script:recent[$i]
        }
        $script:recent = $next
        $sum = 0
        foreach ($v in $script:recent) { $sum += [int]$v }
        $script:expectedLast = [int][Math]::Floor($sum / 4)
        $script:sampleCount++
    } else {
        $script:holdCount++
    }
    $actual = ([int]($response[3] -band 0x0F) -shl 8) -bor [int]$response[4]
    $script:rows.Add([pscustomobject]@{
        Sequence = $thisSeq
        Phase = $Phase
        Opcode = $Op
        Input = $Data
        Expected = $script:expectedLast
        FPGA = $actual
        Equal = ($actual -eq $script:expectedLast)
        RoundTripMs = [Math]::Round($timer.Elapsed.TotalMilliseconds, 3)
    }) | Out-Null
    if ($actual -ne $script:expectedLast) {
        throw "FIR_HARDWARE_MISMATCH seq=$thisSeq input=$Data expected=$($script:expectedLast) FPGA=$actual"
    }
}

try {
    if (-not (Test-Path -LiteralPath $bitstream)) {
        throw "MISSING_BITSTREAM: $bitstream. Run build_fir_uart.tcl first."
    }
    $bitstreamHash = (Get-FileHash -LiteralPath $bitstream -Algorithm SHA256).Hash
    $rtlHash = (Get-FileHash -LiteralPath (Join-Path $lab 'rtl\moving_average4.v') -Algorithm SHA256).Hash
    $script:serial = [System.IO.Ports.SerialPort]::new(
        $Port, 115200, [System.IO.Ports.Parity]::None, 8,
        [System.IO.Ports.StopBits]::One
    )
    $script:serial.ReadTimeout = 3000
    $script:serial.WriteTimeout = 3000
    $script:serial.Handshake = [System.IO.Ports.Handshake]::None
    $script:serial.DtrEnable = $false
    $script:serial.RtsEnable = $false
    $script:serial.Open()
    Start-Sleep -Milliseconds 150
    $script:serial.DiscardInBuffer()

    Invoke-Transaction -Op 2 -Data 0 -Phase 'initial_reset'
    foreach ($value in @(4,0,0,0,0,4095,4095,4095,4095,0,1,2,3,4095)) {
        Invoke-Transaction -Op 1 -Data $value -Phase 'directed'
    }
    Invoke-Transaction -Op 3 -Data 0 -Phase 'hold_no_valid'
    $random = [System.Random]::new($Seed)
    for ($k=0; $k -lt $RandomCount; $k++) {
        if ($k -gt 0 -and ($k % 97) -eq 0) {
            Invoke-Transaction -Op 2 -Data 0 -Phase 'midstream_reset'
        }
        if (($k % 13) -eq 0) {
            Invoke-Transaction -Op 3 -Data 0 -Phase 'hold_no_valid'
        }
        Invoke-Transaction -Op 1 -Data ($random.Next(0,4096)) -Phase 'random'
    }
    $success = $true
    Write-Host "FIR_UART_V02_HARDWARE_PASS: $($script:sampleCount) samples, $($script:holdCount) holds, $($script:resetCount) resets, port $Port"
} catch {
    $failure = $_.Exception.Message
    Write-Host "FIR_UART_V02_HARDWARE_FAIL: $failure" -ForegroundColor Red
} finally {
    if ($null -ne $script:serial -and $script:serial.IsOpen) { $script:serial.Close() }
    if ($script:rows.Count -gt 0) {
        $script:rows | Export-Csv -LiteralPath $tracePath -Encoding utf8 -NoTypeInformation
    }
    [pscustomobject]@{
        Experiment = 'DDF-LAB-02 / Tang Nano 9K UART external comparison v0.2 registered reset'
        Status = $(if($success){'FIR_UART_V02_HARDWARE_PASS'}else{'FIR_UART_V02_HARDWARE_FAIL'})
        StartUTC = $startUtc.ToString('o')
        EndUTC = ([datetime]::UtcNow).ToString('o')
        ComPort = $Port
        Baudrate = 115200
        Frame = '115200 8N1, request A5, response 5A, XOR/sequence'
        Seed = $Seed
        RequestedRandomSamples = $RandomCount
        VerifiedSamples = $script:sampleCount
        Holds = $script:holdCount
        Resets = $script:resetCount
        VerifiedTransactions = $script:rows.Count
        BitstreamSHA256 = $bitstreamHash
        OriginalFIRRTL_SHA256 = $rtlHash
        Failure = $failure
        TraceFile = 'results/fir_uart_v02_hardware_trace.csv'
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $reportPath -Encoding utf8
    Write-Host "Report: $reportPath"
    Write-Host "Trace:  $tracePath"
}
if (-not $success) { throw "FIR_UART_V02_HARDWARE_FAIL: $failure" }
