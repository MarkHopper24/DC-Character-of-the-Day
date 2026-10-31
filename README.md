# DC Character of the Day
  [![Fetch DC Character Of The Day](https://github.com/MarkHopper24/DC-Character-of-the-Day/actions/workflows/DCCharacterOTDFetcher.yml/badge.svg)](https://github.com/MarkHopper24/DC-Character-of-the-Day/actions/workflows/DCCharacterOTDFetcher.yml)
<p align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/3/3d/DC_Comics_logo.svg" alt="DC Logo" width="350" height="auto">
</p>

## Patrick Wayne
<p align="center">
<img src="https://comicvine.gamespot.com/a/uploads/scale_medium/11114/111147698/4521161-screen%20shot%202015-04-21%20at%207.51.43%20pm.jpg" width="600" height="auto"/>
</p>

Patrick Wayne is the father of Thomas Wayne and grandfather to Bruce Wayne. He is the eldest son of Kenneth and Elizabeth Wayne. His father developed Wayne Chemical, but died at a fairly young age leaving the fortune to his 37-year-old wife Laura Wayne. Laura was a shrewd businesswoman and heavily involved in the Prohibition movement, while raising their infant son. Patrick inherited the family business upon his mother's death. He was the creator of Wayne Tech which helped support both World Wars. Later, he would combine the Wayne resources to create Wayne Corp. He worked closely with his brother Silas Wayne.

**First Appearance:** Batman Secret Files #1 (10/1/1997)

[Character Details](https://comicvine.gamespot.com/patrick-wayne/4005-117754/)

<h2>What is this repository?</h2>
DC Character of the Day is a PowerShell-based application hosted in GitHub that provides information about a different DC character each day. The repository picks a random character daily @ 5am UTC.

<h3>Features</h3>

- <b>Daily DC Character Information:</b> Fetches and displays information about a random DC character every day from ComicVine's API.

- <b>Automated Scripts:</b> Uses PowerShell scripts and GitHub Workflow Actions to automate the process of retrieving and displaying character data.
  
- <b>Friendly JSON Endpoint:</b> Offers an easily retrievable endpoint containing a JSON file with the Daily Character information. You can find this here: https://raw.githubusercontent.com/MarkHopper24/DC-Character-of-the-Day/refs/heads/main/DCCharacterOfTheDay.json
  
- <b>TRMNL Integration:</b> Offers Liquid templates for usage with [TRMNL](https://usetrmnl.com). To use this data for a plugin, you can either:
    1. Create a custom plugin with the polling strategy pointing to the JSON endpoint above. Copy the contents of the files in the .\templates folder to your plugin's markup, and you're done.
    2. Use the companion DC Character of the Day private plugin in TRMNL.
<p align="center">
<img src="https://raw.githubusercontent.com/MarkHopper24/DC-Character-of-the-Day/refs/heads/main/templates/trmnlPluginScreenshot.jpg" width="400" height="auto"/><br>
(Sample TRMNL screenshot)
</p>

<h3>Attribution</h3>
Data provided by Comic Vine https://comicvine.gamespot.com. © 2026 DC Comics
This project and repository has no affiliation with DC.


## Setup

Add your Comic Vine API key as the repository Actions secret [COMICVINEAPIKEY](https://github.com/MarkHopper24/DC-Character-of-the-Day/settings/secrets/actions). Then run **Fetch DC Character Of The Day** from the Actions tab. The workflow runs daily at 05:00 UTC and can also be run manually.

The updater uses Comic Vine publisher ID 10 (DC Comics), keeps the same character JSON fields as the Marvel companion, and adds UpdatedAt and Status for display freshness. character.jpg is the portrait; characterQR.jpg is the Comic Vine character-page QR code. A failed fetch leaves the previously published character unchanged.

The four layout templates mirror the current Marvel plugin markup and use the same TRMNL Framework 3.0.5 version. Clear Shared (templates/shared.liquid is intentionally empty) and copy the matching HTML templates to Full, Half Horizontal, Half Vertical, and Quadrant. templates/settings.yml contains the polling settings.

Companion project: [Marvel Character of the Day](https://github.com/MarkHopper24/Marvel-Character-of-the-Day).
