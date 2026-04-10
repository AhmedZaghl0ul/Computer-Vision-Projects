param(
    [string]$Root = 'd:\ML\computer vision projects\sandstone microstructure (Semantic Segmintation)',
    [int]$TrainCount = 30,
    [int]$TestCount = 20
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$trainDir = Join-Path $Root 'Data\Train'
$testDir = Join-Path $Root 'Data\Test'

if (-not (Test-Path $trainDir)) {
    throw "Training folder not found: $trainDir"
}
if (-not (Test-Path $testDir)) {
    throw "Testing folder not found: $testDir"
}

# Clean previous generated files to enforce exact counts.
Get-ChildItem -Path $trainDir -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $testDir -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$headers = @{
    'User-Agent' = 'CopilotImageDownloader/1.0 (Wikimedia Commons educational dataset prep)'
}

$seedTerms = @(
    'sandstone thin section',
    'sandstone petrography',
    'quartz sandstone thin section',
    'sedimentary rock thin section',
    'rock thin section photomicrograph',
    'petrographic thin section',
    'thin section photomicrograph',
    'rock micrograph',
    'x-ray tomography sandstone',
    'micro-ct sandstone'
)

function Get-ImageExtension {
    param(
        [string]$Url,
        [string]$Mime
    )

    $ext = ''
    try {
        $uri = [Uri]$Url
        $ext = [IO.Path]::GetExtension($uri.AbsolutePath).ToLowerInvariant()
    } catch {
        $ext = ''
    }

    switch ($ext) {
        '.jpg' { return '.jpg' }
        '.jpeg' { return '.jpg' }
        '.png' { return '.png' }
        '.tif' { return '.tif' }
        '.tiff' { return '.tiff' }
        default {
            if ($Mime -match 'png') { return '.png' }
            if ($Mime -match 'tif') { return '.tif' }
            return '.jpg'
        }
    }
}

function Add-CandidatesFromTerm {
    param(
        [string]$Term,
        [System.Collections.Generic.List[object]]$Store,
        [System.Collections.Generic.HashSet[string]]$Seen
    )

    $encoded = [Uri]::EscapeDataString($Term)

    foreach ($offset in 0, 50, 100, 150) {
        $url = "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrsearch=$encoded&gsrlimit=50&gsroffset=$offset&prop=imageinfo|categories&iiprop=url|mime&cllimit=10"

        try {
            $resp = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 60
        } catch {
            continue
        }

        if (-not ($resp.PSObject.Properties.Name -contains 'query')) {
            continue
        }
        if (-not ($resp.query.PSObject.Properties.Name -contains 'pages')) {
            continue
        }
        if (-not $resp.query.pages) {
            continue
        }

        foreach ($page in $resp.query.pages.PSObject.Properties.Value) {
            if (-not ($page.PSObject.Properties.Name -contains 'imageinfo')) {
                continue
            }
            if (-not $page.imageinfo) {
                continue
            }

            $info = $page.imageinfo[0]
            $imgUrl = [string]$info.url
            $mime = [string]$info.mime

            if ([string]::IsNullOrWhiteSpace($imgUrl)) {
                continue
            }

            if ($mime -notmatch '^image/(jpeg|jpg|png|tif|tiff)$') {
                continue
            }

            $title = ([string]$page.title).ToLowerInvariant()
            $catText = ''
            if (($page.PSObject.Properties.Name -contains 'categories') -and $page.categories) {
                $catText = (($page.categories | ForEach-Object { $_.title }) -join ' ').ToLowerInvariant()
            }
            $combined = "$title $catText"

            if ($combined -notmatch 'sandstone|thin section|petrograph|micrograph|sediment|quartz|grain|tomograph|ct|lithic|arenite') {
                continue
            }

            if ($Seen.Add($imgUrl)) {
                $Store.Add([pscustomobject]@{
                    Title = [string]$page.title
                    Url = $imgUrl
                    Mime = $mime
                    Query = $Term
                }) | Out-Null
            }
        }
    }
}

$neededTotal = $TrainCount + $TestCount
$candidates = New-Object System.Collections.Generic.List[object]
$seenUrls = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($term in $seedTerms) {
    Add-CandidatesFromTerm -Term $term -Store $candidates -Seen $seenUrls
}

if ($candidates.Count -lt $neededTotal) {
    $fallbackTerms = @(
        'sedimentary thin section',
        'rock texture micrograph',
        'petrography thin section',
        'sandstone reservoir rock'
    )
    foreach ($term in $fallbackTerms) {
        Add-CandidatesFromTerm -Term $term -Store $candidates -Seen $seenUrls
    }
}

if ($candidates.Count -lt $neededTotal) {
    throw "Not enough relevant candidates found. Needed $neededTotal, found $($candidates.Count)."
}

$queue = $candidates | Sort-Object { Get-Random }
$trainMeta = New-Object System.Collections.Generic.List[object]
$testMeta = New-Object System.Collections.Generic.List[object]
$trainDownloaded = 0
$testDownloaded = 0

foreach ($item in $queue) {
    if ($trainDownloaded -ge $TrainCount -and $testDownloaded -ge $TestCount) {
        break
    }

    if ($trainDownloaded -lt $TrainCount) {
        $split = 'train'
        $index = $trainDownloaded + 1
        $destDir = $trainDir
    } else {
        $split = 'test'
        $index = $testDownloaded + 1
        $destDir = $testDir
    }

    $ext = Get-ImageExtension -Url $item.Url -Mime $item.Mime
    $fileName = ('sandstone_{0}_{1:000}{2}' -f $split, $index, $ext)
    $destPath = Join-Path $destDir $fileName

    try {
        Invoke-WebRequest -Uri $item.Url -OutFile $destPath -Headers $headers -TimeoutSec 120
        $size = (Get-Item -Path $destPath).Length

        # Tiny files are usually thumbnails/error responses; skip those.
        if ($size -lt 8192) {
            Remove-Item -Path $destPath -Force -ErrorAction SilentlyContinue
            continue
        }

        $entry = [pscustomobject]@{
            FileName = $fileName
            SourceTitle = $item.Title
            SourceUrl = $item.Url
            Query = $item.Query
            SizeBytes = $size
        }

        if ($split -eq 'train') {
            $trainDownloaded++
            $trainMeta.Add($entry) | Out-Null
        } else {
            $testDownloaded++
            $testMeta.Add($entry) | Out-Null
        }
    } catch {
        if (Test-Path $destPath) {
            Remove-Item -Path $destPath -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($trainDownloaded -lt $TrainCount -or $testDownloaded -lt $TestCount) {
    throw "Incomplete download. Train=$trainDownloaded/$TrainCount, Test=$testDownloaded/$TestCount, Candidates=$($candidates.Count)."
}

$trainMeta | Export-Csv -Path (Join-Path $trainDir 'sources_train.csv') -NoTypeInformation -Encoding UTF8
$testMeta | Export-Csv -Path (Join-Path $testDir 'sources_test.csv') -NoTypeInformation -Encoding UTF8

Write-Output "Success: downloaded $trainDownloaded training images and $testDownloaded testing images."
