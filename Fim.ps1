Write-Host " "
Write-Host "What would you like to do"
Write-Host "A) Collect new BaseLine?"
Write-Host "B) Begin Monitoring files with saved BaseLine?"

$response = Read-Host -prompt "Please enter 'A' or 'B' "

Write-Host "User entered $($response)"

Function calculate_File-Hash($filepath) {
    $filehash= Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-if-already-exist()  {
    $baseline=Test-Path -Path .\baseline.txt
    if ($baseline) {
        Remove-Item  -path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    Erase-Baseline-if-already-exist

    $files = Get-ChildItem -Path '.\Files'

    foreach ($f in $files){
        $hash = calculate_File-Hash  $f.FullName
        "$($hash.Path) | $($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}
elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}

    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    while ($true) {
        Start-Sleep -Seconds 1

        $files = Get-ChildItem -Path '.\Files'

        foreach ($f in $files) {
            $hash = calculate_File-Hash $f.FullName

            if ($fileHashDictionary[$hash.Path] -eq $null) {
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
                $fileHashDictionary[$hash.Path] = $hash.Hash
            }
            else {
                if ($fileHashDictionary[$hash.Path] -ne $hash.Hash) {
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
                    $fileHashDictionary[$hash.Path] = $hash.Hash
                }
            }
        }

        foreach ($key in @($fileHashDictionary.Keys)) {
            if (-Not (Test-Path -Path $key)) {
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
                $fileHashDictionary.Remove($key)
            }
        }
    }
}
