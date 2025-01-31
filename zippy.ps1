param (
    # To unset any parameter (use default prompt), set to $null:

    # Root folder where the script will search for zip files.
    # Example of setting the default value using the current user's Documents folder:
    # "$env:USERPROFILE\Documents"
    # Example of setting the default value with a C:\ type path (including spaces):
    # "C:\Users\YourName\My Documents"
    [string]$rootFolder = $null,   
    
    # Path to the log file where the script will log messages.
    # Example of setting the default value using the current user's Documents folder:
    # "$env:USERPROFILE\Documents\processlog.txt"
    # Example of setting the default value with a C:\ type path (including spaces):
    # "C:\Users\YourName\My Documents\processlog.txt"
    [string]$logFilePath = $null,   
    
    # Maximum number of retries for a failed action.
    # Example of setting the default value: 3
    [int]$maxRetries = $null,       
   
    # Switch to indicate whether zip files should be deleted after processing.
    # Example of setting the default value: $true (or $false)
    [switch]$deleteZipFiles = $null,  
    
    # Test mode to limit the number of files processed.
    # Example of setting the default value: 10 (to process only 10 files for testing)
    [int]$testMode = $null,         
    
    # Process mode for how files are handled. Options: "validate-only", "validate-after", or "normal"
    # Example of setting the default value: "normal"
    [ValidateSet("validate-only", "validate-after", "normal")]
    [string]$processMode = $null    
)

# Function to log messages to both the console and a log file
function Log-Message {
    param (
        [string]$message,   # The message to log
        [string]$level = "INFO"  # Default level for the message (INFO by default)
    )
    
    # Get the current date and time, and format the log message
    $logMessage = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) [$level] $message"
    
    # Output the message to the console
    Write-Host $logMessage
    
    # Append the message to the log file
    Add-Content -Path $logFilePath -Value $logMessage
}

# Function to prompt the user for input if the parameter is missing
function Prompt-ForInput {
    param (
        [string]$promptMessage,  # Message to display to the user
        [string]$defaultValue,   # Default value to use if the user does not provide any input
        [scriptblock]$validateScript = { $true }  # A script to validate the input
    )
    
    # Ask for user input, showing the default value in parentheses
    $input = Read-Host "$promptMessage (default: $defaultValue)"
    
    # If the user leaves it blank, return the default value
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $defaultValue
    }

    # If a validation script is provided, run it to check the input
    if ($validateScript -and -not (&$validateScript $input)) {
        Write-Host "Invalid input. Please try again." -ForegroundColor Red
        return Prompt-ForInput -promptMessage $promptMessage -defaultValue $defaultValue -validateScript $validateScript
    }
    
    # Return the user's input
    return $input
}

# Function to prompt for a yes/no response
function Prompt-ForBoolean {
    param (
        [string]$promptMessage  # Message to display to the user
    )
    
    # Array of valid answers
    $validAnswers = @("Y", "N")
    do {
        # Prompt for yes/no answer
        $response = Read-Host "$promptMessage (Y/N)"
    } while ($response -notin $validAnswers)

    # Return true if the response was "Y"
    return $response -eq "Y"
}

# Function to compare files and check if they need to be overwritten
function Should-OverwriteFile {
    param (
        [string]$sourceFile,  # Path to the source file
        [string]$destinationFile  # Path to the destination file
    )

    if (-not (Test-Path $destinationFile)) {
        return $true  # If destination file doesn't exist, overwrite
    }

    # Compare file hashes to check if they are the same
    $sourceHash = Get-FileHash -Path $sourceFile
    $destinationHash = Get-FileHash -Path $destinationFile

    return $sourceHash.Hash -ne $destinationHash.Hash  # Return true if hashes are different
}

# Function to safely move files with logging
function Move-FileWithLogging {
    param (
        [string]$sourcePath,  # Path to the source file or folder
        [string]$destinationPath  # Path to the destination file or folder
    )

    if (Test-Path $destinationPath) {
        Write-Host "Skipping: $sourcePath (already exists)" -ForegroundColor Yellow
        Log-Message "Skipped: $sourcePath (already exists)"
    }
    else {
        Write-Host "Moving: $sourcePath to $destinationPath" -NoNewline -ForegroundColor Cyan
        Move-Item -Path $sourcePath -Destination $destinationPath
        Write-Host " Done" -ForegroundColor Green
        Log-Message "Moved: $sourcePath to $destinationPath"
    }
}

# Function to process the root folder and all subfolders
function Process-Folder {
    param (
        [string]$folderPath  # Path to the folder to process
    )

    # Log that we are starting to search in this folder
    Log-Message "Searching folder: $folderPath"

    # Get all zip files in the current folder (and subfolders)
    $zipFiles = Get-ChildItem -Path $folderPath -Recurse -Filter "*.zip"
    
    # Log the files found
    if ($zipFiles.Count -gt 0) {
        $zipFiles | ForEach-Object {
            Log-Message "Found zip file: $($_.FullName)"
        }
    } else {
        Log-Message "No zip files found in: $folderPath"
    }
    
    return $zipFiles
}

# Function to try processing with retry logic
function Try-Process {
    param (
        [scriptblock]$Action,  # The action to try
        [int]$maxRetries = 3   # The maximum number of retries
    )
    
    $attempt = 1
    while ($attempt -le $maxRetries) {
        try {
            & $Action  # Execute the action
            return $true  # Successfully executed
        }
        catch {
            Write-Host "Attempt $attempt failed: $_" -ForegroundColor Red
            if ($attempt -eq $maxRetries) {
                Write-Host "Max retries reached. Aborting..." -ForegroundColor Red
                return $false
            }
            else {
                Write-Host "Retrying... ($attempt of $maxRetries)" -ForegroundColor Yellow
            }
        }
        $attempt++
    }
}

