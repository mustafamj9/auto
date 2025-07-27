# ---------------- CONFIG ----------------
$sourceStorageAccount = ""
$sourceKey = ""
$destinationStorageAccount = ""
$destinationKey = ""

$shareName = ""
$directoryPath = ""  # Subfolder to copy (inside share)

# ---------------- LOGIN ----------------
# No login needed — using storage keys

# ---------------- CREATE STORAGE CONTEXTS ----------------
$sourceContext = New-AzStorageContext -StorageAccountName $sourceStorageAccount -StorageAccountKey $sourceKey
$destinationContext = New-AzStorageContext -StorageAccountName $destinationStorageAccount -StorageAccountKey $destinationKey

# ---------------- GET FILES & FOLDERS RECURSIVELY ----------------
function Copy-AzFileShareDirectoryRecursive {
    param (
        [string]$sourceShare,
        [string]$destinationShare,
        [string]$relativePath
    )

    $files = Get-AzStorageFile -ShareName $sourceShare -Path $relativePath -Context $sourceContext -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $fullPath = if ($relativePath) { "$relativePath/$($file.Name)" } else { $file.Name }

        if ($file.GetType().Name -eq "AzureStorageFileDirectory") {
            # Create directory at destination
            New-AzStorageFileDirectory -ShareName $destinationShare -Path $fullPath -Context $destinationContext -ErrorAction SilentlyContinue
            # Recurse into subfolder
            Copy-AzFileShareDirectoryRecursive -sourceShare $sourceShare -destinationShare $destinationShare -relativePath $fullPath
        }
        else {
            # It's a file – copy it
            Start-AzStorageFileCopy `
                -SrcShareName $sourceShare `
                -SrcFilePath $fullPath `
                -DestShareName $destinationShare `
                -DestFilePath $fullPath `
                -SrcContext $sourceContext `
                -DestContext $destinationContext
        }
    }
}

# ---------------- RUN COPY ----------------
Copy-AzFileShareDirectoryRecursive -sourceShare $shareName -destinationShare $shareName -relativePath $directoryPath

Write-Output "✅ File Share content from '$directoryPath' copied from $sourceStorageAccount to $destinationStorageAccount"
