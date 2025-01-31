# Zip File Processor Script

## Overview

Alright, buckle up, because here’s a script that’ll take your ZIP files, untangle them like a messy cable knot, and organize everything with the finesse of a coffee shop barista making the perfect latte. Whether you’re dealing with a mountain of Google Takeout files or just trying to wrangle a bunch of user data into shape, this script is your new best friend.

### Why You Need This (aka When to Use It)

Let’s set the scene: You’ve got a whole bunch of ZIP files. Maybe they’re from Google Takeout (looking at you, folks with 10 years of social media data to unpack), maybe they’re from some other source. Whatever the case, you’ve got one big problem — you need to process these files in bulk **without losing your mind**.

This script is perfect when:
- **Google Takeout unpacking**: Imagine you’ve got hundreds of users’ Takeout files and you need to extract and sort them. We’re talking about tons of ZIP files, each one holding data from different accounts, and you don’t want to sit there manually unpacking and moving files one-by-one like it’s 1999.
  
- **Bulk file processing**: Maybe it’s not Google Takeout — maybe it’s any other batch of ZIPs that needs to be unpacked, processed, and possibly moved around. The script handles it with parallel processing (yes, multitasking!) and logging, so you’ll know exactly what happened, when, and where.

- **Automation for the lazy (or busy)**: Look, we get it. You’re a busy person. Who has time to manually extract files from a thousand ZIPs? This script lets you sit back, relax, and let the magic happen without lifting a finger. Well, except to run the script, of course.

## Features

- **Root Folder Search**: Automatically scans a root folder and all subfolders for ZIP files. No more hunting for that one ZIP file buried in a thousand directories. (We’ve all been there.)
  
- **Logging**: Every step of the way, from “Found ZIP file!” to “Moved file successfully,” gets logged. That means you’ll know exactly what happened, when it happened, and where it happened. 
   
- **Retries**: If something goes wrong (it happens), the script retries up to a certain number of times. Because sometimes, things need a second (or third) chance.  

- **File Processing Modes**:
  - **`normal`**: The whole shebang. Extract, move, and delete if you’re feeling brave.
  - **`validate-only`**: Just check things out. No files get moved, just a nice validation to ensure everything looks good.
  - **`validate-after`**: It’s like the validate-only mode, but with a plot twist: it does the validation *after* moving the files. Suspense, anyone?

- **Test Mode**: You don’t need to process all the files — just a few to make sure things are running smoothly. You can limit it to a specific number of files, and voila! Instant peace of mind.

- **Parallel Processing**: This is where the magic happens. Multiple files processed at once, like a well-oiled machine. It’s fast, it’s efficient, and it won’t make you cry.

- **Delete ZIP Files After Processing**: Feeling bold? You can make the script delete those ZIP files once it’s done, so you don’t have to stare at a folder full of "already processed" files ever again.

## Parameters

### `$rootFolder`
- **Type**: `string`
- **Description**: The root folder where the script will search for ZIP files. Think of it like your home base. All files are born here.
- **Default**: The script will ask you if you don’t specify. Just be sure it’s pointing to where your ZIP files live.

### `$logFilePath`
- **Type**: `string`
- **Description**: The file where everything is logged. Every ZIP file, every move, every mistake will be logged here. You’ll never have to wonder what went wrong.
- **Default**: It’ll ask you. Or, you know, you can just give it a path if you’re feeling fancy.

### `$maxRetries`
- **Type**: `int`
- **Description**: How many times should the script try again if something goes wrong? Default is 3 retries because, honestly, things don’t always go right on the first try.
- **Default**: 3

### `$deleteZipFiles`
- **Type**: `switch`
- **Description**: Do you want to delete the ZIP files after they’ve been processed? Only use this if you’re *absolutely* sure. It’s like clearing out your browser history — once it’s gone, it’s gone.
- **Default**: It'll ask you. But you know you can always say "no" if you're feeling nostalgic about those ZIP files.

### `$testMode`
- **Type**: `int`
- **Description**: Want to process just a few files to test things out? You can set a limit. It’s like dipping your toes in the water before you dive in.
- **Default**: 0, because we don’t limit your ambition. 

### `$processMode`
- **Type**: `string`
- **Description**: Defines how you want the files processed. Choose from:
  - **`normal`**: The full treatment.
  - **`validate-only`**: A soft check, no moving.
  - **`validate-after`**: Validation after the move, for those who like a bit of suspense.
- **Default**: `normal`

## Script Workflow

1. **Prompt for Missing Parameters**: If you forget to set a parameter, don’t worry. The script’s got your back and will ask you for it.
2. **Folder Processing**: It’ll search through the root folder and its subfolders for ZIP files, because we all know they have a way of hiding in obscure places.
3. **File Processing**: Depending on the mode, it’ll either move, validate, or just stare at the files without doing much. All with snazzy logging.
4. **Logging**: Every single action gets logged, so you can go back and see exactly what happened.
5. **Parallel Processing**: Because who wants to wait for one file to process when you can do 5 at once? Multitasking at its finest.

## Functions

### `Log-Message`
This is where all the logging happens. From “file found” to “file moved,” you’ll know everything. Like the gossipy neighbor who sees everything.

### `Prompt-ForInput`
If you forgot to set a parameter, this is the script’s way of politely asking for it.

### `Prompt-ForBoolean`
The good ol’ yes/no question. Very high school dance vibes.

### `Should-OverwriteFile`
Checks if a file should be overwritten or not. Because if it ain’t broke, don’t fix it.

### `Move-FileWithLogging`
Moves your files and logs it for posterity. It’s like your personal assistant, but for files.

### `Process-Folder`
Scours the folder for ZIP files. It’s like a treasure hunt, but without the treasure… just ZIP files.

### `Try-Process`
Tries to process an action with retries. Think of it as your second chance to get things right.

### `Process-ZipFile`
The grand finale! This is where the ZIP file gets processed. Extraction, validation, and moving all happen here. You’ll barely need to lift a finger.

## Example Usage

### 1. Run the script with default parameters:
```powershell
.\ProcessZipFiles.ps1
```

### 2. Run with custom parameters:
```powershell
.\ProcessZipFiles.ps1 -rootFolder "C:\Users\YourName\Documents" -logFilePath "C:\Logs\processlog.txt" -maxRetries 5 -deleteZipFiles -testMode 10 -processMode "validate-only"
```

## Requirements
- PowerShell 5.1 or later
- Proper permissions for the files and directories involved (you don’t want to be locked out like Rory at a Yale party)

## License
- It’s all yours! Enjoy under the MIT License.
