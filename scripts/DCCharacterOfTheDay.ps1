<#
.SYNOPSIS
    This script interacts with the Comic Vine API to retrieve and process data about DC characters.

.PARAMETER comicVineApiKey
    The API key for accessing the Comic Vine API.

.DESCRIPTION
    This script provides functions to interact with the Comic Vine API, retrieve a random DC character,
    save it to a JSON file, and generate QR codes for character URLs.

.EXAMPLE
     .\DCCharacterOfTheDay.ps1 -comicVineApiKey "your_api_key"

.NOTES
     File Name      : DCCharacterOfTheDay.ps1
     Author         : Mark Hopper
     Prerequisite   : The DCCharacterOfTheDay.json and README.md files should be present in the parent directory.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$comicVineApiKey
)

# Set the Comic Vine API key and base URL
$ErrorActionPreference = "Stop"
$apiKey = $comicVineApiKey
if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "Configure the COMICVINEAPIKEY repository secret before running the updater." }
$BaseURL = "https://comicvine.gamespot.com/api/"

# Bio quality settings
$MinimumBioCharacters = 250
$MaximumBioCharacters = 700

function Wait-BeforeApiCall {
    Start-Sleep -Seconds 15
}

function Get-ComicVineApiData {
    param ([string]$endpoint, [hashtable]$queryParams = @{})
    $queryParams.Remove("api_key") | Out-Null
    $queryParams["api_key"] = $apiKey
    $queryParams["format"] = "json"
    $queryString = ($queryParams.GetEnumerator() | ForEach-Object {
        "{0}={1}" -f [Uri]::EscapeDataString($_.Key), [Uri]::EscapeDataString([string]$_.Value)
    }) -join "&"
    $url = $BaseURL + $endpoint.Trim('/') + "/?" + $queryString
    $retryDelay = 15
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            Wait-BeforeApiCall
            $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 60 -UserAgent "DCCharacterOfTheDay/1.0 (github.com/MarkHopper24/DC-Character-of-the-Day)"
            if ($response.status_code -ne 1) {
                throw "Comic Vine returned an unsuccessful API response."
            }
            return $response
        }
        catch {
            $statusCode = [int]$_.Exception.Response.StatusCode
            if ($attempt -lt 5 -and ($statusCode -in @(420, 429, 500, 502, 503, 504))) {
                Write-Warning "Comic Vine is temporarily unavailable; retrying in $retryDelay seconds."
                Start-Sleep -Seconds $retryDelay
                $retryDelay *= 2
            } else {
                # Do not emit request URLs: Comic Vine credentials are query parameters.
                throw "Comic Vine request failed (HTTP $statusCode). Check the repository secret and provider availability."
            }
        }
    }
}

function Normalize-PlainText {
    param (
        [string]$text
    )

    if ([string]::IsNullOrWhiteSpace($text)) {
        return ""
    }

    $text = [System.Net.WebUtility]::HtmlDecode($text)
    $text = $text -replace ([string][char]0xA0), ' '
    $text = $text -replace '\s+', ' '
    $text = $text -replace '\s+([,.;:!?])', '$1'
    $text = $text -replace '([.!?])([A-Z])', '$1 $2'

    return $text.Trim()
}

