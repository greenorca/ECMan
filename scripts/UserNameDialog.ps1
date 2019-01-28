# source adapted from https://powershell-tips.blogspot.com/2012/10/display-inputbox-with-powershell_23.html?m=1
# create link in C:\Users\student\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
# with powershell.exe -file \path2\UserNameDialog.ps1

function CustomInputBox([string] $title, [string] $message, [string] $defaultText) 
 {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

    $userForm = New-Object System.Windows.Forms.Form
    $userForm.Text = "$title"
    $userForm.Size = New-Object System.Drawing.Size(290,150)
    $userForm.StartPosition = "CenterScreen"
        $userForm.AutoSize = $False
        $userForm.MinimizeBox = $False
        $userForm.MaximizeBox = $False
        $userForm.SizeGripStyle= "Hide"
        $userForm.WindowState = "Normal"
        $userForm.FormBorderStyle="Fixed3D"
     
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(115,80)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({$value=$objTextBox.Text;$userForm.Close()})
    $userForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(195,80)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$userForm.Close()})
    $userForm.Controls.Add($CancelButton)

    $userLabel = New-Object System.Windows.Forms.Label
    $userLabel.Location = New-Object System.Drawing.Size(10,20)
    $userLabel.Size = New-Object System.Drawing.Size(280,20)
    $userLabel.Text = "$message"
    $userForm.Controls.Add($userLabel) 

    $objTextBox = New-Object System.Windows.Forms.TextBox
    $objTextBox.Location = New-Object System.Drawing.Size(10,40)
    $objTextBox.Size = New-Object System.Drawing.Size(260,20)
    $objTextBox.Text="$defaultText"
    $userForm.Controls.Add($objTextBox) 

    $userForm.Topmost = $True
    $userForm.Opacity = 0.91
        $userForm.ShowIcon = $False

    $userForm.Add_Shown({$userForm.Activate()})
    [void] $userForm.ShowDialog()

    $value=$objTextBox.Text 

    return $value

 }


$userInput = CustomInputBox "User Name" "Please enter your name." ""
 if ( $userInput -ne $null ) 
 {
  echo "Input was [$userInput]"
  $file=$env:USERPROFILE+"\candidate.md"
  Set-Content -Path $file -Value [$userInput]
 }
 else
 {
  echo "User cancelled the form!"
}