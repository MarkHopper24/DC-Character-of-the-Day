<#
.SYNOPSIS
This script updates the README.md file with the DC Character of the Day information.

.DESCRIPTION
This script reads the DCCharacterOfTheDay.json file to get the character information and then updates the README.md file with the character's name, image, description, first appearance, and comic gallery link.

.NOTES
File Name      : ReadMeUpdater.ps1
Author         : Mark Hopper
Prerequisite   : The DCCharacterOfTheDay.json and README.md files should be present in the parent directory.

.EXAMPLE
.\ReadMeUpdater.ps1
#>

# Read the JSON file
$dcCharacter = Get-Content -Path .\DCCharacterOfTheDay.json | ConvertFrom-Json

# Read the existing README content
$readmeContent = Get-Content -Path .\README.md -Raw

# Create the new character section
$characterSection = @"
## $($dcCharacter.Name)
<p align="center">
<img src="$($dcCharacter.ImageURL)" width="600" height="auto"/>
</p>

$($dcCharacter.Description)

**First Appearance:** $($dcCharacter.FirstComicTitle) ($($dcCharacter.FirstAppearance))

[Character Details]($($dcCharacter.CharacterURL))
"@

# Replace the content between the DC logo and "What is this repository?" section
$pattern = "(?s)(?<=<\/p>\r?\n\r?\n).*?(?=<h2>What is this repository\?)"
$newContent = [regex]::Replace($readmeContent, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) "$characterSection`n`n" })

# Save the updated content back to README.md
$newContent | Set-Content -Path .\README.md -NoNewline
