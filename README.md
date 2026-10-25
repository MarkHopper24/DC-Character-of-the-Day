# DC Character of the Day
  [![Fetch DC Character Of The Day](https://github.com/MarkHopper24/DC-Character-of-the-Day/actions/workflows/DCCharacterOTDFetcher.yml/badge.svg)](https://github.com/MarkHopper24/DC-Character-of-the-Day/actions/workflows/DCCharacterOTDFetcher.yml)
<p align="center">
<img src="https://upload.wikimedia.org/wikipedia/commons/3/3d/DC_Comics_logo.svg" alt="DC Logo" width="350" height="auto">
</p>

## Waiting for the first daily character

The first successful workflow run will publish a DC character here.

<h2>What is this repository?</h2>
DC Character of the Day is a PowerShell-based application hosted in GitHub that provides information about a different DC character each day. The repository picks a random character daily @ 5am UTC.

<h3>Features</h3>

- <b>Daily DC Character Information:</b> Fetches and displays information about a random DC character every day from ComicVine's API.

- <b>Automated Scripts:</b> Uses PowerShell scripts and GitHub Workflow Actions to automate the process of retrieving and displaying character data.
  
- <b>Friendly JSON Endpoint:</b> Offers an easily retrievable endpoint containing a JSON file with the Daily Character information. You can find this here: https://raw.githubusercontent.com/MarkHopper24/DC-Character-of-the-Day/refs/heads/main/DCCharacterOfTheDay.json
  
- <b>TRMNL Integration:</b> Offers Liquid templates for usage with [TRMNL](https://usetrmnl.com). To use this data for a plugin, you can either:
    1. Create a custom plugin with the polling strategy pointing to the JSON endpoint above. Copy the contents of the files in the .\templates folder to your plugin's markup, and you're done.
    2. Use the companion DC Character of the Day private plugin in TRMNL.
<!-- Verified DC preview will be added after the first render. -->

<h3>Attribution</h3>
Data provided by Comic Vine https://comicvine.gamespot.com. © 2026 DC Comics
This project and repository has no affiliation with DC.


## Setup

Add your Comic Vine API key as the repository Actions secret [COMICVINEAPIKEY](https://github.com/MarkHopper24/DC-Character-of-the-Day/settings/secrets/actions). Then run **Fetch DC Character Of The Day** from the Actions tab. The workflow runs daily at 05:00 UTC and can also be run manually.

The updater uses Comic Vine publisher ID 10 (DC Comics), keeps the same character JSON fields as the Marvel companion, and adds UpdatedAt and Status for display freshness. character.jpg is the portrait; characterQR.jpg is the Comic Vine character-page QR code. A failed fetch leaves the previously published character unchanged.

The four layout templates use TRMNL Framework 3.4. Copy templates/shared.liquid to Shared and the matching HTML templates to Full, Half Horizontal, Half Vertical, and Quadrant. templates/settings.yml contains the polling settings.

Companion project: [Marvel Character of the Day](https://github.com/MarkHopper24/Marvel-Character-of-the-Day).