function Convert-HtmlToTextBlocks {
    param (
        [string]$html
    )

    if ([string]::IsNullOrWhiteSpace($html)) {
        return @()
    }

    $text = [System.Net.WebUtility]::HtmlDecode($html)

    # Remove script/style content if present.
    $text = $text -replace '(?is)<\s*script[^>]*>.*?<\s*/\s*script\s*>', ' '
    $text = $text -replace '(?is)<\s*style[^>]*>.*?<\s*/\s*style\s*>', ' '

    # Preserve meaningful boundaries before removing tags.
    $text = $text -replace '(?i)<\s*br\s*/?\s*>', "`n"
    $text = $text -replace '(?i)</\s*(p|div|li|h[1-6]|tr|blockquote)\s*>', "`n"
    $text = $text -replace '(?i)<\s*(p|div|li|h[1-6]|tr|blockquote)[^>]*>', "`n"

    # Remove remaining tags.
    $text = $text -replace '<[^>]+>', ' '

    # Decode again in case entities were inside tags/content.
    $text = [System.Net.WebUtility]::HtmlDecode($text)
    $text = $text -replace ([string][char]0xA0), ' '

    $text = $text -replace "`r", "`n"

    return @(
        $text -split "`n" |
            ForEach-Object { Normalize-PlainText -text $_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Remove-HtmlTags {
    param (
        [string]$html
    )

    if ([string]::IsNullOrWhiteSpace($html)) {
        return ""
    }

    $blocks = Convert-HtmlToTextBlocks -html $html
    return (Normalize-PlainText -text ($blocks -join " "))
}

function Test-BioStopHeading {
    param (
        [string]$text
    )

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }

    $normalized = $text.Trim()

    $stopHeadings = @(
        '^major story arcs?$',
        '^story arcs?$',
        '^powers and abilities$',
        '^powers$',
        '^abilities$',
        '^character evolution$',
        '^other versions$',
        '^in other media$',
        '^movies$',
        '^television$',
        '^video games$',
        '^merchandise$',
        '^equipment$',
        '^weapons$',
        '^notes$',
        '^trivia$',
        '^links$',
        '^see also$',
        '^recommended reading$',
        '^footnotes$',
        '^character links$'
    )

    foreach ($heading in $stopHeadings) {
        if ($normalized -match $heading) {
            return $true
        }
    }

    return $false
}

function Test-BioHeading {
    param (
        [string]$text
    )

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }

    $normalized = $text.Trim()

    $allowedButSkippedHeadings = @(
        '^origin$',
        '^origins$',
        '^creation$',
        '^biography$',
        '^history$'
    )

    foreach ($heading in $allowedButSkippedHeadings) {
        if ($normalized -match $heading) {
            return $true
        }
    }

    return (Test-BioStopHeading -text $normalized)
}

function Limit-BioLength {
    param (
        [string]$text,
        [int]$minimumCharacters = 250,
        [int]$maximumCharacters = 700
    )

    $text = Normalize-PlainText -text $text

    if ($text.Length -le $maximumCharacters) {
        return $text
    }

    $cut = $text.Substring(0, $maximumCharacters)

    # Prefer ending on a full sentence after the minimum character count.
    $lastSentenceEnd = $cut.LastIndexOfAny([char[]]".!?")
    if ($lastSentenceEnd -ge $minimumCharacters) {
        return $cut.Substring(0, $lastSentenceEnd + 1).Trim()
    }

    # Otherwise end at the last space after the minimum character count.
    $lastSpace = $cut.LastIndexOf(' ')
    if ($lastSpace -ge $minimumCharacters) {
        return ($cut.Substring(0, $lastSpace).Trim() + "...")
    }

    return ($cut.Trim() + "...")
}

function Get-CharacterBio {
    param (
        [object]$character,
        [int]$minimumCharacters = 250,
        [int]$maximumCharacters = 700
    )

    $bioParts = @()

    # Prefer full description because deck is often too short.
    # Convert description HTML into clean text blocks while preserving paragraph and heading boundaries.
    $descriptionBlocks = Convert-HtmlToTextBlocks -html $character.description

    foreach ($block in $descriptionBlocks) {
        if ([string]::IsNullOrWhiteSpace($block)) {
            continue
        }

        # Once we hit sections like "Major Story Arcs", stop.
        # This prevents the README from including everything.
        if (Test-BioStopHeading -text $block) {
            break
        }

        # Skip heading labels like "Origin" or "Creation".
        if (Test-BioHeading -text $block) {
            continue
        }

        # Skip tiny fragments that are unlikely to be useful bio content.
        if ($block.Length -lt 40) {
            continue
        }

        $bioParts += $block

        $currentBio = Normalize-PlainText -text ($bioParts -join " ")

        if ($currentBio.Length -ge $minimumCharacters) {
            return Limit-BioLength -text $currentBio -minimumCharacters $minimumCharacters -maximumCharacters $maximumCharacters
        }
    }

    # Fallback to deck only if it is already long enough to be useful.
    $deck = Normalize-PlainText -text $character.deck
    if ($deck.Length -ge $minimumCharacters) {
        return Limit-BioLength -text $deck -minimumCharacters $minimumCharacters -maximumCharacters $maximumCharacters
    }

    # If neither description intro nor deck produces a coherent minimum-length bio,
    # return empty so the character is rejected by the candidate check.
    return ""
}

function Get-RandomCharacter {
    $batchSize = 100
    $maxAttempts = 5

    try {
        # Get the total number of DC characters, publisher ID 10.
        $countResponse = Get-ComicVineApiData -endpoint "characters" -queryParams @{ filter = "publisher:10" }
        $total = [int]$countResponse.number_of_total_results
        if ($total -le 0) { throw "Comic Vine returned no DC Comics characters (publisher 10)." }

        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            # Pick a random offset and fetch a batch of characters to filter locally.
            $maxOffset = [Math]::Max(0, $total - $batchSize)
            $randomOffset = Get-Random -Minimum 0 -Maximum ($maxOffset + 1)

            $response = Get-ComicVineApiData -endpoint "characters" -queryParams @{
                offset = $randomOffset
                limit  = $batchSize
                filter = "publisher:10"
            }

            # Filter the batch for characters that meet quality criteria.
            # The bio check uses cleaned, section-aware text.
            # .Length includes spaces.
            $candidates = @($response.results | Where-Object {
                $characterBio = Get-CharacterBio -character $_ -minimumCharacters $MinimumBioCharacters -maximumCharacters $MaximumBioCharacters

                $_.publisher.id -eq 10 -and
                -not [string]::IsNullOrWhiteSpace($characterBio) -and
                $characterBio.Length -ge $MinimumBioCharacters -and
                $null -ne $_.first_appeared_in_issue -and
                $null -ne $_.image -and
                $null -ne $_.image.medium_url -and
                $_.image.medium_url -notlike "*image_not_available*" -and
                $null -ne $_.site_detail_url -and
                $_.site_detail_url -ne ""
            })

            if ($candidates.Count -gt 0) {
                return ($candidates | Get-Random)
            }

            Write-Verbose "No suitable characters in batch at offset $randomOffset. Attempt $attempt of $maxAttempts."
        }

        throw "Could not find a suitable character after $maxAttempts batch attempts."
    }
    catch {
        throw $_
    }
}

