Add-Type -AssemblyName PresentationFramework

# Create the WPF window
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
$window = New-Object Windows.Window
$window.Title = "CrowdStrike Recovery Tool | gokhanyildan.com"
$window.SizeToContent = "WidthAndHeight"
$window.ResizeMode = "NoResize"

# Create a stack panel to arrange the controls vertically
$stackPanel = New-Object Windows.Controls.StackPanel
$stackPanel.Orientation = "Vertical"
$stackPanel.Margin = "10"

# Information text block
$infoText = New-Object Windows.Controls.TextBlock
$infoText.Text = "If your device is BitLocker encrypted, use your phone to log on to https://aka.ms/aadrecoverykey. 
Log on with your Email ID and domain account password to find the BitLocker recovery key associated with your device."
$infoText.TextWrapping = "Wrap"
$infoText.Margin = "0,10,0,10"
$stackPanel.Children.Add($infoText)

# BitLocker ID label
$bitlockerIdLabel = New-Object Windows.Controls.TextBlock
$bitlockerIdLabel.Text = "BitLocker ID: "
$bitlockerIdLabel.Visibility = "Collapsed"
$stackPanel.Children.Add($bitlockerIdLabel)

# BitLocker not found label
$bitlockerNotFoundLabel = New-Object Windows.Controls.TextBlock
$bitlockerNotFoundLabel.Text = "BitLocker Encryption Not Found"
$bitlockerNotFoundLabel.Visibility = "Collapsed"
$stackPanel.Children.Add($bitlockerNotFoundLabel)

# Recovery key prompt
$recoveryKeyLabel = New-Object Windows.Controls.TextBlock
$recoveryKeyLabel.Text = "Enter recovery key for this drive if required: (Place hyphen(-) manually. Example xxxxxx-xxxxxx)"
$stackPanel.Children.Add($recoveryKeyLabel)

# TextBox for recovery key input
$recoveryKeyBox = New-Object Windows.Controls.TextBox
$recoveryKeyBox.Width = 400
$stackPanel.Children.Add($recoveryKeyBox)

# Button to proceed
$proceedButton = New-Object Windows.Controls.Button
$proceedButton.Content = "Unlock Drive and Clean Up"
$proceedButton.Margin = "0,10,0,0"
$stackPanel.Children.Add($proceedButton)

# Add stack panel to window
$window.Content = $stackPanel

# Function to check BitLocker status and update the UI
function Check-BitLockerStatus {
    $drive = "C:"
    
    # Check if manage-bde is available
    if (-not (Get-Command manage-bde -ErrorAction SilentlyContinue)) {
        $bitlockerNotFoundLabel.Text = "BitLocker is not available on this system."
        $bitlockerNotFoundLabel.Visibility = "Visible"
        return
    }

    # Try to get BitLocker recovery key information
    try {
        $recoveryInfo = manage-bde -protectors $drive -get -Type RecoveryPassword 2>&1
        if ($recoveryInfo -match "No key protectors found") {
            $bitlockerNotFoundLabel.Visibility = "Visible"
        } elseif ($recoveryInfo -match "ID: (\S+)") {
            $bitlockerId = ($recoveryInfo | Select-String -Pattern 'ID: (\S+)').Matches.Groups[1].Value
            $bitlockerIdLabel.Text = "BitLocker ID: $bitlockerId"
            $bitlockerIdLabel.Visibility = "Visible"
        } else {
            $bitlockerNotFoundLabel.Text = "BitLocker Encryption Not Found or Unable to retrieve ID."
            $bitlockerNotFoundLabel.Visibility = "Visible"
        }
    } catch {
        $bitlockerNotFoundLabel.Text = "Error retrieving BitLocker status."
        $bitlockerNotFoundLabel.Visibility = "Visible"
    }
}

# Button click event
$proceedButton.Add_Click({
    $drive = "C:"
    $reckey = $recoveryKeyBox.Text

    # Function to show a message box
    function Show-MessageBox {
        param (
            [string]$message,
            [string]$title = "Information"
        )
        [System.Windows.MessageBox]::Show($message, $title)
    }

    # Unlock the drive if the recovery key is provided
    if ($reckey) {
        manage-bde -unlock $drive -recoverypassword $reckey
    }

    # Perform the cleanup operation
    Remove-Item "$drive\Windows\System32\drivers\CrowdStrike\C-00000291*.sys" -Force -ErrorAction SilentlyContinue
    Show-MessageBox -message "Done performing cleanup operation."

    # Close the window
    $window.Close()
})

# Show the WPF window and check BitLocker status on load
$window.add_Loaded({
    Check-BitLockerStatus
})
[void]$window.ShowDialog()
