# WordNet® Dictionary DB File Parser

Threw this script together for parsing the database files from [Princeton's WordNet® 3.1 dictionary](https://wordnet.princeton.edu/). It's not perfect and I might be missing a few things, but I wanted to generate a word list to use in some other things I'm making and this was the quickest and easiest way. It only gets the words and what category the word is in (Noun, verb, adjective, and adverb), so no definitions or any other data contained in the database files.

There should be `155,467` English words parsed from the files.

## Pre-requisites

- [PowerShell 7.2](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.2)
  - May work on other versions of PowerShell, but I have only tested this on PowerShell 7.2.
- [WordNet® 3.1 DB files](https://wordnetcode.princeton.edu/wn3.1.dict.tar.gz)

## Usage

To start the parse, you need to extract the `wn3.1.dict.tar.gz` file. Then note the path where the files whose names start with `index.` are located.

Then run the script with the path you noted earlier, like so:

```powershell
$wordNetWords = .\Invoke-ParseWordNetDictDBFile.ps1 -DbDirectoryPath ".\replace\with\path\" -Verbose
```

You can then pipe the `$wordNetWords` variable to other cmdlets, like `ConvertTo-Json`.

## License

The script is licensed with the MIT license, [which can be found here](LICENSE).

Your use of the data parsed from the WordNet® 3.1 database files is subject to their license, [which can be found here](https://wordnet.princeton.edu/license-and-commercial-use).