# Function to process zip files based on modes
function Process-ZipFile {
    param (
        [string]$zipFilePath  # Path to the zip file to process
    )

    $zipFile = Get-Item -Path $zipFilePath
    $accountFolder = $zipFile.DirectoryName
    $accountName = [System.IO.Path]::GetFileName($accountFolder)
    $tempFolder = [System.IO.Path]::Combine($accountFolder, "temp_takeout")
    $takeoutFolder = [System.IO.Path]::Combine($tempFolder, "takeout")

    # Log the start of the account processing
    Write-Host -NoNewline "Processing account: $accountName - "
    Log-Message "Starting processing for account: $accountName"

    # Clean up any pre-existing temp folder
    Write-Host -NoNewline "Cleaning up temp folder if exists... "
    Try-Process -Action {
        if (Test-Path $tempFolder) {
            Remove-Item -Path $tempFolder -Recurse -Force
            Write-Host "Done" -ForegroundColor Green
        } else {
            Write-Host "Temp folder not found." -ForegroundColor Yellow
        }
    }

    # Extract the zip file to the temp folder
    Write-Host -NoNewline "Extracting zip file... "
    $extracted = Try-Process -Action {
        Expand-Archive -Path $zipFile.FullName -DestinationPath $tempFolder -Force
        Write-Host "Done" -ForegroundColor Green
    }

    if ($extracted) {
        # Move items from the "takeout" folder to the account folder
        if (Test-Path $takeoutFolder) {
            Write-Host -NoNewline "Moving 'takeout' contents... "
            Get-ChildItem -Path $takeoutFolder | ForEach-Object {
                $item = $_
                $destinationPath = [System.IO.Path]::Combine($accountFolder, $item.Name)

                # Skip or move based on mode
                if ($processMode -eq "validate-only") {
                    Write-Host "Validation-only mode: Skipping move for $destinationPath" -ForegroundColor Yellow
                    Log-Message "Validation-only: Skipped $destinationPath"
                }
                elseif ($processMode -eq "validate-after" -and (Should-OverwriteFile -sourceFile $item.FullName -destinationFile $destinationPath)) {
                    Write-Host "Validation-after mode: Validating $destinationPath" -ForegroundColor Yellow
                    Log-Message "Validation-after: Validating $destinationPath"
                }
                elseif (Should-OverwriteFile -sourceFile $item.FullName -destinationFile $destinationPath) {
                    Move-FileWithLogging -sourcePath $item.FullName -destinationPath $destinationPath
                }
                else {
                    Write-Host "Skipping: $destinationPath (no change)" -ForegroundColor Yellow
                    Log-Message "Skipped: $destinationPath (no change)"
                }
            }
        }
    }
}

# Prompt for missing parameters
if (-not $rootFolder) {
    $rootFolder = Prompt-ForInput -promptMessage "Enter the root folder path" -defaultValue "$env:USERPROFILE\Documents"
}

if (-not $logFilePath) {
    $logFilePath = Prompt-ForInput -promptMessage "Enter the log file path" -defaultValue (Join-Path -Path $env:TEMP -ChildPath "processlog.txt")
}

if (-not $maxRetries) {
    $maxRetries = [int](Prompt-ForInput -promptMessage "Enter the maximum number of retries" -defaultValue "3" -validateScript { $_ -match '^\d+$' })
}

if (-not $deleteZipFiles) {
    $deleteZipFiles = Prompt-ForBoolean -promptMessage "Do you want to delete zip files after processing?"
}

if (-not $processMode) {
    $processMode = Prompt-ForInput -promptMessage "Select the process mode" -defaultValue "normal" -validateScript { $_ -in @("normal", "validate-only", "validate-after") }
}

# Log the parameters
Log-Message "Using the following parameters:"
Log-Message "Root Folder: $rootFolder"
Log-Message "Log File: $logFilePath"
Log-Message "Max Retries: $maxRetries"
Log-Message "Delete Zip Files: $deleteZipFiles"
Log-Message "Process Mode: $processMode"

# Process the root folder and subfolders for zip files
$zipFiles = Process-Folder -folderPath $rootFolder

$maxParallelJobs = 5
$jobs = @()
$batchCount = 0

# Process zip files in parallel with batching
if ($zipFiles.Count -gt 0) {
    foreach ($zipFile in $zipFiles) {
        $zipFilePath = $zipFile.FullName
        
        # Check for test mode
        if ($testMode -gt 0 -and $jobs.Count -ge $testMode) {
            Log-Message "Test mode active, halting after $testMode files."
            break
        }

        # Start a new job for processing
        $jobs += Start-Job -ScriptBlock {
            param ($zipFilePath)
            Process-ZipFile -zipFilePath $zipFilePath
        } -ArgumentList $zipFilePath

        $batchCount++

        # Manage parallel job batches
        if ($batchCount -ge $maxParallelJobs) {
            $jobs | Wait-Job | Out-Null
            $jobs | Remove-Job
            $jobs = @()
            $batchCount = 0
        }
    }

    # Ensure remaining jobs are processed
    if ($jobs.Count -gt 0) {
        $jobs | Wait-Job | Out-Null
        $jobs | Remove-Job
    }

    Log-Message "Script execution completed."
} else {
    Log-Message "No zip files were found to process."
}

Write-Host "All zip files processed successfully."