function Get-FirstCharacterComic {
    param (
        [object]$character
    )

    if ($null -eq $character.first_appeared_in_issue) {
        return $null
    }

    $issueId = $character.first_appeared_in_issue.id

    if ($null -eq $issueId) {
        return $null
    }

    $issueResponse = Get-ComicVineApiData -endpoint "issues" -queryParams @{
        filter = "id:$issueId"
        limit  = 1
    }

    return $issueResponse.results | Select-Object -First 1
}

function Test-URL {
    param (
        [string]$url
    )

    try {
        Wait-BeforeApiCall
        $request = Invoke-WebRequest -Uri $url -Method Head -ErrorAction SilentlyContinue

        if ($request.StatusCode -eq 200) {
            return $url
        }
    }
    catch {
        return $null
    }
}

Function Save-CharacterData {
    param (
        [object]$character,
        [object]$firstComic
    )

    $characterName = $character.name

    # Use the same cleaned, coherent bio helper that the candidate check uses.
    $characterDescription = Get-CharacterBio -character $character -minimumCharacters $MinimumBioCharacters -maximumCharacters $MaximumBioCharacters

    $characterImageURL = $character.image.medium_url

    Wait-BeforeApiCall
    Invoke-WebRequest -Uri $characterImageURL -OutFile "character.jpg" -TimeoutSec 60

    $firstComicTitle = $null
    $firstComicDescription = $null
    $releaseDate = $null

    if ($null -ne $firstComic) {
        $volumeName = $firstComic.volume.name
        $issueNumber = $firstComic.issue_number

        if ($null -ne $volumeName -and $null -ne $issueNumber) {
            $firstComicTitle = $volumeName + " #" + $issueNumber
        }
        elseif ($null -ne $volumeName) {
            $firstComicTitle = $volumeName
        }
        else {
            $firstComicTitle = $firstComic.name
        }

        $firstComicDescription = $firstComic.deck

        if ($null -eq $firstComicDescription -or $firstComicDescription -eq "") {
            $firstComicDescription = Remove-HtmlTags -html $firstComic.description
        }

        $releaseDate = $firstComic.cover_date

        try {
            $releaseDate = [DateTime]::Parse($releaseDate).ToShortDateString()
        }
        catch {
            $releaseDate = $null
        }
    }

    $characterUrl = $character.site_detail_url
    #$comicsUrl = if ($null -ne $firstComic) { $firstComic.site_detail_url } else { $null }

    #$comicsUrlQrCode = $null
    $characterUrlQrCode = $null

    if ($null -ne $characterUrl -and $characterUrl -ne "") {
        #$characterUrl = Test-URL -url $characterUrl
        #if ($null -ne $characterUrl -and $characterUrl -ne "") {
            $characterUrlQrCode = Save-QRCode -url $characterUrl -fileName "characterQR"
        #}
    }

    $date = Get-Date -Format "yyyy"
    $attribution = "Data provided by Comic Vine. © $date Comic Vine"

    $characterObject = [PSCustomObject]@{
        Name                  = $characterName
        Description           = $characterDescription
        ImageURL              = $characterImageURL
        FirstComicTitle       = $firstComicTitle
        #FirstComicDescription = $firstComicDescription
        FirstAppearance       = $releaseDate
        #WikiURL               = $null
        #ComicsURL             = $comicsUrl
        CharacterURL          = $characterUrl
        #WikiURLQRCode         = $null
        #ComicsURLQRCode       = $comicsUrlQrCode
        CharacterURLQRCode    = $characterUrlQrCode
        Date                  = $date
        UpdatedAt             = (Get-Date).ToUniversalTime().ToString("o")
        Status                = "ok"
        Attribution           = $attribution
    }

    # Save character data to a JSON file.
    $characterObject | ConvertTo-Json -Depth 10 | Set-Content -Path ".\DCCharacterOfTheDay.json" -Force

    return $characterObject
}

function Save-QRCode {
    param (
        [string]$url,
        [string]$fileName
    )

    $qrCode = $fileName + ".jpg"
    $qrCodeUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&format=jpg&data=$([Uri]::EscapeDataString($url))"

    #Wait-BeforeApiCall
    Invoke-WebRequest -Uri $qrCodeUrl -OutFile $qrCode -TimeoutSec 60

    return $qrCode
}

function Invoke-RandomCharacterProcessing {
    $randomCharacter = Get-RandomCharacter
    $firstComic = Get-FirstCharacterComic -character $randomCharacter
    Save-CharacterData -character $randomCharacter -firstComic $firstComic
}

Invoke-RandomCharacterProcessing