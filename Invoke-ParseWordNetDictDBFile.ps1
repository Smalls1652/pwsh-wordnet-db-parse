
<#PSScriptInfo

.VERSION 2022.08.00

.GUID 4195b17d-b6f7-420f-b96a-93249a971dfc

.AUTHOR Tim Small

.COMPANYNAME Smalls.Online

.COPYRIGHT 2022

.TAGS wordnet dictionary parser english

.LICENSEURI https://raw.githubusercontent.com/Smalls1652/pwsh-wordnet-db-parse/main/LICENSE

.PROJECTURI https://github.com/Smalls1652/pwsh-wordnet-db-parse

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#
.SYNOPSIS
    Parse Princeton's WordNet® 3.1 database files.
.DESCRIPTION
    Get a list of English dictionary words by parsing Princeton's WordNet® 3.1 database files.
.PARAMETER DbDirectoryPath
    The path to where the database files are located.
.EXAMPLE
    .\Invoke-ParseWordNetDictDBFile.ps1 -DbDirectoryPath ".\replace\with\path\" -Verbose

    Parses the database files and returns them to console.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DbDirectoryPath
)

class WordNetDbIndexItem {
    [string]$Value
    [string]$Category
    [int]$NumOfWords

    WordNetDbIndexItem([string]$inputLine) {
        # Regex for parsing the line.
        $entryRegex = [regex]::new("^(?'word'\S+)\s(?'category'[nvasr]).+$")

        # Run the regex query on the line provided.
        $entryMatch = $entryRegex.Match($inputLine)

        if (!$entryMatch.Success) {
            # If the match wasn't successful, then throw an error.
            throw [System.Exception]::new("Line '$($inputLine)' failed to parse the entire line.")
        }
        else {
            # Otherwise, start setting the properties of the item.

            # Replace any '_' characters in the word with ' ',
            # then set it to the `Value` property.
            $this.Value = $entryMatch.Groups["word"].Value.Replace("_", " ")

            # Make the captured 'category' value human readable,
            # then set it to the `Category` property.
            switch ($entryMatch.Groups["category"].Value) {
                # 'n' = "Noun"
                "n" {
                    $this.Category = "Noun"
                    break
                }

                # 'v' = "Verb"
                "v" {
                    $this.Category = "Verb"
                    break
                }

                # 'a' = "Adjective"
                "a" {
                    $this.Category = "Adjective"
                    break
                }

                # 'r' = "Adverb"
                "r" {
                    $this.Category = "Adverb"
                    break
                }

                # If it matches anything else, throw an error.
                Default {
                    throw [System.Exception]::new("Line '$($inputLine)' failed to parse the category.")
                    break
                }
            }

            # Count the number of words,
            # then set it to the `NumOfWords` property.
            # 
            # This will make it a little bit easier to filter out any items
            # that have more than '1' word after the parse, if needed. This is because the DB
            # defines both a word and collocations as entries.
            $this.NumOfWords = ($this.Word.Split(" ") | Measure-Object).Count
        }
    }
}

# Attempt to resolve the path to the provided directory.
# If it fails to resolve, throw an error.
Write-Verbose "Trying to resolve the path to the provided file."
$dbDirPathResolved = (Resolve-Path -Path $DbDirectoryPath -ErrorAction "Stop").Path

# Check to ensure the supplied path is a directory.
# If it isn't, throw an error.
$dbDirItem = Get-Item -Path $dbDirPathResolved
if ([System.IO.FileAttributes]::Directory -notin $dbDirItem.Attributes) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileFormatException]::new("Provided path is not a directory."),
            "PathIsNotDir",
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $dbDirItem
        )
    )
}

# Get all files with the name "index", except for "index.sense".
$indexFiles = Get-ChildItem -Path $dbDirPathResolved | Where-Object { ($PSItem.BaseName -eq "index") -and ($PSItem.Extension -ne ".sense") }

# If no "index" files were found, throw an error.
if ($null -eq $indexFiles) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.FileNotFoundException]::new("No suitable files were found at the provided path."),
            "NoFilesFound",
            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
            $dbDirPathResolved
        )
    )
}

# Initialize a regex object for determining if the line is
# a license statement line.
$dbLicenseLineRegex = [regex]::new("^\s{2}.+$")

# Loop through each "index" file.
foreach ($indexFileItem in $indexFiles) {
    # Get the string contents of the file.
    Write-Verbose "Getting the contents of '$($indexFileItem.Name)'."
    $dbFileContents = Get-Content -Path $indexFileItem.FullName

    # Loop through each line and parse it.
    Write-Verbose "Parsing each line in '$($indexFileItem.Name)'."
    foreach ($dbFileLineItem in $dbFileContents) {
        # Only continue if the line doesn't match the license statement portion of the DB file.
        if (!$dbLicenseLineRegex.IsMatch($dbFileLineItem)) {
            try {
                # Write the parsed line to output.
                Write-Output -InputObject ([WordNetDbIndexItem]::new($dbFileLineItem))
            }
            catch [System.Exception] {
                # If an exception is thrown, write a warning message instead of an error.
                $errorDetails = $PSItem
                Write-Warning $errorDetails.Exception.Message
            }
        }
    }
}

Write-Verbose "Finished."