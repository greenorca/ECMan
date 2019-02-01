<#
	.NOTES
	===========================================================================
 Created on:2018.11.09
 Latest Update: 2018.12.15
 Script Version:1.1.3
 Author:Timothy Gruber
 Website:   TimothyGruber.com
 GitLab:https://gitlab.com/tjgruber/win10crappremover
	===========================================================================
	.DESCRIPTION
This PowerShell script is used to granularly remove unneeded or unwanted applications and settings from Windows 10 
easily via an intuitive GUI without installing anything, with minimal requirements, and 
without the need to run the script with switches or edit anything within the script. Everything is done via the GUI.

== Tested Against ==
a. Windows 10 1803 (17134.1) Fresh
a. Audit Mode Pre/post-updates
b. User Mode Pre/post-updates
b. Windows 10 1809 (17763.107) Fresh
a. Audit Mode Pre/post-updates
b. User Mode Pre/post-updates
.TODO
1. Implement PowerShell Runspaces / Multi-threading for version 2.0.
2. Create a few needed highly advanced functions to dramatically cut down repetitive code.
-possibly reducing code amount by at least 80%.
3. Implement undo or reversal of registry settings, similar to how services and scheduled tasks are done.
#>

#===========================================================================
#region Run script as elevated admin and unrestricted executionpolicy
#===========================================================================

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);
# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole)) {
# We are running as an administrator, so change the title and background colour to indicate this
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";
$Host.UI.RawUI.BackgroundColor = "DarkBlue";
Clear-Host;
} else {
# We are not running as an administrator, so relaunch as administrator
# Create a new process object that starts PowerShell
$newProcess = New-Object Diagnostics.ProcessStartInfo 'powershell.exe';
# Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
$newProcess.Arguments = '-ExecutionPolicy Unrestricted -File "' +
$script:MyInvocation.MyCommand.Path + '"'
# Indicate that the process should be elevated
$newProcess.Verb = 'runas';
# Start the new process
[Diagnostics.Process]::Start($newProcess);
# Exit from the current, unelevated, process
Exit;
}
#endregion

#===========================================================================
#region XAML GUI Code
#===========================================================================

$RawXAML = @"
<Window x:Class="Win10crAPPRemover.MainWindow"
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
xmlns:local="clr-namespace:Win10crAPPRemover"
mc:Ignorable="d"
Title="Windows 10 crAPP Remover v1.1.3 | by Timothy Gruber" Height="500" Width="958" ScrollViewer.VerticalScrollBarVisibility="Disabled">
<Grid>
<DockPanel>
<StatusBar DockPanel.Dock="Bottom">
<StatusBar.ItemsPanel>
<ItemsPanelTemplate>
<Grid>
<Grid.ColumnDefinitions>
<ColumnDefinition Width="*" />
<ColumnDefinition Width="Auto" />
<ColumnDefinition Width="Auto" />
</Grid.ColumnDefinitions>
</Grid>
</ItemsPanelTemplate>
</StatusBar.ItemsPanel>
<StatusBarItem Margin="2,0,0,0">
<TextBlock x:Name="StatusBarText" Text="Ready..." />
</StatusBarItem>
<Separator Grid.Column="1" />
<StatusBarItem Grid.Column="3" Margin="0,0,2,0">
<ProgressBar x:Name="ProgressBar" Value="0" Width="150" Height="16" />
</StatusBarItem>
</StatusBar>
<TabControl>
<TabItem Header="Win10 crAPPs" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<DockPanel Margin="0,5,0,0">
<Grid DockPanel.Dock="Bottom" Margin="5,1"/>
<DockPanel DockPanel.Dock="Right" Margin="0">
<DockPanel DockPanel.Dock="Top" Margin="0">
<Button x:Name="LoadcrAPPListbutton" DockPanel.Dock="Right" Content="Load crAPP List" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Margin="5,0" Padding="10,1"/>
<StackPanel DockPanel.Dock="Left" HorizontalAlignment="Left" Margin="15,0,0,0">
<CheckBox x:Name="RemovecrAPPProvisioningCheckBox" Content="Remove Provisioning" Margin="0,0,0,1" FontWeight="Bold" />
<StackPanel HorizontalAlignment="Left" Orientation="Horizontal">
<Button x:Name="CheckAllcrAPPsButton" Content="Check All" Padding="10,0" VerticalContentAlignment="Center" Margin="0,0,2,0" VerticalAlignment="Center" FontSize="10"/>
<Button x:Name="UncheckAllcrAPPsButton" Content="Uncheck All" Padding="10,0" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0" FontSize="10"/>
</StackPanel>
</StackPanel>
</DockPanel>
<GroupBox x:Name="crAPPListBoxGroupBox" Header="List of crAPPs" DockPanel.Dock="Right" Width="300" Margin="0,2,0,0">
<ListBox x:Name="crAPPListBox"/>
</GroupBox>
</DockPanel>
<DockPanel DockPanel.Dock="Top" LastChildFill="False" Margin="0">
<Button x:Name="ExportLogButton" DockPanel.Dock="Left" Content="Export Log" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0"/>
<Button x:Name="UndoRemovedcrAPPsButton" Content="Undo crAPP Removal" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="0,0,5,0"/>
<Button x:Name="FixWindowsUpdateButton" Content="Fix Windows Update" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="0,0,5,0"/>
<Button DockPanel.Dock="Right" x:Name="RemoveSelectedcrAPPsButton" Content="Remove Selected crAPPs" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="0,0,7,0"/>
</DockPanel>
<GroupBox Header="Working Output" Margin="0,2,0,0">
<TextBox x:Name="workingOutput" FontFamily="Consolas" ScrollViewer.VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="Black" FontWeight="Medium" ScrollViewer.CanContentScroll="True" HorizontalScrollBarVisibility="Auto"/>
</GroupBox>
</DockPanel>
</TabItem>
<TabItem Header="App &amp; Privacy Settings" Height="20" VerticalAlignment="Top" HorizontalAlignment="Left" TextOptions.TextFormattingMode="Display">
<DockPanel Margin="0,5,0,0">
<Grid DockPanel.Dock="Bottom" Margin="5,1"/>
<DockPanel DockPanel.Dock="Right" Margin="0">
<DockPanel DockPanel.Dock="Top" Margin="0">
<Button DockPanel.Dock="Right" x:Name="RefreshSettingsListButtonPrivacySettings" Content="Detect Current Settings" VerticalAlignment="Center" Height="30" FontSize="14" Padding="10,1" Margin="0,0,5,0" HorizontalAlignment="Right" FontWeight="Bold"/>
<StackPanel DockPanel.Dock="Left" HorizontalAlignment="Left" Margin="20,0,0,0">
<Button x:Name="CheckAllButtonPrivacySettings" Content="Check All" Padding="10,0" VerticalContentAlignment="Center" Margin="0" VerticalAlignment="Center" FontSize="10"/>
<Button x:Name="UncheckAllButtonPrivacySettings" Content="Uncheck All" Padding="10,0" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0,1,0,0" FontSize="10"/>
</StackPanel>
</DockPanel>
<GroupBox x:Name="PrivacySettingsListBoxGroupBox" Header="Privacy &amp; App Settings List" Margin="0,2,0,0" Width="336">
<ListBox x:Name="PrivacySettingsListBox">
<Label Content="Privacy Setttings" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableAppTrackingCheckBox" Content="Disable App Tracking" ToolTip="Right-click for details!" Tag="Disables the tracking of app launches for start menu and search results improbement." />
<CheckBox x:Name="DisableSharedExperiencesCheckBox" Content="Disable Shared Experiences" ToolTip="Right-click for details!" Tag="Disables the &quot;share across devices&quot;, which lets apps on this and other linked devices open and message apps." />
<CheckBox x:Name="DisableTailoredExperiencesCheckBox" Content="Disable Tailored Experiences" ToolTip="Right-click for details!" Tag="Stops Windows from sending diagnostics data to provide a tailored experience." />
<CheckBox x:Name="DisableAdvertisingIDCheckBox" Content="Disable Advertising ID Sharing" ToolTip="Right-click for details!" Tag="Disables and resets Advertising ID" />
<CheckBox x:Name="DisableWindows10FeedbackCheckBox" Content="Disable Windows 10 Feedback" ToolTip="Right-click for details!" Tag="Disables the Windows 10 Feedback prompts that appear every few weeks." />
<CheckBox x:Name="DisableHttpAcceptLanguageOptOutCheckBox" Content="Disable Access to Language List" ToolTip="Right-click for details!" Tag="Deletes the current content of the HTTP Accept Language registry key and blocks updates to the key based on changes to the language list of the user." />
<CheckBox x:Name="DisableInkTypeRecognitionCheckBox" Content="Disable Inking and Typing Recognition" ToolTip="Right-click for details!" Tag="Disables improvement of inking and typing recognition via data sharing." />
<CheckBox x:Name="DisablePenInkRecommendationsCheckBox" Content="Disable Pen and Ink Recommendations" ToolTip="Right-click for details!" Tag="Disables Windows from showing recommended App suggestions for Pen and Ink." />
<CheckBox x:Name="DisableInkTypePersonalizationCheckBox" Content="Disable Inking and Typing Personalization" ToolTip="Right-click for details!" Tag="Disallows your inking and typing personalization data from being shared." />
<CheckBox x:Name="DisableInventoryCollectorCheckBox" Content="Disable Inventory Collector" ToolTip="Right-click for details!" Tag="Disallows your inking and typing personalization data from being shared." />
<CheckBox x:Name="DisableApplicationTelemetryCheckBox" Content="Disable Application Telemetry" ToolTip="Right-click for details!" Tag="Disallows your inking and typing personalization data from being shared." />
<CheckBox x:Name="DisableLocationGloballyCheckBox" Content="Disable Location Globally" ToolTip="Right-click for details!" Tag="Disables location global setting." />
<CheckBox x:Name="DisableTelemetryCheckBox" Content="Disable Telemetry" ToolTip="Right-click for details!" Tag="Disables Telemetry for Win10 Enterprise, or sets to Basic for Win10 Pro and lower." />
<CheckBox x:Name="DisableEdgeTrackingCheckBox" Content="Disable Edge Tracking" ToolTip="Right-click for details!" Tag="Disables MS Edge tracking. Always send do not track." />
<Label Content="Cortana" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableCortanaCheckBox" Content="Disable Cortana" ToolTip="Right-click for details!" Tag="Disables Cortana on machine." />
<CheckBox x:Name="DisableCortanaOnLockScreenCheckBox" Content="Disable Cortana on Lock Screen" ToolTip="Right-click for details!" Tag="Disables Cortana on the Lock Screen." />
<CheckBox x:Name="DisableCortanaAboveLockScreenCheckBox" Content="Disable Cortana Above Lock Screen" ToolTip="Right-click for details!" Tag="Allows you to perform certain tasks, such as play music, set reminders, make a note to yourself, and a lot more even when your PC is locked." />
<CheckBox x:Name="DisableCortanaAndBingSearchScreenCheckBox" Content="Disable Cortana and Bing Search" ToolTip="Right-click for details!" Tag="Disables Cortana and Bing search user settings." />
<CheckBox x:Name="DisableCortanaSearchHistoryCheckBox" Content="Disable Cortana Search History" ToolTip="Right-click for details!" Tag="Disables Cortana search history." />
<Label Content="App Permissions" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DenyAppsRunningInBackgroundCheckBox" Content="Deny Apps Running in Background" ToolTip="Right-click for details!" Tag="Disallow apps to run in the gackground." />
<CheckBox x:Name="DenyAppDiagnosticsCheckBox" Content="Deny App Diagnostics" ToolTip="Right-click for details!" Tag="Denies app diagnostics." />
<CheckBox x:Name="DenyBroadFileSystemAccessAccessCheckBox" Content="Deny Broad File System Access Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Broad File System Access." />
<CheckBox x:Name="DenyCalendarAccessCheckBox" Content="Deny Calendar Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Calendar." />
<CheckBox x:Name="DenyCellularDataAccessCheckBox" Content="Deny Cellular Data Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Cellular Data." />
<CheckBox x:Name="DenyChatAccessCheckBox" Content="Deny Chat Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Chat." />
<CheckBox x:Name="DenyContactsAccessCheckBox" Content="Deny Contacts Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Contacts." />
<CheckBox x:Name="DenyDocumentsLibraryAccessCheckBox" Content="Deny Documents Library Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Documents Library." />
<CheckBox x:Name="DenyEmailAccessCheckBox" Content="Deny Email Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Email." />
<CheckBox x:Name="DenyGazeInputAccessCheckBox" Content="Deny Gaze Input Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Gaze Input." />
<CheckBox x:Name="DenyLocationAccessCheckBox" Content="Deny Location Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Location." />
<CheckBox x:Name="DenyMicrophoneAccessCheckBox" Content="Deny Microphone Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Microphone." />
<CheckBox x:Name="DenyNotificationsCheckBox" Content="Deny Notifications" ToolTip="Right-click for details!" Tag="Denies notifications." />
<CheckBox x:Name="DenyOtherDevicesCheckBox" Content="Deny Other Devices" ToolTip="Right-click for details!" Tag="Denies other devices." />
<CheckBox x:Name="DenyPhoneCallHistoryAccessCheckBox" Content="Deny Phone Call History Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Phone Call History." />
<CheckBox x:Name="DenyPicturesLibraryAccessCheckBox" Content="Deny Pictures Library Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Pictures Library." />
<CheckBox x:Name="DenyRadiosCheckBox" Content="Deny Radios" ToolTip="Right-click for details!" Tag="Denies radios." />
<CheckBox x:Name="DenyTasksAccessCheckBox" Content="Deny Tasks Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Tasks." />
<CheckBox x:Name="DenyUserAccountInformationAccessCheckBox" Content="Deny User Account Information Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your User Account Information." />
<CheckBox x:Name="DenyVideosLibraryAccessCheckBox" Content="Deny Videos Library Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Videos Library." />
<CheckBox x:Name="DenyWebcamAccessCheckBox" Content="Deny Webcam Access" ToolTip="Right-click for details!" Tag="Denies apps from accessing your Webcam." />
<Label Content="Suggestions, Ads, Tips, etc." Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableStartMenuSuggestionsCheckBox" Content="Disable Start Menu Suggestions" ToolTip="Right-click for details!" Tag="Disables Start Menu suggestions." />
<CheckBox x:Name="DisableSuggestedContentInSettingsCheckBox" Content="Disable Suggested Content in Settings" ToolTip="Right-click for details!" Tag="Disables showing suggested content in settings." />
<CheckBox x:Name="DisableOccasionalSuggestionsCheckBox" Content="Disable Occasional Suggestions" ToolTip="Right-click for details!" Tag="Disables showing occasional suggestions." />
<CheckBox x:Name="DisableSuggestionsInTimelineCheckBox" Content="Disable Suggestions in Timeline" ToolTip="Right-click for details!" Tag="Disables showing suggestions in Timeline." />
<CheckBox x:Name="DisableLockscreenSuggestionsAndRotatingPicturesCheckBox" Content="Disable Lockscreen Suggestions &amp; Rotating Pictures" ToolTip="Right-click for details!" Tag="Disables Lockscreen suggestions and rotating pictures." />
<CheckBox x:Name="DisableTipsTricksSuggestionsCheckBox" Content="Disable Tips, Tricks, and Suggestions" ToolTip="Right-click for details!" Tag="Disables getting tips, tricks, and suggestions as you use Windows." />
<CheckBox x:Name="DisableAdsInFileExplorerCheckBox" Content="Disable Ads in File Explorer" ToolTip="Right-click for details!" Tag="Disables ads in File Explorer." />
<CheckBox x:Name="DisableAdInfoDeviceMetaCollectionCheckBox" Content="Disable Ad Info &amp; Device Metadata Collection" ToolTip="Right-click for details!" Tag="Disables Advertising Info &amp; Device Metadata Collection" />
<CheckBox x:Name="DisablePreReleaseFeaturesSettingsCheckBox" Content="Disable Pre-release Features &amp; Settings" ToolTip="Right-click for details!" Tag="Disables pre-release features and settings." />
<CheckBox x:Name="DisableFeedbackNotificationsCheckBox" Content="Disable Feedback Notifications" ToolTip="Right-click for details!" Tag="Disables showing feedback notifications." />
<Label Content="People" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableMyPeopleNotificationsCheckBox" Content="Disable My People Notifications" ToolTip="Right-click for details!" Tag="Disables My People Notifications / Shouldertap." />
<CheckBox x:Name="DisableMyPeopleSuggestionsCheckBox" Content="Disable My People Suggestions" ToolTip="Right-click for details!" Tag="Disables My People Suggestions." />
<CheckBox x:Name="DisablePeopleOnTaskbarCheckBox" Content="Disable People on Taskbar" ToolTip="Right-click for details!" Tag="Disables People on Taskbar." />
<Label Content="OneDrive" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="PreventUsageOfOneDriveCheckBox" Content="Prevent Usage of OneDrive" ToolTip="Right-click for details!" Tag="Prevents apps and features from working with files on OneDrive. * Users can't access OneDrive from the OneDrive app and file picker." />
<CheckBox x:Name="DisableAutomaticOneDriveSetupCheckBox" Content="Disable Automatic OneDrive Setup" ToolTip="Right-click for details!" Tag="Disables automatic OneDrive setup for new accounts." />
<CheckBox x:Name="DisableOneDriveStartupRunCheckBox" Content="Disable OneDrive Startup Run" ToolTip="Right-click for details!" Tag="Disables OneDrive from running at login." />
<CheckBox x:Name="RemoveOneDriveFromFileExplorerCheckBox" Content="Remove OneDrive from File Explorer" ToolTip="Right-click for details!" Tag="Removes OneDrive from File Explorer." />
<Label Content="Games &amp; Entertainment" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableGameDVRCheckBox" Content="Disable GameDVR" ToolTip="Right-click for details!" Tag="Disables GameDVR without needing a Microsoft account." />
<CheckBox x:Name="DisablePreinstalledAppsCheckBox" Content="Disable Preinstalled Apps" ToolTip="Right-click for details!" Tag="Disables the preinstalled apps you see. You'll still need to clean the Start Menu." />
<CheckBox x:Name="DisableXboxGameMonitoringServiceCheckBox" Content="Disable Xbox Game Monitoring Service" ToolTip="Right-click for details!" Tag="Disables the Xbox Game Monitoring Service." />
<Label Content="Cloud" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableWindowsTipsCheckBox" Content="Disable Windows Tips" ToolTip="Right-click for details!" Tag="Disables showing Windows Tips." />
<CheckBox x:Name="DisableConsumerExperiencesCheckBox" Content="Disable Consumer Experiences" ToolTip="Right-click for details!" Tag="Disables Consumer Experiences." />
<CheckBox x:Name="DisableThirdPartySuggestionsCheckBox" Content="Disable 3rd Party Suggestions" ToolTip="Right-click for details!" Tag="Disables third party suggestions." />
<CheckBox x:Name="DisableSpotlightFeaturesCheckBox" Content="Disable Spotlight Features" ToolTip="Right-click for details!" Tag="Disables all spotlight features." />
<Label Content="Windows Update" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableFeaturedSoftwareNotificationsCheckBox" Content="Disable Featured Software Notifications" ToolTip="Right-click for details!" Tag="Disables featured software notifications through Windows Update." />
<CheckBox x:Name="SetDeliveryOptimizationLANOnlyCheckBox" Content="Set Delivery Optimization LAN Only" ToolTip="Right-click for details!" Tag="Sets delivery optimization to LAN only." />
<CheckBox x:Name="DisableAutomaticStoreAppUpdatesCheckBox" Content="Disable Automatic Store App Updates" ToolTip="Right-click for details!" Tag="Disables automatic download and installation of Windows App Store app updates." />
<CheckBox x:Name="DisableAutoLoginUpdatesCheckBox" Content="Disable Automatic Login to Update" ToolTip="Right-click for details!" Tag="Disables using your sign-in info to automatically finish updates." />
<Label Content="Other Settings" Padding="0" FontWeight="Bold"/>
<CheckBox x:Name="DisableShoehorningAppsCheckBox" Content="Disable Shoehorning Apps" ToolTip="Right-click for details!" Tag="Disables shoehorning apps secretly into your profile." />
<CheckBox x:Name="DisableOccasionalWelcomeExperienceCheckBox" Content="Disable Occasional Welcome Experience" ToolTip="Right-click for details!" Tag="Disables the occasional Windows Welcome Experience." />
<CheckBox x:Name="DisableAutoplayCheckBox" Content="Disable Autoplay" ToolTip="Right-click for details!" Tag="Disables Autoplay for all media and devices." />
<CheckBox x:Name="DisableTaskbarSearchCheckBox" Content="Disable Taskbar Search" ToolTip="Right-click for details!" Tag="Disables Taskbar search." />
<CheckBox x:Name="DenyLocationUseForSearchesCheckBox" Content="Deny Location Use For Searches" ToolTip="Right-click for details!" Tag="Denies location usage for Search." />
<CheckBox x:Name="DisableTabletSettingsCheckBox" Content="Disable Tablet Settings (caution)" ToolTip="Right-click for details!" Tag="Disables tablet settings. Don't do this if you're on a tablet." />
<CheckBox x:Name="AnonymizeSearchInfoCheckBox" Content="Anonymize Search Info" ToolTip="Right-click for details!" Tag="Anonymize the info that is shared in your searches." />
<CheckBox x:Name="DisableMicrosoftStoreCheckBox" Content="Disable Microsoft Store" ToolTip="Right-click for details!" Tag="Disables the Windows Store." />
<CheckBox x:Name="DisableStoreAppsCheckBox" Content="Disable Store Apps" ToolTip="Right-click for details!" Tag="Disables all apps from the store." />
<CheckBox x:Name="DisableCEIPCheckBox" Content="Disable CEIP" ToolTip="Right-click for details!" Tag="Disables CEIP, which sets all users opted out of the Windows Customer Experience Improvement Program ." />
<CheckBox x:Name="DisableAppPairingCheckBox" Content="Disable App Pairing" ToolTip="Right-click for details!" Tag="Disables app and phone pairing." />
<CheckBox x:Name="EnableDiagnosticDataViewerCheckBox" Content="Enable Diagnostic Data Viewer" ToolTip="Right-click for details!" Tag="Enables the diagnostic data viewer." />
<CheckBox x:Name="DisableEdgeDesktopShortcutCheckBox" Content="Disable Edge Desktop Shortcut" ToolTip="Right-click for details!" Tag="Disables Edge desktop shortcut creation." />
<CheckBox x:Name="DisableWebContentEvaluationCheckBox" Content="Disable Web Content Evaluation" ToolTip="Right-click for details!" Tag="Disables filtering of web content through Smartscreen." />
</ListBox>
</GroupBox>
</DockPanel>
<DockPanel DockPanel.Dock="Top" LastChildFill="False" Margin="0">
<Button x:Name="ExportLogButtonPrivacySettings" Content="Export Log" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalAlignment="Right"/>
<Button x:Name="PerformSystemCheckpointButton" Content="Perform System Checkpoint" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="0,0,5,0"/>
<Button DockPanel.Dock="Right" x:Name="ProcessPrivacySettingsButton" Content="Process Selected Settings" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="0,0,55,0"/>
</DockPanel>
<GroupBox Header="Working Output" Margin="0,2,0,0">
<TextBox x:Name="workingOutputPrivacySettings" FontFamily="Consolas" ScrollViewer.VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="Black" FontWeight="Medium" IsUndoEnabled="False" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" Grid.IsSharedSizeScope="True" ScrollViewer.CanContentScroll="True"/>
</GroupBox>
</DockPanel>
</TabItem>
<TabItem Header="Start Menu" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<DockPanel Margin="0,5,0,0">
<Grid DockPanel.Dock="Bottom" Margin="5,1"/>
<DockPanel DockPanel.Dock="Top" LastChildFill="False" Margin="0">
<ComboBox x:Name="XMLTemplateSelectionComboBox"  Margin="5,0" VerticalAlignment="Center">
<ComboBoxItem Content="Select XML Layout Template..." IsSelected="True"/>
<ComboBoxItem Content="Empty Start Menu XML"/>
<ComboBoxItem Content="Current Start Menu XML"/>
<ComboBoxItem Content="Clean Start Menu XML"/>
</ComboBox>
<Button x:Name="LoadSelectedXMLTemplateButton" Content="Load Selected XML Template" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalAlignment="Right"/>
<Button x:Name="ExportToButton" Content="Export to..." VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalAlignment="Right"/>
<Button DockPanel.Dock="Right" x:Name="SetBelowXMLButton" Content="SET Below XML" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0"/>
</DockPanel>
<GroupBox Header="Start Menu Layout Editor" Margin="0,2,0,0">
<TextBox x:Name="StartMenuLayoutXML" FontFamily="Consolas" ScrollViewer.VerticalScrollBarVisibility="Auto" Background="Black" FontWeight="Medium" IsUndoEnabled="True" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" Grid.IsSharedSizeScope="True" ScrollViewer.CanContentScroll="True" Foreground="LightGreen" Text="Load from template, or Paste in your own XML..." AcceptsReturn="True" AcceptsTab="True" TextOptions.TextFormattingMode="Display"/>
</GroupBox>
</DockPanel>
</TabItem>
<TabItem Header="Scheduled Tasks" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<DockPanel Margin="0,5,0,0">
<Grid DockPanel.Dock="Bottom" Margin="5,1"/>
<DockPanel DockPanel.Dock="Right" Margin="0">
<DockPanel DockPanel.Dock="Top" Margin="0">
<Button DockPanel.Dock="Right" x:Name="DetectRelevantScheduledTasksListButton" Content="Detect Relevant Scheduled Tasks" VerticalAlignment="Center" Height="30" FontSize="14" Padding="10,1" Margin="5,0" HorizontalAlignment="Right" FontWeight="Bold"/>
<StackPanel DockPanel.Dock="Left" HorizontalAlignment="Left" Margin="20,0,5,0">
<Button x:Name="CheckAllScheduledTasksButton" Content="Check All" Padding="10,0" VerticalContentAlignment="Center" Margin="0" VerticalAlignment="Center" FontSize="10"/>
<Button x:Name="UncheckAllScheduledTasksButton" Content="Uncheck All" Padding="10,0" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0,1,0,0" FontSize="10"/>
</StackPanel>
</DockPanel>
<GroupBox x:Name="ScheduledTasksListBoxGroupBox" Header="Scheduled Tasks List" Margin="0,2,0,0" Width="350">
<ListBox x:Name="ScheduledTasksListBox" />
</GroupBox>
</DockPanel>
<DockPanel DockPanel.Dock="Top" LastChildFill="False" Margin="0">
<Button x:Name="ExportLogButtonScheduledTasks" Content="Export Log" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalAlignment="Right"/>
<Button x:Name="DisableSelectedScheduledTasksButton" Content="Disable Selected Scheduled Tasks" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0,30,0" HorizontalContentAlignment="Center" DockPanel.Dock="Right"/>
<Button x:Name="EnableSelectedScheduledTasksButton" Content="Enable Selected Tasks" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalContentAlignment="Center" DockPanel.Dock="Right"/>
</DockPanel>
<GroupBox Header="Working Output" Margin="0,2,0,0">
<TextBox x:Name="workingOutputScheduledTasks" FontFamily="Consolas" ScrollViewer.VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="Black" FontWeight="Medium" IsUndoEnabled="False" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" Grid.IsSharedSizeScope="True" ScrollViewer.CanContentScroll="True"/>
</GroupBox>
</DockPanel>
</TabItem>
<TabItem Header="Services" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<DockPanel Margin="0,5,0,0">
<Grid DockPanel.Dock="Bottom" Margin="5,1"/>
<DockPanel DockPanel.Dock="Right" Margin="0">
<DockPanel DockPanel.Dock="Top" Margin="0">
<Button DockPanel.Dock="Right" x:Name="DetectRelevantServicesListButton" Content="Detect Relevant Services" VerticalAlignment="Center" Height="30" FontSize="14" Padding="10,1" Margin="0,0,5,0" HorizontalAlignment="Right" FontWeight="Bold"/>
<StackPanel DockPanel.Dock="Left" HorizontalAlignment="Left" Margin="20,0,5,0">
<Button x:Name="CheckAllServicesButton" Content="Check All" Padding="10,0" VerticalContentAlignment="Center" Margin="0" VerticalAlignment="Center" FontSize="10"/>
<Button x:Name="UncheckAllServicesButton" Content="Uncheck All" Padding="10,0" VerticalAlignment="Center" VerticalContentAlignment="Center" Margin="0,1,0,0" FontSize="10"/>
</StackPanel>
</DockPanel>
<GroupBox x:Name="ServicesListBoxGroupBox" Header="Services List" Margin="0,2,0,0" Width="300">
<ListBox x:Name="ServicesListBox" />
</GroupBox>
</DockPanel>
<DockPanel DockPanel.Dock="Top" LastChildFill="False" Margin="0">
<Button x:Name="ExportLogButtonServices" Content="Export Log" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalAlignment="Right"/>
<Button x:Name="DisableSelectedServicesButton" Content="Disable Selected Services" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0,55,0" HorizontalContentAlignment="Center" DockPanel.Dock="Right"/>
<Button x:Name="EnableSelectedServicesButton" Content="Enable Selected Services" VerticalAlignment="Top" Height="30" FontWeight="Bold" FontSize="14" Padding="10,1" Margin="5,0" HorizontalContentAlignment="Center" DockPanel.Dock="Right"/>
</DockPanel>
<GroupBox Header="Working Output" Margin="0,2,0,0">
<TextBox x:Name="workingOutputServices" FontFamily="Consolas" ScrollViewer.VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="Black" FontWeight="Medium" IsUndoEnabled="False" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" Grid.IsSharedSizeScope="True" ScrollViewer.CanContentScroll="True"/>
</GroupBox>
</DockPanel>
</TabItem>
<TabItem Header="about" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<DockPanel Margin="0,5,0,0">
<GroupBox Header="about" DockPanel.Dock="Bottom" VerticalAlignment="Bottom" FontWeight="Bold">
<ScrollViewer>
<TextBlock TextWrapping="Wrap" FontWeight="Normal"><Run FontWeight="Bold" Text="Created by: "/><Run Text="&#x9;Timothy Gruber&#xA;"/><Run FontWeight="Bold" Text="Website:&#x9;"/><Hyperlink NavigateUri="https://timothygruber.com/"><Run Text="TimothyGruber.com&#xA;"/></Hyperlink><Run FontWeight="Bold" Text="Gitlab:&#x9;&#x9;"/><Hyperlink NavigateUri="https://gitlab.com/tjgruber/win10crappremover"><Run Text="https://gitlab.com/tjgruber/win10crappremover&#xA;"/></Hyperlink><Run FontWeight="Bold" Text="Version:"/><Run Text="&#x9;&#x9;1.1.3.2018.12.15"/></TextBlock>
</ScrollViewer>
</GroupBox>
<GroupBox Header="Instructions..." FontWeight="Bold">
<TabControl TabStripPlacement="Left">
<TabItem Header="General" Height="20" TextOptions.TextFormattingMode="Display" VerticalAlignment="Top" HorizontalContentAlignment="Stretch">
<GroupBox Header="General">
<ScrollViewer>
<TextBlock  TextWrapping="Wrap" FontWeight="Normal"><Run FontWeight="Normal" Text="Create a System Checkpoint from the App &amp; Privacy Settings tab before processing any settings. Checkpoint does not work while in Audit Mode."/><LineBreak FontWeight="Normal"/><LineBreak FontWeight="Normal"/><Run FontWeight="Normal" Text="You may run this in an existing Windows user profile, but apps and settings results may vary. Some apps cannot be uninstalled on a per-user basis, or at all, such as Apps or settings that are a part of Windows... expect some harmless uninstall errors in those cases."/><LineBreak FontWeight="Normal"/><LineBreak FontWeight="Normal"/><Run FontWeight="Normal" Text="For the best and cleanest results, run this while in "/><Run FontWeight="Bold" Text="Audit Mode"/><Run FontWeight="Normal" Text=" before any users are created on the machine."/><LineBreak FontWeight="Normal"/><Run FontWeight="Normal" Text="You can enter Audit Mode by pressing"/><Run FontWeight="Bold" Text=" CTRL+SHIFT+F3"/><Run FontWeight="Normal" Text=" during "/><Run FontWeight="Bold" Text="OOBE"/><Run FontWeight="Normal" Text=". You can manually enter Audit Mode by running "/><Run FontWeight="Bold" Text="C:\Windows\System32\Sysprep\sysprep.exe"/><Run FontWeight="Normal" Text=". Select the option to reboot into Audit mode, "/><Run FontWeight="Normal" Text="which will reset Windows" TextDecorations="Underline"/><Run FontWeight="Normal" Text=". Back up your data first."/></TextBlock>
</ScrollViewer>
</GroupBox>
</TabItem>
<TabItem Header="Win10 crAPPs" Height="20" TextOptions.TextFormattingMode="Display" VerticalAlignment="Top" HorizontalContentAlignment="Stretch">
<GroupBox Header="Win10 crAPPs">
<ScrollViewer>
<TextBlock TextWrapping="Wrap" FontWeight="Normal"><Run Text="1.  Click the "/><Run FontWeight="Bold" Text="Load crAPP List"/><Run Text=" button in the "/><Run FontWeight="Bold" Text="Win10 crAPPs"/><Run Text=" Tab."/><LineBreak/><Run Text="2.  Select the apps you want to remove, then click the "/><Run FontWeight="Bold" Text="Remove Selected crAPPs"/><Run Text=" button."/><LineBreak/><Run Text="3.  Export the log before closing this app."/></TextBlock>
</ScrollViewer>
</GroupBox>
</TabItem>
<TabItem Header="App &amp; Privacy Settings" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<GroupBox Header="App &amp; Privacy Settings">
<ScrollViewer>
<TextBlock TextWrapping="Wrap" FontWeight="Normal"><Run FontSize="11" Text="Note: Processing many settings at once may cause the GUI to hang for a few seconds, but it IS still working. This will be fixed in v2.0 with multi-threading."/><LineBreak/><Run FontSize="11"/><LineBreak/><Run Text="1.  Click the "/><Run FontWeight="Bold" Text="Detect Current Settings"/><Run Text=" button to automatically detect current privacy and app settings and check appropriately:"/><LineBreak/><Run Text="&#x9;"/><Run Foreground="#FF369726" FontWeight="Bold" Text="GREEN"/><Run Text=":  Setting is already applied or processed -- No action is needed."/><LineBreak/><Run Text="&#x9;"/><Run Foreground="Red" FontWeight="Bold" Text="RED"/><Run Text=":  Setting is not applied or disabled and requires processing."/><LineBreak/><Run Text="&#x9;"/><Run Foreground="Blue" FontWeight="Bold" Text="BLUE"/><Run Text=":  Automatic detection could not be performed. May or may not need processed."/><LineBreak/><Run Text="2.  Check the settings you would like to disable on your system."/><LineBreak/><Run Text="3.  Click the "/><Run FontWeight="Bold" Text="Process Selected Settings"/><Run Text=" button to disable or process all checked settings."/><LineBreak/><Run Text="4.  Click the "/><Run FontWeight="Bold" Text="Refresh Settings List"/><Run Text=" button to verify selected settings have been properly processed. They should show up as green."/><LineBreak/><Run Text="4.  Export the log before closing this app in case you need to review later."/><LineBreak/><Run/><LineBreak/><Run/></TextBlock>
</ScrollViewer>
</GroupBox>
</TabItem>
<TabItem Header="Start Menu" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<GroupBox Header="Start Menu">
<ScrollViewer>
<TextBlock ><Run FontWeight="Normal" Text="1.  Select a Template from the drop-down menu, then click the "/><Run Text="Load Selected XML Template"/><Run FontWeight="Normal" Text=" button..."/><LineBreak/><Run FontWeight="Normal" Text="2.  In the Layout Editor area, edit the XML template or paste in your own XML."/><LineBreak/><Run FontWeight="Normal" Text="3.  Use the "/><Run Text="Export to..."/><Run FontWeight="Normal" Text=" button to save your XML in the Layout Editor to disk."/><LineBreak/><Run FontWeight="Normal" Text="4.  Click the "/><Run Text="SET Below XML"/><Run FontWeight="Normal" Text=" button to apply the XML data in the Layout Editor to the Default User profile."/><LineBreak/><Run/></TextBlock>
</ScrollViewer>
</GroupBox>
</TabItem>
<TabItem Header="Scheduled Tasks" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<GroupBox Header="Scheduled Tasks">
<ScrollViewer>
<TextBlock ><Run FontWeight="Normal" Text="1.  Click the "/><Run Text="Detect Relevant Scheduled Tasks"/><Run FontWeight="Normal" Text=" button."/><LineBreak/><Run FontWeight="Normal" Text=" a. This will load all Scheduled Tasks present on the system."/><LineBreak/><Run FontWeight="Normal" Text=" b. This will also automatically detect their statuses, checkmark, and color enabled tasks that may be superfluous or compromise your"/><LineBreak/><Run FontWeight="Normal" Text="  privacy."/><LineBreak/><Run FontWeight="Normal" Text=""/><Run Foreground="#FF369726" FontWeight="Bold" Text="GREEN"/><Run FontWeight="Normal" Text=":  Scheduled Task is already disabled -- No action is needed."/><LineBreak FontWeight="Normal"/><Run FontWeight="Normal" Text="&#x9;"/><Run Foreground="Red" FontWeight="Bold" Text="RED"/><Run FontWeight="Normal" Text=":  Scheduled Task is enabled and requires processing."/><LineBreak/><Run FontWeight="Normal" Text="2. Check the Scheduled Tasks you wish to disable."/><LineBreak/><Run FontWeight="Normal" Text="3. Click the "/><Run Text="Disable Selected Scheduled Tasks"/><Run FontWeight="Normal" Text=" button to disable the tasks you have checkmarked."/><LineBreak/><Run FontWeight="Normal" Text="4. Should you need to re-enable any Scheduled Tasks, checkmark the appropriate tasks, and click "/><Run Text="the Enable Selected Tasks"/><Run FontWeight="Normal" Text=" button."/><LineBreak/><Run FontWeight="Normal" Text="5. Click the "/><Run Text="Export Log"/><Run FontWeight="Normal" Text=" button to export the log."/></TextBlock>
</ScrollViewer>
</GroupBox>
</TabItem>
<TabItem Header="Services" Height="20" VerticalAlignment="Top" TextOptions.TextFormattingMode="Display">
<GroupBox Header="Services">
<ScrollViewer>
<TextBlock ><Run FontWeight="Normal" Text="1.  Click the "/><Run Text="Detect Relevant Services"/><Run FontWeight="Normal" Text=" button."/><LineBreak/><Run FontWeight="Normal" Text=" a. This will load all Services present on the system."/><LineBreak/><Run FontWeight="Normal" Text=" b. This will also automatically detect their statuses, checkmark, and color enabled services that may be superfluous or compromise your"/><LineBreak/><Run FontWeight="Normal" Text="  privacy."/><LineBreak/><Run FontWeight="Normal" Text=""/><Run Foreground="#FF369726" Text="GREEN"/><Run FontWeight="Normal" Text=":  Service is already disabled -- No action is needed."/><LineBreak FontWeight="Normal"/><Run FontWeight="Normal" Text="&#x9;"/><Run Foreground="Red" Text="RED"/><Run FontWeight="Normal" Text=":  Service is enabled and requires processing."/><LineBreak/><Run FontWeight="Normal" Text="2. Check the Services you wish to disable."/><LineBreak/><Run FontWeight="Normal" Text="3. Click the "/><Run Text="Disable Selected Services"/><Run FontWeight="Normal" Text=" button to disable the services you have checkmarked."/><LineBreak/><Run FontWeight="Normal" Text="4. Should you need to re-enable any Services, checkmark the appropriate services, and click "/><Run Text="the Enable Services"/><Run FontWeight="Normal" Text=" button."/><LineBreak/><Run FontWeight="Normal" Text="5. Click the "/><Run Text="Export Log"/><Run FontWeight="Normal" Text=" button to export the log."/></TextBlock>
</ScrollViewer>
</GroupBox>
</TabItem>
</TabControl>
</GroupBox>
</DockPanel>
</TabItem>
</TabControl>
</DockPanel>
</Grid>
</Window>
"@
#endregion

#===========================================================================
#region Replace some XAML code to make it usable in PowerShell
#===========================================================================

[void][System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[xml]$XAML = $RawXAML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
#endregion

#===========================================================================
#region Read the XAML code
#===========================================================================

$XAMLReader= New-Object System.Xml.XmlNodeReader $XAML
try{
$Form=[Windows.Markup.XamlReader]::Load($XAMLReader)
} catch {
Throw "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
#endregion

#===========================================================================
#region Load XAML Objects In PowerShell
#===========================================================================
 
$XAML.SelectNodes("//*[@Name]") |
ForEach-Object {
Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -Scope Global
}
#endregion

#===========================================================================
#region PowerShell Process window message when app is running
#===========================================================================

Write-Host "Running Windows 10 crAPP Remover v1.1.3 | by Timothy Gruber..."
Write-Host ""
Write-Host "This window will close when you exit the applicaiton."
#endregion

#===========================================================================
#region Output WPF form variables in PowerShell - useful for GUI testing
#===========================================================================

#Get-Variable WPF* # Will show you the form / GUI variables
#endregion

#===========================================================================
#region Events
#===========================================================================

function timestamp {
$timestamp = "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss:fff')"
Write-Output "$timestamp "
}

function MountDefaultUserReg {
$DefaultUserRegTest = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
if (Test-Path $DefaultUserRegTest) {
$DefaultUserReg = (Get-ItemProperty $DefaultUserRegTest Default).Default
[Void](reg load "HKLM\DefaultUserReg" $DefaultUserReg\NTUSER.DAT)
if (!(Get-PSDrive -Name "DefaultUserReg" -ErrorAction SilentlyContinue)) {
[Void](New-PSDrive -Name "DefaultUserReg" -PSProvider Registry -Root "HKLM\DefaultUserReg" -Scope Global)
} else {
[Void](Remove-PSDrive -Name "DefaultUserReg" -Scope Global)
[Void](Remove-PSDrive -Name "DefaultUserReg" -ErrorAction SilentlyContinue)
[Void](New-PSDrive -Name "DefaultUserReg" -PSProvider Registry -Root "HKLM\DefaultUserReg" -Scope Global)
}
}
}

Function UnmountDefaultUserReg {
[Void](Remove-PSDrive -Name "DefaultUserReg" -Scope Global)
[gc]::collect()
$DefaultUserRegUnload = [Void](reg unload "HKLM\DefaultUserReg")
if (Test-Path "HKLM:\DefaultUserReg") {
#Write-Host "`t`nDefaultUserReg was not unloaded because it was busy. Trying again..."
Start-Sleep -Milliseconds 750
$DefaultUserRegUnload = [Void](Remove-PSDrive -Name "DefaultUserReg" -Scope Global)
[gc]::collect()
[Void](reg unload "HKLM\DefaultUserReg")
if (!(Test-Path "HKLM:\DefaultUserReg")) {
#Write-Host "DefaultUserReg was successfully unloaded."
}
}
}

Set-Variable -Name "HKLMD" -Value "DefaultUserReg:" -Scope Global

Function Set-HKCR {
[Void](New-PSDrive -Name "HKCR" -PSProvider Registry -Root "HKEY_CLASSES_ROOT" -Scope Global)
}

Function Remove-HKCR {
[Void](Remove-PSDrive -Name "HKCR" -Scope Global)
[gc]::collect()
}

#
#
#
#
#
#===========================================================================
#region Win10 crAPPs Tab
#===========================================================================
#
#
#
#
#

$WPFworkingOutput.Foreground = "LightGreen"

#===========================================================================
#region Load crAPP List Button (Win10 crAPPs Tab)
#===========================================================================

$WPFLoadcrAPPListbutton.Add_Click({
$WPFcrAPPListBox.Items.Clear()
$WPFworkingOutput.AppendText("$(timestamp) *** Loading crAPP List***`r`n")
$crAPPyList = Get-AppxPackage -PackageTypeFilter Main -AllUsers | Sort-Object -Property Name

$crAPPKeepers =	"secheal|soundrecorder|.NET.N|desktopappins|screensketch|secureass|stickyno|windows.photos|calculator|store|mspaint|AAD|MicrosoftEdge|Cortana|accounts|-|Cred|Help|PPI|win32web|Apprep|Windows.Cloud|Windows.OOBE|Windows.Parental|Windows.Shell|windowscommu|windows.immer|Windows.PrintDialog|InputApp|Microsoft.Async|Microsoft.ECApp|Microsoft.WebMediaExt|AssignedAcc|Windows.CaptureP|Windows.ContentDelivery|Windows.Pinning"

$NewcrAPPsLabel1 = New-Object System.Windows.Controls.Label
$NewcrAPPsLabel1.Content = "More Likely Superfluous"
$NewcrAPPsLabel1.Padding = "0"
$NewcrAPPsLabel1.FontWeight = "Bold"
$WPFcrAPPListBox.AddChild($NewcrAPPsLabel1)

ForEach ($crAPPName in $crAPPyList | Where-Object {$_.Name -notmatch $crAPPKeepers}) {
$NewCheckBox = New-Object System.Windows.Controls.CheckBox
$newCheckBox.Content = $crAPPName.Name
$newCheckBox.ToolTip = $crAPPName.PackageFullName
$newCheckBox.Tag = $crAPPName.InstallLocation
$newCheckBox.Background = "White"
$newCheckBox.IsChecked = $True
$WPFcrAPPListBox.AddChild($NewCheckBox)
}

$NewcrAPPsLabel2 = New-Object System.Windows.Controls.Label
$NewcrAPPsLabel2.Content = "All Other Detected crAPPs"
$NewcrAPPsLabel2.Padding = "0"
$NewcrAPPsLabel2.FontWeight = "Bold"
$WPFcrAPPListBox.AddChild($NewcrAPPsLabel2)

ForEach ($crAPPName in $crAPPyList | Where-Object {$_.Name -match $crAPPKeepers}) {
$NewCheckBox = New-Object System.Windows.Controls.CheckBox
$newCheckBox.Content = $crAPPName.Name
$newCheckBox.ToolTip = $crAPPName.PackageFullName
$newCheckBox.Tag = $crAPPName.InstallLocation
$newCheckBox.Background = "White"
$newCheckBox.IsChecked = $False
$WPFcrAPPListBox.AddChild($NewCheckBox)
}
$WPFworkingOutput.AppendText("$(timestamp) ...crAPP List loaded.`r`n`n")
})
#endregion

#===========================================================================
#region Remove Provisioning Checkbox (Win10 crAPPs Tab)
#===========================================================================

#===========================================================================
#region Check Remove Provisioning Checkbox (Win10 crAPPs Tab)
#===========================================================================

$WPFRemovecrAPPProvisioningCheckBox.Add_Checked({
$WPFworkingOutput.AppendText("$(timestamp) *** Remove AppxProvisioning ENABLED ***`r`n")
$WPFworkingOutput.AppendText("$(timestamp) Removed apps may no longer be re-installable.`r`n")
$WPFworkingOutput.AppendText("$(timestamp) Back up your system and proceed with caution!`r`n`n")
$WPFRemovecrAPPProvisioningCheckBox.Foreground = "#FFDA1212"
$WPFRemovecrAPPProvisioningCheckBox.BorderBrush = "Red"
})
#endregion

#===========================================================================
#region Uncheck Remove Provisioning Checkbox (Win10 crAPPs Tab)
#===========================================================================

$WPFRemovecrAPPProvisioningCheckBox.Add_Unchecked({
$WPFworkingOutput.AppendText("$(timestamp) *** Remove AppxProvisioning DISABLED ***`r`n")
$WPFworkingOutput.AppendText("$(timestamp) Removed apps may more likely be re-installable.`r`n")
$WPFworkingOutput.AppendText("$(timestamp) Still, back up your system and proceed with caution!`r`n`n")
$WPFRemovecrAPPProvisioningCheckBox.Foreground = "#FF000000"
$WPFRemovecrAPPProvisioningCheckBox.BorderBrush = "#FF707070"
})
#endregion
#region

#===========================================================================
#region Check/Uncheck All Checkbox (Win10 crAPPs Tab)
#===========================================================================

#=== Check All Checkbox (Checked) ===#
$WPFCheckAllcrAPPsButton.Add_Click({
$crAPPListUnchecked = $WPFcrAPPListBox.Items | Where-Object {$_.IsChecked -eq $false}
if (!($crAPPListUnchecked)) {
$WPFworkingOutput.AppendText("$(timestamp) Nothing to check. Click 'Load crAPP List' button or uncheck something.`r`n")
} else {
ForEach ($unchecked in $crAPPListUnchecked) {
$unchecked.IsChecked = $true
}
$WPFworkingOutput.AppendText("$(timestamp) Checked all crAPPs.`r`n")
}
})

#=== Uncheck All Checkbox (Checked) ===#
$WPFUncheckAllcrAPPsButton.Add_Click({
$crAPPListChecked = $WPFcrAPPListBox.Items | Where-Object {$_.IsChecked -eq $true}
if (!($crAPPListChecked)) {
$WPFworkingOutput.AppendText("$(timestamp) Nothing to uncheck. Click 'Load crAPP List' button or check something.`r`n")
} else {
ForEach ($checked in $crAPPListChecked) {
$checked.IsChecked = $false
}
$WPFworkingOutput.AppendText("$(timestamp) Unchecked all crAPPs.`r`n`n")
}
})
#endregion

#===========================================================================
#region Remove Selected Apps Button (Win10 crAPPs Tab)
#===========================================================================

$WPFRemoveSelectedcrAPPsButton.Add_Click({
Set-Variable -Name "CheckedcrAPPs" -Value ($WPFcrAPPListBox.Items | Where-Object {$_.IsChecked -eq $true}) -Scope Global
if (!($CheckedcrAPPs)) {
$WPFworkingOutput.AppendText("$(timestamp) No crAPPs selected. Click 'Load crAPP List' button or check something.`r`n")
} else {
if ($WPFRemovecrAPPProvisioningCheckBox.IsChecked -eq $true) {
$WPFworkingOutput.AppendText("$(timestamp) Remove AppxProvisioning Checkbox IS checked.`r`n")
$WPFworkingOutput.AppendText("$(timestamp) Attempting to also remove AppXProvisionedPackages associated with each AppxPackage.`r`n")
} else {
$WPFworkingOutput.AppendText("$(timestamp) Remove AppxProvisioning Checkbox is OFF, ignoring.`r`n")
}
#$CheckedcrAPPs.Content # AppxPackage Name field
#$CheckedcrAPPs.ToolTip # AppxPackage PackageFullName field
#$CheckedcrAPPs.Tag # AppxPackage InstallLocation field
$WPFworkingOutput.AppendText("`r$(timestamp) *** Removing selected crAPPs ***`r`n`n")
ForEach ($crAPPyAPP in $CheckedcrAPPs) {
$AppxPackageFullName = Get-AppxPackage -Name $crAPPyAPP.Content -AllUsers | Select-Object -ExpandProperty PackageFullName -First 1
$AppxProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $crAPPyAPP.Content } | Select-Object -ExpandProperty PackageName -First 1
$WPFworkingOutput.AppendText("$(timestamp) PROCESSING: $($crAPPyAPP.Content)`r`n")
$WPFworkingOutput.AppendText("`t`t`t`t`t$($crAPPyAPP.ToolTip)`r`n")
$WPFworkingOutput.AppendText("`t`t`t`t`t$($crAPPyAPP.Tag)`r`n")
if ($AppxPackageFullName -ne $null) {
try {
$WPFworkingOutput.AppendText("$(timestamp) UNINSTALLING AppxPackage: '$($AppxPackageFullName)'...`r`n")
Remove-AppxPackage -Package $AppxPackageFullName -AllUsers -ErrorAction Stop | Out-Null
$WPFworkingOutput.AppendText("$(timestamp) SUCCESS: '$($AppxPackageFullName)' uninstall completed.`r`n")
$WPFworkingOutput.AppendText("*** To reinstall manually, try running the following command:  'Add-AppxPackage -Register '$($crAPPyAPP.Tag)\appxmanifest.xml' -DisableDevelopmentMode'`r`n")
}
catch [System.Exception] {
$WPFworkingOutput.AppendText("$(timestamp) FAILURE: Uninstall of AppxPackage '$($AppxPackageFullName)' failed: $($_.Exception.Message)`r`n")
}
} else {
$WPFworkingOutput.AppendText("$(timestamp) ERROR: Unable to locate AppxPackage: '$($crAPPyAPP.ToolTip)'`r`n")
}
if ($WPFRemovecrAPPProvisioningCheckBox.IsChecked -eq $true) {
if ($AppxProvisioningPackageName -ne $null) {
try {
$WPFworkingOutput.AppendText("$(timestamp) UNINSTALLING AppxProvisioningPackage: '$($AppxProvisioningPackageName)'...`r`n")
Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like $AppxProvisioningPackageName} | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
$WPFworkingOutput.AppendText("$(timestamp) SUCCESS: '$($AppxProvisioningPackageName)' uninstall completed.`r`n")
}
catch [System.Exception] {
$WPFworkingOutput.AppendText("$(timestamp) FAILURE: Uninstall of AppxProvisioningPackage '$($AppxProvisioningPackageName)' failed: $($_.Exception.Message)`r`n")
}
} else {
$WPFworkingOutput.AppendText("$(timestamp) ERROR: Unable to locate AppxProvisioningPackage: '$($crAPPyAPP.ToolTip)'`r`n")
}
}
}
}
})
#endregion

#===========================================================================
#region Undo crAPP Removal Button (Win10 crAPPs Tab)
#===========================================================================

$WPFUndoRemovedcrAPPsButton.Add_Click({
if (!($CheckedcrAPPs)) {
$WPFworkingOutput.AppendText("$(timestamp) No crAPPs selected, or you haven't removed anything yet from THIS session. Click 'Load crAPP List' button or check something.`r`n")
} else {
ForEach ($crAPPyAPP in $CheckedcrAPPs) {
if (!(Test-Path -Path "$($crAPPyAPP.Tag)\AppxManifest.xml")) {
   if (!(Test-Path -Path "C:\Program Files\WindowsApps\Deleted\$($crAPPyAPP.ToolTip)\AppxManifest.xml")) {
if (!(Test-Path -Path "C:\Program Files\WindowsApps\DeletedAllUserPackages\$($crAPPyAPP.ToolTip)\AppxManifest.xml")) {
if (!(Test-Path -Path "C:\Program Files\WindowsApps\MovedPackages\$($crAPPyAPP.ToolTip)\AppxManifest.xml")) {
$WPFworkingOutput.AppendText("$(timestamp) FAILURE: $($crAPPyAPP.ToolTip) installation files cannot be found. Try restoring from backup.`r`n")
}
}
}
}
$WPFworkingOutput.AppendText("`r$(timestamp) *** Attempting to REINSTALL selected crAPPs ***`r`n`n")
try {
Add-AppxPackage -register "$($crAPPyAPP.Tag)\AppxManifest.xml" -DisableDevelopmentMode -ErrorAction Stop | Out-Null
$WPFworkingOutput.AppendText("$(timestamp) SUCCESS: $($crAPPyAPP.ToolTip) reinstallation was successfull.`r`n")
}
catch [System.Exception] {
$WPFworkingOutput.AppendText("$(timestamp) FAILURE: Reinstallation of AppxProvisioningPackage '$($crAPPyAPP.ToolTip)' failed: $($_.Exception.Message)`r`n")
}
}
}
})
#endregion

#===========================================================================
#region Fix Windows Update Button (Win10 crAPPs Tab)
#===========================================================================

$WPFFixWindowsUpdateButton.Add_Click({
$WPFworkingOutput.AppendText("`r`n$(timestamp) Fix Windows Update button clicked...`r`n")
$msgBoxInput =  [System.Windows.MessageBox]::Show("This will launch CMD.exe and run the following commands to fix Windows Updates if it's broken, and then scan and fix system files.`r`n`r`n`t1. DISM.exe /Online /Cleanup-image /Restorehealth`r`n`t2. sfc /scannow`r`n`r`nThis could take up to 30 minutes depeding on your system.`r`n`r`nWould you like to proceed?","Fix Windows Update Confirmation | Windows 10 crAPP Remover Fix Windows Update","YesNo","Warning")
switch  ($msgBoxInput) {
'Yes' {
$WPFStatusBarText.Text = "Launched 'Fix Windows Update', ready..."
Start-Process 'cmd.exe' -Verb RunAs -ArgumentList '/c echo ******************************************************************************************* && echo Running DISM /Online /Cleanup-image /Restorehealth. This may take a few minutes... && echo ******************************************************************************************* && DISM.exe /Online /Cleanup-image /Restorehealth && echo. && echo ******************************************************************************************* && echo Running sfc /scannow command. This may take a few minutes... && echo ******************************************************************************************* && sfc /scannow && exit'
$WPFworkingOutput.AppendText("`r`n$(timestamp) Running 'Fix Windows Update'.`r`n")
}
'No' {
$WPFStatusBarText.Text = "Fix Winodws Update operation cancelled, ready..."
$WPFworkingOutput.AppendText("`r`n$(timestamp) Fix Windows Update operation cancelled.`r`n")
[System.Windows.Forms.MessageBox]::Show("Operation has been cancelled. No changes were made.","Fix Windows Update Confirmation | Windows 10 crAPP Remover Fix Windows Update")
}
}
})
#endregion

#===========================================================================
#region Button (Win10 crAPPs Tab)
#===========================================================================

$WPFExportLogButton.Add_Click({
$WPFworkingOutput.AppendText("`r`n$(timestamp) Exporting crAPP Removal log...`r`n")
$SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveDialog.InitialDirectory = "$ENV:USERPROFILE\Desktop"
$SaveDialog.Filter = "LOG Files (*.log)|*.log|All files (*.*)|*.*"
$SaveDialog.ShowDialog() | Out-Null
$WPFworkingOutput.Text >> $SaveDialog.Filename #$outDir"\Win10crAPPRemover_crAPPRemoval.LOG"
if ($SaveDialog.Filename) {
[System.Windows.Forms.MessageBox]::Show("Logs exported at $($SaveDialog.Filename)","Log Export | Windows 10 crAPP Remover")
} else {
$WPFworkingOutput.AppendText("`r`n$(timestamp) Log export cancelled.`r`n")
}
})
#endregion


#endregion

#
#
#
#
#
#===========================================================================
#region Privacy Settings Tab
#===========================================================================
#
#
#
#
#

$WPFworkingOutputPrivacySettings.Foreground = "LightGreen"
$WPFworkingOutputPrivacySettings.AppendText(" Right-click on settings for more information about them.  ---->`r`n`n")

#===========================================================================
#region Perform System Checkpoint Button (Privacy Settings Tab)
#===========================================================================

$WPFPerformSystemCheckpointButton.Add_Click({
$WPFworkingOutputPrivacySettings.AppendText("INFO: This button will enable system restore and perform a system checkpoint,`r`n")
$WPFworkingOutputPrivacySettings.AppendText("`twhich can be managed via 'SystemPropertiesProtection.exe'.`r`n")

$msgBoxInput =  [System.Windows.MessageBox]::Show("Would you like to enable System Restore and perform a System Checkpoint, which can be managed via 'SystemPropertiesProtection.exe'?`r`n`r`nNOTE: By default, only one Restore Point can be created in a 24-hour period.`r`n`r`nWould you like to temporarily bypass this restriction and create a System Restore Point anyways?","System Checkpoint | Windows 10 crAPP Remover","YesNo","Warning")
switch  ($msgBoxInput) {
'Yes' {
$WPFworkingOutputPrivacySettings.AppendText("INFO: Enabling services 'VSS', 'swprv', 'smphost'.`r`n")
(Get-Service VSS,swprv,smphost -ErrorAction SilentlyContinue | Start-Service -PassThru | Set-Service -StartupType Automatic)
$WPFworkingOutputPrivacySettings.AppendText("INFO: Enabling system restore.`r`n")
(Enable-ComputerRestore -Drive "C:\")

#=== Bypass 24-hour Restore Point Restriction ===#
Set-Variable -Name "BypassRestorePointRestrictionRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Scope Global
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Bypass 24-hour Restore Point Restriction #`r`n")
if (Test-Path $BypassRestorePointRestrictionRegPath) {
$BypassRestorePointRestrictionRegPathBackup = "$($BypassRestorePointRestrictionRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $BypassRestorePointRestrictionRegPath to $BypassRestorePointRestrictionRegPathBackup.`r`n")
[Void](Copy-Item -Path $BypassRestorePointRestrictionRegPath -Destination $BypassRestorePointRestrictionRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $BypassRestorePointRestrictionRegPath to $BypassRestorePointRestrictionRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $BypassRestorePointRestrictionRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $BypassRestorePointRestrictionRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BYPASSING: '24-hour Restore Point Restriction'.'`r`n")
[Void](New-ItemProperty -Path $BypassRestorePointRestrictionRegPath -Name "SystemRestorePointCreationFrequency" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SystemRestorePointCreationFrequency' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: 'Bypass 24-hour Restore Point Restriction' has been applied.`r`n")

$WPFworkingOutputPrivacySettings.AppendText("INFO: Attempting system checkpoint.`r`n")
(Checkpoint-Computer -Description "Win10crAPPRemover - App & Privacy Settings Checkpoint" -RestorePointType "MODIFY_SETTINGS")

#=== Restore 24-hour Restore Point Restriction ===#
Set-Variable -Name "RestoreRestorePointRestrictionRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Scope Global
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Restore 24-hour Restore Point Restriction #`r`n")
if (Test-Path $RestoreRestorePointRestrictionRegPath) {
$RestoreRestorePointRestrictionRegPathBackup = "$($RestoreRestorePointRestrictionRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $RestoreRestorePointRestrictionRegPath to $RestoreRestorePointRestrictionRegPathBackup.`r`n")
[Void](Copy-Item -Path $RestoreRestorePointRestrictionRegPath -Destination $RestoreRestorePointRestrictionRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $RestoreRestorePointRestrictionRegPath to $RestoreRestorePointRestrictionRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $RestoreRestorePointRestrictionRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $RestoreRestorePointRestrictionRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) RESTORING: '24-hour Restore Point Restriction'.`r`n")
[Void](Remove-ItemProperty -Path $RestoreRestorePointRestrictionRegPath -Name "SystemRestorePointCreationFrequency" -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DELETED REG VALUE: 'SystemRestorePointCreationFrequency'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: 'Restore 24-hour Restore Point Restriction' has been applied.`r`n")

$WPFworkingOutputPrivacySettings.AppendText("INFO: Finished. Open 'SystemPropertiesProtection.exe' to manage your System Restore Checkpoints.`r`n")
$msgBoxInput =  [System.Windows.MessageBox]::Show("Would you like to open 'SystemPropertiesProtection.exe' to manage your System Checkpoints?","System Checkpoint | Windows 10 crAPP Remover","YesNo","Warning")
switch  ($msgBoxInput) {
'Yes' {
Start-Process SystemPropertiesProtection.exe
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) OPENED: 'SystemPropertiesProtection.exe'.`r`n")
}
'No' {
# Do nothing.
}
}
}
'No' {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) 'Perform System Checkpoint' has been cancelled.`r`n")
}
}
})

#endregion

#===========================================================================
#region Privacy Settings Detection for Check List (Privacy Settings Tab)
#===========================================================================

function detectprivappsettings {
#=== Set Initial Detection to Unknown Blue ===#
$AppPrivacySettingsInitialNoDetect = $WPFPrivacySettingsListBox.Items | Where-Object {($_.IsChecked -eq $true) -or ($_.IsChecked -eq $false)}
ForEach ($checkbox in $AppPrivacySettingsInitialNoDetect) {
$checkbox.Foreground = "#0000FF"
$checkbox.IsChecked = $false
}
MountDefaultUserReg
Set-HKCR

############################# Privacy Settings ########################################

#=== Disable App Tracking CheckBox ===#
Set-Variable -Name "AppTrackRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Scope Global
Set-Variable -Name "AppTrackRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Scope Global
if ((Test-Path -Path $AppTrackRegPath) -or (Test-Path -Path $AppTrackRegPathD)) {
$AppTrackRegValue = (Get-ItemProperty -Path $AppTrackRegPath -Name Start_TrackProgs -ErrorAction SilentlyContinue).Start_TrackProgs
$AppTrackRegValueD = (Get-ItemProperty -Path $AppTrackRegPathD -Name Start_TrackProgs -ErrorAction SilentlyContinue).Start_TrackProgs
if (($AppTrackRegValue -ne "0") -or ($AppTrackRegValueD -ne "0")) {
$WPFDisableAppTrackingCheckBox.Foreground = "#FF0000"
$WPFDisableAppTrackingCheckBox.IsChecked = $false
} else {
$WPFDisableAppTrackingCheckBox.Foreground = "#FF369726"
$WPFDisableAppTrackingCheckBox.IsChecked = $false
}
} else {
$WPFDisableAppTrackingCheckBox.Foreground = "#FF0000"
$WPFDisableAppTrackingCheckBox.IsChecked = $false
}

#=== Disable Shared Experiences CheckBox ===#
Set-Variable -Name "SharedExpRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" -Scope Global
Set-Variable -Name "SharedExpRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CDP" -Scope Global
if ((Test-Path -Path $SharedExpRegPath) -or (Test-Path -Path $SharedExpRegPathD)) {
$SharedExpRegValue1 = (Get-ItemProperty -Path $SharedExpRegPath -Name RomeSdkChannelUserAuthzPolicy -ErrorAction SilentlyContinue).RomeSdkChannelUserAuthzPolicy
$SharedExpRegValue2 = (Get-ItemProperty -Path $SharedExpRegPath -Name CdpSessionUserAuthzPolicy -ErrorAction SilentlyContinue).CdpSessionUserAuthzPolicy
$SharedExpRegValueD1 = (Get-ItemProperty -Path $SharedExpRegPathD -Name RomeSdkChannelUserAuthzPolicy -ErrorAction SilentlyContinue).RomeSdkChannelUserAuthzPolicy
$SharedExpRegValueD2 = (Get-ItemProperty -Path $SharedExpRegPathD -Name CdpSessionUserAuthzPolicy -ErrorAction SilentlyContinue).CdpSessionUserAuthzPolicy
if (($SharedExpRegValue1 -ne "0") -or ($SharedExpRegValue2 -ne "0") -or ($SharedExpRegValueD1 -ne "0") -or ($SharedExpRegValueD2 -ne "0")) {
$WPFDisableSharedExperiencesCheckBox.Foreground = "#FF0000"
$WPFDisableSharedExperiencesCheckBox.IsChecked = $true
} else {
$WPFDisableSharedExperiencesCheckBox.Foreground = "#FF369726"
$WPFDisableSharedExperiencesCheckBox.IsChecked = $false
}
} else {
$WPFDisableSharedExperiencesCheckBox.Foreground = "#FF0000"
$WPFDisableSharedExperiencesCheckBox.IsChecked = $true
}

#=== Disable Tailored Experiences CheckBox ===#
Set-Variable -Name "TailoredExpRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Scope Global
Set-Variable -Name "TailoredExpRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Scope Global
if ((Test-Path -Path $TailoredExpRegPath) -or (Test-Path -Path $TailoredExpRegPathD)) {
$TailoredExpRegValue = (Get-ItemProperty -Path $TailoredExpRegPath -Name TailoredExperiencesWithDiagnosticDataEnabled -ErrorAction SilentlyContinue).TailoredExperiencesWithDiagnosticDataEnabled
$TailoredExpRegValueD = (Get-ItemProperty -Path $TailoredExpRegPathD -Name TailoredExperiencesWithDiagnosticDataEnabled -ErrorAction SilentlyContinue).TailoredExperiencesWithDiagnosticDataEnabled
if (($TailoredExpRegValue -ne "0") -or ($TailoredExpRegValueD -ne "0")) {
$WPFDisableTailoredExperiencesCheckBox.Foreground = "#FF0000"
$WPFDisableTailoredExperiencesCheckBox.IsChecked = $true
} else {
$WPFDisableTailoredExperiencesCheckBox.Foreground = "#FF369726"
$WPFDisableTailoredExperiencesCheckBox.IsChecked = $false
}
} else {
$WPFDisableTailoredExperiencesCheckBox.Foreground = "#FF0000"
$WPFDisableTailoredExperiencesCheckBox.IsChecked = $true
}

#=== Disable Advertising ID Sharing CheckBox ===#
Set-Variable -Name "AdIDRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Scope Global
Set-Variable -Name "AdIDRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Scope Global
if ((Test-Path -Path $AdIDRegPath) -or (Test-Path -Path $AdIDRegPathD)) {
$AdIDRegValue = (Get-ItemProperty -Path $AdIDRegPath -Name Enabled -ErrorAction SilentlyContinue).Enabled
$AdIDRegValueD = (Get-ItemProperty -Path $AdIDRegPathD -Name Enabled -ErrorAction SilentlyContinue).Enabled
if (($AdIDRegValue -ne "0") -or ($AdIDRegValueD -ne "0")) {
$WPFDisableAdvertisingIDCheckBox.Foreground = "#FF0000"
$WPFDisableAdvertisingIDCheckBox.IsChecked = $true
} else {
$WPFDisableAdvertisingIDCheckBox.Foreground = "#FF369726"
$WPFDisableAdvertisingIDCheckBox.IsChecked = $false
}
} else {
$WPFDisableAdvertisingIDCheckBox.Foreground = "#FF0000"
$WPFDisableAdvertisingIDCheckBox.IsChecked = $true
}

#=== Disable Windows 10 Feedback CheckBox ===#
Set-Variable -Name "Win10FeedbackRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Scope Global
Set-Variable -Name "Win10FeedbackRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Siuf\Rules" -Scope Global
if ((Test-Path -Path $Win10FeedbackRegPath) -or (Test-Path -Path $Win10FeedbackRegPathD)) {
$siuftest1 = (Get-ItemProperty -Path $Win10FeedbackRegPath -Name NumberOfSIUFInPeriod -ErrorAction SilentlyContinue).NumberOfSIUFInPeriod
$siuftest2 = (Get-ItemProperty -Path $Win10FeedbackRegPath -Name PeriodInNanoSeconds -ErrorAction SilentlyContinue).PeriodInNanoSeconds
$siuftest3 = (Get-ItemProperty -Path $Win10FeedbackRegPathD -Name NumberOfSIUFInPeriod -ErrorAction SilentlyContinue).NumberOfSIUFInPeriod
$siuftest4 = (Get-ItemProperty -Path $Win10FeedbackRegPathD -Name PeriodInNanoSeconds -ErrorAction SilentlyContinue).PeriodInNanoSeconds
if (($siuftest1 -ne "0") -or ($siuftest2 -ne "0") -or ($siuftest3 -ne "0") -or ($siuftest4 -ne "0")) {
$WPFDisableWindows10FeedbackCheckBox.Foreground = "#FF0000"
$WPFDisableWindows10FeedbackCheckBox.IsChecked = $true
} else {
$WPFDisableWindows10FeedbackCheckBox.Foreground = "#FF369726"
$WPFDisableWindows10FeedbackCheckBox.IsChecked = $false
}
} else {
$WPFDisableWindows10FeedbackCheckBox.Foreground = "#FF0000"
$WPFDisableWindows10FeedbackCheckBox.IsChecked = $true
}

#=== Disable Access to Language List CheckBox ===#
Set-Variable -Name "HttpAccept" -Value (Get-WinAcceptLanguageFromLanguageListOptOut) -Scope Global
if ($HttpAccept -eq $false) {
$WPFDisableHttpAcceptLanguageOptOutCheckBox.Foreground = "#FF0000"
$WPFDisableHttpAcceptLanguageOptOutCheckBox.IsChecked = $true
} elseif ($HttpAccept -eq $true) {
$WPFDisableHttpAcceptLanguageOptOutCheckBox.Foreground = "#FF369726"
$WPFDisableHttpAcceptLanguageOptOutCheckBox.IsChecked = $false
} else {
$WPFDisableHttpAcceptLanguageOptOutCheckBox.Foreground = "#0000FF"
$WPFDisableHttpAcceptLanguageOptOutCheckBox.Content = "Disable Access to Language List (status undetermined)"
}

#=== Disable Inking and Typing Recognition CheckBox ===#
Set-Variable -Name "InkTypeRecoRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Scope Global
Set-Variable -Name "InkTypeRecoRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Input\TIPC" -Scope Global
if ((Test-Path -Path $InkTypeRecoRegPath) -or (Test-Path -Path $InkTypeRecoRegPathD)) {
$InkTypeRecoRegValue = (Get-ItemProperty -Path $InkTypeRecoRegPath -Name Enabled -ErrorAction SilentlyContinue).Enabled
$InkTypeRecoRegValueD = (Get-ItemProperty -Path $InkTypeRecoRegPathD -Name Enabled -ErrorAction SilentlyContinue).Enabled
if (($InkTypeRecoRegValue -ne "0") -or ($InkTypeRecoRegValueD -ne "0")) {
$WPFDisableInkTypeRecognitionCheckBox.Foreground = "#FF0000"
$WPFDisableInkTypeRecognitionCheckBox.IsChecked = $true
} else {
$WPFDisableInkTypeRecognitionCheckBox.Foreground = "#FF369726"
$WPFDisableInkTypeRecognitionCheckBox.IsChecked = $false
}
} else {
$WPFDisableInkTypeRecognitionCheckBox.Foreground = "#FF0000"
$WPFDisableInkTypeRecognitionCheckBox.IsChecked = $true
}

#=== Disable Pen and Ink Recommendations CheckBox ===#
Set-Variable -Name "PenInkRecoRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace" -Scope Global
Set-Variable -Name "PenInkRecoRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace" -Scope Global
if ((Test-Path -Path $PenInkRecoRegPath) -or (Test-Path -Path $PenInkRecoRegPathD)) {
$PenInkRecoRegValue = (Get-ItemProperty -Path $PenInkRecoRegPath -Name PenWorkspaceAppSuggestionsEnabled -ErrorAction SilentlyContinue).PenWorkspaceAppSuggestionsEnabled
$PenInkRecoRegValueD = (Get-ItemProperty -Path $PenInkRecoRegPathD -Name PenWorkspaceAppSuggestionsEnabled -ErrorAction SilentlyContinue).PenWorkspaceAppSuggestionsEnabled
if (($PenInkRecoRegValue -ne "0") -or ($PenInkRecoRegValueD -ne "0")) {
$WPFDisablePenInkRecommendationsCheckBox.Foreground = "#FF0000"
$WPFDisablePenInkRecommendationsCheckBox.IsChecked = $true
} else {
$WPFDisablePenInkRecommendationsCheckBox.Foreground = "#FF369726"
$WPFDisablePenInkRecommendationsCheckBox.IsChecked = $false
}
} else {
$WPFDisablePenInkRecommendationsCheckBox.Foreground = "#FF0000"
$WPFDisablePenInkRecommendationsCheckBox.IsChecked = $true
}

#=== Disable Inking and Typing Personalization CheckBox ===#
Set-Variable -Name "InkTypePersRegPath1" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Scope Global
Set-Variable -Name "InkTypePersRegPath2" -Value "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Scope Global
Set-Variable -Name "InkTypePersRegPath3" -Value "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Scope Global
Set-Variable -Name "InkTypePersRegPath35" -Value "HKCU:\SOFTWARE\Microsoft\Personalization" -Scope Global
Set-Variable -Name "InkTypePersRegPath4" -Value "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Scope Global
Set-Variable -Name "InkTypePersRegPathD1" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Scope Global
Set-Variable -Name "InkTypePersRegPathD2" -Value "$HKLMD\SOFTWARE\Microsoft\InputPersonalization" -Scope Global
Set-Variable -Name "InkTypePersRegPathD3" -Value "$HKLMD\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Scope Global
Set-Variable -Name "InkTypePersRegPathD35" -Value "$HKLMD\SOFTWARE\Microsoft\Personalization" -Scope Global
Set-Variable -Name "InkTypePersRegPathD4" -Value "$HKLMD\SOFTWARE\Microsoft\Personalization\Settings" -Scope Global
if ((Test-Path -Path $InkTypePersRegPath1) -or (Test-Path -Path $InkTypePersRegPathD1) -or (Test-Path -Path $InkTypePersRegPath2) -or (Test-Path -Path $InkTypePersRegPathD2) -or (Test-Path -Path $InkTypePersRegPath3) -or (Test-Path -Path $InkTypePersRegPathD3) -or (Test-Path -Path $InkTypePersRegPath4) -or (Test-Path -Path $InkTypePersRegPathD4)) {
$InkTypePersRegValue1 = (Get-ItemProperty -Path $InkTypePersRegPath1 -Name Enabled -ErrorAction SilentlyContinue).Enabled
$InkTypePersRegValue2 = (Get-ItemProperty -Path $InkTypePersRegPath2 -Name RestrictImplicitTextCollection -ErrorAction SilentlyContinue).RestrictImplicitTextCollection
$InkTypePersRegValue3 = (Get-ItemProperty -Path $InkTypePersRegPath2 -Name RestrictImplicitInkCollection -ErrorAction SilentlyContinue).RestrictImplicitInkCollection
$InkTypePersRegValue4 = (Get-ItemProperty -Path $InkTypePersRegPath3 -Name HarvestContacts -ErrorAction SilentlyContinue).HarvestContacts
$InkTypePersRegValue5 = (Get-ItemProperty -Path $InkTypePersRegPath4 -Name AcceptedPrivacyPolicy -ErrorAction SilentlyContinue).AcceptedPrivacyPolicy
$InkTypePersRegValueD1 = (Get-ItemProperty -Path $InkTypePersRegPathD1 -Name Enabled -ErrorAction SilentlyContinue).Enabled
$InkTypePersRegValueD2 = (Get-ItemProperty -Path $InkTypePersRegPathD2 -Name RestrictImplicitTextCollection -ErrorAction SilentlyContinue).RestrictImplicitTextCollection
$InkTypePersRegValueD3 = (Get-ItemProperty -Path $InkTypePersRegPathD2 -Name RestrictImplicitInkCollection -ErrorAction SilentlyContinue).RestrictImplicitInkCollection
$InkTypePersRegValueD4 = (Get-ItemProperty -Path $InkTypePersRegPathD3 -Name HarvestContacts -ErrorAction SilentlyContinue).HarvestContacts
$InkTypePersRegValueD5 = (Get-ItemProperty -Path $InkTypePersRegPathD4 -Name AcceptedPrivacyPolicy -ErrorAction SilentlyContinue).AcceptedPrivacyPolicy
if (($InkTypePersRegValue1 -ne "0") -or ($InkTypePersRegValueD1 -ne "0") -or ($InkTypePersRegValue2 -ne "1") -or ($InkTypePersRegValueD2 -ne "1") -or ($InkTypePersRegValue3 -ne "1") -or ($InkTypePersRegValueD3 -ne "1") -or ($InkTypePersRegValue4 -ne "0") -or ($InkTypePersRegValueD4 -ne "0") -or ($InkTypePersRegValue5 -ne "0") -or ($InkTypePersRegValueD5 -ne "0")) {
$WPFDisableInkTypePersonalizationCheckBox.Foreground = "#FF0000"
$WPFDisableInkTypePersonalizationCheckBox.IsChecked = $true
} else {
$WPFDisableInkTypePersonalizationCheckBox.Foreground = "#FF369726"
$WPFDisableInkTypePersonalizationCheckBox.IsChecked = $false
}
} else {
$WPFDisableInkTypePersonalizationCheckBox.Foreground = "#FF0000"
$WPFDisableInkTypePersonalizationCheckBox.IsChecked = $true
}

#=== Disable Inventory Collector CheckBox ===#
Set-Variable -Name "DisableInventoryCollectorRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Scope Global
if (Test-Path -Path $DisableInventoryCollectorRegPath) {
$DisableInventoryCollectorRegValue = (Get-ItemProperty -Path $DisableInventoryCollectorRegPath -Name DisableInventory -ErrorAction SilentlyContinue).DisableInventory
if ($DisableInventoryCollectorRegValue -ne "0") {
$WPFDisableInventoryCollectorCheckBox.Foreground = "#FF0000"
$WPFDisableInventoryCollectorCheckBox.IsChecked = $true
} else {
$WPFDisableInventoryCollectorCheckBox.Foreground = "#FF369726"
$WPFDisableInventoryCollectorCheckBox.IsChecked = $false
}
} else {
$WPFDisableInventoryCollectorCheckBox.Foreground = "#FF0000"
$WPFDisableInventoryCollectorCheckBox.IsChecked = $true
}

#=== Disable Application Telemetry CheckBox ===#
Set-Variable -Name "DisableApplicationTelemetryRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Scope Global
if (Test-Path -Path $DisableApplicationTelemetryRegPath) {
$DisableApplicationTelemetryRegValue = (Get-ItemProperty -Path $DisableApplicationTelemetryRegPath -Name AITEnable -ErrorAction SilentlyContinue).AITEnable
if ($DisableApplicationTelemetryRegValue -ne "0") {
$WPFDisableApplicationTelemetryCheckBox.Foreground = "#FF0000"
$WPFDisableApplicationTelemetryCheckBox.IsChecked = $true
} else {
$WPFDisableApplicationTelemetryCheckBox.Foreground = "#FF369726"
$WPFDisableApplicationTelemetryCheckBox.IsChecked = $false
}
} else {
$WPFDisableApplicationTelemetryCheckBox.Foreground = "#FF0000"
$WPFDisableApplicationTelemetryCheckBox.IsChecked = $true
}

#=== Disable Location Globally CheckBox ===#
Set-Variable -Name "DisableLocationGloballyRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Scope Global
if (Test-Path -Path $DisableLocationGloballyRegPath) {
$DisableLocationGloballyRegValue = (Get-ItemProperty -Path $DisableLocationGloballyRegPath -Name Value -ErrorAction SilentlyContinue).Value
if ($DisableLocationGloballyRegValue -ne "Deny") {
$WPFDisableLocationGloballyCheckBox.Foreground = "#FF0000"
$WPFDisableLocationGloballyCheckBox.IsChecked = $false
} else {
$WPFDisableLocationGloballyCheckBox.Foreground = "#FF369726"
$WPFDisableLocationGloballyCheckBox.IsChecked = $false
}
} else {
$WPFDisableLocationGloballyCheckBox.Foreground = "#FF0000"
$WPFDisableLocationGloballyCheckBox.IsChecked = $false
}

#=== Disable Telemetry CheckBox ===#
Set-Variable -Name "DisableTelemetryRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Scope Global
if (Test-Path -Path $DisableTelemetryRegPath) {
$DisableTelemetryRegValue = (Get-ItemProperty -Path $DisableTelemetryRegPath -Name AllowTelemetry -ErrorAction SilentlyContinue).AllowTelemetry
if ($DisableTelemetryRegValue -ne "0") {
$WPFDisableTelemetryCheckBox.Foreground = "#FF0000"
$WPFDisableTelemetryCheckBox.IsChecked = $true
} else {
$WPFDisableTelemetryCheckBox.Foreground = "#FF369726"
$WPFDisableTelemetryCheckBox.IsChecked = $false
}
} else {
$WPFDisableTelemetryCheckBox.Foreground = "#FF0000"
$WPFDisableTelemetryCheckBox.IsChecked = $true
}

#=== Disable Edge Tracking CheckBox ===#
Set-Variable -Name "DisableEdgeTrackingRegPath1" -Value "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge" -Scope Global
Set-Variable -Name "DisableEdgeTrackingRegPath2" -Value "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Scope Global
if (Test-Path -Path $DisableEdgeTrackingRegPath2) {
$DisableEdgeTrackingRegValue = (Get-ItemProperty -Path $DisableEdgeTrackingRegPath2 -Name DoNotTrack -ErrorAction SilentlyContinue).DoNotTrack
if ($DisableEdgeTrackingRegValue -ne "1") {
$WPFDisableEdgeTrackingCheckBox.Foreground = "#FF0000"
$WPFDisableEdgeTrackingCheckBox.IsChecked = $true
} else {
$WPFDisableEdgeTrackingCheckBox.Foreground = "#FF369726"
$WPFDisableEdgeTrackingCheckBox.IsChecked = $false
}
} else {
$WPFDisableEdgeTrackingCheckBox.Foreground = "#FF0000"
$WPFDisableEdgeTrackingCheckBox.IsChecked = $true
}

############################# Cortana #################################################

#=== Disable Cortana CheckBox ===#
Set-Variable -Name "DisableCortanaRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Scope Global
if (Test-Path -Path $DisableCortanaRegPath) {
$DisableCortanaRegValue = (Get-ItemProperty -Path $DisableCortanaRegPath -Name AllowCortana -ErrorAction SilentlyContinue).AllowCortana
if ($DisableCortanaRegValue -ne "0") {
$WPFDisableCortanaCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaCheckBox.IsChecked = $false
} else {
$WPFDisableCortanaCheckBox.Foreground = "#FF369726"
$WPFDisableCortanaCheckBox.IsChecked = $false
}
} else {
$WPFDisableCortanaCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaCheckBox.IsChecked = $false
}

#=== Disable Cortana on Lock Screen CheckBox ===#
Set-Variable -Name "DisableCortanaLokScrnRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Scope Global
if (Test-Path -Path $DisableCortanaLokScrnRegPath) {
$DisableCortanaLokScrnRegValue = (Get-ItemProperty -Path $DisableCortanaLokScrnRegPath -Name AllowCortanaAboveLock -ErrorAction SilentlyContinue).AllowCortanaAboveLock
if ($DisableCortanaLokScrnRegValue -ne "0") {
$WPFDisableCortanaOnLockScreenCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaOnLockScreenCheckBox.IsChecked = $true
} else {
$WPFDisableCortanaOnLockScreenCheckBox.Foreground = "#FF369726"
$WPFDisableCortanaOnLockScreenCheckBox.IsChecked = $false
}
} else {
$WPFDisableCortanaOnLockScreenCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaOnLockScreenCheckBox.IsChecked = $true
}

#=== Disable Cortana Above Lock Screen CheckBox ===#
Set-Variable -Name "DisableCortanaAboveLockScreenRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Preferences" -Scope Global
Set-Variable -Name "DisableCortanaAboveLockScreenRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Speech_OneCore\Preferences" -Scope Global
if ((Test-Path -Path $DisableCortanaAboveLockScreenRegPath) -or (Test-Path -Path $DisableCortanaAboveLockScreenRegPathD)) {
$DisableCortanaAboveLockScreenRegValue = (Get-ItemProperty -Path $DisableCortanaAboveLockScreenRegPath -Name VoiceActivationEnableAboveLockscreen -ErrorAction SilentlyContinue).VoiceActivationEnableAboveLockscreen
$DisableCortanaAboveLockScreenRegValueD = (Get-ItemProperty -Path $DisableCortanaAboveLockScreenRegPathD -Name VoiceActivationEnableAboveLockscreen -ErrorAction SilentlyContinue).VoiceActivationEnableAboveLockscreen
if (($DisableCortanaAboveLockScreenRegValue -ne "0") -or ($DisableCortanaAboveLockScreenRegValueD -ne "0")) {
$WPFDisableCortanaAboveLockScreenCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaAboveLockScreenCheckBox.IsChecked = $true
} else {
$WPFDisableCortanaAboveLockScreenCheckBox.Foreground = "#FF369726"
$WPFDisableCortanaAboveLockScreenCheckBox.IsChecked = $false
}
} else {
$WPFDisableCortanaAboveLockScreenCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaAboveLockScreenCheckBox.IsChecked = $true
}

#=== Disable Cortana and Bing Search CheckBox ===#
Set-Variable -Name "DisableCortanaAndBingSearchRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
Set-Variable -Name "DisableCortanaAndBingSearchRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
if ((Test-Path -Path $DisableCortanaAndBingSearchRegPath) -or (Test-Path -Path $DisableCortanaAndBingSearchRegPathD)) {
$DisableCortanaAndBingSearchRegValue1 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name CortanaEnabled -ErrorAction SilentlyContinue).CortanaEnabled
$DisableCortanaAndBingSearchRegValue2 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name CanCortanaBeEnabled -ErrorAction SilentlyContinue).CanCortanaBeEnabled
$DisableCortanaAndBingSearchRegValue3 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name BingSearchEnabled -ErrorAction SilentlyContinue).BingSearchEnabled
$DisableCortanaAndBingSearchRegValue4 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name DeviceHistoryEnabled -ErrorAction SilentlyContinue).DeviceHistoryEnabled
$DisableCortanaAndBingSearchRegValue5 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name CortanaConsent -ErrorAction SilentlyContinue).CortanaConsent
$DisableCortanaAndBingSearchRegValue6 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name CortanaInAmbientMode -ErrorAction SilentlyContinue).CortanaInAmbientMode
$DisableCortanaAndBingSearchRegValueD1 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name CortanaEnabled -ErrorAction SilentlyContinue).CortanaEnabled
$DisableCortanaAndBingSearchRegValueD2 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name CanCortanaBeEnabled -ErrorAction SilentlyContinue).CanCortanaBeEnabled
$DisableCortanaAndBingSearchRegValueD3 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name BingSearchEnabled -ErrorAction SilentlyContinue).BingSearchEnabled
$DisableCortanaAndBingSearchRegValueD4 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name DeviceHistoryEnabled -ErrorAction SilentlyContinue).DeviceHistoryEnabled
$DisableCortanaAndBingSearchRegValueD5 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name CortanaConsent -ErrorAction SilentlyContinue).CortanaConsent
$DisableCortanaAndBingSearchRegValueD6 = (Get-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name CortanaInAmbientMode -ErrorAction SilentlyContinue).CortanaInAmbientMode
if (($DisableCortanaAndBingSearchRegValue1 -ne "0") -or ($DisableCortanaAndBingSearchRegValueD1 -ne "0") -or ($DisableCortanaAndBingSearchRegValue2 -ne "0") -or ($DisableCortanaAndBingSearchRegValueD2 -ne "0") -or ($DisableCortanaAndBingSearchRegValue3 -ne "0") -or ($DisableCortanaAndBingSearchRegValueD3 -ne "0") -or ($DisableCortanaAndBingSearchRegValue4 -ne "0") -or ($DisableCortanaAndBingSearchRegValueD4 -ne "0") -or ($DisableCortanaAndBingSearchRegValue5 -ne "0") -or ($DisableCortanaAndBingSearchRegValueD5 -ne "0") -or ($DisableCortanaAndBingSearchRegValue6 -ne "0") -or ($DisableCortanaAndBingSearchRegValueD6 -ne "0")) {
$WPFDisableCortanaAndBingSearchScreenCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaAndBingSearchScreenCheckBox.IsChecked = $true
} else {
$WPFDisableCortanaAndBingSearchScreenCheckBox.Foreground = "#FF369726"
$WPFDisableCortanaAndBingSearchScreenCheckBox.IsChecked = $false
}
} else {
$WPFDisableCortanaAndBingSearchScreenCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaAndBingSearchScreenCheckBox.IsChecked = $true
}

#=== Disable Cortana Search History CheckBox ===#
Set-Variable -Name "DisableCortanaSearchHistoryRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
Set-Variable -Name "DisableCortanaSearchHistoryRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
if ((Test-Path -Path $DisableCortanaSearchHistoryRegPath) -or (Test-Path -Path $DisableCortanaSearchHistoryRegPathD)) {
$DisableCortanaSearchHistoryRegValue = (Get-ItemProperty -Path $DisableCortanaSearchHistoryRegPath -Name HistoryViewEnabled -ErrorAction SilentlyContinue).HistoryViewEnabled
$DisableCortanaSearchHistoryRegValueD = (Get-ItemProperty -Path $DisableCortanaSearchHistoryRegPathD -Name HistoryViewEnabled -ErrorAction SilentlyContinue).HistoryViewEnabled
if (($DisableCortanaSearchHistoryRegValue -ne "0") -or ($DisableCortanaSearchHistoryRegValueD -ne "0")) {
$WPFDisableCortanaSearchHistoryCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaSearchHistoryCheckBox.IsChecked = $true
} else {
$WPFDisableCortanaSearchHistoryCheckBox.Foreground = "#FF369726"
$WPFDisableCortanaSearchHistoryCheckBox.IsChecked = $false
}
} else {
$WPFDisableCortanaSearchHistoryCheckBox.Foreground = "#FF0000"
$WPFDisableCortanaSearchHistoryCheckBox.IsChecked = $true
}

############################# APP Permissions #########################################

#=== Deny Apps Running in Background CheckBox ===#
Set-Variable -Name "DenyAppsRunningInBackgroundRegPath1" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Scope Global
Set-Variable -Name "DenyAppsRunningInBackgroundRegPathD1" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Scope Global
Set-Variable -Name "DenyAppsRunningInBackgroundRegPath2" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
Set-Variable -Name "DenyAppsRunningInBackgroundRegPathD2" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
if ((Test-Path -Path $DenyAppsRunningInBackgroundRegPath1) -or (Test-Path -Path $DenyAppsRunningInBackgroundRegPathD1) -or(Test-Path -Path $DenyAppsRunningInBackgroundRegPath2) -or (Test-Path -Path $DenyAppsRunningInBackgroundRegPathD2)) {
$DenyAppsRunningInBackgroundRegValue1 = (Get-ItemProperty -Path $DenyAppsRunningInBackgroundRegPath1 -Name GlobalUserDisabled -ErrorAction SilentlyContinue).GlobalUserDisabled
$DenyAppsRunningInBackgroundRegValueD1 = (Get-ItemProperty -Path $DenyAppsRunningInBackgroundRegPathD1 -Name GlobalUserDisabled -ErrorAction SilentlyContinue).GlobalUserDisabled
$DenyAppsRunningInBackgroundRegValue2 = (Get-ItemProperty -Path $DenyAppsRunningInBackgroundRegPath2 -Name BackgroundAppGlobalToggle -ErrorAction SilentlyContinue).BackgroundAppGlobalToggle
$DenyAppsRunningInBackgroundRegValueD2 = (Get-ItemProperty -Path $DenyAppsRunningInBackgroundRegPathD2 -Name BackgroundAppGlobalToggle -ErrorAction SilentlyContinue).BackgroundAppGlobalToggle
if (($DenyAppsRunningInBackgroundRegValue1 -ne "1") -or ($DenyAppsRunningInBackgroundRegValueD1 -ne "1") -or($DenyAppsRunningInBackgroundRegValue2 -ne "0") -or ($DenyAppsRunningInBackgroundRegValueD2 -ne "0")) {
$WPFDenyAppsRunningInBackgroundCheckBox.Foreground = "#FF0000"
$WPFDenyAppsRunningInBackgroundCheckBox.IsChecked = $true
} else {
$WPFDenyAppsRunningInBackgroundCheckBox.Foreground = "#FF369726"
$WPFDenyAppsRunningInBackgroundCheckBox.IsChecked = $false
}
} else {
$WPFDenyAppsRunningInBackgroundCheckBox.Foreground = "#FF0000"
$WPFDenyAppsRunningInBackgroundCheckBox.IsChecked = $true
}

#=== Deny App Diagnostics CheckBox ===#
Set-Variable -Name "DenyAppDiagnosticsRegPath1" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess" -Scope Global
Set-Variable -Name "DenyAppDiagnosticsRegPathD1" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess" -Scope Global
Set-Variable -Name "DenyAppDiagnosticsRegPath2" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global" -Scope Global
Set-Variable -Name "DenyAppDiagnosticsRegPathD2" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global" -Scope Global
Set-Variable -Name "DenyAppDiagnosticsRegPath3" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2297E4E2-5DBE-466D-A12B-0F8286F0D9CA}" -Scope Global
Set-Variable -Name "DenyAppDiagnosticsRegPathD3" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2297E4E2-5DBE-466D-A12B-0F8286F0D9CA}" -Scope Global
if ((Test-Path -Path $DenyAppDiagnosticsRegPath3) -or (Test-Path -Path $DenyAppDiagnosticsRegPathD3)) {
$DenyAppDiagnosticsRegValue3 = (Get-ItemProperty -Path $DenyAppDiagnosticsRegPath3 -Name Value -ErrorAction SilentlyContinue).Value
$DenyAppDiagnosticsRegValueD3 = (Get-ItemProperty -Path $DenyAppDiagnosticsRegPathD3 -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyAppDiagnosticsRegValue3 -ne "Deny") -or ($DenyAppDiagnosticsRegValueD3 -ne "Deny")) {
$WPFDenyAppDiagnosticsCheckBox.Foreground = "#FF0000"
$WPFDenyAppDiagnosticsCheckBox.IsChecked = $false
} else {
$WPFDenyAppDiagnosticsCheckBox.Foreground = "#FF369726"
$WPFDenyAppDiagnosticsCheckBox.IsChecked = $false
}
} else {
$WPFDenyAppDiagnosticsCheckBox.Foreground = "#FF0000"
$WPFDenyAppDiagnosticsCheckBox.IsChecked = $false
}

#=== Deny Broad File System Access Access CheckBox ===#
Set-Variable -Name "DenyBroadFileSystemAccessAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" -Scope Global
Set-Variable -Name "DenyBroadFileSystemAccessAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" -Scope Global
if ((Test-Path -Path $DenyBroadFileSystemAccessAccessRegPath) -or (Test-Path -Path $DenyBroadFileSystemAccessAccessRegPathD)) {
$DenyBroadFileSystemAccessAccessRegValue = (Get-ItemProperty -Path $DenyBroadFileSystemAccessAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyBroadFileSystemAccessAccessRegValueD = (Get-ItemProperty -Path $DenyBroadFileSystemAccessAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyBroadFileSystemAccessAccessRegValue -ne "Deny") -or ($DenyBroadFileSystemAccessAccessRegValueD -ne "Deny")) {
$WPFDenyBroadFileSystemAccessAccessCheckBox.Foreground = "#FF0000"
$WPFDenyBroadFileSystemAccessAccessCheckBox.IsChecked = $true
} else {
$WPFDenyBroadFileSystemAccessAccessCheckBox.Foreground = "#FF369726"
$WPFDenyBroadFileSystemAccessAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyBroadFileSystemAccessAccessCheckBox.Foreground = "#FF0000"
$WPFDenyBroadFileSystemAccessAccessCheckBox.IsChecked = $true
}

#=== Deny Calendar Access CheckBox ===#
Set-Variable -Name "DenyCalendarAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" -Scope Global
Set-Variable -Name "DenyCalendarAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" -Scope Global
if ((Test-Path -Path $DenyCalendarAccessRegPath) -or (Test-Path -Path $DenyCalendarAccessRegPathD)) {
$DenyCalendarAccessRegValue = (Get-ItemProperty -Path $DenyCalendarAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyCalendarAccessRegValueD = (Get-ItemProperty -Path $DenyCalendarAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyCalendarAccessRegValue -ne "Deny") -or ($DenyCalendarAccessRegValueD -ne "Deny")) {
$WPFDenyCalendarAccessCheckBox.Foreground = "#FF0000"
$WPFDenyCalendarAccessCheckBox.IsChecked = $true
} else {
$WPFDenyCalendarAccessCheckBox.Foreground = "#FF369726"
$WPFDenyCalendarAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyCalendarAccessCheckBox.Foreground = "#FF0000"
$WPFDenyCalendarAccessCheckBox.IsChecked = $true
}

#=== Deny Cellular Data Access CheckBox ===#
Set-Variable -Name "DenyCellularDataAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\cellularData" -Scope Global
Set-Variable -Name "DenyCellularDataAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\cellularData" -Scope Global
if ((Test-Path -Path $DenyCellularDataAccessRegPath) -or (Test-Path -Path $DenyCellularDataAccessRegPathD)) {
$DenyCellularDataAccessRegValue = (Get-ItemProperty -Path $DenyCellularDataAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyCellularDataAccessRegValueD = (Get-ItemProperty -Path $DenyCellularDataAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyCellularDataAccessRegValue -ne "Deny") -or ($DenyCellularDataAccessRegValueD -ne "Deny")) {
$WPFDenyCellularDataAccessCheckBox.Foreground = "#FF0000"
$WPFDenyCellularDataAccessCheckBox.IsChecked = $true
} else {
$WPFDenyCellularDataAccessCheckBox.Foreground = "#FF369726"
$WPFDenyCellularDataAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyCellularDataAccessCheckBox.Foreground = "#FF0000"
$WPFDenyCellularDataAccessCheckBox.IsChecked = $true
}

#=== Deny Chat Access CheckBox ===#
Set-Variable -Name "DenyChatAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" -Scope Global
Set-Variable -Name "DenyChatAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" -Scope Global
if ((Test-Path -Path $DenyChatAccessRegPath) -or (Test-Path -Path $DenyChatAccessRegPathD)) {
$DenyChatAccessRegValue = (Get-ItemProperty -Path $DenyChatAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyChatAccessRegValueD = (Get-ItemProperty -Path $DenyChatAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyChatAccessRegValue -ne "Deny") -or ($DenyChatAccessRegValueD -ne "Deny")) {
$WPFDenyChatAccessCheckBox.Foreground = "#FF0000"
$WPFDenyChatAccessCheckBox.IsChecked = $true
} else {
$WPFDenyChatAccessCheckBox.Foreground = "#FF369726"
$WPFDenyChatAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyChatAccessCheckBox.Foreground = "#FF0000"
$WPFDenyChatAccessCheckBox.IsChecked = $true
}

#=== Deny Contacts Access CheckBox ===#
Set-Variable -Name "DenyContactsAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" -Scope Global
Set-Variable -Name "DenyContactsAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" -Scope Global
if ((Test-Path -Path $DenyContactsAccessRegPath) -or (Test-Path -Path $DenyContactsAccessRegPathD)) {
$DenyContactsAccessRegValue = (Get-ItemProperty -Path $DenyContactsAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyContactsAccessRegValueD = (Get-ItemProperty -Path $DenyContactsAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyContactsAccessRegValue -ne "Deny") -or ($DenyContactsAccessRegValueD -ne "Deny")) {
$WPFDenyContactsAccessCheckBox.Foreground = "#FF0000"
$WPFDenyContactsAccessCheckBox.IsChecked = $true
} else {
$WPFDenyContactsAccessCheckBox.Foreground = "#FF369726"
$WPFDenyContactsAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyContactsAccessCheckBox.Foreground = "#FF0000"
$WPFDenyContactsAccessCheckBox.IsChecked = $true
}

#=== Deny Documents Library Access CheckBox ===#
Set-Variable -Name "DenyDocumentsLibraryAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" -Scope Global
Set-Variable -Name "DenyDocumentsLibraryAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" -Scope Global
if ((Test-Path -Path $DenyDocumentsLibraryAccessRegPath) -or (Test-Path -Path $DenyDocumentsLibraryAccessRegPathD)) {
$DenyDocumentsLibraryAccessRegValue = (Get-ItemProperty -Path $DenyDocumentsLibraryAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyDocumentsLibraryAccessRegValueD = (Get-ItemProperty -Path $DenyDocumentsLibraryAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyDocumentsLibraryAccessRegValue -ne "Deny") -or ($DenyDocumentsLibraryAccessRegValueD -ne "Deny")) {
$WPFDenyDocumentsLibraryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyDocumentsLibraryAccessCheckBox.IsChecked = $true
} else {
$WPFDenyDocumentsLibraryAccessCheckBox.Foreground = "#FF369726"
$WPFDenyDocumentsLibraryAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyDocumentsLibraryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyDocumentsLibraryAccessCheckBox.IsChecked = $true
}

#=== Deny Email Access CheckBox ===#
Set-Variable -Name "DenyEmailAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" -Scope Global
Set-Variable -Name "DenyEmailAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" -Scope Global
if ((Test-Path -Path $DenyEmailAccessRegPath) -or (Test-Path -Path $DenyEmailAccessRegPathD)) {
$DenyEmailAccessRegValue = (Get-ItemProperty -Path $DenyEmailAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyEmailAccessRegValueD = (Get-ItemProperty -Path $DenyEmailAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyEmailAccessRegValue -ne "Deny") -or ($DenyEmailAccessRegValueD -ne "Deny")) {
$WPFDenyEmailAccessCheckBox.Foreground = "#FF0000"
$WPFDenyEmailAccessCheckBox.IsChecked = $true
} else {
$WPFDenyEmailAccessCheckBox.Foreground = "#FF369726"
$WPFDenyEmailAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyEmailAccessCheckBox.Foreground = "#FF0000"
$WPFDenyEmailAccessCheckBox.IsChecked = $true
}

#=== Deny Gaze Input Access CheckBox ===#
Set-Variable -Name "DenyGazeInputAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\gazeInput" -Scope Global
Set-Variable -Name "DenyGazeInputAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\gazeInput" -Scope Global
if ((Test-Path -Path $DenyGazeInputAccessRegPath) -or (Test-Path -Path $DenyGazeInputAccessRegPathD)) {
$DenyGazeInputAccessRegValue = (Get-ItemProperty -Path $DenyGazeInputAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyGazeInputAccessRegValueD = (Get-ItemProperty -Path $DenyGazeInputAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyGazeInputAccessRegValue -ne "Deny") -or ($DenyGazeInputAccessRegValueD -ne "Deny")) {
$WPFDenyGazeInputAccessCheckBox.Foreground = "#FF0000"
$WPFDenyGazeInputAccessCheckBox.IsChecked = $true
} else {
$WPFDenyGazeInputAccessCheckBox.Foreground = "#FF369726"
$WPFDenyGazeInputAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyGazeInputAccessCheckBox.Foreground = "#FF0000"
$WPFDenyGazeInputAccessCheckBox.IsChecked = $true
}

#=== Deny Location Access CheckBox ===#
Set-Variable -Name "DenyLocationAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Scope Global
Set-Variable -Name "DenyLocationAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Scope Global
if ((Test-Path -Path $DenyLocationAccessRegPath) -or (Test-Path -Path $DenyLocationAccessRegPathD)) {
$DenyLocationAccessRegValue = (Get-ItemProperty -Path $DenyLocationAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyLocationAccessRegValueD = (Get-ItemProperty -Path $DenyLocationAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyLocationAccessRegValue -ne "Deny") -or ($DenyLocationAccessRegValueD -ne "Deny")) {
$WPFDenyLocationAccessCheckBox.Foreground = "#FF0000"
$WPFDenyLocationAccessCheckBox.IsChecked = $true
} else {
$WPFDenyLocationAccessCheckBox.Foreground = "#FF369726"
$WPFDenyLocationAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyLocationAccessCheckBox.Foreground = "#FF0000"
$WPFDenyLocationAccessCheckBox.IsChecked = $true
}

#=== Deny Microphone Access CheckBox ===#
Set-Variable -Name "DenyMicrophoneAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" -Scope Global
Set-Variable -Name "DenyMicrophoneAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" -Scope Global
if ((Test-Path -Path $DenyMicrophoneAccessRegPath) -or (Test-Path -Path $DenyMicrophoneAccessRegPathD)) {
$DenyMicrophoneAccessRegValue = (Get-ItemProperty -Path $DenyMicrophoneAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyMicrophoneAccessRegValueD = (Get-ItemProperty -Path $DenyMicrophoneAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyMicrophoneAccessRegValue -ne "Deny") -or ($DenyMicrophoneAccessRegValueD -ne "Deny")) {
$WPFDenyMicrophoneAccessCheckBox.Foreground = "#FF0000"
$WPFDenyMicrophoneAccessCheckBox.IsChecked = $true
} else {
$WPFDenyMicrophoneAccessCheckBox.Foreground = "#FF369726"
$WPFDenyMicrophoneAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyMicrophoneAccessCheckBox.Foreground = "#FF0000"
$WPFDenyMicrophoneAccessCheckBox.IsChecked = $true
}

#=== Deny Notifications CheckBox ===#
Set-Variable -Name "DenyNotificationsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}" -Scope Global
Set-Variable -Name "DenyNotificationsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}" -Scope Global
if ((Test-Path -Path $DenyNotificationsRegPath) -or (Test-Path -Path $DenyNotificationsRegPathD)) {
$DenyNotificationsRegValue = (Get-ItemProperty -Path $DenyNotificationsRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyNotificationsRegValueD = (Get-ItemProperty -Path $DenyNotificationsRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyNotificationsRegValue -ne "Deny") -or ($DenyNotificationsRegValueD -ne "Deny")) {
$WPFDenyNotificationsCheckBox.Foreground = "#FF0000"
$WPFDenyNotificationsCheckBox.IsChecked = $false
} else {
$WPFDenyNotificationsCheckBox.Foreground = "#FF369726"
$WPFDenyNotificationsCheckBox.IsChecked = $false
}
} else {
$WPFDenyNotificationsCheckBox.Foreground = "#FF0000"
$WPFDenyNotificationsCheckBox.IsChecked = $false
}

#=== Deny Other Devices CheckBox ===#
Set-Variable -Name "DenyOtherDevicesRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled" -Scope Global
Set-Variable -Name "DenyOtherDevicesRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled" -Scope Global
if ((Test-Path -Path $DenyOtherDevicesRegPath) -or (Test-Path -Path $DenyOtherDevicesRegPathD)) {
$DenyOtherDevicesRegValue = (Get-ItemProperty -Path $DenyOtherDevicesRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyOtherDevicesRegValueD = (Get-ItemProperty -Path $DenyOtherDevicesRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyOtherDevicesRegValue -ne "Deny") -or ($DenyOtherDevicesRegValueD -ne "Deny")) {
$WPFDenyOtherDevicesCheckBox.Foreground = "#FF0000"
$WPFDenyOtherDevicesCheckBox.IsChecked = $false
} else {
$WPFDenyOtherDevicesCheckBox.Foreground = "#FF369726"
$WPFDenyOtherDevicesCheckBox.IsChecked = $false
}
} else {
$WPFDenyOtherDevicesCheckBox.Foreground = "#FF0000"
$WPFDenyOtherDevicesCheckBox.IsChecked = $false
}

#=== Deny Phone Call History Access CheckBox ===#
Set-Variable -Name "DenyPhoneCallHistoryAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" -Scope Global
Set-Variable -Name "DenyPhoneCallHistoryAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" -Scope Global
if ((Test-Path -Path $DenyPhoneCallHistoryAccessRegPath) -or (Test-Path -Path $DenyPhoneCallHistoryAccessRegPathD)) {
$DenyPhoneCallHistoryAccessRegValue = (Get-ItemProperty -Path $DenyPhoneCallHistoryAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyPhoneCallHistoryAccessRegValueD = (Get-ItemProperty -Path $DenyPhoneCallHistoryAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyPhoneCallHistoryAccessRegValue -ne "Deny") -or ($DenyPhoneCallHistoryAccessRegValueD -ne "Deny")) {
$WPFDenyPhoneCallHistoryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyPhoneCallHistoryAccessCheckBox.IsChecked = $true
} else {
$WPFDenyPhoneCallHistoryAccessCheckBox.Foreground = "#FF369726"
$WPFDenyPhoneCallHistoryAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyPhoneCallHistoryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyPhoneCallHistoryAccessCheckBox.IsChecked = $true
}

#=== Deny Pictures Library Access CheckBox ===#
Set-Variable -Name "DenyPicturesLibraryAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" -Scope Global
Set-Variable -Name "DenyPicturesLibraryAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" -Scope Global
if ((Test-Path -Path $DenyPicturesLibraryAccessRegPath) -or (Test-Path -Path $DenyPicturesLibraryAccessRegPathD)) {
$DenyPicturesLibraryAccessRegValue = (Get-ItemProperty -Path $DenyPicturesLibraryAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyPicturesLibraryAccessRegValueD = (Get-ItemProperty -Path $DenyPicturesLibraryAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyPicturesLibraryAccessRegValue -ne "Deny") -or ($DenyPicturesLibraryAccessRegValueD -ne "Deny")) {
$WPFDenyPicturesLibraryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyPicturesLibraryAccessCheckBox.IsChecked = $true
} else {
$WPFDenyPicturesLibraryAccessCheckBox.Foreground = "#FF369726"
$WPFDenyPicturesLibraryAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyPicturesLibraryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyPicturesLibraryAccessCheckBox.IsChecked = $true
}

#=== Deny Radios CheckBox ===#
Set-Variable -Name "DenyRadiosRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" -Scope Global
Set-Variable -Name "DenyRadiosRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" -Scope Global
if ((Test-Path -Path $DenyRadiosRegPath) -or (Test-Path -Path $DenyRadiosRegPathD)) {
$DenyRadiosRegValue = (Get-ItemProperty -Path $DenyRadiosRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyRadiosRegValueD = (Get-ItemProperty -Path $DenyRadiosRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyRadiosRegValue -ne "Deny") -or ($DenyRadiosRegValueD -ne "Deny")) {
$WPFDenyRadiosCheckBox.Foreground = "#FF0000"
$WPFDenyRadiosCheckBox.IsChecked = $false
} else {
$WPFDenyRadiosCheckBox.Foreground = "#FF369726"
$WPFDenyRadiosCheckBox.IsChecked = $false
}
} else {
$WPFDenyRadiosCheckBox.Foreground = "#FF0000"
$WPFDenyRadiosCheckBox.IsChecked = $false
}

#=== Deny Tasks Access CheckBox ===#
Set-Variable -Name "DenyTasksAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" -Scope Global
Set-Variable -Name "DenyTasksAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" -Scope Global
if ((Test-Path -Path $DenyTasksAccessRegPath) -or (Test-Path -Path $DenyTasksAccessRegPathD)) {
$DenyTasksAccessRegValue = (Get-ItemProperty -Path $DenyTasksAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyTasksAccessRegValueD = (Get-ItemProperty -Path $DenyTasksAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyTasksAccessRegValue -ne "Deny") -or ($DenyTasksAccessRegValueD -ne "Deny")) {
$WPFDenyTasksAccessCheckBox.Foreground = "#FF0000"
$WPFDenyTasksAccessCheckBox.IsChecked = $true
} else {
$WPFDenyTasksAccessCheckBox.Foreground = "#FF369726"
$WPFDenyTasksAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyTasksAccessCheckBox.Foreground = "#FF0000"
$WPFDenyTasksAccessCheckBox.IsChecked = $true
}

#=== Deny User Account Information Access CheckBox ===#
Set-Variable -Name "DenyUserAccountInformationAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" -Scope Global
Set-Variable -Name "DenyUserAccountInformationAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" -Scope Global
if ((Test-Path -Path $DenyUserAccountInformationAccessRegPath) -or (Test-Path -Path $DenyUserAccountInformationAccessRegPathD)) {
$DenyUserAccountInformationAccessRegValue = (Get-ItemProperty -Path $DenyUserAccountInformationAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyUserAccountInformationAccessRegValueD = (Get-ItemProperty -Path $DenyUserAccountInformationAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyUserAccountInformationAccessRegValue -ne "Deny") -or ($DenyUserAccountInformationAccessRegValueD -ne "Deny")) {
$WPFDenyUserAccountInformationAccessCheckBox.Foreground = "#FF0000"
$WPFDenyUserAccountInformationAccessCheckBox.IsChecked = $true
} else {
$WPFDenyUserAccountInformationAccessCheckBox.Foreground = "#FF369726"
$WPFDenyUserAccountInformationAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyUserAccountInformationAccessCheckBox.Foreground = "#FF0000"
$WPFDenyUserAccountInformationAccessCheckBox.IsChecked = $true
}

#=== Deny Videos Library Access CheckBox ===#
Set-Variable -Name "DenyVideosLibraryAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" -Scope Global
Set-Variable -Name "DenyVideosLibraryAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" -Scope Global
if ((Test-Path -Path $DenyVideosLibraryAccessRegPath) -or (Test-Path -Path $DenyVideosLibraryAccessRegPathD)) {
$DenyVideosLibraryAccessRegValue = (Get-ItemProperty -Path $DenyVideosLibraryAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyVideosLibraryAccessRegValueD = (Get-ItemProperty -Path $DenyVideosLibraryAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyVideosLibraryAccessRegValue -ne "Deny") -or ($DenyVideosLibraryAccessRegValueD -ne "Deny")) {
$WPFDenyVideosLibraryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyVideosLibraryAccessCheckBox.IsChecked = $true
} else {
$WPFDenyVideosLibraryAccessCheckBox.Foreground = "#FF369726"
$WPFDenyVideosLibraryAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyVideosLibraryAccessCheckBox.Foreground = "#FF0000"
$WPFDenyVideosLibraryAccessCheckBox.IsChecked = $true
}

#=== Deny Webcam Access CheckBox ===#
Set-Variable -Name "DenyWebcamAccessRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" -Scope Global
Set-Variable -Name "DenyWebcamAccessRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" -Scope Global
if ((Test-Path -Path $DenyWebcamAccessRegPath) -or (Test-Path -Path $DenyWebcamAccessRegPathD)) {
$DenyWebcamAccessRegValue = (Get-ItemProperty -Path $DenyWebcamAccessRegPath -Name Value -ErrorAction SilentlyContinue).Value
$DenyWebcamAccessRegValueD = (Get-ItemProperty -Path $DenyWebcamAccessRegPathD -Name Value -ErrorAction SilentlyContinue).Value
if (($DenyWebcamAccessRegValue -ne "Deny") -or ($DenyWebcamAccessRegValueD -ne "Deny")) {
$WPFDenyWebcamAccessCheckBox.Foreground = "#FF0000"
$WPFDenyWebcamAccessCheckBox.IsChecked = $true
} else {
$WPFDenyWebcamAccessCheckBox.Foreground = "#FF369726"
$WPFDenyWebcamAccessCheckBox.IsChecked = $false
}
} else {
$WPFDenyWebcamAccessCheckBox.Foreground = "#FF0000"
$WPFDenyWebcamAccessCheckBox.IsChecked = $true
}

############################# Suggestions, Ads, Tips, etc #############################

#=== Disable Start Menu Suggestions CheckBox ===#
Set-Variable -Name "DisableStartMenuSuggestionsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableStartMenuSuggestionsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableStartMenuSuggestionsRegPath) -or (Test-Path -Path $DisableStartMenuSuggestionsRegPathD)) {
$DisableStartMenuSuggestionsRegValue = (Get-ItemProperty -Path $DisableStartMenuSuggestionsRegPath -Name SystemPaneSuggestionsEnabled -ErrorAction SilentlyContinue).SystemPaneSuggestionsEnabled
$DisableStartMenuSuggestionsRegValueD = (Get-ItemProperty -Path $DisableStartMenuSuggestionsRegPathD -Name SystemPaneSuggestionsEnabled -ErrorAction SilentlyContinue).SystemPaneSuggestionsEnabled
if (($DisableStartMenuSuggestionsRegValue -ne "0") -or ($DisableStartMenuSuggestionsRegValueD -ne "0")) {
$WPFDisableStartMenuSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableStartMenuSuggestionsCheckBox.IsChecked = $true
} else {
$WPFDisableStartMenuSuggestionsCheckBox.Foreground = "#FF369726"
$WPFDisableStartMenuSuggestionsCheckBox.IsChecked = $false
}
} else {
$WPFDisableStartMenuSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableStartMenuSuggestionsCheckBox.IsChecked = $true
}

#=== Disable Suggested Content in Settings CheckBox ===#
Set-Variable -Name "DisableSuggestedContentInSettingsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableSuggestedContentInSettingsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableSuggestedContentInSettingsRegPath) -or (Test-Path -Path $DisableSuggestedContentInSettingsRegPathD)) {
$DisableSuggestedContentInSettingsRegValue1 = (Get-ItemProperty -Path $DisableSuggestedContentInSettingsRegPath -Name "SubscribedContent-338393Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338393Enabled"
$DisableSuggestedContentInSettingsRegValueD1 = (Get-ItemProperty -Path $DisableSuggestedContentInSettingsRegPathD -Name "SubscribedContent-338393Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338393Enabled"
$DisableSuggestedContentInSettingsRegValue2 = (Get-ItemProperty -Path $DisableSuggestedContentInSettingsRegPath -Name "SubscribedContent-353694Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-353694Enabled"
$DisableSuggestedContentInSettingsRegValueD2 = (Get-ItemProperty -Path $DisableSuggestedContentInSettingsRegPathD -Name "SubscribedContent-353694Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-353694Enabled"
if (($DisableSuggestedContentInSettingsRegValue1 -ne "0") -or ($DisableSuggestedContentInSettingsRegValueD1 -ne "0") -or ($DisableSuggestedContentInSettingsRegValue2 -ne "0") -or ($DisableSuggestedContentInSettingsRegValueD2 -ne "0")) {
$WPFDisableSuggestedContentInSettingsCheckBox.Foreground = "#FF0000"
$WPFDisableSuggestedContentInSettingsCheckBox.IsChecked = $true
} else {
$WPFDisableSuggestedContentInSettingsCheckBox.Foreground = "#FF369726"
$WPFDisableSuggestedContentInSettingsCheckBox.IsChecked = $false
}
} else {
$WPFDisableSuggestedContentInSettingsCheckBox.Foreground = "#FF0000"
$WPFDisableSuggestedContentInSettingsCheckBox.IsChecked = $true
}

#=== Disable Occasional Suggestions CheckBox ===#
Set-Variable -Name "DisableOccasionalSuggestionsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableOccasionalSuggestionsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableOccasionalSuggestionsRegPath) -or (Test-Path -Path $DisableOccasionalSuggestionsRegPathD)) {
$DisableOccasionalSuggestionsRegValue = (Get-ItemProperty -Path $DisableOccasionalSuggestionsRegPath -Name "SubscribedContent-338388Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338388Enabled"
$DisableOccasionalSuggestionsRegValueD = (Get-ItemProperty -Path $DisableOccasionalSuggestionsRegPathD -Name "SubscribedContent-338388Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338388Enabled"
if (($DisableOccasionalSuggestionsRegValue -ne "0") -or ($DisableOccasionalSuggestionsRegValueD -ne "0")) {
$WPFDisableOccasionalSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableOccasionalSuggestionsCheckBox.IsChecked = $true
} else {
$WPFDisableOccasionalSuggestionsCheckBox.Foreground = "#FF369726"
$WPFDisableOccasionalSuggestionsCheckBox.IsChecked = $false
}
} else {
$WPFDisableOccasionalSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableOccasionalSuggestionsCheckBox.IsChecked = $true
}

#=== Disable Suggestions in Timeline CheckBox ===#
Set-Variable -Name "DisableSuggestionsInTimelineRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableSuggestionsInTimelineRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableSuggestionsInTimelineRegPath) -or (Test-Path -Path $DisableSuggestionsInTimelineRegPathD)) {
$DisableSuggestionsInTimelineRegValue = (Get-ItemProperty -Path $DisableSuggestionsInTimelineRegPath -Name "SubscribedContent-353698Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-353698Enabled"
$DisableSuggestionsInTimelineRegValueD = (Get-ItemProperty -Path $DisableSuggestionsInTimelineRegPathD -Name "SubscribedContent-353698Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-353698Enabled"
if (($DisableSuggestionsInTimelineRegValue -ne "0") -or ($DisableSuggestionsInTimelineRegValueD -ne "0")) {
$WPFDisableSuggestionsInTimelineCheckBox.Foreground = "#FF0000"
$WPFDisableSuggestionsInTimelineCheckBox.IsChecked = $true
} else {
$WPFDisableSuggestionsInTimelineCheckBox.Foreground = "#FF369726"
$WPFDisableSuggestionsInTimelineCheckBox.IsChecked = $false
}
} else {
$WPFDisableSuggestionsInTimelineCheckBox.Foreground = "#FF0000"
$WPFDisableSuggestionsInTimelineCheckBox.IsChecked = $true
}

#=== Disable Lockscreen Suggestions and Rotating Pictures CheckBox ===#
Set-Variable -Name "DisableLockscreenSuggestionsAndRotatingPicturesRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableLockscreenSuggestionsAndRotatingPicturesRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath) -or (Test-Path -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD)) {
$DisableLockscreenSuggestionsAndRotatingPicturesRegValue1 = (Get-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Name SoftLandingEnabled -ErrorAction SilentlyContinue).SoftLandingEnabled
$DisableLockscreenSuggestionsAndRotatingPicturesRegValueD1 = (Get-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Name SoftLandingEnabled -ErrorAction SilentlyContinue).SoftLandingEnabled
$DisableLockscreenSuggestionsAndRotatingPicturesRegValue2 = (Get-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Name RotatingLockScreenEnabled -ErrorAction SilentlyContinue).RotatingLockScreenEnabled
$DisableLockscreenSuggestionsAndRotatingPicturesRegValueD2 = (Get-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Name RotatingLockScreenEnabled -ErrorAction SilentlyContinue).RotatingLockScreenEnabled
$DisableLockscreenSuggestionsAndRotatingPicturesRegValue3 = (Get-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Name RotatingLockScreenOverlayEnabled -ErrorAction SilentlyContinue).RotatingLockScreenOverlayEnabled
$DisableLockscreenSuggestionsAndRotatingPicturesRegValueD3 = (Get-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Name RotatingLockScreenOverlayEnabled -ErrorAction SilentlyContinue).RotatingLockScreenOverlayEnabled
if (($DisableLockscreenSuggestionsAndRotatingPicturesRegValue1 -ne "0") -or ($DisableLockscreenSuggestionsAndRotatingPicturesRegValueD1 -ne "0") -or ($DisableLockscreenSuggestionsAndRotatingPicturesRegValue2 -ne "0") -or ($DisableLockscreenSuggestionsAndRotatingPicturesRegValueD2 -ne "0") -or ($DisableLockscreenSuggestionsAndRotatingPicturesRegValue3 -ne "0") -or ($DisableLockscreenSuggestionsAndRotatingPicturesRegValueD3 -ne "0")) {
$WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.Foreground = "#FF0000"
$WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.IsChecked = $true
} else {
$WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.Foreground = "#FF369726"
$WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.IsChecked = $false
}
} else {
$WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.Foreground = "#FF0000"
$WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.IsChecked = $true
}

#=== Disable Tips, Tricks, and Suggestions CheckBox ===#
Set-Variable -Name "DisableTipsTricksSuggestionsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableTipsTricksSuggestionsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableTipsTricksSuggestionsRegPath) -or (Test-Path -Path $DisableTipsTricksSuggestionsRegPathD)) {
$DisableTipsTricksSuggestionsRegValue = (Get-ItemProperty -Path $DisableTipsTricksSuggestionsRegPath -Name "SubscribedContent-338389Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338389Enabled"
$DisableTipsTricksSuggestionsRegValueD = (Get-ItemProperty -Path $DisableTipsTricksSuggestionsRegPathD -Name "SubscribedContent-338389Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-338389Enabled"
if (($DisableTipsTricksSuggestionsRegValue -ne "0") -or ($DisableTipsTricksSuggestionsRegValueD -ne "0")) {
$WPFDisableTipsTricksSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableTipsTricksSuggestionsCheckBox.IsChecked = $true
} else {
$WPFDisableTipsTricksSuggestionsCheckBox.Foreground = "#FF369726"
$WPFDisableTipsTricksSuggestionsCheckBox.IsChecked = $false
}
} else {
$WPFDisableTipsTricksSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableTipsTricksSuggestionsCheckBox.IsChecked = $true
}

#=== Disable Ads in File Explorer CheckBox ===#
Set-Variable -Name "DisableAdsInFileExplorerRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Scope Global
Set-Variable -Name "DisableAdsInFileExplorerRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Scope Global
if ((Test-Path -Path $DisableAdsInFileExplorerRegPath) -or (Test-Path -Path $DisableAdsInFileExplorerRegPathD)) {
$DisableAdsInFileExplorerRegValue = (Get-ItemProperty -Path $DisableAdsInFileExplorerRegPath -Name ShowSyncProviderNotifications -ErrorAction SilentlyContinue).ShowSyncProviderNotifications
$DisableAdsInFileExplorerRegValueD = (Get-ItemProperty -Path $DisableAdsInFileExplorerRegPathD -Name ShowSyncProviderNotifications -ErrorAction SilentlyContinue).ShowSyncProviderNotifications
if (($DisableAdsInFileExplorerRegValue -ne "0") -or ($DisableAdsInFileExplorerRegValueD -ne "0")) {
$WPFDisableAdsInFileExplorerCheckBox.Foreground = "#FF0000"
$WPFDisableAdsInFileExplorerCheckBox.IsChecked = $true
} else {
$WPFDisableAdsInFileExplorerCheckBox.Foreground = "#FF369726"
$WPFDisableAdsInFileExplorerCheckBox.IsChecked = $false
}
} else {
$WPFDisableAdsInFileExplorerCheckBox.Foreground = "#FF0000"
$WPFDisableAdsInFileExplorerCheckBox.IsChecked = $true
}

#=== Disable Advertising Info & Device Metadata Collection CheckBox ===#
Set-Variable -Name "DisableAdInfoDeviceMetaCollectionRegPath1" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Scope Global
Set-Variable -Name "DisableAdInfoDeviceMetaCollectionRegPath2" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" -Scope Global
if ((Test-Path -Path $DisableAdInfoDeviceMetaCollectionRegPath1) -or (Test-Path -Path $DisableAdInfoDeviceMetaCollectionRegPath2)) {
$DisableAdInfoDeviceMetaCollectionRegValue1 = (Get-ItemProperty -Path $DisableAdInfoDeviceMetaCollectionRegPath1 -Name Enabled -ErrorAction SilentlyContinue).Enabled
$DisableAdInfoDeviceMetaCollectionRegValue2 = (Get-ItemProperty -Path $DisableAdInfoDeviceMetaCollectionRegPath2 -Name PreventDeviceMetadataFromNetwork -ErrorAction SilentlyContinue).PreventDeviceMetadataFromNetwork
if (($DisableAdInfoDeviceMetaCollectionRegValue1 -ne "0") -or ($DisableAdInfoDeviceMetaCollectionRegValue2 -ne "1")) {
$WPFDisableAdInfoDeviceMetaCollectionCheckBox.Foreground = "#FF0000"
$WPFDisableAdInfoDeviceMetaCollectionCheckBox.IsChecked = $true
} else {
$WPFDisableAdInfoDeviceMetaCollectionCheckBox.Foreground = "#FF369726"
$WPFDisableAdInfoDeviceMetaCollectionCheckBox.IsChecked = $false
}
} else {
$WPFDisableAdInfoDeviceMetaCollectionCheckBox.Foreground = "#FF0000"
$WPFDisableAdInfoDeviceMetaCollectionCheckBox.IsChecked = $true
}

#=== Disable Pre-release Features & Settings CheckBox ===#
Set-Variable -Name "DisablePreReleaseFeaturesSettingsRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Scope Global
if (Test-Path -Path $DisablePreReleaseFeaturesSettingsRegPath) {
$DisablePreReleaseFeaturesSettingsRegValue = (Get-ItemProperty -Path $DisablePreReleaseFeaturesSettingsRegPath -Name EnableConfigFlighting -ErrorAction SilentlyContinue).EnableConfigFlighting
if ($DisablePreReleaseFeaturesSettingsRegValue -ne "0") {
$WPFDisablePreReleaseFeaturesSettingsCheckBox.Foreground = "#FF0000"
$WPFDisablePreReleaseFeaturesSettingsCheckBox.IsChecked = $false
} else {
$WPFDisablePreReleaseFeaturesSettingsCheckBox.Foreground = "#FF369726"
$WPFDisablePreReleaseFeaturesSettingsCheckBox.IsChecked = $false
}
} else {
$WPFDisablePreReleaseFeaturesSettingsCheckBox.Foreground = "#FF0000"
$WPFDisablePreReleaseFeaturesSettingsCheckBox.IsChecked = $false
}

#=== Disable Feedback Notifications CheckBox ===#
Set-Variable -Name "DisableFeedbackNotificationsRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Scope Global
if (Test-Path -Path $DisableFeedbackNotificationsRegPath) {
$DisableFeedbackNotificationsRegValue = (Get-ItemProperty -Path $DisableFeedbackNotificationsRegPath -Name DoNotShowFeedbackNotifications -ErrorAction SilentlyContinue).DoNotShowFeedbackNotifications
if ($DisableFeedbackNotificationsRegValue -ne "1") {
$WPFDisableFeedbackNotificationsCheckBox.Foreground = "#FF0000"
$WPFDisableFeedbackNotificationsCheckBox.IsChecked = $true
} else {
$WPFDisableFeedbackNotificationsCheckBox.Foreground = "#FF369726"
$WPFDisableFeedbackNotificationsCheckBox.IsChecked = $false
}
} else {
$WPFDisableFeedbackNotificationsCheckBox.Foreground = "#FF0000"
$WPFDisableFeedbackNotificationsCheckBox.IsChecked = $true
}

############################# People ##################################################

#=== Disable My People Notifications CheckBox ===#
Set-Variable -Name "DisableMyPeopleNotificationsRegPath1" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Scope Global
Set-Variable -Name "DisableMyPeopleNotificationsRegPathD1" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Scope Global
Set-Variable -Name "DisableMyPeopleNotificationsRegPath2" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People\ShoulderTap" -Scope Global
Set-Variable -Name "DisableMyPeopleNotificationsRegPathD2" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People\ShoulderTap" -Scope Global
if ((Test-Path -Path $DisableMyPeopleNotificationsRegPath2) -or (Test-Path -Path $DisableMyPeopleNotificationsRegPathD2)) {
$DisableMyPeopleNotificationsRegValue = (Get-ItemProperty -Path $DisableMyPeopleNotificationsRegPath2 -Name ShoulderTap -ErrorAction SilentlyContinue).ShoulderTap
$DisableMyPeopleNotificationsRegValueD = (Get-ItemProperty -Path $DisableMyPeopleNotificationsRegPathD2 -Name ShoulderTap -ErrorAction SilentlyContinue).ShoulderTap
if (($DisableMyPeopleNotificationsRegValue -ne "0") -or ($DisableMyPeopleNotificationsRegValueD -ne "0")) {
$WPFDisableMyPeopleNotificationsCheckBox.Foreground = "#FF0000"
$WPFDisableMyPeopleNotificationsCheckBox.IsChecked = $true
} else {
$WPFDisableMyPeopleNotificationsCheckBox.Foreground = "#FF369726"
$WPFDisableMyPeopleNotificationsCheckBox.IsChecked = $false
}
} else {
$WPFDisableMyPeopleNotificationsCheckBox.Foreground = "#FF0000"
$WPFDisableMyPeopleNotificationsCheckBox.IsChecked = $true
}

#=== Disable My People Suggestions CheckBox ===#
Set-Variable -Name "DisableMyPeopleSuggestionsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableMyPeopleSuggestionsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableMyPeopleSuggestionsRegPath) -or (Test-Path -Path $DisableMyPeopleSuggestionsRegPathD)) {
$DisableMyPeopleSuggestionsRegValue = (Get-ItemProperty -Path $DisableMyPeopleSuggestionsRegPath -Name SubscribedContent-314563Enabled -ErrorAction SilentlyContinue)."SubscribedContent-314563Enabled"
$DisableMyPeopleSuggestionsRegValueD = (Get-ItemProperty -Path $DisableMyPeopleSuggestionsRegPathD -Name SubscribedContent-314563Enabled -ErrorAction SilentlyContinue)."SubscribedContent-314563Enabled"
if (($DisableMyPeopleSuggestionsRegValue -ne "0") -or ($DisableMyPeopleSuggestionsRegValueD -ne "0")) {
$WPFDisableMyPeopleSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableMyPeopleSuggestionsCheckBox.IsChecked = $true
} else {
$WPFDisableMyPeopleSuggestionsCheckBox.Foreground = "#FF369726"
$WPFDisableMyPeopleSuggestionsCheckBox.IsChecked = $false
}
} else {
$WPFDisableMyPeopleSuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableMyPeopleSuggestionsCheckBox.IsChecked = $true
}

#=== Disable People on Taskbar CheckBox ===#
Set-Variable -Name "DisablePeopleOnTaskbarRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Scope Global
Set-Variable -Name "DisablePeopleOnTaskbarRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Scope Global
if ((Test-Path -Path $DisablePeopleOnTaskbarRegPath) -or (Test-Path -Path $DisablePeopleOnTaskbarRegPathD)) {
$DisablePeopleOnTaskbarRegValue = (Get-ItemProperty -Path $DisablePeopleOnTaskbarRegPath -Name PeopleBand -ErrorAction SilentlyContinue).PeopleBand
$DisablePeopleOnTaskbarRegValueD = (Get-ItemProperty -Path $DisablePeopleOnTaskbarRegPathD -Name PeopleBand -ErrorAction SilentlyContinue).PeopleBand
if (($DisablePeopleOnTaskbarRegValue -ne "0") -or ($DisablePeopleOnTaskbarRegValueD -ne "0")) {
$WPFDisablePeopleOnTaskbarCheckBox.Foreground = "#FF0000"
$WPFDisablePeopleOnTaskbarCheckBox.IsChecked = $true
} else {
$WPFDisablePeopleOnTaskbarCheckBox.Foreground = "#FF369726"
$WPFDisablePeopleOnTaskbarCheckBox.IsChecked = $false
}
} else {
$WPFDisablePeopleOnTaskbarCheckBox.Foreground = "#FF0000"
$WPFDisablePeopleOnTaskbarCheckBox.IsChecked = $true
}

############################# OneDrive ################################################

#=== Prevent Usage of OneDrive CheckBox ===#
Set-Variable -Name "PreventUsageOfOneDriveRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Scope Global
if (Test-Path -Path $PreventUsageOfOneDriveRegPath) {
$PreventUsageOfOneDriveRegValue1 = (Get-ItemProperty -Path $PreventUsageOfOneDriveRegPath -Name DisableFileSync -ErrorAction SilentlyContinue).DisableFileSync
$PreventUsageOfOneDriveRegValue2 = (Get-ItemProperty -Path $PreventUsageOfOneDriveRegPath -Name DisableFileSyncNGSC -ErrorAction SilentlyContinue).DisableFileSyncNGSC
if (($PreventUsageOfOneDriveRegValue1 -ne "1") -or ($PreventUsageOfOneDriveRegValue2 -ne "1")) {
$WPFPreventUsageOfOneDriveCheckBox.Foreground = "#FF0000"
$WPFPreventUsageOfOneDriveCheckBox.IsChecked = $true
} else {
$WPFPreventUsageOfOneDriveCheckBox.Foreground = "#FF369726"
$WPFPreventUsageOfOneDriveCheckBox.IsChecked = $false
}
} else {
$WPFPreventUsageOfOneDriveCheckBox.Foreground = "#FF0000"
$WPFPreventUsageOfOneDriveCheckBox.IsChecked = $true
}

#=== Disable Automatic OneDrive Setup CheckBox ===#
Set-Variable -Name "DisableAutomaticOneDriveSetupRegPath" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Scope Global
if (Test-Path -Path $DisableAutomaticOneDriveSetupRegPath) {
$DisableAutomaticOneDriveSetupRegValue = (Get-ItemProperty -Path $DisableAutomaticOneDriveSetupRegPath -Name OneDriveSetup -ErrorAction SilentlyContinue).OneDriveSetup
if (($DisableAutomaticOneDriveSetupRegValue)) {
$WPFDisableAutomaticOneDriveSetupCheckBox.Foreground = "#FF0000"
$WPFDisableAutomaticOneDriveSetupCheckBox.IsChecked = $true
} else {
$WPFDisableAutomaticOneDriveSetupCheckBox.Foreground = "#FF369726"
$WPFDisableAutomaticOneDriveSetupCheckBox.IsChecked = $false
}
} else {
$WPFDisableAutomaticOneDriveSetupCheckBox.Foreground = "#FF0000"
$WPFDisableAutomaticOneDriveSetupCheckBox.IsChecked = $true
}

#=== Disable OneDrive Startup Run CheckBox ===#
Set-Variable -Name "DisableOneDriveStartupRunRegPath1" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved" -Scope Global
Set-Variable -Name "DisableOneDriveStartupRunRegPath2" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Scope Global
Set-Variable -Name "DisableOneDriveStartupRunRegPathD1" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved" -Scope Global
Set-Variable -Name "DisableOneDriveStartupRunRegPathD2" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Scope Global
Set-Variable -Name "BinaryInput" -Value "03,00,00,00,21,B9,DE,B3,96,D7,D0,01" -Scope Global
Set-Variable -Name "InputHexified" -Value ($BinaryInput.Split(',') | ForEach-Object { "0x$_"}) -Scope Global
Set-Variable -Name "BinaryInputX" -Value (([byte[]]$InputHexified) -join ',') -Scope Global
if ((Test-Path -Path $DisableOneDriveStartupRunRegPath2) -or (Test-Path -Path $DisableOneDriveStartupRunRegPathD2)) {
$DisableOneDriveStartupRunRegValue = (Get-ItemProperty -Path $DisableOneDriveStartupRunRegPath2 -Name OneDrive -ErrorAction SilentlyContinue).OneDrive
$DisableOneDriveStartupRunRegValueD = (Get-ItemProperty -Path $DisableOneDriveStartupRunRegPathD2 -Name OneDrive -ErrorAction SilentlyContinue).OneDrive
$DisableOneDriveStartupRunRegValueX = $DisableOneDriveStartupRunRegValue -join ','
$DisableOneDriveStartupRunRegValueDX = $DisableOneDriveStartupRunRegValueD -join ','
if (($DisableOneDriveStartupRunRegValueX -ne $BinaryInputX) -or ($DisableOneDriveStartupRunRegValueDX -ne $BinaryInputX)) {
$WPFDisableOneDriveStartupRunCheckBox.Foreground = "#FF0000"
$WPFDisableOneDriveStartupRunCheckBox.IsChecked = $true
} else {
$WPFDisableOneDriveStartupRunCheckBox.Foreground = "#FF369726"
$WPFDisableOneDriveStartupRunCheckBox.IsChecked = $false
}
} else {
$WPFDisableOneDriveStartupRunCheckBox.Foreground = "#FF0000"
$WPFDisableOneDriveStartupRunCheckBox.IsChecked = $true
}

#=== Remove OneDrive from File Explorer CheckBox ===#
Set-Variable -Name "RemoveOneDriveFromFileExplorerRegPath1" -Value "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Scope Global
Set-Variable -Name "RemoveOneDriveFromFileExplorerRegPath2" -Value "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Scope Global
if ((Test-Path -Path $RemoveOneDriveFromFileExplorerRegPath1) -or (Test-Path -Path $RemoveOneDriveFromFileExplorerRegPath2)) {
$RemoveOneDriveFromFileExplorerRegValue1 = (Get-ItemProperty -Path $RemoveOneDriveFromFileExplorerRegPath1 -Name "System.IsPinnedToNameSpaceTree" -ErrorAction SilentlyContinue)."System.IsPinnedToNameSpaceTree"
$RemoveOneDriveFromFileExplorerRegValue2 = (Get-ItemProperty -Path $RemoveOneDriveFromFileExplorerRegPath2 -Name "System.IsPinnedToNameSpaceTree" -ErrorAction SilentlyContinue)."System.IsPinnedToNameSpaceTree"
if (($RemoveOneDriveFromFileExplorerRegValue1 -ne "0") -or ($RemoveOneDriveFromFileExplorerRegValue2 -ne "0")) {
$WPFRemoveOneDriveFromFileExplorerCheckBox.Foreground = "#FF0000"
$WPFRemoveOneDriveFromFileExplorerCheckBox.IsChecked = $true
} else {
$WPFRemoveOneDriveFromFileExplorerCheckBox.Foreground = "#FF369726"
$WPFRemoveOneDriveFromFileExplorerCheckBox.IsChecked = $false
}
} else {
$WPFRemoveOneDriveFromFileExplorerCheckBox.Foreground = "#FF0000"
$WPFRemoveOneDriveFromFileExplorerCheckBox.IsChecked = $true
}

############################# Games ###################################################

#=== Disable GameDVR CheckBox ===#
Set-Variable -Name "DisableGameDVRRegPath" -Value "HKCU:\System\GameConfigStore" -Scope Global
Set-Variable -Name "DisableGameDVRRegPathD" -Value "$HKLMD\System\GameConfigStore" -Scope Global
Set-Variable -Name "DisableGameDVRRegPath2" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Scope Global
if ((Test-Path -Path $DisableGameDVRRegPath) -or (Test-Path -Path $DisableGameDVRRegPathD) -or (Test-Path -Path $DisableGameDVRRegPath2)) {
$DisableGameDVRRegValue = (Get-ItemProperty -Path $DisableGameDVRRegPath -Name GameDVR_Enabled -ErrorAction SilentlyContinue).GameDVR_Enabled
$DisableGameDVRRegValueD = (Get-ItemProperty -Path $DisableGameDVRRegPathD -Name GameDVR_Enabled -ErrorAction SilentlyContinue).GameDVR_Enabled
$DisableGameDVRRegValue2 = (Get-ItemProperty -Path $DisableGameDVRRegPath2 -Name AllowGameDVR -ErrorAction SilentlyContinue).AllowGameDVR
if (($DisableGameDVRRegValue -ne "0") -or ($DisableGameDVRRegValueD -ne "0") -or ($DisableGameDVRRegValue2 -ne "0")) {
$WPFDisableGameDVRCheckBox.Foreground = "#FF0000"
$WPFDisableGameDVRCheckBox.IsChecked = $true
} else {
$WPFDisableGameDVRCheckBox.Foreground = "#FF369726"
$WPFDisableGameDVRCheckBox.IsChecked = $false
}
} else {
$WPFDisableGameDVRCheckBox.Foreground = "#FF0000"
$WPFDisableGameDVRCheckBox.IsChecked = $true
}

#=== Disable Preinstalled Apps CheckBox ===#
Set-Variable -Name "DisablePreinstalledAppsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisablePreinstalledAppsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisablePreinstalledAppsRegPath) -or (Test-Path -Path $DisablePreinstalledAppsRegPathD)) {
$DisablePreinstalledAppsRegValue1 = (Get-ItemProperty -Path $DisablePreinstalledAppsRegPath -Name PreInstalledAppsEnabled -ErrorAction SilentlyContinue).PreInstalledAppsEnabled
$DisablePreinstalledAppsRegValueD1 = (Get-ItemProperty -Path $DisablePreinstalledAppsRegPathD -Name PreInstalledAppsEnabled -ErrorAction SilentlyContinue).PreInstalledAppsEnabled
$DisablePreinstalledAppsRegValue2 = (Get-ItemProperty -Path $DisablePreinstalledAppsRegPath -Name PreInstalledAppsEverEnabled -ErrorAction SilentlyContinue).PreInstalledAppsEverEnabled
$DisablePreinstalledAppsRegValueD2 = (Get-ItemProperty -Path $DisablePreinstalledAppsRegPathD -Name PreInstalledAppsEverEnabled -ErrorAction SilentlyContinue).PreInstalledAppsEverEnabled
$DisablePreinstalledAppsRegValue3 = (Get-ItemProperty -Path $DisablePreinstalledAppsRegPath -Name OEMPreInstalledAppsEnabled -ErrorAction SilentlyContinue).OEMPreInstalledAppsEnabled
$DisablePreinstalledAppsRegValueD3 = (Get-ItemProperty -Path $DisablePreinstalledAppsRegPathD -Name OEMPreInstalledAppsEnabled -ErrorAction SilentlyContinue).OEMPreInstalledAppsEnabled
if (($DisablePreinstalledAppsRegValue1 -ne "0") -or ($DisablePreinstalledAppsRegValueD1 -ne "0") -or ($DisablePreinstalledAppsRegValue2 -ne "0") -or ($DisablePreinstalledAppsRegValueD2 -ne "0") -or ($DisablePreinstalledAppsRegValue3 -ne "0") -or ($DisablePreinstalledAppsRegValueD3 -ne "0")) {
$WPFDisablePreinstalledAppsCheckBox.Foreground = "#FF0000"
$WPFDisablePreinstalledAppsCheckBox.IsChecked = $true
} else {
$WPFDisablePreinstalledAppsCheckBox.Foreground = "#FF369726"
$WPFDisablePreinstalledAppsCheckBox.IsChecked = $false
}
} else {
$WPFDisablePreinstalledAppsCheckBox.Foreground = "#FF0000"
$WPFDisablePreinstalledAppsCheckBox.IsChecked = $true
}

#=== Disable Xbox Game Monitoring Service CheckBox ===#
Set-Variable -Name "DisableXboxGameMonitoringServiceRegPath" -Value "HKLM:\SYSTEM\CurrentControlSet\Services\xbgm" -Scope Global
if (Test-Path -Path $DisableXboxGameMonitoringServiceRegPath) {
$DisableXboxGameMonitoringServiceRegValue = (Get-ItemProperty -Path $DisableXboxGameMonitoringServiceRegPath -Name Start -ErrorAction SilentlyContinue).Start
if ($DisableXboxGameMonitoringServiceRegValue -ne "4") {
$WPFDisableXboxGameMonitoringServiceCheckBox.Foreground = "#FF0000"
$WPFDisableXboxGameMonitoringServiceCheckBox.IsChecked = $true
} else {
$WPFDisableXboxGameMonitoringServiceCheckBox.Foreground = "#FF369726"
$WPFDisableXboxGameMonitoringServiceCheckBox.IsChecked = $false
}
} else {
$WPFDisableXboxGameMonitoringServiceCheckBox.Foreground = "#FF0000"
$WPFDisableXboxGameMonitoringServiceCheckBox.IsChecked = $true
}

############################# Cloud ###################################################

#=== Disable Windows Tips CheckBox ===#
Set-Variable -Name "DisableWindowsTipsRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Scope Global
if (Test-Path -Path $DisableWindowsTipsRegPath) {
$DisableWindowsTipsRegValue = (Get-ItemProperty -Path $DisableWindowsTipsRegPath -Name DisableSoftLanding -ErrorAction SilentlyContinue).DisableSoftLanding
if ($DisableWindowsTipsRegValue -ne "1") {
$WPFDisableWindowsTipsCheckBox.Foreground = "#FF0000"
$WPFDisableWindowsTipsCheckBox.IsChecked = $true
} else {
$WPFDisableWindowsTipsCheckBox.Foreground = "#FF369726"
$WPFDisableWindowsTipsCheckBox.IsChecked = $false
}
} else {
$WPFDisableWindowsTipsCheckBox.Foreground = "#FF0000"
$WPFDisableWindowsTipsCheckBox.IsChecked = $true
}

#=== Disable Consumer Experiences CheckBox ===#
Set-Variable -Name "DisableConsumerExperiencesRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Scope Global
if (Test-Path -Path $DisableConsumerExperiencesRegPath) {
$DisableConsumerExperiencesRegValue = (Get-ItemProperty -Path $DisableConsumerExperiencesRegPath -Name DisableWindowsConsumerFeatures -ErrorAction SilentlyContinue).DisableWindowsConsumerFeatures
if ($DisableConsumerExperiencesRegValue -ne "1") {
$WPFDisableConsumerExperiencesCheckBox.Foreground = "#FF0000"
$WPFDisableConsumerExperiencesCheckBox.IsChecked = $true
} else {
$WPFDisableConsumerExperiencesCheckBox.Foreground = "#FF369726"
$WPFDisableConsumerExperiencesCheckBox.IsChecked = $false
}
} else {
$WPFDisableConsumerExperiencesCheckBox.Foreground = "#FF0000"
$WPFDisableConsumerExperiencesCheckBox.IsChecked = $true
}

#=== Disable 3rd Party Suggestions CheckBox ===#
Set-Variable -Name "DisableThirdPartySuggestionsRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Scope Global
if (Test-Path -Path $DisableThirdPartySuggestionsRegPath) {
$DisableThirdPartySuggestionsRegValue = (Get-ItemProperty -Path $DisableThirdPartySuggestionsRegPath -Name DisableThirdPartySuggestions -ErrorAction SilentlyContinue).DisableThirdPartySuggestions
if ($DisableThirdPartySuggestionsRegValue -ne "1") {
$WPFDisableThirdPartySuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableThirdPartySuggestionsCheckBox.IsChecked = $true
} else {
$WPFDisableThirdPartySuggestionsCheckBox.Foreground = "#FF369726"
$WPFDisableThirdPartySuggestionsCheckBox.IsChecked = $false
}
} else {
$WPFDisableThirdPartySuggestionsCheckBox.Foreground = "#FF0000"
$WPFDisableThirdPartySuggestionsCheckBox.IsChecked = $true
}

#=== Disable Spotlight Features CheckBox ===#
Set-Variable -Name "DisableSpotlightFeaturesRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Scope Global
if (Test-Path -Path $DisableSpotlightFeaturesRegPath) {
$DisableSpotlightFeaturesRegValue = (Get-ItemProperty -Path $DisableSpotlightFeaturesRegPath -Name DisableWindowsSpotlightFeatures -ErrorAction SilentlyContinue).DisableWindowsSpotlightFeatures
if ($DisableSpotlightFeaturesRegValue -ne "1") {
$WPFDisableSpotlightFeaturesCheckBox.Foreground = "#FF0000"
$WPFDisableSpotlightFeaturesCheckBox.IsChecked = $false
} else {
$WPFDisableSpotlightFeaturesCheckBox.Foreground = "#FF369726"
$WPFDisableSpotlightFeaturesCheckBox.IsChecked = $false
}
} else {
$WPFDisableSpotlightFeaturesCheckBox.Foreground = "#FF0000"
$WPFDisableSpotlightFeaturesCheckBox.IsChecked = $false
}

############################# Windows Update ##########################################

#=== Disable Featured Software Notifications CheckBox ===#
Set-Variable -Name "DisableFeaturedSoftwareNotificationsRegPath1" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Scope Global
Set-Variable -Name "DisableFeaturedSoftwareNotificationsRegPath2" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Scope Global
if (Test-Path -Path $DisableFeaturedSoftwareNotificationsRegPath2) {
$DisableFeaturedSoftwareNotificationsRegValue = (Get-ItemProperty -Path $DisableFeaturedSoftwareNotificationsRegPath2 -Name EnableFeaturedSoftware -ErrorAction SilentlyContinue).EnableFeaturedSoftware
if ($DisableFeaturedSoftwareNotificationsRegValue -ne "0") {
$WPFDisableFeaturedSoftwareNotificationsCheckBox.Foreground = "#FF0000"
$WPFDisableFeaturedSoftwareNotificationsCheckBox.IsChecked = $true
} else {
$WPFDisableFeaturedSoftwareNotificationsCheckBox.Foreground = "#FF369726"
$WPFDisableFeaturedSoftwareNotificationsCheckBox.IsChecked = $false
}
} else {
$WPFDisableFeaturedSoftwareNotificationsCheckBox.Foreground = "#FF0000"
$WPFDisableFeaturedSoftwareNotificationsCheckBox.IsChecked = $true
}

#=== Set Delivery Optimization LAN Only CheckBox ===#
Set-Variable -Name "SetDeliveryOptimizationLANOnlyRegPath1" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Scope Global
Set-Variable -Name "SetDeliveryOptimizationLANOnlyRegPath2" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" -Scope Global
if ((Test-Path -Path $SetDeliveryOptimizationLANOnlyRegPath1) -or (Test-Path -Path $SetDeliveryOptimizationLANOnlyRegPath2)) {
$SetDeliveryOptimizationLANOnlyRegValue = (Get-ItemProperty -Path $SetDeliveryOptimizationLANOnlyRegPath1 -Name DownloadMode -ErrorAction SilentlyContinue).DownloadMode
$SetDeliveryOptimizationLANOnlyRegValue2 = (Get-ItemProperty -Path $SetDeliveryOptimizationLANOnlyRegPath1 -Name DODownloadMode -ErrorAction SilentlyContinue).DODownloadMode
$SetDeliveryOptimizationLANOnlyRegValue3 = (Get-ItemProperty -Path $SetDeliveryOptimizationLANOnlyRegPath2 -Name DownloadMode -ErrorAction SilentlyContinue).DownloadMode
if (($SetDeliveryOptimizationLANOnlyRegValue -ne "1") -or ($SetDeliveryOptimizationLANOnlyRegValue2 -ne "1") -or ($SetDeliveryOptimizationLANOnlyRegValue3 -ne "1")) {
$WPFSetDeliveryOptimizationLANOnlyCheckBox.Foreground = "#FF0000"
$WPFSetDeliveryOptimizationLANOnlyCheckBox.IsChecked = $true
} else {
$WPFSetDeliveryOptimizationLANOnlyCheckBox.Foreground = "#FF369726"
$WPFSetDeliveryOptimizationLANOnlyCheckBox.IsChecked = $false
}
} else {
$WPFSetDeliveryOptimizationLANOnlyCheckBox.Foreground = "#FF0000"
$WPFSetDeliveryOptimizationLANOnlyCheckBox.IsChecked = $true
}

#=== Disable Automatic Store App Updates CheckBox ===#
Set-Variable -Name "DisableAutomaticStoreAppUpdatesRegPath1" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Scope Global
Set-Variable -Name "DisableAutomaticStoreAppUpdatesRegPath2" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore" -Scope Global
Set-Variable -Name "DisableAutomaticStoreAppUpdatesRegPath3" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Scope Global
if (Test-Path -Path $DisableAutomaticStoreAppUpdatesRegPath3) {
$DisableAutomaticStoreAppUpdatesRegValue = (Get-ItemProperty -Path $DisableAutomaticStoreAppUpdatesRegPath3 -Name AutoDownload -ErrorAction SilentlyContinue).AutoDownload
if ($DisableAutomaticStoreAppUpdatesRegValue -ne "2") {
$WPFDisableAutomaticStoreAppUpdatesCheckBox.Foreground = "#FF0000"
$WPFDisableAutomaticStoreAppUpdatesCheckBox.IsChecked = $false
} else {
$WPFDisableAutomaticStoreAppUpdatesCheckBox.Foreground = "#FF369726"
$WPFDisableAutomaticStoreAppUpdatesCheckBox.IsChecked = $false
}
} else {
$WPFDisableAutomaticStoreAppUpdatesCheckBox.Foreground = "#FF0000"
$WPFDisableAutomaticStoreAppUpdatesCheckBox.IsChecked = $false
}

#=== Disable Automatic Login to Update CheckBox ===#
Set-Variable -Name "DisableAutoLoginUpdatesRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Scope Global
if (Test-Path -Path $DisableAutoLoginUpdatesRegPath) {
$DisableAutoLoginUpdatesRegValue = (Get-ItemProperty -Path $DisableAutoLoginUpdatesRegPath -Name ARSOUserConsent -ErrorAction SilentlyContinue).ARSOUserConsent
if ($DisableAutoLoginUpdatesRegValue -ne "2") {
$WPFDisableAutoLoginUpdatesCheckBox.Foreground = "#FF0000"
$WPFDisableAutoLoginUpdatesCheckBox.IsChecked = $true
} else {
$WPFDisableAutoLoginUpdatesCheckBox.Foreground = "#FF369726"
$WPFDisableAutoLoginUpdatesCheckBox.IsChecked = $false
}
} else {
$WPFDisableAutoLoginUpdatesCheckBox.Foreground = "#FF0000"
$WPFDisableAutoLoginUpdatesCheckBox.IsChecked = $true
}

############################# Other Settings ##########################################

#=== Disable Shoehorning Apps CheckBox ===#
Set-Variable -Name "DisableShoehorningAppsRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableShoehorningAppsRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableShoehorningAppsRegPath) -or (Test-Path -Path $DisableShoehorningAppsRegPathD)) {
$DisableShoehorningAppsRegValue1 = (Get-ItemProperty -Path $DisableShoehorningAppsRegPath -Name SilentInstalledAppsEnabled -ErrorAction SilentlyContinue).SilentInstalledAppsEnabled
$DisableShoehorningAppsRegValueD1 = (Get-ItemProperty -Path $DisableShoehorningAppsRegPathD -Name SilentInstalledAppsEnabled -ErrorAction SilentlyContinue).SilentInstalledAppsEnabled
$DisableShoehorningAppsRegValue2 = (Get-ItemProperty -Path $DisableShoehorningAppsRegPath -Name ContentDeliveryAllowed -ErrorAction SilentlyContinue).ContentDeliveryAllowed
$DisableShoehorningAppsRegValueD2 = (Get-ItemProperty -Path $DisableShoehorningAppsRegPathD -Name ContentDeliveryAllowed -ErrorAction SilentlyContinue).ContentDeliveryAllowed
$DisableShoehorningAppsRegValue3 = (Get-ItemProperty -Path $DisableShoehorningAppsRegPath -Name SubscribedContentEnabled -ErrorAction SilentlyContinue).SubscribedContentEnabled
$DisableShoehorningAppsRegValueD3 = (Get-ItemProperty -Path $DisableShoehorningAppsRegPathD -Name SubscribedContentEnabled -ErrorAction SilentlyContinue).SubscribedContentEnabled
if (($DisableShoehorningAppsRegValue1 -ne "0") -or ($DisableShoehorningAppsRegValueD1 -ne "0") -or ($DisableShoehorningAppsRegValue2 -ne "0") -or ($DisableShoehorningAppsRegValueD2 -ne "0") -or ($DisableShoehorningAppsRegValue3 -ne "0") -or ($DisableShoehorningAppsRegValueD3 -ne "0")) {
$WPFDisableShoehorningAppsCheckBox.Foreground = "#FF0000"
$WPFDisableShoehorningAppsCheckBox.IsChecked = $true
} else {
$WPFDisableShoehorningAppsCheckBox.Foreground = "#FF369726"
$WPFDisableShoehorningAppsCheckBox.IsChecked = $false
}
} else {
$WPFDisableShoehorningAppsCheckBox.Foreground = "#FF0000"
$WPFDisableShoehorningAppsCheckBox.IsChecked = $true
}

#=== Disable Occasional Welcome Experience CheckBox ===#
Set-Variable -Name "DisableOccasionalWelcomeExperienceRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
Set-Variable -Name "DisableOccasionalWelcomeExperienceRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Scope Global
if ((Test-Path -Path $DisableOccasionalWelcomeExperienceRegPath) -or (Test-Path -Path $DisableOccasionalWelcomeExperienceRegPathD)) {
$DisableOccasionalWelcomeExperienceRegValue = (Get-ItemProperty -Path $DisableOccasionalWelcomeExperienceRegPath -Name "SubscribedContent-310093Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-310093Enabled"
$DisableOccasionalWelcomeExperienceRegValueD = (Get-ItemProperty -Path $DisableOccasionalWelcomeExperienceRegPathD -Name "SubscribedContent-310093Enabled" -ErrorAction SilentlyContinue)."SubscribedContent-310093Enabled"
if (($DisableOccasionalWelcomeExperienceRegValue -ne "0") -or ($DisableOccasionalWelcomeExperienceRegValueD -ne "0")) {
$WPFDisableOccasionalWelcomeExperienceCheckBox.Foreground = "#FF0000"
$WPFDisableOccasionalWelcomeExperienceCheckBox.IsChecked = $true
} else {
$WPFDisableOccasionalWelcomeExperienceCheckBox.Foreground = "#FF369726"
$WPFDisableOccasionalWelcomeExperienceCheckBox.IsChecked = $false
}
} else {
$WPFDisableOccasionalWelcomeExperienceCheckBox.Foreground = "#FF0000"
$WPFDisableOccasionalWelcomeExperienceCheckBox.IsChecked = $true
}

#=== Disable Autoplay CheckBox ===#
Set-Variable -Name "DisableAutoplayRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Scope Global
Set-Variable -Name "DisableAutoplayRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Scope Global
if ((Test-Path -Path $DisableAutoplayRegPath) -or (Test-Path -Path $DisableAutoplayRegPathD)) {
$DisableAutoplayRegValue = (Get-ItemProperty -Path $DisableAutoplayRegPath -Name DisableAutoplay -ErrorAction SilentlyContinue).DisableAutoplay
$DisableAutoplayRegValueD = (Get-ItemProperty -Path $DisableAutoplayRegPathD -Name DisableAutoplay -ErrorAction SilentlyContinue).DisableAutoplay
if (($DisableAutoplayRegValue -ne "1") -or ($DisableAutoplayRegValueD -ne "1")) {
$WPFDisableAutoplayCheckBox.Foreground = "#FF0000"
$WPFDisableAutoplayCheckBox.IsChecked = $true
} else {
$WPFDisableAutoplayCheckBox.Foreground = "#FF369726"
$WPFDisableAutoplayCheckBox.IsChecked = $false
}
} else {
$WPFDisableAutoplayCheckBox.Foreground = "#FF0000"
$WPFDisableAutoplayCheckBox.IsChecked = $true
}

#=== Disable Taskbar Search CheckBox ===#
Set-Variable -Name "DisableTaskbarSearchRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
Set-Variable -Name "DisableTaskbarSearchRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Scope Global
if ((Test-Path -Path $DisableTaskbarSearchRegPath) -or (Test-Path -Path $DisableTaskbarSearchRegPathD)) {
$DisableTaskbarSearchRegValue = (Get-ItemProperty -Path $DisableTaskbarSearchRegPath -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue).SearchboxTaskbarMode
$DisableTaskbarSearchRegValueD = (Get-ItemProperty -Path $DisableTaskbarSearchRegPathD -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue).SearchboxTaskbarMode
if (($DisableTaskbarSearchRegValue -ne "0") -or ($DisableTaskbarSearchRegValueD -ne "0")) {
$WPFDisableTaskbarSearchCheckBox.Foreground = "#FF0000"
$WPFDisableTaskbarSearchCheckBox.IsChecked = $true
} else {
$WPFDisableTaskbarSearchCheckBox.Foreground = "#FF369726"
$WPFDisableTaskbarSearchCheckBox.IsChecked = $false
}
} else {
$WPFDisableTaskbarSearchCheckBox.Foreground = "#FF0000"
$WPFDisableTaskbarSearchCheckBox.IsChecked = $true
}

#=== Deny Location Use For Searches CheckBox ===#
Set-Variable -Name "DenyLocationUseForSearchesRegPath" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Scope Global
Set-Variable -Name "DenyLocationUseForSearchesRegPathD" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Scope Global
if ((Test-Path -Path $DenyLocationUseForSearchesRegPath) -or (Test-Path -Path $DenyLocationUseForSearchesRegPathD)) {
$DenyLocationUseForSearchesRegValue = (Get-ItemProperty -Path $DenyLocationUseForSearchesRegPath -Name AllowSearchToUseLocation -ErrorAction SilentlyContinue).AllowSearchToUseLocation
$DenyLocationUseForSearchesRegValueD = (Get-ItemProperty -Path $DenyLocationUseForSearchesRegPathD -Name AllowSearchToUseLocation -ErrorAction SilentlyContinue).AllowSearchToUseLocation
if (($DenyLocationUseForSearchesRegValue -ne "0") -or ($DenyLocationUseForSearchesRegValueD -ne "0")) {
$WPFDenyLocationUseForSearchesCheckBox.Foreground = "#FF0000"
$WPFDenyLocationUseForSearchesCheckBox.IsChecked = $true
} else {
$WPFDenyLocationUseForSearchesCheckBox.Foreground = "#FF369726"
$WPFDenyLocationUseForSearchesCheckBox.IsChecked = $false
}
} else {
$WPFDenyLocationUseForSearchesCheckBox.Foreground = "#FF0000"
$WPFDenyLocationUseForSearchesCheckBox.IsChecked = $true
}

#=== Disable Tablet Settings CheckBox ===#
Set-Variable -Name "DisableTabletSettingsRegPath1" -Value "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPathD1" -Value "$HKLMD\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPath2" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPathD2" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPath3" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPathD3" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPath4" -Value "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Scope Global
Set-Variable -Name "DisableTabletSettingsRegPathD4" -Value "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Scope Global
if ((Test-Path -Path $DisableTabletSettingsRegPath1) -or (Test-Path -Path $DisableTabletSettingsRegPathD1) -or (Test-Path -Path $DisableTabletSettingsRegPath2) -or (Test-Path -Path $DisableTabletSettingsRegPathD2) -or (Test-Path -Path $DisableTabletSettingsRegPath3) -or (Test-Path -Path $DisableTabletSettingsRegPathD3) -or (Test-Path -Path $DisableTabletSettingsRegPath4) -or (Test-Path -Path $DisableTabletSettingsRegPathD4)) {
$DisableTabletSettingsRegValue1 = (Get-ItemProperty -Path $DisableTabletSettingsRegPath1 -Name SensorPermissionState -ErrorAction SilentlyContinue).SensorPermissionState
$DisableTabletSettingsRegValueD1 = (Get-ItemProperty -Path $DisableTabletSettingsRegPathD1 -Name SensorPermissionState -ErrorAction SilentlyContinue).SensorPermissionState
$DisableTabletSettingsRegValue2 = (Get-ItemProperty -Path $DisableTabletSettingsRegPath2 -Name Value -ErrorAction SilentlyContinue).Value
$DisableTabletSettingsRegValueD2 = (Get-ItemProperty -Path $DisableTabletSettingsRegPathD2 -Name Value -ErrorAction SilentlyContinue).Value
$DisableTabletSettingsRegValue3 = (Get-ItemProperty -Path $DisableTabletSettingsRegPath3 -Name Value -ErrorAction SilentlyContinue).Value
$DisableTabletSettingsRegValueD3 = (Get-ItemProperty -Path $DisableTabletSettingsRegPathD3 -Name Value -ErrorAction SilentlyContinue).Value
$DisableTabletSettingsRegValue4 = (Get-ItemProperty -Path $DisableTabletSettingsRegPath4 -Name Value -ErrorAction SilentlyContinue).Value
$DisableTabletSettingsRegValueD4 = (Get-ItemProperty -Path $DisableTabletSettingsRegPathD4 -Name Value -ErrorAction SilentlyContinue).Value
if (($DisableTabletSettingsRegValue1 -ne "0") -or ($DisableTabletSettingsRegValueD1 -ne "0") -or ($DisableTabletSettingsRegValue2 -ne "Deny") -or ($DisableTabletSettingsRegValueD2 -ne "Deny") -or ($DisableTabletSettingsRegValue3 -ne "Deny") -or ($DisableTabletSettingsRegValueD3 -ne "Deny") -or ($DisableTabletSettingsRegValue4 -ne "Deny") -or ($DisableTabletSettingsRegValueD4 -ne "Deny")) {
$WPFDisableTabletSettingsCheckBox.Foreground = "#FF0000"
$WPFDisableTabletSettingsCheckBox.IsChecked = $false
} else {
$WPFDisableTabletSettingsCheckBox.Foreground = "#FF369726"
$WPFDisableTabletSettingsCheckBox.IsChecked = $false
}
} else {
$WPFDisableTabletSettingsCheckBox.Foreground = "#FF0000"
$WPFDisableTabletSettingsCheckBox.IsChecked = $true
}

#=== Anonymize Search Info CheckBox ===#
Set-Variable -Name "AnonymizeSearchInfoRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Scope Global
if (Test-Path -Path $AnonymizeSearchInfoRegPath) {
$AnonymizeSearchInfoRegValue = (Get-ItemProperty -Path $AnonymizeSearchInfoRegPath -Name ConnectedSearchPrivacy -ErrorAction SilentlyContinue).ConnectedSearchPrivacy
if ($AnonymizeSearchInfoRegValue -ne "3") {
$WPFAnonymizeSearchInfoCheckBox.Foreground = "#FF0000"
$WPFAnonymizeSearchInfoCheckBox.IsChecked = $true
} else {
$WPFAnonymizeSearchInfoCheckBox.Foreground = "#FF369726"
$WPFAnonymizeSearchInfoCheckBox.IsChecked = $false
}
} else {
$WPFAnonymizeSearchInfoCheckBox.Foreground = "#FF0000"
$WPFAnonymizeSearchInfoCheckBox.IsChecked = $true
}

#=== Disable Microsoft Store CheckBox ===#
Set-Variable -Name "DisableMicrosoftStoreRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Scope Global
if (Test-Path -Path $DisableMicrosoftStoreRegPath) {
$DisableMicrosoftStoreRegValue = (Get-ItemProperty -Path $DisableMicrosoftStoreRegPath -Name RemoveWindowsStore -ErrorAction SilentlyContinue).RemoveWindowsStore
if ($DisableMicrosoftStoreRegValue -ne "1") {
$WPFDisableMicrosoftStoreCheckBox.Foreground = "#FF0000"
$WPFDisableMicrosoftStoreCheckBox.IsChecked = $false
} else {
$WPFDisableMicrosoftStoreCheckBox.Foreground = "#FF369726"
$WPFDisableMicrosoftStoreCheckBox.IsChecked = $false
}
} else {
$WPFDisableMicrosoftStoreCheckBox.Foreground = "#FF0000"
$WPFDisableMicrosoftStoreCheckBox.IsChecked = $false
}

#=== Disable Store Apps CheckBox ===#
Set-Variable -Name "DisableStoreAppsRegPath" -Value "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Scope Global
if (Test-Path -Path $DisableStoreAppsRegPath) {
$DisableStoreAppsRegValue = (Get-ItemProperty -Path $DisableStoreAppsRegPath -Name DisableStoreApps -ErrorAction SilentlyContinue).DisableStoreApps
if ($DisableStoreAppsRegValue -ne "1") {
$WPFDisableStoreAppsCheckBox.Foreground = "#FF0000"
$WPFDisableStoreAppsCheckBox.IsChecked = $false
} else {
$WPFDisableStoreAppsCheckBox.Foreground = "#FF369726"
$WPFDisableStoreAppsCheckBox.IsChecked = $false
}
} else {
$WPFDisableStoreAppsCheckBox.Foreground = "#FF0000"
$WPFDisableStoreAppsCheckBox.IsChecked = $false
}

#=== Disable CEIP CheckBox ===#
Set-Variable -Name "DisableCEIPRegPath" -Value "HKLM:\SOFTWARE\Microsoft\SQMClient\Windows" -Scope Global
if (Test-Path -Path $DisableCEIPRegPath) {
$DisableCEIPRegValue = (Get-ItemProperty -Path $DisableCEIPRegPath -Name CEIPEnable -ErrorAction SilentlyContinue).CEIPEnable
if ($DisableCEIPRegValue -ne "0") {
$WPFDisableCEIPCheckBox.Foreground = "#FF0000"
$WPFDisableCEIPCheckBox.IsChecked = $true
} else {
$WPFDisableCEIPCheckBox.Foreground = "#FF369726"
$WPFDisableCEIPCheckBox.IsChecked = $false
}
} else {
$WPFDisableCEIPCheckBox.Foreground = "#FF0000"
$WPFDisableCEIPCheckBox.IsChecked = $true
}

#=== Disable App Pairing CheckBox ===#
Set-Variable -Name "DisableAppPairingRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartGlass" -Scope Global
if (Test-Path -Path $DisableAppPairingRegPath) {
$DisableAppPairingRegValue = (Get-ItemProperty -Path $DisableAppPairingRegPath -Name UserAuthPolicy -ErrorAction SilentlyContinue).UserAuthPolicy
if ($DisableAppPairingRegValue -ne "0") {
$WPFDisableAppPairingCheckBox.Foreground = "#FF0000"
$WPFDisableAppPairingCheckBox.IsChecked = $false
} else {
$WPFDisableAppPairingCheckBox.Foreground = "#FF369726"
$WPFDisableAppPairingCheckBox.IsChecked = $false
}
} else {
$WPFDisableAppPairingCheckBox.Foreground = "#FF0000"
$WPFDisableAppPairingCheckBox.IsChecked = $false
}

#=== Enable Diagnostic Data Viewer CheckBox ===#
Set-Variable -Name "EnableDiagnosticDataViewerRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack\EventTranscriptKey" -Scope Global
if (Test-Path -Path $EnableDiagnosticDataViewerRegPath) {
$EnableDiagnosticDataViewerRegValue = (Get-ItemProperty -Path $EnableDiagnosticDataViewerRegPath -Name EnableEventTranscript -ErrorAction SilentlyContinue).EnableEventTranscript
if ($EnableDiagnosticDataViewerRegValue -ne "1") {
$WPFEnableDiagnosticDataViewerCheckBox.Foreground = "#FF0000"
$WPFEnableDiagnosticDataViewerCheckBox.IsChecked = $true
} else {
$WPFEnableDiagnosticDataViewerCheckBox.Foreground = "#FF369726"
$WPFEnableDiagnosticDataViewerCheckBox.IsChecked = $false
}
} else {
$WPFEnableDiagnosticDataViewerCheckBox.Foreground = "#FF0000"
$WPFEnableDiagnosticDataViewerCheckBox.IsChecked = $true
}

#=== Disable Edge Desktop Shortcut CheckBox ===#
Set-Variable -Name "DisableEdgeDesktopShortcutRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Scope Global
if (Test-Path -Path $DisableEdgeDesktopShortcutRegPath) {
$DisableEdgeDesktopShortcutRegValue = (Get-ItemProperty -Path $DisableEdgeDesktopShortcutRegPath -Name DisableEdgeDesktopShortcutCreation -ErrorAction SilentlyContinue).DisableEdgeDesktopShortcutCreation
if ($DisableEdgeDesktopShortcutRegValue -ne "1") {
$WPFDisableEdgeDesktopShortcutCheckBox.Foreground = "#FF0000"
$WPFDisableEdgeDesktopShortcutCheckBox.IsChecked = $true
} else {
$WPFDisableEdgeDesktopShortcutCheckBox.Foreground = "#FF369726"
$WPFDisableEdgeDesktopShortcutCheckBox.IsChecked = $false
}
} else {
$WPFDisableEdgeDesktopShortcutCheckBox.Foreground = "#FF0000"
$WPFDisableEdgeDesktopShortcutCheckBox.IsChecked = $true
}

#=== Disable Web Content Evaluation CheckBox ===#
Set-Variable -Name "DisableWebContentEvaluationRegPath" -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Scope Global
if (Test-Path -Path $DisableWebContentEvaluationRegPath) {
$DisableWebContentEvaluationRegValue = (Get-ItemProperty -Path $DisableWebContentEvaluationRegPath -Name EnableWebContentEvaluation -ErrorAction SilentlyContinue).EnableWebContentEvaluation
if ($DisableWebContentEvaluationRegValue -ne "0") {
$WPFDisableWebContentEvaluationCheckBox.Foreground = "#FF0000"
$WPFDisableWebContentEvaluationCheckBox.IsChecked = $false
} else {
$WPFDisableWebContentEvaluationCheckBox.Foreground = "#FF369726"
$WPFDisableWebContentEvaluationCheckBox.IsChecked = $false
}
} else {
$WPFDisableWebContentEvaluationCheckBox.Foreground = "#FF0000"
$WPFDisableWebContentEvaluationCheckBox.IsChecked = $false
}

Remove-HKCR
UnmountDefaultUserReg
}
#detectprivappsettings
#endregion

#===========================================================================
#region Reload Settings List Button (Privacy Settings Tab)
#===========================================================================

$WPFRefreshSettingsListButtonPrivacySettings.Add_Click({
detectprivappsettings
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) App and Privacy Settings list refreshed.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) Current App and Privacy Settings redetected.`r`n")
})

#endregion

#===========================================================================
#region Check All / Uncheck All Checkbox (Privacy Settings Tab)
#===========================================================================

#=== Check All Checkbox (Checked) ===#
$WPFCheckAllButtonPrivacySettings.Add_Click({
$PrivacySettingsUnchecked = $WPFPrivacySettingsListBox.Items | Where-Object {$_.IsChecked -eq $false}
if (!($PrivacySettingsUnchecked)) {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) Nothing to check. Uncheck something first.`r`n")
} else {
ForEach ($unchecked in $PrivacySettingsUnchecked) {
$unchecked.IsChecked = $true
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) Checked all App & Privacy Settings.`r`n")
}
})

#=== Uncheck All Checkbox (Checked) ===#
$WPFUncheckAllButtonPrivacySettings.Add_Click({
$PrivacySettingsChecked = $WPFPrivacySettingsListBox.Items | Where-Object {$_.IsChecked -eq $true}
if (!($PrivacySettingsChecked)) {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) Nothing to uncheck. Check something first.`r`n")
} else {
ForEach ($checked in $PrivacySettingsChecked) {
$checked.IsChecked = $false
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) Unchecked all App & Privacy Settings.`r`n`n")
}
})
#endregion

#===========================================================================
#region PrivacySettingsListBox Right-Click Events (Privacy Settings Tab)
#===========================================================================

foreach ($PrivacyListItem in ($WPFPrivacySettingsListBox.Items)) {
if ($PrivacyListItem.Tag) {
$PrivacyListItem.Add_MouseRightButtonDown({
$WPFworkingOutputPrivacySettings.AppendText("INFO: $($This.Content) - $($This.Tag)`r`n`n")
})
}
}
#endregion

#===========================================================================
#region Process Privacy Settings Button (Privacy Settings Tab)
#===========================================================================

$WPFProcessPrivacySettingsButton.Add_Click({
MountDefaultUserReg
Set-HKCR
$WPFProgressBarPrivacySettings.Value = "0"
Set-Variable -Name "CheckedPrivSettings" -Value ($WPFPrivacySettingsListBox.Items | Where-Object {$_.IsChecked -eq $true}) -Scope Global
if (!($CheckedPrivSettings)) {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) No App or Privacy Settings selected. Check something first.`r`n")
} else {
#$CheckedPrivSettings.Tag # Description of setting / Setting description
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) *** Processing selected App & Privacy Settings ***`r`n")

#=== Check for Checked-items Pre-reqs ===
if ($CheckedPrivSettings | Where-Object {($_.Content -like "Disable Tablet Settings*") -or ($_.Content -like "Deny*Access") -or ($_.Content -like "Deny Noti*") -or ($_.Content -like "Deny Oth*") -or ($_.Content -like "Deny Radi*")}) {

if ($CheckedPrivSettings | Where-Object {($_.Content -like "Disable Tablet Settings*") -or ($_.Content -like "Deny Noti*") -or ($_.Content -like "Deny Oth*") -or ($_.Content -like "Deny Radi*")}) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) Certain Tablet or App Permissions settings detected. Verifying prerequisites...`r`n")
$PrivPreReq3 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess"
$PrivPreReq4 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global"
$PrivPreReq7 = "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess"
$PrivPreReq8 = "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global"
if (!(Test-Path $PrivPreReq3)) {
[Void](New-Item -Path $PrivPreReq3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq3.`r`n")
}
if (!(Test-Path $PrivPreReq4)) {
[Void](New-Item -Path $PrivPreReq4)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq4.`r`n")
}
if (!(Test-Path $PrivPreReq7)) {
[Void](New-Item -Path $PrivPreReq7)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq7.`r`n")
}
if (!(Test-Path $PrivPreReq8)) {
[Void](New-Item -Path $PrivPreReq8)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq8.`r`n")
}
if (!($CheckedPrivSettings | Where-Object {$_.Content -like "Disable Tablet Settings*"})) {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: Prerequisites check completed.`r`n")
}
}

if ($CheckedPrivSettings | Where-Object {$_.Content -like "Disable Tablet Settings*"}) {
$PrivPreReq1 = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor"
$PrivPreReq2 = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions"
$PrivPreReq1D = "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager"
$PrivPreReq2D = "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
$PrivPreReq5 = "$HKLMD\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor"
$PrivPreReq6 = "$HKLMD\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions"
if (!(Test-Path $PrivPreReq1D)) {
[Void](New-Item -Path $PrivPreReq1D)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq1D.`r`n")
}
if (!(Test-Path $PrivPreReq2D)) {
[Void](New-Item -Path $PrivPreReq2D)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq2D.`r`n")
}
if (!(Test-Path $PrivPreReq1)) {
[Void](New-Item -Path $PrivPreReq1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq1.`r`n")
}
if (!(Test-Path $PrivPreReq2)) {
[Void](New-Item -Path $PrivPreReq2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq2.`r`n")
}
if (!(Test-Path $PrivPreReq5)) {
[Void](New-Item -Path $PrivPreReq5)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq5.`r`n")
}
if (!(Test-Path $PrivPreReq6)) {
[Void](New-Item -Path $PrivPreReq6)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq6.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: Prerequisites check completed.`r`n")
}

if ($CheckedPrivSettings | Where-Object {$_.Content -like "Deny*Access"}) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) Win10 App Permission(s) selection detected. Verifying prerequisites...`r`n")
$PrivPreReq9 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager"
$PrivPreReq10 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
$PrivPreReq9D = "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager"
$PrivPreReq10D = "$HKLMD\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
if (!(Test-Path $PrivPreReq9)) {
[Void](New-Item -Path $PrivPreReq9)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq9.`r`n")
}
if (!(Test-Path $PrivPreReq10)) {
[Void](New-Item -Path $PrivPreReq10)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq10.`r`n")
}
if (!(Test-Path $PrivPreReq9D)) {
[Void](New-Item -Path $PrivPreReq9D)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq9D.`r`n")
}
if (!(Test-Path $PrivPreReq10D)) {
[Void](New-Item -Path $PrivPreReq10D)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PrivPreReq10D.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: Win10 App Permissions prerequisites check completed.`r`n")
}
}

############################# Privacy Settings ########################################

#=== Disable App Tracking CheckBox ===#
if ($WPFDisableAppTrackingCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Advertising ID Sharing #`r`n")
if (Test-Path $AppTrackRegPath) {
$AppTrackRegPathBackup = "$($AppTrackRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $AppTrackRegPath to $AppTrackRegPathBackup.`r`n")
[Void](Copy-Item -Path $AppTrackRegPath -Destination $AppTrackRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $AppTrackRegPath to $AppTrackRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $AppTrackRegPath)
}
if (Test-Path $AppTrackRegPathD) {
$AppTrackRegPathBackupD = "$($AppTrackRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $AppTrackRegPathD to $AppTrackRegPathBackupD.`r`n")
[Void](Copy-Item -Path $AppTrackRegPathD -Destination $AppTrackRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $AppTrackRegPathD to $AppTrackRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $AppTrackRegPathD)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAppTrackingCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $AppTrackRegPath -Name "Start_TrackProgs" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $AppTrackRegPathD -Name "Start_TrackProgs" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAppTrackingCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Shared Experiences CheckBox ===#
if ($WPFDisableSharedExperiencesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Shared Experiences #`r`n")
if (Test-Path $SharedExpRegPath) {
$SharedExpRegPathBackup = "$($SharedExpRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $SharedExpRegPath to $SharedExpRegPathBackup.`r`n")
[Void](Copy-Item -Path $SharedExpRegPath -Destination $SharedExpRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $SharedExpRegPath to $SharedExpRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $SharedExpRegPath -Force)
}
if (Test-Path $SharedExpRegPathD) {
$SharedExpRegPathBackupD = "$($SharedExpRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $SharedExpRegPathD to $SharedExpRegPathBackupD.`r`n")
[Void](Copy-Item -Path $SharedExpRegPathD -Destination $SharedExpRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $SharedExpRegPathD to $SharedExpRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $SharedExpRegPathD -Force)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableSharedExperiencesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $SharedExpRegPath -Name "RomeSdkChannelUserAuthzPolicy" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $SharedExpRegPath -Name "CdpSessionUserAuthzPolicy" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $SharedExpRegPathD -Name "RomeSdkChannelUserAuthzPolicy" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $SharedExpRegPathD -Name "CdpSessionUserAuthzPolicy" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableSharedExperiencesCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Tailored Experiences CheckBox ===#
if ($WPFDisableTailoredExperiencesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Tailored Experiences #`r`n")
if (Test-Path $TailoredExpRegPath) {
$TailoredExpRegPathBackup = "$($TailoredExpRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $TailoredExpRegPath to $TailoredExpRegPathBackup.`r`n")
[Void](Copy-Item -Path $TailoredExpRegPath -Destination $TailoredExpRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $TailoredExpRegPath to $TailoredExpRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $TailoredExpRegPath)
}
if (Test-Path $TailoredExpRegPathD) {
$TailoredExpRegPathBackupD = "$($TailoredExpRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $TailoredExpRegPathD to $TailoredExpRegPathBackupD.`r`n")
[Void](Copy-Item -Path $TailoredExpRegPathD -Destination $TailoredExpRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $TailoredExpRegPathD to $TailoredExpRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $TailoredExpRegPathD)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableTailoredExperiencesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $TailoredExpRegPath -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $TailoredExpRegPathD -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableTailoredExperiencesCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Advertising ID Sharing CheckBox ===#
if ($WPFDisableAdvertisingIDCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Advertising ID Sharing #`r`n")
if (Test-Path $AdIDRegPath) {
$AdIDRegPathBackup = "$($AdIDRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $AdIDRegPath to $AdIDRegPathBackup.`r`n")
[Void](Copy-Item -Path $AdIDRegPath -Destination $AdIDRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $AdIDRegPath to $AdIDRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $AdIDRegPath -Force)
}
if (Test-Path $AdIDRegPathD) {
$AdIDRegPathBackupD = "$($AdIDRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $AdIDRegPathD to $AdIDRegPathBackupD.`r`n")
[Void](Copy-Item -Path $AdIDRegPathD -Destination $AdIDRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $AdIDRegPathD to $AdIDRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $AdIDRegPathD -Force)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAdvertisingIDCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $AdIDRegPath -Name "Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $AdIDRegPathD -Name "Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAdvertisingIDCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Windows 10 Feedback CheckBox ===#
if ($WPFDisableWindows10FeedbackCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Windows 10 Feedback #`r`n")
if (Test-Path $Win10FeedbackRegPath) {
$Win10FeedbackRegPathBackup = "$($Win10FeedbackRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $Win10FeedbackRegPath to $Win10FeedbackRegPathBackup.`r`n")
[Void](Copy-Item -Path $Win10FeedbackRegPath -Destination $Win10FeedbackRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $Win10FeedbackRegPath to $Win10FeedbackRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $Win10FeedbackRegPath -Force)
}
if (Test-Path $Win10FeedbackRegPathD) {
$Win10FeedbackRegPathBackupD = "$($Win10FeedbackRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $Win10FeedbackRegPathD to $Win10FeedbackRegPathBackupD.`r`n")
[Void](Copy-Item -Path $Win10FeedbackRegPathD -Destination $Win10FeedbackRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $Win10FeedbackRegPathD to $Win10FeedbackRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $Win10FeedbackRegPathD -Force)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableWindows10FeedbackCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $Win10FeedbackRegPath -Name "NumberOfSIUFInPeriod" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $Win10FeedbackRegPathD -Name "NumberOfSIUFInPeriod" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $Win10FeedbackRegPath -Name "PeriodInNanoSeconds" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $Win10FeedbackRegPathD -Name "PeriodInNanoSeconds" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableWindows10FeedbackCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Access to Language List CheckBox ===#
if ($WPFDisableHttpAcceptLanguageOptOutCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Access to Language List #`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableHttpAcceptLanguageOptOutCheckBox.Content)`r`n")
[Void](Set-WinAcceptLanguageFromLanguageListOptOut $true)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: 'Set-WinAcceptLanguageFromLanguageListOptOut' has been set to 'true'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableHttpAcceptLanguageOptOutCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Inking and Typing Recognition CheckBox ===#
if ($WPFDisableInkTypeRecognitionCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Inking and Typing Recognition #`r`n")
if (Test-Path $InkTypeRecoRegPath) {
$InkTypeRecoRegPathBackup = "$($InkTypeRecoRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypeRecoRegPath to $InkTypeRecoRegPathBackup.`r`n")
[Void](Copy-Item -Path $InkTypeRecoRegPath -Destination $InkTypeRecoRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypeRecoRegPath to $InkTypeRecoRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $InkTypeRecoRegPath)
}
if (Test-Path $InkTypeRecoRegPathD) {
$InkTypeRecoRegPathBackupD = "$($InkTypeRecoRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypeRecoRegPathD to $InkTypeRecoRegPathBackupD.`r`n")
[Void](Copy-Item -Path $InkTypeRecoRegPathD -Destination $InkTypeRecoRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypeRecoRegPathD to $InkTypeRecoRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $InkTypeRecoRegPathD)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableInkTypeRecognitionCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $InkTypeRecoRegPath -Name "Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypeRecoRegPathD -Name "Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableInkTypeRecognitionCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Pen and Ink Recommendations CheckBox ===#
if ($WPFDisablePenInkRecommendationsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Pen and Ink Recommendations #`r`n")
if (Test-Path $PenInkRecoRegPath) {
$PenInkRecoRegPathBackup = "$($PenInkRecoRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $PenInkRecoRegPath to $PenInkRecoRegPathBackup.`r`n")
[Void](Copy-Item -Path $PenInkRecoRegPath -Destination $PenInkRecoRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $PenInkRecoRegPath to $PenInkRecoRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $PenInkRecoRegPath)
}
if (Test-Path $PenInkRecoRegPathD) {
$PenInkRecoRegPathBackupD = "$($PenInkRecoRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $PenInkRecoRegPathD to $PenInkRecoRegPathBackupD.`r`n")
[Void](Copy-Item -Path $PenInkRecoRegPathD -Destination $PenInkRecoRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $PenInkRecoRegPathD to $PenInkRecoRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $PenInkRecoRegPathD)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisablePenInkRecommendationsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $PenInkRecoRegPath -Name "PenWorkspaceAppSuggestionsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $PenInkRecoRegPathD -Name "PenWorkspaceAppSuggestionsEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisablePenInkRecommendationsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Inking and Typing Personalization CheckBox ===#
if ($WPFDisableInkTypePersonalizationCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Inking and Typing Personalization #`r`n")
if (Test-Path $InkTypePersRegPath1) {
$InkTypePersRegPathBackup = "$($InkTypePersRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPath1 to $InkTypePersRegPathBackup.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPath1 -Destination $InkTypePersRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPath1 to $InkTypePersRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPath1)
}
if (Test-Path $InkTypePersRegPath2) {
$InkTypePersRegPathBackup = "$($InkTypePersRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPath2 to $InkTypePersRegPathBackup.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPath2 -Destination $InkTypePersRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPath2 to $InkTypePersRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPath2)
}
if (Test-Path $InkTypePersRegPath3) {
$InkTypePersRegPathBackup = "$($InkTypePersRegPath3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPath3 to $InkTypePersRegPathBackup.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPath3 -Destination $InkTypePersRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPath3 to $InkTypePersRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPath3)
}
if (Test-Path $InkTypePersRegPath35) {
$InkTypePersRegPathBackup = "$($InkTypePersRegPath35).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPath35 to $InkTypePersRegPathBackup.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPath35 -Destination $InkTypePersRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPath35 to $InkTypePersRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPath35)
}
if (Test-Path $InkTypePersRegPath4) {
$InkTypePersRegPathBackup = "$($InkTypePersRegPath4).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPath4 to $InkTypePersRegPathBackup.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPath4 -Destination $InkTypePersRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPath4 to $InkTypePersRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPath4)
}
if (Test-Path $InkTypePersRegPathD1) {
$InkTypePersRegPathBackupD = "$($InkTypePersRegPathD1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPathD1 to $InkTypePersRegPathBackupD.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPathD1 -Destination $InkTypePersRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPathD1 to $InkTypePersRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPathD1)
}
if (Test-Path $InkTypePersRegPathD2) {
$InkTypePersRegPathBackupD = "$($InkTypePersRegPathD2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPathD2 to $InkTypePersRegPathBackupD.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPathD2 -Destination $InkTypePersRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPathD2 to $InkTypePersRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPathD2)
}
if (Test-Path $InkTypePersRegPathD3) {
$InkTypePersRegPathBackupD = "$($InkTypePersRegPathD3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPathD3 to $InkTypePersRegPathBackupD.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPathD3 -Destination $InkTypePersRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPathD3 to $InkTypePersRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPathD3)
}
if (Test-Path $InkTypePersRegPathD35) {
$InkTypePersRegPathBackupD = "$($InkTypePersRegPathD35).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPathD35 to $InkTypePersRegPathBackupD.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPathD35 -Destination $InkTypePersRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPathD35 to $InkTypePersRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPathD35)
}
if (Test-Path $InkTypePersRegPathD4) {
$InkTypePersRegPathBackupD = "$($InkTypePersRegPathD4).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $InkTypePersRegPathD4 to $InkTypePersRegPathBackupD.`r`n")
[Void](Copy-Item -Path $InkTypePersRegPathD4 -Destination $InkTypePersRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $InkTypePersRegPathD4 to $InkTypePersRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $InkTypePersRegPathD4)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableInkTypePersonalizationCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $InkTypePersRegPath1 -Name "Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPath2 -Name "RestrictImplicitTextCollection" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPath2 -Name "RestrictImplicitInkCollection" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPath3 -Name "HarvestContacts" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPath4 -Name "AcceptedPrivacyPolicy" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPathD1 -Name "Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPathD2 -Name "RestrictImplicitTextCollection" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPathD2 -Name "RestrictImplicitInkCollection" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPathD3 -Name "HarvestContacts" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $InkTypePersRegPathD4 -Name "AcceptedPrivacyPolicy" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableInkTypePersonalizationCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Inventory Collector CheckBox ===#
if ($WPFDisableInventoryCollectorCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Inventory Collector #`r`n")
if (Test-Path $DisableInventoryCollectorRegPath) {
$DisableInventoryCollectorRegPathBackup = "$($DisableInventoryCollectorRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableInventoryCollectorRegPath to $DisableInventoryCollectorRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableInventoryCollectorRegPath -Destination $DisableInventoryCollectorRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableInventoryCollectorRegPath to $DisableInventoryCollectorRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableInventoryCollectorRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableInventoryCollectorRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableInventoryCollectorCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableInventoryCollectorRegPath -Name "DisableInventory" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableInventory' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableInventoryCollectorCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Application Telemetry CheckBox ===#
if ($WPFDisableApplicationTelemetryCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Application Telemetry #`r`n")
if (Test-Path $DisableApplicationTelemetryRegPath) {
$DisableApplicationTelemetryRegPathBackup = "$($DisableApplicationTelemetryRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableApplicationTelemetryRegPath to $DisableApplicationTelemetryRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableApplicationTelemetryRegPath -Destination $DisableApplicationTelemetryRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableApplicationTelemetryRegPath to $DisableApplicationTelemetryRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableApplicationTelemetryRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableApplicationTelemetryRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableApplicationTelemetryCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableApplicationTelemetryRegPath -Name "AITEnable" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AITEnable' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableApplicationTelemetryCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Location Globally CheckBox ===#
if ($WPFDisableLocationGloballyCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Location Globally #`r`n")
if (Test-Path $DisableLocationGloballyRegPath) {
$DisableLocationGloballyRegPathBackup = "$($DisableLocationGloballyRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableLocationGloballyRegPath to $DisableLocationGloballyRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableLocationGloballyRegPath -Destination $DisableLocationGloballyRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableLocationGloballyRegPath to $DisableLocationGloballyRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableLocationGloballyRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableLocationGloballyRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableLocationGloballyCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableLocationGloballyRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableLocationGloballyCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Telemetry CheckBox ===#
if ($WPFDisableTelemetryCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Telemetry #`r`n")
if (Test-Path $DisableTelemetryRegPath) {
$DisableTelemetryRegPathBackup = "$($DisableTelemetryRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTelemetryRegPath to $DisableTelemetryRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableTelemetryRegPath -Destination $DisableTelemetryRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTelemetryRegPath to $DisableTelemetryRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableTelemetryRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTelemetryRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableTelemetryCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableTelemetryRegPath -Name "AllowTelemetry" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AllowTelemetry' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableTelemetryCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Edge Tracking CheckBox ===#
if ($WPFDisableEdgeTrackingCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Edge Tracking #`r`n")
if (Test-Path $DisableEdgeTrackingRegPath1) {
$DisableEdgeTrackingRegPath1Backup = "$($DisableEdgeTrackingRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableEdgeTrackingRegPath1 to $DisableEdgeTrackingRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableEdgeTrackingRegPath1 -Destination $DisableEdgeTrackingRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableEdgeTrackingRegPath1 to $DisableEdgeTrackingRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableEdgeTrackingRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableEdgeTrackingRegPath1.`r`n")
}
if (Test-Path $DisableEdgeTrackingRegPath2) {
$DisableEdgeTrackingRegPath2Backup = "$($DisableEdgeTrackingRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableEdgeTrackingRegPath2 to $DisableEdgeTrackingRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableEdgeTrackingRegPath2 -Destination $DisableEdgeTrackingRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableEdgeTrackingRegPath2 to $DisableEdgeTrackingRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableEdgeTrackingRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableEdgeTrackingRegPath2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableEdgeTrackingCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableEdgeTrackingRegPath2 -Name "DoNotTrack" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DoNotTrack' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableEdgeTrackingCheckBox.Content) setting has been applied.`r`n")
}

############################# Cortana #################################################

#=== Disable Cortana CheckBox ===#
if ($WPFDisableCortanaCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Cortana #`r`n")
if (Test-Path $DisableCortanaRegPath) {
$DisableCortanaRegPathBackup = "$($DisableCortanaRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaRegPath to $DisableCortanaRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableCortanaRegPath -Destination $DisableCortanaRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaRegPath to $DisableCortanaRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCortanaRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableCortanaCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableCortanaRegPath -Name "AllowCortana" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AllowCortana' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableCortanaCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Cortana on Lock Screen CheckBox ===#
if ($WPFDisableCortanaOnLockScreenCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Cortana on Lock Screen #`r`n")
if (Test-Path $DisableCortanaLokScrnRegPath) {
$DisableCortanaLokScrnRegPathBackup = "$($DisableCortanaLokScrnRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaLokScrnRegPath to $DisableCortanaLokScrnRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableCortanaLokScrnRegPath -Destination $DisableCortanaLokScrnRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaLokScrnRegPath to $DisableCortanaLokScrnRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaLokScrnRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCortanaLokScrnRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableCortanaOnLockScreenCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableCortanaLokScrnRegPath -Name "AllowCortanaAboveLock" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AllowCortanaAboveLock' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableCortanaOnLockScreenCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Cortana Above Lock Screen CheckBox ===#
if ($WPFDisableCortanaAboveLockScreenCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Cortana Above Lock Screen #`r`n")
if (Test-Path $DisableCortanaAboveLockScreenRegPath) {
$DisableCortanaAboveLockScreenRegPathBackup = "$($DisableCortanaAboveLockScreenRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaAboveLockScreenRegPath to $DisableCortanaAboveLockScreenRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableCortanaAboveLockScreenRegPath -Destination $DisableCortanaAboveLockScreenRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaAboveLockScreenRegPath to $DisableCortanaAboveLockScreenRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaAboveLockScreenRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCortanaAboveLockScreenRegPath.`r`n")
}
if (Test-Path $DisableCortanaAboveLockScreenRegPathD) {
$DisableCortanaAboveLockScreenRegPathBackupD = "$($DisableCortanaAboveLockScreenRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaAboveLockScreenRegPathD to $DisableCortanaAboveLockScreenRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableCortanaAboveLockScreenRegPathD -Destination $DisableCortanaAboveLockScreenRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaAboveLockScreenRegPathD to $DisableCortanaAboveLockScreenRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaAboveLockScreenRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCortanaAboveLockScreenRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableCortanaAboveLockScreenCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableCortanaAboveLockScreenRegPath -Name "VoiceActivationEnableAboveLockscreen" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAboveLockScreenRegPathD -Name "VoiceActivationEnableAboveLockscreen" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'VoiceActivationEnableAboveLockscreen' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableCortanaAboveLockScreenCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Cortana and Bing Search CheckBox ===#
if ($WPFDisableCortanaAndBingSearchScreenCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Cortana and Bing Search #`r`n")
if (Test-Path $DisableCortanaAndBingSearchRegPath) {
$DisableCortanaAndBingSearchRegPathBackup = "$($DisableCortanaAndBingSearchRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaAndBingSearchRegPath to $DisableCortanaAndBingSearchRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableCortanaAndBingSearchRegPath -Destination $DisableCortanaAndBingSearchRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaAndBingSearchRegPath to $DisableCortanaAndBingSearchRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaAndBingSearchRegPath -Force)
}
if (Test-Path $DisableCortanaAndBingSearchRegPathD) {
$DisableCortanaAndBingSearchRegPathBackupD = "$($DisableCortanaAndBingSearchRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaAndBingSearchRegPathD to $DisableCortanaAndBingSearchRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableCortanaAndBingSearchRegPathD -Destination $DisableCortanaAndBingSearchRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaAndBingSearchRegPathD to $DisableCortanaAndBingSearchRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaAndBingSearchRegPathD -Force)
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableCortanaAndBingSearchScreenCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name "CortanaEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name "CanCortanaBeEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name "BingSearchEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name "DeviceHistoryEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name "CortanaConsent" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPath -Name "CortanaInAmbientMode" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name "CortanaEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name "CanCortanaBeEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name "BingSearchEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name "DeviceHistoryEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name "CortanaConsent" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaAndBingSearchRegPathD -Name "CortanaInAmbientMode" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableCortanaAndBingSearchScreenCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Cortana Search History CheckBox ===#
if ($WPFDisableCortanaSearchHistoryCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Cortana Search History #`r`n")
if (Test-Path $DisableCortanaSearchHistoryRegPath) {
$DisableCortanaSearchHistoryRegPathBackup = "$($DisableCortanaSearchHistoryRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaSearchHistoryRegPath to $DisableCortanaSearchHistoryRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableCortanaSearchHistoryRegPath -Destination $DisableCortanaSearchHistoryRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaSearchHistoryRegPath to $DisableCortanaSearchHistoryRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaSearchHistoryRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCortanaSearchHistoryRegPath.`r`n")
}
if (Test-Path $DisableCortanaSearchHistoryRegPathD) {
$DisableCortanaSearchHistoryRegPathBackupD = "$($DisableCortanaSearchHistoryRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCortanaSearchHistoryRegPathD to $DisableCortanaSearchHistoryRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableCortanaSearchHistoryRegPathD -Destination $DisableCortanaSearchHistoryRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCortanaSearchHistoryRegPathD to $DisableCortanaSearchHistoryRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableCortanaSearchHistoryRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCortanaSearchHistoryRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableCortanaSearchHistoryCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableCortanaSearchHistoryRegPath -Name "HistoryViewEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableCortanaSearchHistoryRegPathD -Name "HistoryViewEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'HistoryViewEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableCortanaSearchHistoryCheckBox.Content) setting has been applied.`r`n")
}

############################# APP Permissions #########################################

#=== Deny Apps Running in Background CheckBox ===#
if ($WPFDenyAppsRunningInBackgroundCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Apps Running in Background #`r`n")
if (Test-Path $DenyAppsRunningInBackgroundRegPath1) {
$DenyAppsRunningInBackgroundRegPath1Backup = "$($DenyAppsRunningInBackgroundRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppsRunningInBackgroundRegPath1 to $DenyAppsRunningInBackgroundRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DenyAppsRunningInBackgroundRegPath1 -Destination $DenyAppsRunningInBackgroundRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppsRunningInBackgroundRegPath1 to $DenyAppsRunningInBackgroundRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DenyAppsRunningInBackgroundRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppsRunningInBackgroundRegPath1.`r`n")
}
if (Test-Path $DenyAppsRunningInBackgroundRegPathD1) {
$DenyAppsRunningInBackgroundRegPathBackupD1 = "$($DenyAppsRunningInBackgroundRegPathD1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppsRunningInBackgroundRegPathD1 to $DenyAppsRunningInBackgroundRegPathBackupD1.`r`n")
[Void](Copy-Item -Path $DenyAppsRunningInBackgroundRegPathD1 -Destination $DenyAppsRunningInBackgroundRegPathBackupD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppsRunningInBackgroundRegPathD1 to $DenyAppsRunningInBackgroundRegPathBackupD1.`r`n")
} else {
[Void](New-Item -Path $DenyAppsRunningInBackgroundRegPathD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppsRunningInBackgroundRegPathD1.`r`n")
}
if (Test-Path $DenyAppsRunningInBackgroundRegPath2) {
$DenyAppsRunningInBackgroundRegPath2Backup = "$($DenyAppsRunningInBackgroundRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppsRunningInBackgroundRegPath2 to $DenyAppsRunningInBackgroundRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DenyAppsRunningInBackgroundRegPath2 -Destination $DenyAppsRunningInBackgroundRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppsRunningInBackgroundRegPath2 to $DenyAppsRunningInBackgroundRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DenyAppsRunningInBackgroundRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppsRunningInBackgroundRegPath2.`r`n")
}
if (Test-Path $DenyAppsRunningInBackgroundRegPathD2) {
$DenyAppsRunningInBackgroundRegPathBackupD2 = "$($DenyAppsRunningInBackgroundRegPathD2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppsRunningInBackgroundRegPathD2 to $DenyAppsRunningInBackgroundRegPathBackupD2.`r`n")
[Void](Copy-Item -Path $DenyAppsRunningInBackgroundRegPathD2 -Destination $DenyAppsRunningInBackgroundRegPathBackupD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppsRunningInBackgroundRegPathD2 to $DenyAppsRunningInBackgroundRegPathBackupD2.`r`n")
} else {
[Void](New-Item -Path $DenyAppsRunningInBackgroundRegPathD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppsRunningInBackgroundRegPathD2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyAppsRunningInBackgroundCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyAppsRunningInBackgroundRegPath1 -Name "GlobalUserDisabled" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DenyAppsRunningInBackgroundRegPathD1 -Name "GlobalUserDisabled" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DenyAppsRunningInBackgroundRegPath2 -Name "BackgroundAppGlobalToggle" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DenyAppsRunningInBackgroundRegPathD2 -Name "BackgroundAppGlobalToggle" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'GlobalUserDisabled' to '1' at '$DenyAppsRunningInBackgroundRegPath1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'BackgroundAppGlobalToggle' to '0' at '$DenyAppsRunningInBackgroundRegPath2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyAppsRunningInBackgroundCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Broad File System Access Access CheckBox ===#
if ($WPFDenyAppDiagnosticsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Broad File System Access Access #`r`n")
if (Test-Path $DenyAppDiagnosticsRegPath1) {
$DenyAppDiagnosticsRegPath1Backup = "$($DenyAppDiagnosticsRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppDiagnosticsRegPath1 to $DenyAppDiagnosticsRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DenyAppDiagnosticsRegPath1 -Destination $DenyAppDiagnosticsRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppDiagnosticsRegPath1 to $DenyAppDiagnosticsRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DenyAppDiagnosticsRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppDiagnosticsRegPath1.`r`n")
}
if (Test-Path $DenyAppDiagnosticsRegPathD1) {
$DenyAppDiagnosticsRegPathBackupD1 = "$($DenyAppDiagnosticsRegPathD1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppDiagnosticsRegPathD1 to $DenyAppDiagnosticsRegPathBackupD1.`r`n")
[Void](Copy-Item -Path $DenyAppDiagnosticsRegPathD1 -Destination $DenyAppDiagnosticsRegPathBackupD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppDiagnosticsRegPathD1 to $DenyAppDiagnosticsRegPathBackupD1.`r`n")
} else {
[Void](New-Item -Path $DenyAppDiagnosticsRegPathD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppDiagnosticsRegPathD1.`r`n")
}
if (Test-Path $DenyAppDiagnosticsRegPath2) {
$DenyAppDiagnosticsRegPath2Backup = "$($DenyAppDiagnosticsRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppDiagnosticsRegPath2 to $DenyAppDiagnosticsRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DenyAppDiagnosticsRegPath2 -Destination $DenyAppDiagnosticsRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppDiagnosticsRegPath2 to $DenyAppDiagnosticsRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DenyAppDiagnosticsRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppDiagnosticsRegPath2.`r`n")
}
if (Test-Path $DenyAppDiagnosticsRegPathD2) {
$DenyAppDiagnosticsRegPathBackupD2 = "$($DenyAppDiagnosticsRegPathD2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppDiagnosticsRegPathD2 to $DenyAppDiagnosticsRegPathBackupD2.`r`n")
[Void](Copy-Item -Path $DenyAppDiagnosticsRegPathD2 -Destination $DenyAppDiagnosticsRegPathBackupD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppDiagnosticsRegPathD2 to $DenyAppDiagnosticsRegPathBackupD2.`r`n")
} else {
[Void](New-Item -Path $DenyAppDiagnosticsRegPathD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppDiagnosticsRegPathD2.`r`n")
}
if (Test-Path $DenyAppDiagnosticsRegPath3) {
$DenyAppDiagnosticsRegPath3Backup = "$($DenyAppDiagnosticsRegPath3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppDiagnosticsRegPath3 to $DenyAppDiagnosticsRegPath3Backup.`r`n")
[Void](Copy-Item -Path $DenyAppDiagnosticsRegPath3 -Destination $DenyAppDiagnosticsRegPath3Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppDiagnosticsRegPath3 to $DenyAppDiagnosticsRegPath3Backup.`r`n")
} else {
[Void](New-Item -Path $DenyAppDiagnosticsRegPath3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppDiagnosticsRegPath3.`r`n")
}
if (Test-Path $DenyAppDiagnosticsRegPathD3) {
$DenyAppDiagnosticsRegPathBackupD3 = "$($DenyAppDiagnosticsRegPathD3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyAppDiagnosticsRegPathD3 to $DenyAppDiagnosticsRegPathBackupD3.`r`n")
[Void](Copy-Item -Path $DenyAppDiagnosticsRegPathD3 -Destination $DenyAppDiagnosticsRegPathBackupD3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyAppDiagnosticsRegPathD3 to $DenyAppDiagnosticsRegPathBackupD3.`r`n")
} else {
[Void](New-Item -Path $DenyAppDiagnosticsRegPathD3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyAppDiagnosticsRegPathD3.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyAppDiagnosticsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyAppDiagnosticsRegPath3 -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyAppDiagnosticsRegPathD3 -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny' at '$DenyAppDiagnosticsRegPath3'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyAppDiagnosticsCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Broad File System Access Access CheckBox ===#
if ($WPFDenyBroadFileSystemAccessAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Broad File System Access Access #`r`n")
if (Test-Path $DenyBroadFileSystemAccessAccessRegPath) {
$DenyBroadFileSystemAccessAccessRegPathBackup = "$($DenyBroadFileSystemAccessAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyBroadFileSystemAccessAccessRegPath to $DenyBroadFileSystemAccessAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyBroadFileSystemAccessAccessRegPath -Destination $DenyBroadFileSystemAccessAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyBroadFileSystemAccessAccessRegPath to $DenyBroadFileSystemAccessAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyBroadFileSystemAccessAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyBroadFileSystemAccessAccessRegPath.`r`n")
}
if (Test-Path $DenyBroadFileSystemAccessAccessRegPathD) {
$DenyBroadFileSystemAccessAccessRegPathBackupD = "$($DenyBroadFileSystemAccessAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyBroadFileSystemAccessAccessRegPathD to $DenyBroadFileSystemAccessAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyBroadFileSystemAccessAccessRegPathD -Destination $DenyBroadFileSystemAccessAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyBroadFileSystemAccessAccessRegPathD to $DenyBroadFileSystemAccessAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyBroadFileSystemAccessAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyBroadFileSystemAccessAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyBroadFileSystemAccessAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyBroadFileSystemAccessAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyBroadFileSystemAccessAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyBroadFileSystemAccessAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Calendar Access CheckBox ===#
if ($WPFDenyCalendarAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Calendar Access #`r`n")
if (Test-Path $DenyCalendarAccessRegPath) {
$DenyCalendarAccessRegPathBackup = "$($DenyCalendarAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyCalendarAccessRegPath to $DenyCalendarAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyCalendarAccessRegPath -Destination $DenyCalendarAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyCalendarAccessRegPath to $DenyCalendarAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyCalendarAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyCalendarAccessRegPath.`r`n")
}
if (Test-Path $DenyCalendarAccessRegPathD) {
$DenyCalendarAccessRegPathBackupD = "$($DenyCalendarAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyCalendarAccessRegPathD to $DenyCalendarAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyCalendarAccessRegPathD -Destination $DenyCalendarAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyCalendarAccessRegPathD to $DenyCalendarAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyCalendarAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyCalendarAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyCalendarAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyCalendarAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyCalendarAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyCalendarAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Cellular Data Access CheckBox ===#
if ($WPFDenyCellularDataAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Cellular Data Access #`r`n")
if (Test-Path $DenyCellularDataAccessRegPath) {
$DenyCellularDataAccessRegPathBackup = "$($DenyCellularDataAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyCellularDataAccessRegPath to $DenyCellularDataAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyCellularDataAccessRegPath -Destination $DenyCellularDataAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyCellularDataAccessRegPath to $DenyCellularDataAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyCellularDataAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyCellularDataAccessRegPath.`r`n")
}
if (Test-Path $DenyCellularDataAccessRegPathD) {
$DenyCellularDataAccessRegPathBackupD = "$($DenyCellularDataAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyCellularDataAccessRegPathD to $DenyCellularDataAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyCellularDataAccessRegPathD -Destination $DenyCellularDataAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyCellularDataAccessRegPathD to $DenyCellularDataAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyCellularDataAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyCellularDataAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyCellularDataAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyCellularDataAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyCellularDataAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyCellularDataAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Chat Access CheckBox ===#
if ($WPFDenyChatAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Chat Access #`r`n")
if (Test-Path $DenyChatAccessRegPath) {
$DenyChatAccessRegPathBackup = "$($DenyChatAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyChatAccessRegPath to $DenyChatAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyChatAccessRegPath -Destination $DenyChatAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyChatAccessRegPath to $DenyChatAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyChatAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyChatAccessRegPath.`r`n")
}
if (Test-Path $DenyChatAccessRegPathD) {
$DenyChatAccessRegPathBackupD = "$($DenyChatAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyChatAccessRegPathD to $DenyChatAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyChatAccessRegPathD -Destination $DenyChatAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyChatAccessRegPathD to $DenyChatAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyChatAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyChatAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyChatAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyChatAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyChatAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyChatAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Contacts Access CheckBox ===#
if ($WPFDenyContactsAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Contacts Access #`r`n")
if (Test-Path $DenyContactsAccessRegPath) {
$DenyContactsAccessRegPathBackup = "$($DenyContactsAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyContactsAccessRegPath to $DenyContactsAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyContactsAccessRegPath -Destination $DenyContactsAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyContactsAccessRegPath to $DenyContactsAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyContactsAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyContactsAccessRegPath.`r`n")
}
if (Test-Path $DenyContactsAccessRegPathD) {
$DenyContactsAccessRegPathBackupD = "$($DenyContactsAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyContactsAccessRegPathD to $DenyContactsAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyContactsAccessRegPathD -Destination $DenyContactsAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyContactsAccessRegPathD to $DenyContactsAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyContactsAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyContactsAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyContactsAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyContactsAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyContactsAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyContactsAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Documents Library Access CheckBox ===#
if ($WPFDenyDocumentsLibraryAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Documents Library Access #`r`n")
if (Test-Path $DenyDocumentsLibraryAccessRegPath) {
$DenyDocumentsLibraryAccessRegPathBackup = "$($DenyDocumentsLibraryAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyDocumentsLibraryAccessRegPath to $DenyDocumentsLibraryAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyDocumentsLibraryAccessRegPath -Destination $DenyDocumentsLibraryAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyDocumentsLibraryAccessRegPath to $DenyDocumentsLibraryAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyDocumentsLibraryAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyDocumentsLibraryAccessRegPath.`r`n")
}
if (Test-Path $DenyDocumentsLibraryAccessRegPathD) {
$DenyDocumentsLibraryAccessRegPathBackupD = "$($DenyDocumentsLibraryAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyDocumentsLibraryAccessRegPathD to $DenyDocumentsLibraryAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyDocumentsLibraryAccessRegPathD -Destination $DenyDocumentsLibraryAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyDocumentsLibraryAccessRegPathD to $DenyDocumentsLibraryAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyDocumentsLibraryAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyDocumentsLibraryAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyDocumentsLibraryAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyDocumentsLibraryAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyDocumentsLibraryAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyDocumentsLibraryAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Email Access CheckBox ===#
if ($WPFDenyEmailAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Email Access #`r`n")
if (Test-Path $DenyEmailAccessRegPath) {
$DenyEmailAccessRegPathBackup = "$($DenyEmailAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyEmailAccessRegPath to $DenyEmailAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyEmailAccessRegPath -Destination $DenyEmailAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyEmailAccessRegPath to $DenyEmailAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyEmailAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyEmailAccessRegPath.`r`n")
}
if (Test-Path $DenyEmailAccessRegPathD) {
$DenyEmailAccessRegPathBackupD = "$($DenyEmailAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyEmailAccessRegPathD to $DenyEmailAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyEmailAccessRegPathD -Destination $DenyEmailAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyEmailAccessRegPathD to $DenyEmailAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyEmailAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyEmailAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyEmailAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyEmailAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyEmailAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyEmailAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Gaze Input Access CheckBox ===#
if ($WPFDenyGazeInputAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Gaze Input Access #`r`n")
if (Test-Path $DenyGazeInputAccessRegPath) {
$DenyGazeInputAccessRegPathBackup = "$($DenyGazeInputAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyGazeInputAccessRegPath to $DenyGazeInputAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyGazeInputAccessRegPath -Destination $DenyGazeInputAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyGazeInputAccessRegPath to $DenyGazeInputAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyGazeInputAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyGazeInputAccessRegPath.`r`n")
}
if (Test-Path $DenyGazeInputAccessRegPathD) {
$DenyGazeInputAccessRegPathBackupD = "$($DenyGazeInputAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyGazeInputAccessRegPathD to $DenyGazeInputAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyGazeInputAccessRegPathD -Destination $DenyGazeInputAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyGazeInputAccessRegPathD to $DenyGazeInputAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyGazeInputAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyGazeInputAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyGazeInputAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyGazeInputAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyGazeInputAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyGazeInputAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Location Access CheckBox ===#
if ($WPFDenyLocationAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Location Access #`r`n")
if (Test-Path $DenyLocationAccessRegPath) {
$DenyLocationAccessRegPathBackup = "$($DenyLocationAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyLocationAccessRegPath to $DenyLocationAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyLocationAccessRegPath -Destination $DenyLocationAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyLocationAccessRegPath to $DenyLocationAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyLocationAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyLocationAccessRegPath.`r`n")
}
if (Test-Path $DenyLocationAccessRegPathD) {
$DenyLocationAccessRegPathBackupD = "$($DenyLocationAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyLocationAccessRegPathD to $DenyLocationAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyLocationAccessRegPathD -Destination $DenyLocationAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyLocationAccessRegPathD to $DenyLocationAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyLocationAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyLocationAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyLocationAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyLocationAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyLocationAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyLocationAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Microphone Access CheckBox ===#
if ($WPFDenyMicrophoneAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Microphone Access #`r`n")
if (Test-Path $DenyMicrophoneAccessRegPath) {
$DenyMicrophoneAccessRegPathBackup = "$($DenyMicrophoneAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyMicrophoneAccessRegPath to $DenyMicrophoneAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyMicrophoneAccessRegPath -Destination $DenyMicrophoneAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyMicrophoneAccessRegPath to $DenyMicrophoneAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyMicrophoneAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyMicrophoneAccessRegPath.`r`n")
}
if (Test-Path $DenyMicrophoneAccessRegPathD) {
$DenyMicrophoneAccessRegPathBackupD = "$($DenyMicrophoneAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyMicrophoneAccessRegPathD to $DenyMicrophoneAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyMicrophoneAccessRegPathD -Destination $DenyMicrophoneAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyMicrophoneAccessRegPathD to $DenyMicrophoneAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyMicrophoneAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyMicrophoneAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyMicrophoneAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyMicrophoneAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyMicrophoneAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyMicrophoneAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Notifications CheckBox ===#
if ($WPFDenyNotificationsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Notifications #`r`n")
if (Test-Path $DenyNotificationsRegPath) {
$DenyNotificationsRegPathBackup = "$($DenyNotificationsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyNotificationsRegPath to $DenyNotificationsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyNotificationsRegPath -Destination $DenyNotificationsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyNotificationsRegPath to $DenyNotificationsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyNotificationsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyNotificationsRegPath.`r`n")
}
if (Test-Path $DenyNotificationsRegPathD) {
$DenyNotificationsRegPathBackupD = "$($DenyNotificationsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyNotificationsRegPathD to $DenyNotificationsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyNotificationsRegPathD -Destination $DenyNotificationsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyNotificationsRegPathD to $DenyNotificationsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyNotificationsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyNotificationsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyNotificationsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyNotificationsRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyNotificationsRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyNotificationsCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Other Devices CheckBox ===#
if ($WPFDenyOtherDevicesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Other Devices #`r`n")
if (Test-Path $DenyOtherDevicesRegPath) {
$DenyOtherDevicesRegPathBackup = "$($DenyOtherDevicesRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyOtherDevicesRegPath to $DenyOtherDevicesRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyOtherDevicesRegPath -Destination $DenyOtherDevicesRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyOtherDevicesRegPath to $DenyOtherDevicesRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyOtherDevicesRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyOtherDevicesRegPath.`r`n")
}
if (Test-Path $DenyOtherDevicesRegPathD) {
$DenyOtherDevicesRegPathBackupD = "$($DenyOtherDevicesRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyOtherDevicesRegPathD to $DenyOtherDevicesRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyOtherDevicesRegPathD -Destination $DenyOtherDevicesRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyOtherDevicesRegPathD to $DenyOtherDevicesRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyOtherDevicesRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyOtherDevicesRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyOtherDevicesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyOtherDevicesRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyOtherDevicesRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyOtherDevicesCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Phone Call History Access CheckBox ===#
if ($WPFDenyPhoneCallHistoryAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Phone Call History Access #`r`n")
if (Test-Path $DenyPhoneCallHistoryAccessRegPath) {
$DenyPhoneCallHistoryAccessRegPathBackup = "$($DenyPhoneCallHistoryAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyPhoneCallHistoryAccessRegPath to $DenyPhoneCallHistoryAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyPhoneCallHistoryAccessRegPath -Destination $DenyPhoneCallHistoryAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyPhoneCallHistoryAccessRegPath to $DenyPhoneCallHistoryAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyPhoneCallHistoryAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyPhoneCallHistoryAccessRegPath.`r`n")
}
if (Test-Path $DenyPhoneCallHistoryAccessRegPathD) {
$DenyPhoneCallHistoryAccessRegPathBackupD = "$($DenyPhoneCallHistoryAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyPhoneCallHistoryAccessRegPathD to $DenyPhoneCallHistoryAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyPhoneCallHistoryAccessRegPathD -Destination $DenyPhoneCallHistoryAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyPhoneCallHistoryAccessRegPathD to $DenyPhoneCallHistoryAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyPhoneCallHistoryAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyPhoneCallHistoryAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyPhoneCallHistoryAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyPhoneCallHistoryAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyPhoneCallHistoryAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyPhoneCallHistoryAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Pictures Library Access CheckBox ===#
if ($WPFDenyPicturesLibraryAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Pictures Library Access #`r`n")
if (Test-Path $DenyPicturesLibraryAccessRegPath) {
$DenyPicturesLibraryAccessRegPathBackup = "$($DenyPicturesLibraryAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyPicturesLibraryAccessRegPath to $DenyPicturesLibraryAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyPicturesLibraryAccessRegPath -Destination $DenyPicturesLibraryAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyPicturesLibraryAccessRegPath to $DenyPicturesLibraryAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyPicturesLibraryAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyPicturesLibraryAccessRegPath.`r`n")
}
if (Test-Path $DenyPicturesLibraryAccessRegPathD) {
$DenyPicturesLibraryAccessRegPathBackupD = "$($DenyPicturesLibraryAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyPicturesLibraryAccessRegPathD to $DenyPicturesLibraryAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyPicturesLibraryAccessRegPathD -Destination $DenyPicturesLibraryAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyPicturesLibraryAccessRegPathD to $DenyPicturesLibraryAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyPicturesLibraryAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyPicturesLibraryAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyPicturesLibraryAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyPicturesLibraryAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyPicturesLibraryAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyPicturesLibraryAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Radios CheckBox ===#
if ($WPFDenyRadiosCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Radios #`r`n")
if (Test-Path $DenyRadiosRegPath) {
$DenyRadiosRegPathBackup = "$($DenyRadiosRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyRadiosRegPath to $DenyRadiosRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyRadiosRegPath -Destination $DenyRadiosRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyRadiosRegPath to $DenyRadiosRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyRadiosRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyRadiosRegPath.`r`n")
}
if (Test-Path $DenyRadiosRegPathD) {
$DenyRadiosRegPathBackupD = "$($DenyRadiosRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyRadiosRegPathD to $DenyRadiosRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyRadiosRegPathD -Destination $DenyRadiosRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyRadiosRegPathD to $DenyRadiosRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyRadiosRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyRadiosRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyRadiosCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyRadiosRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyRadiosRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyRadiosCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Tasks Access CheckBox ===#
if ($WPFDenyTasksAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Tasks Access #`r`n")
if (Test-Path $DenyTasksAccessRegPath) {
$DenyTasksAccessRegPathBackup = "$($DenyTasksAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyTasksAccessRegPath to $DenyTasksAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyTasksAccessRegPath -Destination $DenyTasksAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyTasksAccessRegPath to $DenyTasksAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyTasksAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyTasksAccessRegPath.`r`n")
}
if (Test-Path $DenyTasksAccessRegPathD) {
$DenyTasksAccessRegPathBackupD = "$($DenyTasksAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyTasksAccessRegPathD to $DenyTasksAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyTasksAccessRegPathD -Destination $DenyTasksAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyTasksAccessRegPathD to $DenyTasksAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyTasksAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyTasksAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyTasksAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyTasksAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyTasksAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyTasksAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny User Account Information Access CheckBox ===#
if ($WPFDenyUserAccountInformationAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny User Account Information Access #`r`n")
if (Test-Path $DenyUserAccountInformationAccessRegPath) {
$DenyUserAccountInformationAccessRegPathBackup = "$($DenyUserAccountInformationAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyUserAccountInformationAccessRegPath to $DenyUserAccountInformationAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyUserAccountInformationAccessRegPath -Destination $DenyUserAccountInformationAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyUserAccountInformationAccessRegPath to $DenyUserAccountInformationAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyUserAccountInformationAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyUserAccountInformationAccessRegPath.`r`n")
}
if (Test-Path $DenyUserAccountInformationAccessRegPathD) {
$DenyUserAccountInformationAccessRegPathBackupD = "$($DenyUserAccountInformationAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyUserAccountInformationAccessRegPathD to $DenyUserAccountInformationAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyUserAccountInformationAccessRegPathD -Destination $DenyUserAccountInformationAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyUserAccountInformationAccessRegPathD to $DenyUserAccountInformationAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyUserAccountInformationAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyUserAccountInformationAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyUserAccountInformationAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyUserAccountInformationAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyUserAccountInformationAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyUserAccountInformationAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Videos Library Access CheckBox ===#
if ($WPFDenyVideosLibraryAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Videos Library Access #`r`n")
if (Test-Path $DenyVideosLibraryAccessRegPath) {
$DenyVideosLibraryAccessRegPathBackup = "$($DenyVideosLibraryAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyVideosLibraryAccessRegPath to $DenyVideosLibraryAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyVideosLibraryAccessRegPath -Destination $DenyVideosLibraryAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyVideosLibraryAccessRegPath to $DenyVideosLibraryAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyVideosLibraryAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyVideosLibraryAccessRegPath.`r`n")
}
if (Test-Path $DenyVideosLibraryAccessRegPathD) {
$DenyVideosLibraryAccessRegPathBackupD = "$($DenyVideosLibraryAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyVideosLibraryAccessRegPathD to $DenyVideosLibraryAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyVideosLibraryAccessRegPathD -Destination $DenyVideosLibraryAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyVideosLibraryAccessRegPathD to $DenyVideosLibraryAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyVideosLibraryAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyVideosLibraryAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyVideosLibraryAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyVideosLibraryAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyVideosLibraryAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyVideosLibraryAccessCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Webcam Access CheckBox ===#
if ($WPFDenyWebcamAccessCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Webcam Access #`r`n")
if (Test-Path $DenyWebcamAccessRegPath) {
$DenyWebcamAccessRegPathBackup = "$($DenyWebcamAccessRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyWebcamAccessRegPath to $DenyWebcamAccessRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyWebcamAccessRegPath -Destination $DenyWebcamAccessRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyWebcamAccessRegPath to $DenyWebcamAccessRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyWebcamAccessRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyWebcamAccessRegPath.`r`n")
}
if (Test-Path $DenyWebcamAccessRegPathD) {
$DenyWebcamAccessRegPathBackupD = "$($DenyWebcamAccessRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyWebcamAccessRegPathD to $DenyWebcamAccessRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyWebcamAccessRegPathD -Destination $DenyWebcamAccessRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyWebcamAccessRegPathD to $DenyWebcamAccessRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyWebcamAccessRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyWebcamAccessRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyWebcamAccessCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyWebcamAccessRegPath -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DenyWebcamAccessRegPathD -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyWebcamAccessCheckBox.Content) setting has been applied.`r`n")
}

############################# Suggestions, Ads, Tips, etc #############################

#=== Disable Start Menu Suggestions CheckBox ===#
if ($WPFDisableStartMenuSuggestionsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Start Menu Suggestions #`r`n")
if (Test-Path $DisableStartMenuSuggestionsRegPath) {
$DisableStartMenuSuggestionsRegPathBackup = "$($DisableStartMenuSuggestionsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableStartMenuSuggestionsRegPath to $DisableStartMenuSuggestionsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableStartMenuSuggestionsRegPath -Destination $DisableStartMenuSuggestionsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableStartMenuSuggestionsRegPath to $DisableStartMenuSuggestionsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableStartMenuSuggestionsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableStartMenuSuggestionsRegPath.`r`n")
}
if (Test-Path $DisableStartMenuSuggestionsRegPathD) {
$DisableStartMenuSuggestionsRegPathBackupD = "$($DisableStartMenuSuggestionsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableStartMenuSuggestionsRegPathD to $DisableStartMenuSuggestionsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableStartMenuSuggestionsRegPathD -Destination $DisableStartMenuSuggestionsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableStartMenuSuggestionsRegPathD to $DisableStartMenuSuggestionsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableStartMenuSuggestionsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableStartMenuSuggestionsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableStartMenuSuggestionsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableStartMenuSuggestionsRegPath -Name "SystemPaneSuggestionsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableStartMenuSuggestionsRegPathD -Name "SystemPaneSuggestionsEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SystemPaneSuggestionsEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableStartMenuSuggestionsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Suggested Content in Settings CheckBox ===#
if ($WPFDisableSuggestedContentInSettingsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Suggested Content in Settings #`r`n")
if (Test-Path $DisableSuggestedContentInSettingsRegPath) {
$DisableSuggestedContentInSettingsRegPathBackup = "$($DisableSuggestedContentInSettingsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableSuggestedContentInSettingsRegPath to $DisableSuggestedContentInSettingsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableSuggestedContentInSettingsRegPath -Destination $DisableSuggestedContentInSettingsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableSuggestedContentInSettingsRegPath to $DisableSuggestedContentInSettingsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableSuggestedContentInSettingsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableSuggestedContentInSettingsRegPath.`r`n")
}
if (Test-Path $DisableSuggestedContentInSettingsRegPathD) {
$DisableSuggestedContentInSettingsRegPathBackupD = "$($DisableSuggestedContentInSettingsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableSuggestedContentInSettingsRegPathD to $DisableSuggestedContentInSettingsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableSuggestedContentInSettingsRegPathD -Destination $DisableSuggestedContentInSettingsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableSuggestedContentInSettingsRegPathD to $DisableSuggestedContentInSettingsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableSuggestedContentInSettingsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableSuggestedContentInSettingsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableSuggestedContentInSettingsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableSuggestedContentInSettingsRegPath -Name "SubscribedContent-338393Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableSuggestedContentInSettingsRegPathD -Name "SubscribedContent-338393Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableSuggestedContentInSettingsRegPath -Name "SubscribedContent-353694Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableSuggestedContentInSettingsRegPathD -Name "SubscribedContent-353694Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-338393Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-353694Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableSuggestedContentInSettingsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Occasional Suggestions CheckBox ===#
if ($WPFDisableOccasionalSuggestionsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Occasional Suggestions #`r`n")
if (Test-Path $DisableOccasionalSuggestionsRegPath) {
$DisableOccasionalSuggestionsRegPathBackup = "$($DisableOccasionalSuggestionsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOccasionalSuggestionsRegPath to $DisableOccasionalSuggestionsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableOccasionalSuggestionsRegPath -Destination $DisableOccasionalSuggestionsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOccasionalSuggestionsRegPath to $DisableOccasionalSuggestionsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableOccasionalSuggestionsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOccasionalSuggestionsRegPath.`r`n")
}
if (Test-Path $DisableOccasionalSuggestionsRegPathD) {
$DisableOccasionalSuggestionsRegPathBackupD = "$($DisableOccasionalSuggestionsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOccasionalSuggestionsRegPathD to $DisableOccasionalSuggestionsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableOccasionalSuggestionsRegPathD -Destination $DisableOccasionalSuggestionsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOccasionalSuggestionsRegPathD to $DisableOccasionalSuggestionsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableOccasionalSuggestionsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOccasionalSuggestionsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableOccasionalSuggestionsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableOccasionalSuggestionsRegPath -Name "SubscribedContent-338388Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableOccasionalSuggestionsRegPathD -Name "SubscribedContent-338388Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-338388Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableOccasionalSuggestionsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Suggestions in Timeline CheckBox ===#
if ($WPFDisableSuggestionsInTimelineCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Suggestions in Timeline #`r`n")
if (Test-Path $DisableSuggestionsInTimelineRegPath) {
$DisableSuggestionsInTimelineRegPathBackup = "$($DisableSuggestionsInTimelineRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableSuggestionsInTimelineRegPath to $DisableSuggestionsInTimelineRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableSuggestionsInTimelineRegPath -Destination $DisableSuggestionsInTimelineRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableSuggestionsInTimelineRegPath to $DisableSuggestionsInTimelineRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableSuggestionsInTimelineRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableSuggestionsInTimelineRegPath.`r`n")
}
if (Test-Path $DisableSuggestionsInTimelineRegPathD) {
$DisableSuggestionsInTimelineRegPathBackupD = "$($DisableSuggestionsInTimelineRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableSuggestionsInTimelineRegPathD to $DisableSuggestionsInTimelineRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableSuggestionsInTimelineRegPathD -Destination $DisableSuggestionsInTimelineRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableSuggestionsInTimelineRegPathD to $DisableSuggestionsInTimelineRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableSuggestionsInTimelineRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableSuggestionsInTimelineRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableSuggestionsInTimelineCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableSuggestionsInTimelineRegPath -Name "SubscribedContent-353698Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableSuggestionsInTimelineRegPathD -Name "SubscribedContent-353698Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-353698Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableSuggestionsInTimelineCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Lockscreen Suggestions and Rotating Pictures CheckBox ===#
if ($WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Lockscreen Suggestions and Rotating Pictures #`r`n")
if (Test-Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath) {
$DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackup = "$($DisableLockscreenSuggestionsAndRotatingPicturesRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableLockscreenSuggestionsAndRotatingPicturesRegPath to $DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Destination $DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableLockscreenSuggestionsAndRotatingPicturesRegPath to $DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableLockscreenSuggestionsAndRotatingPicturesRegPath.`r`n")
}
if (Test-Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD) {
$DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackupD = "$($DisableLockscreenSuggestionsAndRotatingPicturesRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD to $DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Destination $DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD to $DisableLockscreenSuggestionsAndRotatingPicturesRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Name "SoftLandingEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Name "SoftLandingEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Name "RotatingLockScreenEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Name "RotatingLockScreenEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPath -Name "RotatingLockScreenOverlayEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableLockscreenSuggestionsAndRotatingPicturesRegPathD -Name "RotatingLockScreenOverlayEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SoftLandingEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'RotatingLockScreenEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'RotatingLockScreenOverlayEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableLockscreenSuggestionsAndRotatingPicturesCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Tips, Tricks, and Suggestions CheckBox ===#
if ($WPFDisableTipsTricksSuggestionsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Tips, Tricks, and Suggestions #`r`n")
if (Test-Path $DisableTipsTricksSuggestionsRegPath) {
$DisableTipsTricksSuggestionsRegPathBackup = "$($DisableTipsTricksSuggestionsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTipsTricksSuggestionsRegPath to $DisableTipsTricksSuggestionsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableTipsTricksSuggestionsRegPath -Destination $DisableTipsTricksSuggestionsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTipsTricksSuggestionsRegPath to $DisableTipsTricksSuggestionsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableTipsTricksSuggestionsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTipsTricksSuggestionsRegPath.`r`n")
}
if (Test-Path $DisableTipsTricksSuggestionsRegPathD) {
$DisableTipsTricksSuggestionsRegPathBackupD = "$($DisableTipsTricksSuggestionsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTipsTricksSuggestionsRegPathD to $DisableTipsTricksSuggestionsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableTipsTricksSuggestionsRegPathD -Destination $DisableTipsTricksSuggestionsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTipsTricksSuggestionsRegPathD to $DisableTipsTricksSuggestionsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableTipsTricksSuggestionsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTipsTricksSuggestionsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableTipsTricksSuggestionsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableTipsTricksSuggestionsRegPath -Name "SubscribedContent-338389Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableTipsTricksSuggestionsRegPathD -Name "SubscribedContent-338389Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-338389Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableTipsTricksSuggestionsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Ads in File Explorer CheckBox ===#
if ($WPFDisableAdsInFileExplorerCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Ads in File Explorer #`r`n")
if (Test-Path $DisableAdsInFileExplorerRegPath) {
$DisableAdsInFileExplorerRegPathBackup = "$($DisableAdsInFileExplorerRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAdsInFileExplorerRegPath to $DisableAdsInFileExplorerRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableAdsInFileExplorerRegPath -Destination $DisableAdsInFileExplorerRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAdsInFileExplorerRegPath to $DisableAdsInFileExplorerRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableAdsInFileExplorerRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAdsInFileExplorerRegPath.`r`n")
}
if (Test-Path $DisableAdsInFileExplorerRegPathD) {
$DisableAdsInFileExplorerRegPathBackupD = "$($DisableAdsInFileExplorerRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAdsInFileExplorerRegPathD to $DisableAdsInFileExplorerRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableAdsInFileExplorerRegPathD -Destination $DisableAdsInFileExplorerRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAdsInFileExplorerRegPathD to $DisableAdsInFileExplorerRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableAdsInFileExplorerRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAdsInFileExplorerRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAdsInFileExplorerCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableAdsInFileExplorerRegPath -Name "ShowSyncProviderNotifications" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableAdsInFileExplorerRegPathD -Name "ShowSyncProviderNotifications" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'ShowSyncProviderNotifications' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAdsInFileExplorerCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Advertising Info & Device Metadata Collection CheckBox ===#
if ($WPFDisableAdInfoDeviceMetaCollectionCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Advertising Info & Device Metadata Collection #`r`n")
if (Test-Path $DisableAdInfoDeviceMetaCollectionRegPath1) {
$DisableAdInfoDeviceMetaCollectionRegPath1Backup = "$($DisableAdInfoDeviceMetaCollectionRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAdInfoDeviceMetaCollectionRegPath1 to $DisableAdInfoDeviceMetaCollectionRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableAdInfoDeviceMetaCollectionRegPath1 -Destination $DisableAdInfoDeviceMetaCollectionRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAdInfoDeviceMetaCollectionRegPath1 to $DisableAdInfoDeviceMetaCollectionRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableAdInfoDeviceMetaCollectionRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAdInfoDeviceMetaCollectionRegPath1.`r`n")
}
if (Test-Path $DisableAdInfoDeviceMetaCollectionRegPath2) {
$DisableAdInfoDeviceMetaCollectionRegPath2Backup = "$($DisableAdInfoDeviceMetaCollectionRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAdInfoDeviceMetaCollectionRegPath2 to $DisableAdInfoDeviceMetaCollectionRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableAdInfoDeviceMetaCollectionRegPath2 -Destination $DisableAdInfoDeviceMetaCollectionRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAdInfoDeviceMetaCollectionRegPath2 to $DisableAdInfoDeviceMetaCollectionRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableAdInfoDeviceMetaCollectionRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAdInfoDeviceMetaCollectionRegPath2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAdInfoDeviceMetaCollectionCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableAdInfoDeviceMetaCollectionRegPath1 -Name "Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableAdInfoDeviceMetaCollectionRegPath2 -Name "PreventDeviceMetadataFromNetwork" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Enabled' to '0' at '$DisableAdInfoDeviceMetaCollectionRegPath1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'PreventDeviceMetadataFromNetwork' to '1' at '$DisableAdInfoDeviceMetaCollectionRegPath2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAdInfoDeviceMetaCollectionCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Pre-release Features & Settings CheckBox ===#
if ($WPFDisablePreReleaseFeaturesSettingsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Pre-release Features & Settings #`r`n")
if (Test-Path $DisablePreReleaseFeaturesSettingsRegPath) {
$DisablePreReleaseFeaturesSettingsRegPathBackup = "$($DisablePreReleaseFeaturesSettingsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisablePreReleaseFeaturesSettingsRegPath to $DisablePreReleaseFeaturesSettingsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisablePreReleaseFeaturesSettingsRegPath -Destination $DisablePreReleaseFeaturesSettingsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisablePreReleaseFeaturesSettingsRegPath to $DisablePreReleaseFeaturesSettingsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisablePreReleaseFeaturesSettingsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisablePreReleaseFeaturesSettingsRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisablePreReleaseFeaturesSettingsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisablePreReleaseFeaturesSettingsRegPath -Name "EnableConfigFlighting" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'EnableConfigFlighting' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisablePreReleaseFeaturesSettingsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Feedback Notifications CheckBox ===#
if ($WPFDisableFeedbackNotificationsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Feedback Notifications #`r`n")
if (Test-Path $DisableFeedbackNotificationsRegPath) {
$DisableFeedbackNotificationsRegPathBackup = "$($DisableFeedbackNotificationsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableFeedbackNotificationsRegPath to $DisableFeedbackNotificationsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableFeedbackNotificationsRegPath -Destination $DisableFeedbackNotificationsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableFeedbackNotificationsRegPath to $DisableFeedbackNotificationsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableFeedbackNotificationsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableFeedbackNotificationsRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableFeedbackNotificationsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableFeedbackNotificationsRegPath -Name "DoNotShowFeedbackNotifications" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DoNotShowFeedbackNotifications' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableFeedbackNotificationsCheckBox.Content) setting has been applied.`r`n")
}

############################# People ##################################################

#=== Disable My People Notifications CheckBox ===#
if ($WPFDisableMyPeopleNotificationsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable My People Notifications #`r`n")
if (Test-Path $DisableMyPeopleNotificationsRegPath1) {
$DisableMyPeopleNotificationsRegPath1Backup = "$($DisableMyPeopleNotificationsRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMyPeopleNotificationsRegPath1 to $DisableMyPeopleNotificationsRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableMyPeopleNotificationsRegPath1 -Destination $DisableMyPeopleNotificationsRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMyPeopleNotificationsRegPath1 to $DisableMyPeopleNotificationsRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableMyPeopleNotificationsRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMyPeopleNotificationsRegPath1.`r`n")
}
if (Test-Path $DisableMyPeopleNotificationsRegPathD1) {
$DisableMyPeopleNotificationsRegPathBackupD = "$($DisableMyPeopleNotificationsRegPathD1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMyPeopleNotificationsRegPathD1 to $DisableMyPeopleNotificationsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableMyPeopleNotificationsRegPathD1 -Destination $DisableMyPeopleNotificationsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMyPeopleNotificationsRegPathD1 to $DisableMyPeopleNotificationsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableMyPeopleNotificationsRegPathD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMyPeopleNotificationsRegPathD1.`r`n")
}
if (Test-Path $DisableMyPeopleNotificationsRegPath2) {
$DisableMyPeopleNotificationsRegPath2Backup = "$($DisableMyPeopleNotificationsRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMyPeopleNotificationsRegPath2 to $DisableMyPeopleNotificationsRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableMyPeopleNotificationsRegPath2 -Destination $DisableMyPeopleNotificationsRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMyPeopleNotificationsRegPath2 to $DisableMyPeopleNotificationsRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableMyPeopleNotificationsRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMyPeopleNotificationsRegPath2.`r`n")
}
if (Test-Path $DisableMyPeopleNotificationsRegPathD2) {
$DisableMyPeopleNotificationsRegPathBackupD = "$($DisableMyPeopleNotificationsRegPathD2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMyPeopleNotificationsRegPathD2 to $DisableMyPeopleNotificationsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableMyPeopleNotificationsRegPathD2 -Destination $DisableMyPeopleNotificationsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMyPeopleNotificationsRegPathD2 to $DisableMyPeopleNotificationsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableMyPeopleNotificationsRegPathD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMyPeopleNotificationsRegPathD2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableMyPeopleNotificationsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableMyPeopleNotificationsRegPath2 -Name "ShoulderTap" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableMyPeopleNotificationsRegPathD2 -Name "ShoulderTap" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'ShoulderTap' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableMyPeopleNotificationsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable My People Suggestions CheckBox ===#
if ($WPFDisableMyPeopleSuggestionsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable My People Suggestions #`r`n")
if (Test-Path $DisableMyPeopleSuggestionsRegPath) {
$DisableMyPeopleSuggestionsRegPathBackup = "$($DisableMyPeopleSuggestionsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMyPeopleSuggestionsRegPath to $DisableMyPeopleSuggestionsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableMyPeopleSuggestionsRegPath -Destination $DisableMyPeopleSuggestionsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMyPeopleSuggestionsRegPath to $DisableMyPeopleSuggestionsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableMyPeopleSuggestionsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMyPeopleSuggestionsRegPath.`r`n")
}
if (Test-Path $DisableMyPeopleSuggestionsRegPathD) {
$DisableMyPeopleSuggestionsRegPathBackupD = "$($DisableMyPeopleSuggestionsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMyPeopleSuggestionsRegPathD to $DisableMyPeopleSuggestionsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableMyPeopleSuggestionsRegPathD -Destination $DisableMyPeopleSuggestionsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMyPeopleSuggestionsRegPathD to $DisableMyPeopleSuggestionsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableMyPeopleSuggestionsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMyPeopleSuggestionsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableMyPeopleSuggestionsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableMyPeopleSuggestionsRegPath -Name "SubscribedContent-314563Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableMyPeopleSuggestionsRegPathD -Name "SubscribedContent-314563Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-314563Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableMyPeopleSuggestionsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable People on Taskbar CheckBox ===#
if ($WPFDisablePeopleOnTaskbarCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable People on Taskbar #`r`n")
if (Test-Path $DisablePeopleOnTaskbarRegPath) {
$DisablePeopleOnTaskbarRegPathBackup = "$($DisablePeopleOnTaskbarRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisablePeopleOnTaskbarRegPath to $DisablePeopleOnTaskbarRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisablePeopleOnTaskbarRegPath -Destination $DisablePeopleOnTaskbarRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisablePeopleOnTaskbarRegPath to $DisablePeopleOnTaskbarRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisablePeopleOnTaskbarRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisablePeopleOnTaskbarRegPath.`r`n")
}
if (Test-Path $DisablePeopleOnTaskbarRegPathD) {
$DisablePeopleOnTaskbarRegPathBackupD = "$($DisablePeopleOnTaskbarRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisablePeopleOnTaskbarRegPathD to $DisablePeopleOnTaskbarRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisablePeopleOnTaskbarRegPathD -Destination $DisablePeopleOnTaskbarRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisablePeopleOnTaskbarRegPathD to $DisablePeopleOnTaskbarRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisablePeopleOnTaskbarRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisablePeopleOnTaskbarRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisablePeopleOnTaskbarCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisablePeopleOnTaskbarRegPath -Name "PeopleBand" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisablePeopleOnTaskbarRegPathD -Name "PeopleBand" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'PeopleBand' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisablePeopleOnTaskbarCheckBox.Content) setting has been applied.`r`n")
}

############################# OneDrive ################################################

#=== Prevent Usage of OneDrive CheckBox ===#
if ($WPFPreventUsageOfOneDriveCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Prevent Usage of OneDrive #`r`n")
if (Test-Path $PreventUsageOfOneDriveRegPath) {
$PreventUsageOfOneDriveRegPathBackup = "$($PreventUsageOfOneDriveRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $PreventUsageOfOneDriveRegPath to $PreventUsageOfOneDriveRegPathBackup.`r`n")
[Void](Copy-Item -Path $PreventUsageOfOneDriveRegPath -Destination $PreventUsageOfOneDriveRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $PreventUsageOfOneDriveRegPath to $PreventUsageOfOneDriveRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $PreventUsageOfOneDriveRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $PreventUsageOfOneDriveRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFPreventUsageOfOneDriveCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $PreventUsageOfOneDriveRegPath -Name "DisableFileSync" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $PreventUsageOfOneDriveRegPath -Name "DisableFileSyncNGSC" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableFileSync' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableFileSyncNGSC' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFPreventUsageOfOneDriveCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Automatic OneDrive Setup CheckBox ===#
if ($WPFDisableAutomaticOneDriveSetupCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Automatic OneDrive Setup #`r`n")
if (Test-Path $DisableAutomaticOneDriveSetupRegPath) {
$DisableAutomaticOneDriveSetupRegPathBackup = "$($DisableAutomaticOneDriveSetupRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutomaticOneDriveSetupRegPath to $DisableAutomaticOneDriveSetupRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableAutomaticOneDriveSetupRegPath -Destination $DisableAutomaticOneDriveSetupRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutomaticOneDriveSetupRegPath to $DisableAutomaticOneDriveSetupRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableAutomaticOneDriveSetupRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutomaticOneDriveSetupRegPath.`r`n")
}
if (Get-ItemProperty -Path $DisableAutomaticOneDriveSetupRegPath -Name "OneDriveSetup" -ErrorAction SilentlyContinue) {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAutomaticOneDriveSetupCheckBox.Content)`r`n")
[Void](Remove-ItemProperty -Path $DisableAutomaticOneDriveSetupRegPath -Name "OneDriveSetup" -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DELETED REG VALUE: 'OneDriveSetup'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAutomaticOneDriveSetupCheckBox.Content) setting has been applied.`r`n")
} else {
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) 'Disable Automatic OneDrive Setup' seems to already be disabled. Skipping.`r`n")
}
}

#=== Disable OneDrive Startup Run CheckBox ===#
if ($WPFDisableOneDriveStartupRunCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable OneDrive Startup Run #`r`n")
if (Test-Path $DisableOneDriveStartupRunRegPath1) {
$DisableOneDriveStartupRunRegPath1Backup = "$($DisableOneDriveStartupRunRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOneDriveStartupRunRegPath1 to $DisableOneDriveStartupRunRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableOneDriveStartupRunRegPath1 -Destination $DisableOneDriveStartupRunRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOneDriveStartupRunRegPath1 to $DisableOneDriveStartupRunRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableOneDriveStartupRunRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOneDriveStartupRunRegPath1.`r`n")
}
if (Test-Path $DisableOneDriveStartupRunRegPathD1) {
$DisableOneDriveStartupRunRegPathBackupD2 = "$($DisableOneDriveStartupRunRegPathD1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOneDriveStartupRunRegPathD1 to $DisableOneDriveStartupRunRegPathBackupD2.`r`n")
[Void](Copy-Item -Path $DisableOneDriveStartupRunRegPathD1 -Destination $DisableOneDriveStartupRunRegPathBackupD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOneDriveStartupRunRegPathD1 to $DisableOneDriveStartupRunRegPathBackupD2.`r`n")
} else {
[Void](New-Item -Path $DisableOneDriveStartupRunRegPathD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOneDriveStartupRunRegPathD1.`r`n")
}
if (Test-Path $DisableOneDriveStartupRunRegPath2) {
$DisableOneDriveStartupRunRegPath2Backup = "$($DisableOneDriveStartupRunRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOneDriveStartupRunRegPath2 to $DisableOneDriveStartupRunRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableOneDriveStartupRunRegPath2 -Destination $DisableOneDriveStartupRunRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOneDriveStartupRunRegPath2 to $DisableOneDriveStartupRunRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableOneDriveStartupRunRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOneDriveStartupRunRegPath2.`r`n")
}
if (Test-Path $DisableOneDriveStartupRunRegPathD2) {
$DisableOneDriveStartupRunRegPathBackupD2 = "$($DisableOneDriveStartupRunRegPathD2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOneDriveStartupRunRegPathD2 to $DisableOneDriveStartupRunRegPathBackupD2.`r`n")
[Void](Copy-Item -Path $DisableOneDriveStartupRunRegPathD2 -Destination $DisableOneDriveStartupRunRegPathBackupD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOneDriveStartupRunRegPathD2 to $DisableOneDriveStartupRunRegPathBackupD2.`r`n")
} else {
[Void](New-Item -Path $DisableOneDriveStartupRunRegPathD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOneDriveStartupRunRegPathD2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableOneDriveStartupRunCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableOneDriveStartupRunRegPath2 -Name "OneDrive" -Value ([byte[]]$InputHexified) -PropertyType Binary -Force)
[Void](New-ItemProperty -Path $DisableOneDriveStartupRunRegPathD2 -Name "OneDrive" -Value ([byte[]]$InputHexified) -PropertyType Binary -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'OneDrive' to '$BinaryInput'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableOneDriveStartupRunCheckBox.Content) setting has been applied.`r`n")
}

#=== Remove OneDrive from File Explorer CheckBox ===#
if ($WPFRemoveOneDriveFromFileExplorerCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Remove OneDrive from File Explorer #`r`n")
if (Test-Path $RemoveOneDriveFromFileExplorerRegPath1) {
# below commented out until Win10crAPPRemover v2.0 wtih multi-threading enabled
#$RemoveOneDriveFromFileExplorerRegPath1Backup = "$($RemoveOneDriveFromFileExplorerRegPath1).BACKUP"
#$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $RemoveOneDriveFromFileExplorerRegPath1 to $RemoveOneDriveFromFileExplorerRegPath1Backup.`r`n")
#[Void](Copy-Item -Path $RemoveOneDriveFromFileExplorerRegPath1 -Destination $RemoveOneDriveFromFileExplorerRegPath1Backup)
#$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $RemoveOneDriveFromFileExplorerRegPath1 to $RemoveOneDriveFromFileExplorerRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $RemoveOneDriveFromFileExplorerRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $RemoveOneDriveFromFileExplorerRegPath1.`r`n")
}
if (Test-Path $RemoveOneDriveFromFileExplorerRegPath2) {
# below commented out until Win10crAPPRemover v2.0 wtih multi-threading enabled
#$RemoveOneDriveFromFileExplorerRegPath2Backup = "$($RemoveOneDriveFromFileExplorerRegPath2).BACKUP"
#$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $RemoveOneDriveFromFileExplorerRegPath2 to $RemoveOneDriveFromFileExplorerRegPath2Backup.`r`n")
#[Void](Copy-Item -Path $RemoveOneDriveFromFileExplorerRegPath2 -Destination $RemoveOneDriveFromFileExplorerRegPath2Backup)
#$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $RemoveOneDriveFromFileExplorerRegPath2 to $RemoveOneDriveFromFileExplorerRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $RemoveOneDriveFromFileExplorerRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $RemoveOneDriveFromFileExplorerRegPath2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFRemoveOneDriveFromFileExplorerCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $RemoveOneDriveFromFileExplorerRegPath1 -Name "System.IsPinnedToNameSpaceTree" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $RemoveOneDriveFromFileExplorerRegPath2 -Name "System.IsPinnedToNameSpaceTree" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'System.IsPinnedToNameSpaceTree' to '0' at '$RemoveOneDriveFromFileExplorerRegPath1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'System.IsPinnedToNameSpaceTree' to '0' at '$RemoveOneDriveFromFileExplorerRegPath2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFRemoveOneDriveFromFileExplorerCheckBox.Content) setting has been applied.`r`n")
}

############################# Games ###################################################

#=== Disable GameDVR CheckBox ===#
if ($WPFDisableGameDVRCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable GameDVR #`r`n")
if (Test-Path $DisableGameDVRRegPath) {
$DisableGameDVRRegPathBackup = "$($DisableGameDVRRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableGameDVRRegPath to $DisableGameDVRRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableGameDVRRegPath -Destination $DisableGameDVRRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableGameDVRRegPath to $DisableGameDVRRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableGameDVRRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableGameDVRRegPath.`r`n")
}
if (Test-Path $DisableGameDVRRegPathD) {
$DisableGameDVRRegPathBackupD = "$($DisableGameDVRRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableGameDVRRegPathD to $DisableGameDVRRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableGameDVRRegPathD -Destination $DisableGameDVRRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableGameDVRRegPathD to $DisableGameDVRRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableGameDVRRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableGameDVRRegPathD.`r`n")
}
if (Test-Path $DisableGameDVRRegPath2) {
$DisableGameDVRRegPathBackupD = "$($DisableGameDVRRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableGameDVRRegPath2 to $DisableGameDVRRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableGameDVRRegPath2 -Destination $DisableGameDVRRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableGameDVRRegPath2 to $DisableGameDVRRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableGameDVRRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableGameDVRRegPath2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableGameDVRCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableGameDVRRegPath -Name "GameDVR_Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableGameDVRRegPathD -Name "GameDVR_Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableGameDVRRegPath2 -Name "AllowGameDVR" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'GameDVR_Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AllowGameDVR' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableGameDVRCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Preinstalled Apps CheckBox ===#
if ($WPFDisablePreinstalledAppsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Preinstalled Apps #`r`n")
if (Test-Path $DisablePreinstalledAppsRegPath) {
$DisablePreinstalledAppsRegPathBackup = "$($DisablePreinstalledAppsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisablePreinstalledAppsRegPath to $DisablePreinstalledAppsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisablePreinstalledAppsRegPath -Destination $DisablePreinstalledAppsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisablePreinstalledAppsRegPath to $DisablePreinstalledAppsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisablePreinstalledAppsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisablePreinstalledAppsRegPath.`r`n")
}
if (Test-Path $DisablePreinstalledAppsRegPathD) {
$DisablePreinstalledAppsRegPathBackupD = "$($DisablePreinstalledAppsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisablePreinstalledAppsRegPathD to $DisablePreinstalledAppsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisablePreinstalledAppsRegPathD -Destination $DisablePreinstalledAppsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisablePreinstalledAppsRegPathD to $DisablePreinstalledAppsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisablePreinstalledAppsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisablePreinstalledAppsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisablePreinstalledAppsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisablePreinstalledAppsRegPath -Name "PreInstalledAppsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisablePreinstalledAppsRegPathD -Name "PreInstalledAppsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisablePreinstalledAppsRegPath -Name "PreInstalledAppsEverEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisablePreinstalledAppsRegPathD -Name "PreInstalledAppsEverEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisablePreinstalledAppsRegPath -Name "OEMPreInstalledAppsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisablePreinstalledAppsRegPathD -Name "OEMPreInstalledAppsEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'PreInstalledAppsEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'PreInstalledAppsEverEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'OEMPreInstalledAppsEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisablePreinstalledAppsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Xbox Game Monitoring Service CheckBox ===#
if ($WPFDisableXboxGameMonitoringServiceCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Xbox Game Monitoring Service #`r`n")
if (Test-Path $DisableXboxGameMonitoringServiceRegPath) {
$DisableXboxGameMonitoringServiceRegPathBackup = "$($DisableXboxGameMonitoringServiceRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableXboxGameMonitoringServiceRegPath to $DisableXboxGameMonitoringServiceRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableXboxGameMonitoringServiceRegPath -Destination $DisableXboxGameMonitoringServiceRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableXboxGameMonitoringServiceRegPath to $DisableXboxGameMonitoringServiceRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableXboxGameMonitoringServiceRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableXboxGameMonitoringServiceRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableXboxGameMonitoringServiceCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableXboxGameMonitoringServiceRegPath -Name "Start" -Value "4" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Start' to '4'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableXboxGameMonitoringServiceCheckBox.Content) setting has been applied.`r`n")
}

############################# Cloud ###################################################

#=== Disable Windows Tips CheckBox ===#
if ($WPFDisableWindowsTipsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Windows Tips #`r`n")
if (Test-Path $DisableWindowsTipsRegPath) {
$DisableWindowsTipsRegPathBackup = "$($DisableWindowsTipsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableWindowsTipsRegPath to $DisableWindowsTipsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableWindowsTipsRegPath -Destination $DisableWindowsTipsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableWindowsTipsRegPath to $DisableWindowsTipsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableWindowsTipsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableWindowsTipsRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableWindowsTipsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableWindowsTipsRegPath -Name "DisableSoftLanding" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableSoftLanding' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableWindowsTipsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Consumer Experiences CheckBox ===#
if ($WPFDisableConsumerExperiencesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Consumer Experiences Tips #`r`n")
if (Test-Path $DisableConsumerExperiencesRegPath) {
$DisableConsumerExperiencesRegPathBackup = "$($DisableConsumerExperiencesRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableConsumerExperiencesRegPath to $DisableConsumerExperiencesRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableConsumerExperiencesRegPath -Destination $DisableConsumerExperiencesRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableConsumerExperiencesRegPath to $DisableConsumerExperiencesRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableConsumerExperiencesRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableConsumerExperiencesRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableConsumerExperiencesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableConsumerExperiencesRegPath -Name "DisableWindowsConsumerFeatures" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableWindowsConsumerFeatures' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableConsumerExperiencesCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable 3rd Party Suggestions CheckBox ===#
if ($WPFDisableThirdPartySuggestionsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable 3rd Party Suggestions #`r`n")
if (Test-Path $DisableThirdPartySuggestionsRegPath) {
$DisableThirdPartySuggestionsRegPathBackup = "$($DisableThirdPartySuggestionsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableThirdPartySuggestionsRegPath to $DisableThirdPartySuggestionsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableThirdPartySuggestionsRegPath -Destination $DisableThirdPartySuggestionsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableThirdPartySuggestionsRegPath to $DisableThirdPartySuggestionsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableThirdPartySuggestionsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableThirdPartySuggestionsRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableThirdPartySuggestionsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableThirdPartySuggestionsRegPath -Name "DisableThirdPartySuggestions" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableThirdPartySuggestions' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableThirdPartySuggestionsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Spotlight Features CheckBox ===#
if ($WPFDisableSpotlightFeaturesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Spotlight Features #`r`n")
if (Test-Path $DisableSpotlightFeaturesRegPath) {
$DisableSpotlightFeaturesRegPathBackup = "$($DisableSpotlightFeaturesRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableSpotlightFeaturesRegPath to $DisableSpotlightFeaturesRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableSpotlightFeaturesRegPath -Destination $DisableSpotlightFeaturesRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableSpotlightFeaturesRegPath to $DisableSpotlightFeaturesRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableSpotlightFeaturesRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableSpotlightFeaturesRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableSpotlightFeaturesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableSpotlightFeaturesRegPath -Name "DisableWindowsSpotlightFeatures" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableWindowsSpotlightFeatures' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableSpotlightFeaturesCheckBox.Content) setting has been applied.`r`n")
}

############################# Windows Update ##########################################

#=== Disable Featured Software Notifications CheckBox ===#
if ($WPFDisableFeaturedSoftwareNotificationsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Featured Software Notifications #`r`n")
if (Test-Path $DisableFeaturedSoftwareNotificationsRegPath1) {
$DisableFeaturedSoftwareNotificationsRegPath1Backup = "$($DisableFeaturedSoftwareNotificationsRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableFeaturedSoftwareNotificationsRegPath1 to $DisableFeaturedSoftwareNotificationsRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableFeaturedSoftwareNotificationsRegPath1 -Destination $DisableFeaturedSoftwareNotificationsRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableFeaturedSoftwareNotificationsRegPath1 to $DisableFeaturedSoftwareNotificationsRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableFeaturedSoftwareNotificationsRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableFeaturedSoftwareNotificationsRegPath1.`r`n")
}
if (Test-Path $DisableFeaturedSoftwareNotificationsRegPath2) {
$DisableFeaturedSoftwareNotificationsRegPath2Backup = "$($DisableFeaturedSoftwareNotificationsRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableFeaturedSoftwareNotificationsRegPath2 to $DisableFeaturedSoftwareNotificationsRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableFeaturedSoftwareNotificationsRegPath2 -Destination $DisableFeaturedSoftwareNotificationsRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableFeaturedSoftwareNotificationsRegPath2 to $DisableFeaturedSoftwareNotificationsRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableFeaturedSoftwareNotificationsRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableFeaturedSoftwareNotificationsRegPath2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableFeaturedSoftwareNotificationsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableFeaturedSoftwareNotificationsRegPath2 -Name "EnableFeaturedSoftware" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'EnableFeaturedSoftware' to '0' at '$DisableFeaturedSoftwareNotificationsRegPath2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableFeaturedSoftwareNotificationsCheckBox.Content) setting has been applied.`r`n")
}

#=== Set Delivery Optimization LAN Only CheckBox ===#
if ($WPFSetDeliveryOptimizationLANOnlyCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Set Delivery Optimization LAN Only #`r`n")
if (Test-Path $SetDeliveryOptimizationLANOnlyRegPath1) {
$SetDeliveryOptimizationLANOnlyRegPath1Backup = "$($SetDeliveryOptimizationLANOnlyRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $SetDeliveryOptimizationLANOnlyRegPath1 to $SetDeliveryOptimizationLANOnlyRegPath1Backup.`r`n")
[Void](Copy-Item -Path $SetDeliveryOptimizationLANOnlyRegPath1 -Destination $SetDeliveryOptimizationLANOnlyRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $SetDeliveryOptimizationLANOnlyRegPath1 to $SetDeliveryOptimizationLANOnlyRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $SetDeliveryOptimizationLANOnlyRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $SetDeliveryOptimizationLANOnlyRegPath1.`r`n")
}
if (Test-Path $SetDeliveryOptimizationLANOnlyRegPath2) {
$SetDeliveryOptimizationLANOnlyRegPath2Backup = "$($SetDeliveryOptimizationLANOnlyRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $SetDeliveryOptimizationLANOnlyRegPath2 to $SetDeliveryOptimizationLANOnlyRegPath2Backup.`r`n")
[Void](Copy-Item -Path $SetDeliveryOptimizationLANOnlyRegPath2 -Destination $SetDeliveryOptimizationLANOnlyRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $SetDeliveryOptimizationLANOnlyRegPath2 to $SetDeliveryOptimizationLANOnlyRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $SetDeliveryOptimizationLANOnlyRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $SetDeliveryOptimizationLANOnlyRegPath2.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFSetDeliveryOptimizationLANOnlyCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $SetDeliveryOptimizationLANOnlyRegPath1 -Name "DownloadMode" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $SetDeliveryOptimizationLANOnlyRegPath1 -Name "DODownloadMode" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $SetDeliveryOptimizationLANOnlyRegPath2 -Name "DownloadMode" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DownloadMode' to '1' at '$SetDeliveryOptimizationLANOnlyRegPath1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DODownloadMode' to '1' at '$SetDeliveryOptimizationLANOnlyRegPath1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DownloadMode' to '1' at '$SetDeliveryOptimizationLANOnlyRegPath2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFSetDeliveryOptimizationLANOnlyCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Automatic Store App Updates CheckBox ===#
if ($WPFDisableAutomaticStoreAppUpdatesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Automatic Store App Updates #`r`n")
if (Test-Path $DisableAutomaticStoreAppUpdatesRegPath1) {
$DisableAutomaticStoreAppUpdatesRegPath1Backup = "$($DisableAutomaticStoreAppUpdatesRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutomaticStoreAppUpdatesRegPath1 to $DisableAutomaticStoreAppUpdatesRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableAutomaticStoreAppUpdatesRegPath1 -Destination $DisableAutomaticStoreAppUpdatesRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutomaticStoreAppUpdatesRegPath1 to $DisableAutomaticStoreAppUpdatesRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableAutomaticStoreAppUpdatesRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutomaticStoreAppUpdatesRegPath1.`r`n")
}
if (Test-Path $DisableAutomaticStoreAppUpdatesRegPath2) {
$DisableAutomaticStoreAppUpdatesRegPath2Backup = "$($DisableAutomaticStoreAppUpdatesRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutomaticStoreAppUpdatesRegPath2 to $DisableAutomaticStoreAppUpdatesRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableAutomaticStoreAppUpdatesRegPath2 -Destination $DisableAutomaticStoreAppUpdatesRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutomaticStoreAppUpdatesRegPath2 to $DisableAutomaticStoreAppUpdatesRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableAutomaticStoreAppUpdatesRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutomaticStoreAppUpdatesRegPath2.`r`n")
}
if (Test-Path $DisableAutomaticStoreAppUpdatesRegPath3) {
$DisableAutomaticStoreAppUpdatesRegPath3Backup = "$($DisableAutomaticStoreAppUpdatesRegPath3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutomaticStoreAppUpdatesRegPath3 to $DisableAutomaticStoreAppUpdatesRegPath3Backup.`r`n")
[Void](Copy-Item -Path $DisableAutomaticStoreAppUpdatesRegPath3 -Destination $DisableAutomaticStoreAppUpdatesRegPath3Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutomaticStoreAppUpdatesRegPath3 to $DisableAutomaticStoreAppUpdatesRegPath3Backup.`r`n")
} else {
[Void](New-Item -Path $DisableAutomaticStoreAppUpdatesRegPath3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutomaticStoreAppUpdatesRegPath3.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAutomaticStoreAppUpdatesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableAutomaticStoreAppUpdatesRegPath3 -Name "AutoDownload" -Value "2" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AutoDownload' to '2' at '$DisableAutomaticStoreAppUpdatesRegPath3'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAutomaticStoreAppUpdatesCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Automatic Login to Update CheckBox ===#
if ($WPFDisableAutoLoginUpdatesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Automatic Login to Update #`r`n")
if (Test-Path $DisableAutoLoginUpdatesRegPath) {
$DisableAutoLoginUpdatesRegPathBackup = "$($DisableAutoLoginUpdatesRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutoLoginUpdatesRegPath to $DisableAutoLoginUpdatesRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableAutoLoginUpdatesRegPath -Destination $DisableAutoLoginUpdatesRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutoLoginUpdatesRegPath to $DisableAutoLoginUpdatesRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableAutoLoginUpdatesRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutoLoginUpdatesRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAutoLoginUpdatesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableAutoLoginUpdatesRegPath -Name "ARSOUserConsent" -Value "2" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'ARSOUserConsent' to '2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAutoLoginUpdatesCheckBox.Content) setting has been applied.`r`n")
}

############################# Other Settings ##########################################

#=== Disable Shoehorning Apps CheckBox ===#
if ($WPFDisableShoehorningAppsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Shoehorning Apps #`r`n")
if (Test-Path $DisableShoehorningAppsRegPath) {
$DisableShoehorningAppsRegPathBackup = "$($DisableShoehorningAppsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableShoehorningAppsRegPath to $DisableShoehorningAppsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableShoehorningAppsRegPath -Destination $DisableShoehorningAppsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableShoehorningAppsRegPath to $DisableShoehorningAppsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableShoehorningAppsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableShoehorningAppsRegPath.`r`n")
}
if (Test-Path $DisableShoehorningAppsRegPathD) {
$DisableShoehorningAppsRegPathBackupD = "$($DisableShoehorningAppsRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableShoehorningAppsRegPathD to $DisableShoehorningAppsRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableShoehorningAppsRegPathD -Destination $DisableShoehorningAppsRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableShoehorningAppsRegPathD to $DisableShoehorningAppsRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableShoehorningAppsRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableShoehorningAppsRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableShoehorningAppsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableShoehorningAppsRegPath -Name "SilentInstalledAppsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableShoehorningAppsRegPathD -Name "SilentInstalledAppsEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableShoehorningAppsRegPath -Name "ContentDeliveryAllowed" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableShoehorningAppsRegPathD -Name "ContentDeliveryAllowed" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableShoehorningAppsRegPath -Name "SubscribedContentEnabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableShoehorningAppsRegPathD -Name "SubscribedContentEnabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SilentInstalledAppsEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'ContentDeliveryAllowed' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContentEnabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableShoehorningAppsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Occasional Welcome Experience CheckBox ===#
if ($WPFDisableOccasionalWelcomeExperienceCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Occasional Welcome Experience #`r`n")
if (Test-Path $DisableOccasionalWelcomeExperienceRegPath) {
$DisableOccasionalWelcomeExperienceRegPathBackup = "$($DisableOccasionalWelcomeExperienceRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOccasionalWelcomeExperienceRegPath to $DisableOccasionalWelcomeExperienceRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableOccasionalWelcomeExperienceRegPath -Destination $DisableOccasionalWelcomeExperienceRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOccasionalWelcomeExperienceRegPath to $DisableOccasionalWelcomeExperienceRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableOccasionalWelcomeExperienceRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOccasionalWelcomeExperienceRegPath.`r`n")
}
if (Test-Path $DisableOccasionalWelcomeExperienceRegPathD) {
$DisableOccasionalWelcomeExperienceRegPathBackupD = "$($DisableOccasionalWelcomeExperienceRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableOccasionalWelcomeExperienceRegPathD to $DisableOccasionalWelcomeExperienceRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableOccasionalWelcomeExperienceRegPathD -Destination $DisableOccasionalWelcomeExperienceRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableOccasionalWelcomeExperienceRegPathD to $DisableOccasionalWelcomeExperienceRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableOccasionalWelcomeExperienceRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableOccasionalWelcomeExperienceRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableOccasionalWelcomeExperienceCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableOccasionalWelcomeExperienceRegPath -Name "SubscribedContent-310093Enabled" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableOccasionalWelcomeExperienceRegPathD -Name "SubscribedContent-310093Enabled" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SubscribedContent-310093Enabled' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableOccasionalWelcomeExperienceCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Autoplay CheckBox ===#
if ($WPFDisableAutoplayCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Autoplay #`r`n")
if (Test-Path $DisableAutoplayRegPath) {
$DisableAutoplayRegPathBackup = "$($DisableAutoplayRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutoplayRegPath to $DisableAutoplayRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableAutoplayRegPath -Destination $DisableAutoplayRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutoplayRegPath to $DisableAutoplayRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableAutoplayRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutoplayRegPath.`r`n")
}
if (Test-Path $DisableAutoplayRegPathD) {
$DisableAutoplayRegPathBackupD = "$($DisableAutoplayRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAutoplayRegPathD to $DisableAutoplayRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableAutoplayRegPathD -Destination $DisableAutoplayRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAutoplayRegPathD to $DisableAutoplayRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableAutoplayRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAutoplayRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAutoplayCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableAutoplayRegPath -Name "DisableAutoplay" -Value "1" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableAutoplayRegPathD -Name "DisableAutoplay" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableAutoplay' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAutoplayCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Taskbar Search CheckBox ===#
if ($WPFDisableTaskbarSearchCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Taskbar Search #`r`n")
if (Test-Path $DisableTaskbarSearchRegPath) {
$DisableTaskbarSearchRegPathBackup = "$($DisableTaskbarSearchRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTaskbarSearchRegPath to $DisableTaskbarSearchRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableTaskbarSearchRegPath -Destination $DisableTaskbarSearchRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTaskbarSearchRegPath to $DisableTaskbarSearchRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableTaskbarSearchRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTaskbarSearchRegPath.`r`n")
}
if (Test-Path $DisableTaskbarSearchRegPathD) {
$DisableTaskbarSearchRegPathBackupD = "$($DisableTaskbarSearchRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTaskbarSearchRegPathD to $DisableTaskbarSearchRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DisableTaskbarSearchRegPathD -Destination $DisableTaskbarSearchRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTaskbarSearchRegPathD to $DisableTaskbarSearchRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DisableTaskbarSearchRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTaskbarSearchRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableTaskbarSearchCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableTaskbarSearchRegPath -Name "SearchboxTaskbarMode" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableTaskbarSearchRegPathD -Name "SearchboxTaskbarMode" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SearchboxTaskbarMode' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableTaskbarSearchCheckBox.Content) setting has been applied.`r`n")
}

#=== Deny Location Use For Searches CheckBox ===#
if ($WPFDenyLocationUseForSearchesCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Deny Location Use For Searches #`r`n")
if (Test-Path $DenyLocationUseForSearchesRegPath) {
$DenyLocationUseForSearchesRegPathBackup = "$($DenyLocationUseForSearchesRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyLocationUseForSearchesRegPath to $DenyLocationUseForSearchesRegPathBackup.`r`n")
[Void](Copy-Item -Path $DenyLocationUseForSearchesRegPath -Destination $DenyLocationUseForSearchesRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyLocationUseForSearchesRegPath to $DenyLocationUseForSearchesRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DenyLocationUseForSearchesRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyLocationUseForSearchesRegPath.`r`n")
}
if (Test-Path $DenyLocationUseForSearchesRegPathD) {
$DenyLocationUseForSearchesRegPathBackupD = "$($DenyLocationUseForSearchesRegPathD).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DenyLocationUseForSearchesRegPathD to $DenyLocationUseForSearchesRegPathBackupD.`r`n")
[Void](Copy-Item -Path $DenyLocationUseForSearchesRegPathD -Destination $DenyLocationUseForSearchesRegPathBackupD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DenyLocationUseForSearchesRegPathD to $DenyLocationUseForSearchesRegPathBackupD.`r`n")
} else {
[Void](New-Item -Path $DenyLocationUseForSearchesRegPathD)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DenyLocationUseForSearchesRegPathD.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDenyLocationUseForSearchesCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DenyLocationUseForSearchesRegPath -Name "AllowSearchToUseLocation" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DenyLocationUseForSearchesRegPathD -Name "AllowSearchToUseLocation" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'AllowSearchToUseLocation' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDenyLocationUseForSearchesCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Tablet Settings CheckBox ===#
if ($WPFDisableTabletSettingsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Tablet Settings #`r`n")
if (Test-Path $DisableTabletSettingsRegPath1) {
$DisableTabletSettingsRegPath1Backup = "$($DisableTabletSettingsRegPath1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPath1 to $DisableTabletSettingsRegPath1Backup.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPath1 -Destination $DisableTabletSettingsRegPath1Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPath1 to $DisableTabletSettingsRegPath1Backup.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPath1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPath1.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPathD1) {
$DisableTabletSettingsRegPathBackupD1 = "$($DisableTabletSettingsRegPathD1).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPathD1 to $DisableTabletSettingsRegPathBackupD1.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPathD1 -Destination $DisableTabletSettingsRegPathBackupD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPathD1 to $DisableTabletSettingsRegPathBackupD1.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPathD1)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPathD1.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPath2) {
$DisableTabletSettingsRegPath2Backup = "$($DisableTabletSettingsRegPath2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPath2 to $DisableTabletSettingsRegPath2Backup.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPath2 -Destination $DisableTabletSettingsRegPath2Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPath2 to $DisableTabletSettingsRegPath2Backup.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPath2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPath2.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPathD2) {
$DisableTabletSettingsRegPathBackupD2 = "$($DisableTabletSettingsRegPathD2).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPathD2 to $DisableTabletSettingsRegPathBackupD2.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPathD2 -Destination $DisableTabletSettingsRegPathBackupD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPathD2 to $DisableTabletSettingsRegPathBackupD2.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPathD2)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPathD2.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPath3) {
$DisableTabletSettingsRegPath3Backup = "$($DisableTabletSettingsRegPath3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPath3 to $DisableTabletSettingsRegPath3Backup.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPath3 -Destination $DisableTabletSettingsRegPath3Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPath3 to $DisableTabletSettingsRegPath3Backup.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPath3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPath3.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPathD3) {
$DisableTabletSettingsRegPathBackupD3 = "$($DisableTabletSettingsRegPathD3).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPathD3 to $DisableTabletSettingsRegPathBackupD3.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPathD3 -Destination $DisableTabletSettingsRegPathBackupD3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPathD3 to $DisableTabletSettingsRegPathBackupD3.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPathD3)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPathD3.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPath4) {
$DisableTabletSettingsRegPath4Backup = "$($DisableTabletSettingsRegPath4).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPath4 to $DisableTabletSettingsRegPath4Backup.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPath4 -Destination $DisableTabletSettingsRegPath4Backup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPath4 to $DisableTabletSettingsRegPath4Backup.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPath4)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPath4.`r`n")
}
if (Test-Path $DisableTabletSettingsRegPathD4) {
$DisableTabletSettingsRegPathBackupD4 = "$($DisableTabletSettingsRegPathD4).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableTabletSettingsRegPathD4 to $DisableTabletSettingsRegPathBackupD4.`r`n")
[Void](Copy-Item -Path $DisableTabletSettingsRegPathD4 -Destination $DisableTabletSettingsRegPathBackupD4)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableTabletSettingsRegPathD4 to $DisableTabletSettingsRegPathBackupD4.`r`n")
} else {
[Void](New-Item -Path $DisableTabletSettingsRegPathD4)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableTabletSettingsRegPathD4.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableTabletSettingsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPath1 -Name "SensorPermissionState" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPathD1 -Name "SensorPermissionState" -Value "0" -PropertyType DWord -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPath2 -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPathD2 -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPath3 -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPathD3 -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPath4 -Name "Value" -Value "Deny" -PropertyType String -Force)
[Void](New-ItemProperty -Path $DisableTabletSettingsRegPathD4 -Name "Value" -Value "Deny" -PropertyType String -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'SensorPermissionState' to '0' at '$DisableTabletSettingsRegPath1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny' at '$DisableTabletSettingsRegPath2'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny' at '$DisableTabletSettingsRegPath3'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'Value' to 'Deny' at '$DisableTabletSettingsRegPath4'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableTabletSettingsCheckBox.Content) setting has been applied.`r`n")
}

#=== Anonymize Search Info CheckBox ===#
if ($WPFAnonymizeSearchInfoCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Anonymize Search Info #`r`n")
if (Test-Path $AnonymizeSearchInfoRegPath) {
$AnonymizeSearchInfoRegPathBackup = "$($AnonymizeSearchInfoRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $AnonymizeSearchInfoRegPath to $AnonymizeSearchInfoRegPathBackup.`r`n")
[Void](Copy-Item -Path $AnonymizeSearchInfoRegPath -Destination $AnonymizeSearchInfoRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $AnonymizeSearchInfoRegPath to $AnonymizeSearchInfoRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $AnonymizeSearchInfoRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $AnonymizeSearchInfoRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFAnonymizeSearchInfoCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $AnonymizeSearchInfoRegPath -Name "ConnectedSearchPrivacy" -Value "3" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'ConnectedSearchPrivacy' to '3'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFAnonymizeSearchInfoCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Microsoft Store CheckBox ===#
if ($WPFDisableMicrosoftStoreCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Microsoft Store #`r`n")
if (Test-Path $DisableMicrosoftStoreRegPath) {
$DisableMicrosoftStoreRegPathBackup = "$($DisableMicrosoftStoreRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableMicrosoftStoreRegPath to $DisableMicrosoftStoreRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableMicrosoftStoreRegPath -Destination $DisableMicrosoftStoreRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableMicrosoftStoreRegPath to $DisableMicrosoftStoreRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableMicrosoftStoreRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableMicrosoftStoreRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableMicrosoftStoreCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableMicrosoftStoreRegPath -Name "RemoveWindowsStore" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'RemoveWindowsStore' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableMicrosoftStoreCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Store Apps CheckBox ===#
if ($WPFDisableStoreAppsCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Store Apps #`r`n")
if (Test-Path $DisableStoreAppsRegPath) {
$DisableStoreAppsRegPathBackup = "$($DisableStoreAppsRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableStoreAppsRegPath to $DisableStoreAppsRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableStoreAppsRegPath -Destination $DisableStoreAppsRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableStoreAppsRegPath to $DisableStoreAppsRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableStoreAppsRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableStoreAppsRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableStoreAppsCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableStoreAppsRegPath -Name "DisableStoreApps" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableStoreApps' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableStoreAppsCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable CEIP CheckBox ===#
if ($WPFDisableCEIPCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable CEIP #`r`n")
if (Test-Path $DisableCEIPRegPath) {
$DisableCEIPRegPathBackup = "$($DisableCEIPRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableCEIPRegPath to $DisableCEIPRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableCEIPRegPath -Destination $DisableCEIPRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableCEIPRegPath to $DisableCEIPRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableCEIPRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableCEIPRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableCEIPCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableCEIPRegPath -Name "CEIPEnable" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'CEIPEnable' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableCEIPCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable App Pairing CheckBox ===#
if ($WPFDisableAppPairingCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable App Pairing #`r`n")
if (Test-Path $DisableAppPairingRegPath) {
$DisableAppPairingRegPathBackup = "$($DisableAppPairingRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableAppPairingRegPath to $DisableAppPairingRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableAppPairingRegPath -Destination $DisableAppPairingRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableAppPairingRegPath to $DisableAppPairingRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableAppPairingRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableAppPairingRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableAppPairingCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableAppPairingRegPath -Name "UserAuthPolicy" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'UserAuthPolicy' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableAppPairingCheckBox.Content) setting has been applied.`r`n")
}

#=== Enable Diagnostic Data Viewer CheckBox ===#
if ($WPFEnableDiagnosticDataViewerCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Enable Diagnostic Data Viewer #`r`n")
if (Test-Path $EnableDiagnosticDataViewerRegPath) {
$EnableDiagnosticDataViewerRegPathBackup = "$($EnableDiagnosticDataViewerRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $EnableDiagnosticDataViewerRegPath to $EnableDiagnosticDataViewerRegPathBackup.`r`n")
[Void](Copy-Item -Path $EnableDiagnosticDataViewerRegPath -Destination $EnableDiagnosticDataViewerRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $EnableDiagnosticDataViewerRegPath to $EnableDiagnosticDataViewerRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $EnableDiagnosticDataViewerRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $EnableDiagnosticDataViewerRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFEnableDiagnosticDataViewerCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $EnableDiagnosticDataViewerRegPath -Name "EnableEventTranscript" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'EnableEventTranscript' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFEnableDiagnosticDataViewerCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Edge Desktop Shortcut CheckBox ===#
if ($WPFDisableEdgeDesktopShortcutCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Edge Desktop Shortcut #`r`n")
if (Test-Path $DisableEdgeDesktopShortcutRegPath) {
$DisableEdgeDesktopShortcutRegPathBackup = "$($DisableEdgeDesktopShortcutRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableEdgeDesktopShortcutRegPath to $DisableEdgeDesktopShortcutRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableEdgeDesktopShortcutRegPath -Destination $DisableEdgeDesktopShortcutRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableEdgeDesktopShortcutRegPath to $DisableEdgeDesktopShortcutRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableEdgeDesktopShortcutRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableEdgeDesktopShortcutRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableEdgeDesktopShortcutCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableEdgeDesktopShortcutRegPath -Name "DisableEdgeDesktopShortcutCreation" -Value "1" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'DisableEdgeDesktopShortcutCreation' to '1'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableEdgeDesktopShortcutCheckBox.Content) setting has been applied.`r`n")
}

#=== Disable Web Content Evaluation CheckBox ===#
if ($WPFDisableWebContentEvaluationCheckBox.IsChecked) {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) # Disable Web Content Evaluation #`r`n")
if (Test-Path $DisableWebContentEvaluationRegPath) {
$DisableWebContentEvaluationRegPathBackup = "$($DisableWebContentEvaluationRegPath).BACKUP"
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKING UP: $DisableWebContentEvaluationRegPath to $DisableWebContentEvaluationRegPathBackup.`r`n")
[Void](Copy-Item -Path $DisableWebContentEvaluationRegPath -Destination $DisableWebContentEvaluationRegPathBackup)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) BACKUP SUCCESS: $DisableWebContentEvaluationRegPath to $DisableWebContentEvaluationRegPathBackup.`r`n")
} else {
[Void](New-Item -Path $DisableWebContentEvaluationRegPath)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) CREATED REG KEY: $DisableWebContentEvaluationRegPath.`r`n")
}
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) DISABLING: $($WPFDisableWebContentEvaluationCheckBox.Content)`r`n")
[Void](New-ItemProperty -Path $DisableWebContentEvaluationRegPath -Name "EnableWebContentEvaluation" -Value "0" -PropertyType DWord -Force)
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SET REG VALUE: 'EnableWebContentEvaluation' to '0'.`r`n")
$WPFworkingOutputPrivacySettings.AppendText("$(timestamp) SUCCESS: $($WPFDisableWebContentEvaluationCheckBox.Content) setting has been applied.`r`n")
}

$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) *** FINISHED Processing selected Settings ***`r`n`n")
}
Remove-HKCR
UnmountDefaultUserReg
})
#endregion

#===========================================================================
#region Export Privacy Settings Log Button (Privacy Settings Tab)
#===========================================================================

$WPFExportLogButtonPrivacySettings.Add_Click({
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) Exporting App & Privacy Settings log...`r`n")
$SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveDialog.InitialDirectory = "$ENV:USERPROFILE\Desktop"
$SaveDialog.Filter = "LOG Files (*.log)|*.log|All files (*.*)|*.*"
$SaveDialog.ShowDialog() | Out-Null
$WPFworkingOutputPrivacySettings.Text >> $SaveDialog.Filename #"\Win10crAPPRemover_PrivacySettings.LOG"
if ($SaveDialog.Filename) {
[System.Windows.Forms.MessageBox]::Show("Logs exported at $($SaveDialog.Filename)","Log Export | Windows 10 crAPP Remover Privacy Settings")
} else {
$WPFworkingOutputPrivacySettings.AppendText("`r`n$(timestamp) Log export cancelled.`r`n")
}
})
#endregion
#endregion

#endregion

#
#
#
#
#
#===========================================================================
#region Start Menu Tab
#===========================================================================
#
#
#
#
#

$EmptyStartMenuLayoutTemplate = @"
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
<LayoutOptions StartTileGroupCellWidth="6" />
<DefaultLayoutOverride>
<StartLayoutCollection>
<defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
</defaultlayout:StartLayout>
</StartLayoutCollection>
</DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

$CleanStartMenuLayoutTemplate = @" 
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
<StartLayoutCollection>
  <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
<start:Group Name="" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
  <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
  <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Snipping Tool.lnk" />
  <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Control Panel.lnk" />
</start:Group>
  </defaultlayout:StartLayout>
</StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

#===========================================================================
#region Load Selected XML Template Button (Start Menu Tab)
#===========================================================================

$WPFLoadSelectedXMLTemplateButton.Add_Click({
Set-Variable -Name "SelectedXMLTemplate" -Value (($WPFXMLTemplateSelectionComboBox).Items | Where-Object {$_.IsSelected -eq $True}) -Scope Global

switch  ($SelectedXMLTemplate.Content) {
'Select XML Layout Template...' {
$WPFStartMenuLayoutXML.Text = "Load from template, or Paste in your own XML..."
}
'Empty Start Menu XML' {
$WPFStartMenuLayoutXML.Text = "$EmptyStartMenuLayoutTemplate"
}
'Current Start Menu XML' {
$TmpStartLayoutXMLFile = New-TemporaryFile
(Export-StartLayout -Path $TmpStartLayoutXMLFile.FullName)
Set-Variable -Name "CurrentStartMenuLayoutTemplate" -Value (Get-Content -Path $TmpStartLayoutXMLFile.FullName) -Scope Global
Remove-Item $TmpStartLayoutXMLFile.FullName -Force
$WPFStartMenuLayoutXML.Text = ""
foreach ($line in $CurrentStartMenuLayoutTemplate) {
$WPFStartMenuLayoutXML.AppendText("$line`r`n")
}
}
'Clean Start Menu XML' {
$WPFStartMenuLayoutXML.Text = "$CleanStartMenuLayoutTemplate"
}
}
})
#endregion

#===========================================================================
#region Export to Button (Start Menu Tab)
#===========================================================================

$WPFExportToButton.Add_Click({
$SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveDialog.InitialDirectory = "$ENV:USERPROFILE\Desktop"
$SaveDialog.Filter = "XML Files (*.xml)|*.xml|All files (*.*)|*.*"
$SaveDialog.ShowDialog() | Out-Null
$WPFStartMenuLayoutXML.Text > $SaveDialog.Filename
if ($SaveDialog.Filename) {
[System.Windows.Forms.MessageBox]::Show("Start Menu Layout XML saved to $($SaveDialog.Filename)","Start Layout XML Export | Windows 10 crAPP Remover Start Menu")
}
})
#endregion

#===========================================================================
#region Set Below XML Button (Start Menu Tab)
#===========================================================================

$WPFSetBelowXMLButton.Add_Click({
$msgBoxInput =  [System.Windows.MessageBox]::Show("This will set the displayed Start Menu Layout XML from below to the 'Default User' profile, which will take effect for all newly created User Profiles.`r`n`r`nWould you like to proceed?","Start Layout XML Confirmation | Windows 10 crAPP Remover Start Menu","YesNo","Warning")
switch  ($msgBoxInput) {
'Yes' {
$TmpStartLayoutXMLFile = New-TemporaryFile
$WPFStartMenuLayoutXML.Text > $TmpStartLayoutXMLFile.FullName
Import-StartLayout -LayoutPath $TmpStartLayoutXMLFile.FullName -MountPath "$($Env:SYSTEMDRIVE)\"
Remove-Item $TmpStartLayoutXMLFile.FullName -Force
$TmpStartLayoutXMLFile.FullName
[System.Windows.Forms.MessageBox]::Show("Success.`r`n`r`nDisplayed Start Menu Layout XML has been set in the 'Default User' profile and will take effect for all newly created User Profiles.","Start Layout XML Confirmation | Windows 10 crAPP Remover Start Menu")
}
'No' {
[System.Windows.Forms.MessageBox]::Show("Operation has been cancelled. No changes were made.","Start Layout XML Confirmation | Windows 10 crAPP Remover Start Menu")
}
}
})
#endregion

#endregion

#
#
#
#
#
#===========================================================================
#region Scheduled Tasks Tab
#===========================================================================
#
#
#
#
#

$WPFworkingOutputScheduledTasks.Foreground = "LightGreen"
$WPFworkingOutputScheduledTasks.AppendText(" Right-click on Tasks for description.  ---->`r`n`n")

#===========================================================================
#region Check All / Uncheck All Checkbox (Scheduled Tasks Tab)
#===========================================================================

#=== Check All Checkbox (Checked) ===#
$WPFCheckAllScheduledTasksButton.Add_Click({
$ScheduledTasksUnchecked = $WPFScheduledTasksListBox.Items | Where-Object {$_.IsChecked -eq $false}
if (!($ScheduledTasksUnchecked)) {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) Nothing to check. Uncheck something first.`r`n")
} else {
ForEach ($unchecked in $ScheduledTasksUnchecked) {
$unchecked.IsChecked = $true
}
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) Checked all Scheduled Tasks.`r`n")
}
})

#=== Uncheck All Checkbox (Checked) ===#
$WPFUncheckAllScheduledTasksButton.Add_Click({
$ScheduledTasksChecked = $WPFScheduledTasksListBox.Items | Where-Object {$_.IsChecked -eq $true}
if (!($ScheduledTasksChecked)) {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) Nothing to uncheck. Check something first.`r`n")
} else {
ForEach ($checked in $ScheduledTasksChecked) {
$checked.IsChecked = $false
}
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) Unchecked all Scheduled Tasks.`r`n`n")
}
})
#endregion

#===========================================================================
#region Detect Relevant Scheduled Tasks Button (Scheduled Tasks Tab)
#===========================================================================

$WPFDetectRelevantScheduledTasksListButton.Add_Click({
$WPFScheduledTasksListBox.Items.Clear()
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) *** Loading Scheduled Tasks***`r`n")
$ScheduledTasks = Get-ScheduledTask | Sort-Object -Property TaskName

Set-Variable -Name "ScheduledTaskFilter" -Value "Microsoft Compatibility Appraiser|ProgramDataUpdater|Consolidator|KernelCeipTask|UsbCeip|Microsoft-Windows-DiskDiagnosticDataCollector|GatherNetworkInfo|QueueReporting" -Scope Global

$NewScheduledTaskLabel1 = New-Object System.Windows.Controls.Label
$NewScheduledTaskLabel1.Content = "Unnecessary Tasks"
$NewScheduledTaskLabel1.Padding = "0"
$NewScheduledTaskLabel1.FontWeight = "Bold"
$WPFScheduledTasksListBox.AddChild($NewScheduledTaskLabel1)

foreach ($Task in $ScheduledTasks | Where-Object {$_.TaskName -match $ScheduledTaskFilter}) {
$NewScheduledTaskCheckBox = New-Object System.Windows.Controls.CheckBox
$NewScheduledTaskCheckBox.Uid = "$($Task.TaskName)"
$NewScheduledTaskCheckBox.Content = "$($Task.TaskName) ($($Task.State))"
$NewScheduledTaskCheckBox.Tag = $Task.Description
if ($Task.Description) {
$NewScheduledTaskCheckBox.ToolTip = "Right-click for Scheduled Task description!"
$NewScheduledTaskCheckBox.Add_MouseRightButtonDown({
$WPFworkingOutputScheduledTasks.AppendText("INFO: $($This.Content) - $($This.Tag)`r`n`r`n")
})
} else {
$NewScheduledTaskCheckBox.ToolTip = "No description detected."
}
if ($Task.State -eq "Disabled") {
$NewScheduledTaskCheckBox.Content = "$($Task.TaskName) (Disabled)"
$NewScheduledTaskCheckBox.Foreground = "#FF369726"
$NewScheduledTaskCheckBox.IsChecked = $False
} else {
$NewScheduledTaskCheckBox.Content = "$($Task.TaskName) (Enabled)"
$NewScheduledTaskCheckBox.Foreground = "#FF0000"
$NewScheduledTaskCheckBox.IsChecked = $True
}
$NewScheduledTaskCheckBox.Background = "White"
$WPFScheduledTasksListBox.AddChild($NewScheduledTaskCheckBox)
}

$NewScheduledTaskLabel2 = New-Object System.Windows.Controls.Label
$NewScheduledTaskLabel2.Content = "All Other Detected Tasks"
$NewScheduledTaskLabel2.Padding = "0"
$NewScheduledTaskLabel2.FontWeight = "Bold"
$WPFScheduledTasksListBox.AddChild($NewScheduledTaskLabel2)

foreach ($Task in $ScheduledTasks | Where-Object {$_.TaskName -notmatch $ScheduledTaskFilter}) {
$NewScheduledTaskCheckBox = New-Object System.Windows.Controls.CheckBox
$NewScheduledTaskCheckBox.Uid = "$($Task.TaskName)"
$NewScheduledTaskCheckBox.Content = "$($Task.TaskName) ($($Task.State))"
$NewScheduledTaskCheckBox.Tag = $Task.Description
if ($Task.Description) {
$NewScheduledTaskCheckBox.ToolTip = "Right-click for Scheduled Task description!"
$NewScheduledTaskCheckBox.Add_MouseRightButtonDown({
$WPFworkingOutputScheduledTasks.AppendText("INFO: $($This.Content) - $($This.Tag)`r`n`r`n")
})
} else {
$NewScheduledTaskCheckBox.ToolTip = "No description detected."
}
$NewScheduledTaskCheckBox.Background = "White"
$NewScheduledTaskCheckBox.IsChecked = $False
$WPFScheduledTasksListBox.AddChild($NewScheduledTaskCheckBox)
}
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) ...Scheduled Tasks loaded.`r`n`n")
})
#endregion

#===========================================================================
#region Disable Selected Scheduled Tasks Button (Scheduled Tasks Tab)
#===========================================================================

$WPFDisableSelectedScheduledTasksButton.Add_Click({
Set-Variable -Name "CheckedScheduledTasks" -Value ($WPFScheduledTasksListBox.Items | Where-Object {$_.IsChecked -eq $true}) -Scope Global
if (!($CheckedScheduledTasks)) {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) No Tasks selected. Click 'Detect Relevant Scheduled Tasks' button or check something.`r`n")
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) *** Disabling selected Scheduled Tasks ***`r`n`r`n")
ForEach ($CheckedTaskCheckBox in $CheckedScheduledTasks) {
function Set-CheckedScheduledTaskObject {
Set-Variable -Name "CheckedScheduledTaskObject" -Value (Get-ScheduledTask -TaskName "$($CheckedTaskCheckBox.Uid)") -Scope Global
}
Set-CheckedScheduledTaskObject
if ($CheckedTaskCheckBox -ne $null) {
try {
if ($CheckedScheduledTaskObject.State -ne "Disabled") {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) DISABLING Scheduled Task: '$($CheckedTaskCheckBox.Uid)'...`r`n")
Disable-ScheduledTask -TaskName $CheckedScheduledTaskObject.TaskName -TaskPath $CheckedScheduledTaskObject.TaskPath -ErrorAction Stop
Set-CheckedScheduledTaskObject
if ($CheckedScheduledTaskObject.State -eq "Disabled") {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) SUCCESS: '$($CheckedTaskCheckBox.Uid)' Scheduled Task has been disabled.`r`n`r`n")
$CheckedTaskCheckBox.Content = "$($CheckedScheduledTaskObject.TaskName) ($($CheckedScheduledTaskObject.State))"
$CheckedTaskCheckBox.IsChecked = $False
if ($CheckedScheduledTaskObject.TaskName -match $ScheduledTaskFilter) {
$CheckedTaskCheckBox.Foreground = "#FF369726"
}
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) FAILURE: There was a problem disabling '$($CheckedTaskCheckBox.Uid)'.`r`n`r`n")
}
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) SKIPPING: '$($CheckedTaskCheckBox.Uid)' - Scheduled Task is already in the 'Disabled' state.`r`n`r`n")
$CheckedTaskCheckBox.IsChecked = $False
}
}
catch [System.Exception] {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) FAILURE: Disabling of Scheduled Task '$($CheckedTaskCheckBox.Uid)' failed: $($_.Exception.Message)`r`n`r`n")
}
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) ERROR: Unable to locate Scheduled Task: '$($CheckedTaskCheckBox.Uid)'`r`n`r`n")
}
}
}
})
#endregion

#===========================================================================
#region Enable Selected Scheduled Tasks Button (Scheduled Tasks Tab)
#===========================================================================

$WPFEnableSelectedScheduledTasksButton.Add_Click({
Set-Variable -Name "CheckedScheduledTasks" -Value ($WPFScheduledTasksListBox.Items | Where-Object {$_.IsChecked -eq $true}) -Scope Global
if (!($CheckedScheduledTasks)) {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) No Tasks selected. Click 'Detect Relevant Scheduled Tasks' button or check something.`r`n")
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) *** Enabling selected Scheduled Tasks ***`r`n`r`n")
ForEach ($CheckedTaskCheckBox in $CheckedScheduledTasks) {
function Set-CheckedScheduledTaskObject {
Set-Variable -Name "CheckedScheduledTaskObject" -Value (Get-ScheduledTask -TaskName "$($CheckedTaskCheckBox.Uid)") -Scope Global
}
Set-CheckedScheduledTaskObject
if ($CheckedTaskCheckBox -ne $null) {
try {
if ($CheckedScheduledTaskObject.State -eq "Disabled") {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) ENABLING Scheduled Task: '$($CheckedTaskCheckBox.Uid)'...`r`n")
Enable-ScheduledTask -TaskName $CheckedScheduledTaskObject.TaskName -TaskPath $CheckedScheduledTaskObject.TaskPath -ErrorAction Stop
Set-CheckedScheduledTaskObject
if ($CheckedScheduledTaskObject.State -ne "Disabled") {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) SUCCESS: '$($CheckedTaskCheckBox.Uid)' Scheduled Task has been Enabled.`r`n`r`n")
$CheckedTaskCheckBox.Content = "$($CheckedScheduledTaskObject.TaskName) ($($CheckedScheduledTaskObject.State))"
$CheckedTaskCheckBox.IsChecked = $True
if ($CheckedScheduledTaskObject.TaskName -match $ScheduledTaskFilter) {
$CheckedTaskCheckBox.Content = "$($CheckedScheduledTaskObject.TaskName) (Enabled)"
$CheckedTaskCheckBox.Foreground = "#FF0000"
}
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) FAILURE: There was a problem enabling '$($CheckedTaskCheckBox.Uid)'.`r`n`r`n")
}
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) SKIPPING: '$($CheckedTaskCheckBox.Uid)' - Scheduled Task is already in the 'Enabled' state.`r`n`r`n")
$CheckedTaskCheckBox.IsChecked = $False
}
}
catch [System.Exception] {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) FAILURE: Enabling of Scheduled Task '$($CheckedTaskCheckBox.Uid)' failed: $($_.Exception.Message)`r`n`r`n")
}
} else {
$WPFworkingOutputScheduledTasks.AppendText("$(timestamp) ERROR: Unable to locate Scheduled Task: '$($CheckedTaskCheckBox.Uid)'`r`n`r`n")
}
}
}
})
#endregion

#===========================================================================
#region Export Scheduled Tasks Log Button (Scheduled Tasks Tab)
#===========================================================================

$WPFExportLogButtonScheduledTasks.Add_Click({
$WPFworkingOutputScheduledTasks.AppendText("`r`n$(timestamp) Exporting Scheduled Tasks log...`r`n")
$SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveDialog.InitialDirectory = "$ENV:USERPROFILE\Desktop"
$SaveDialog.Filter = "LOG Files (*.log)|*.log|All files (*.*)|*.*"
$SaveDialog.ShowDialog() | Out-Null
$WPFworkingOutputScheduledTasks.Text >> $SaveDialog.Filename
if ($SaveDialog.Filename) {
[System.Windows.Forms.MessageBox]::Show("Logs exported at $($SaveDialog.Filename)","Log Export | Windows 10 crAPP Remover Scheduled Tasks")
} else {
$WPFworkingOutputScheduledTasks.AppendText("`r`n$(timestamp) Log export cancelled.`r`n")
}
})
#endregion


#endregion

#
#
#
#
#
#===========================================================================
#region Services Tab
#===========================================================================
#
#
#
#
#

$WPFworkingOutputServices.Foreground = "LightGreen"
$WPFworkingOutputServices.AppendText(" Right-click on Services for description.  ---->`r`n`n")

#===========================================================================
#region Check All / Uncheck All Checkbox (Services Tab)
#===========================================================================

#=== Check All Checkbox (Checked) ===#
$WPFCheckAllServicesButton.Add_Click({
$ServicesUnchecked = $WPFServicesListBox.Items | Where-Object {$_.IsChecked -eq $false}
if (!($ServicesUnchecked)) {
$WPFworkingOutputServices.AppendText("$(timestamp) Nothing to check. Uncheck something first.`r`n")
} else {
ForEach ($unchecked in $ServicesUnchecked) {
$unchecked.IsChecked = $true
}
$WPFworkingOutputServices.AppendText("$(timestamp) Checked all Services.`r`n")
}
})

#=== Uncheck All Checkbox (Checked) ===#
$WPFUncheckAllServicesButton.Add_Click({
$ServicesChecked = $WPFServicesListBox.Items | Where-Object {$_.IsChecked -eq $true}
if (!($ServicesChecked)) {
$WPFworkingOutputServices.AppendText("$(timestamp) Nothing to uncheck. Check something first.`r`n")
} else {
ForEach ($checked in $ServicesChecked) {
$checked.IsChecked = $false
}
$WPFworkingOutputServices.AppendText("$(timestamp) Unchecked all Services.`r`n`n")
}
})
#endregion

#===========================================================================
#region Detect Relevant Services Button (Services Tab)
#===========================================================================

$WPFDetectRelevantServicesListButton.Add_Click({
$WPFServicesListBox.Items.Clear()
$WPFworkingOutputServices.AppendText("$(timestamp) *** Loading Services***`r`n")
$Services = Get-Service | Sort-Object -Property DisplayName

Set-Variable -Name "ServicesFilter" -Value "Diagtrack|WMPNetworkSvc|XblAuthManager|XblGameSave|XboxNetApiSvc" -Scope Global

$NewServicesLabel1 = New-Object System.Windows.Controls.Label
$NewServicesLabel1.Content = "Unnecessary Services"
$NewServicesLabel1.Padding = "0"
$NewServicesLabel1.FontWeight = "Bold"
$WPFServicesListBox.AddChild($NewServicesLabel1)

foreach ($Service in $Services | Where-Object {$_.Name -match $ServicesFilter}) {
$NewServicesCheckBox = New-Object System.Windows.Controls.CheckBox
$NewServicesCheckBox.Uid = "$($Service.Name)"
$NewServicesCheckBox.Content = "$($Service.Name) ($($Service.Status), $($Service.StartType))"
$NewServicesCheckBox.Tag = $Service.DisplayName
if ($Service.DisplayName) {
$NewServicesCheckBox.ToolTip = "Right-click for Service description!"
$NewServicesCheckBox.Add_MouseRightButtonDown({
$WPFworkingOutputServices.AppendText("INFO: $($This.Content) - $($This.Tag)`r`n`r`n")
})
} else {
$NewServicesCheckBox.ToolTip = "No description detected."
}
if ($Service.StartType -eq "Disabled") {
$NewServicesCheckBox.Content = "$($Service.Name) ($($Service.Status), $($Service.StartType))"
$NewServicesCheckBox.Foreground = "#FF369726"
$NewServicesCheckBox.IsChecked = $False
} else {
$NewServicesCheckBox.Content = "$($Service.Name) ($($Service.Status), $($Service.StartType))"
$NewServicesCheckBox.Foreground = "#FF0000"
$NewServicesCheckBox.IsChecked = $True
}
$NewServicesCheckBox.Background = "White"
$WPFServicesListBox.AddChild($NewServicesCheckBox)
}

$NewServicesLabel2 = New-Object System.Windows.Controls.Label
$NewServicesLabel2.Content = "All Other Detected Services"
$NewServicesLabel2.Padding = "0"
$NewServicesLabel2.FontWeight = "Bold"
$WPFServicesListBox.AddChild($NewServicesLabel2)

foreach ($Service in $Services | Where-Object {$_.Name -notmatch $ServicesFilter}) {
$NewServicesCheckBox = New-Object System.Windows.Controls.CheckBox
$NewServicesCheckBox.Uid = "$($Service.Name)"
$NewServicesCheckBox.Content = "$($Service.Name) ($($Service.Status), $($Service.StartType))"
$NewServicesCheckBox.Tag = $Service.DisplayName
if ($Service.DisplayName) {
$NewServicesCheckBox.ToolTip = "Right-click for Service description!"
$NewServicesCheckBox.Add_MouseRightButtonDown({
$WPFworkingOutputServices.AppendText("INFO: $($This.Content) - $($This.Tag)`r`n`r`n")
})
} else {
$NewServicesCheckBox.ToolTip = "No description detected."
}
$NewServicesCheckBox.Background = "White"
$NewServicesCheckBox.IsChecked = $False
$WPFServicesListBox.AddChild($NewServicesCheckBox)
}
$WPFworkingOutputServices.AppendText("$(timestamp) ...Services loaded.`r`n`n")
})
#endregion

#===========================================================================
#region Disable Selected Services Button (Services Tab)
#===========================================================================

$WPFDisableSelectedServicesButton.Add_Click({
Set-Variable -Name "CheckedServices" -Value ($WPFServicesListBox.Items | Where-Object {$_.IsChecked -eq $true}) -Scope Global
if (!($CheckedServices)) {
$WPFworkingOutputServices.AppendText("$(timestamp) No Services selected. Click 'Detect Relevant Services' button or check something.`r`n")
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) *** Disabling selected Services ***`r`n`r`n")
ForEach ($CheckedServiceCheckBox in $CheckedServices) {
function Set-CheckedServiceObject {
Set-Variable -Name "CheckedServiceObject" -Value (Get-Service -Name "$($CheckedServiceCheckBox.Uid)") -Scope Global
}
Set-CheckedServiceObject
if ($CheckedServiceCheckBox -ne $null) {
try {
if ($CheckedServiceObject.StartType -ne "Disabled") {
$WPFworkingOutputServices.AppendText("$(timestamp) DISABLING Service: '$($CheckedServiceCheckBox.Uid)'...`r`n")
Stop-Service -Name $CheckedServiceObject.Name -Force -PassThru | Set-Service -StartupType Disabled -ErrorAction Stop
Set-CheckedServiceObject
if ($CheckedServiceObject.StartType -eq "Disabled") {
$WPFworkingOutputServices.AppendText("$(timestamp) SUCCESS: '$($CheckedServiceCheckBox.Uid)' Service has been disabled.`r`n`r`n")
$CheckedServiceCheckBox.Content = "$($CheckedServiceObject.Name) ($($CheckedServiceObject.Status), $($CheckedServiceObject.StartType))"
$CheckedServiceCheckBox.IsChecked = $False
if ($CheckedServiceObject.Name -match $ServicesFilter) {
$CheckedServiceCheckBox.Foreground = "#FF369726"
}
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) FAILURE: There was a problem disabling '$($CheckedServiceCheckBox.Uid)'.`r`n`r`n")
}
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) SKIPPING: '$($CheckedServiceCheckBox.Uid)' - Service is already in the 'Disabled' state.`r`n`r`n")
$CheckedServiceCheckBox.IsChecked = $False
}
}
catch [System.Exception] {
$WPFworkingOutputServices.AppendText("$(timestamp) FAILURE: Disabling of Service '$($CheckedServiceCheckBox.Uid)' failed: $($_.Exception.Message)`r`n`r`n")
}
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) ERROR: Unable to locate Service: '$($CheckedServiceCheckBox.Uid)'`r`n`r`n")
}
}
}
})
#endregion

#===========================================================================
#region Enable Selected Services Button (Services Tab)
#===========================================================================

$WPFEnableSelectedServicesButton.Add_Click({
Set-Variable -Name "CheckedServices" -Value ($WPFServicesListBox.Items | Where-Object {$_.IsChecked -eq $true}) -Scope Global
if (!($CheckedServices)) {
$WPFworkingOutputServices.AppendText("$(timestamp) No Services selected. Click 'Detect Relevant Services' button or check something.`r`n")
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) *** Enabling selected Services ***`r`n`r`n")
ForEach ($CheckedServiceCheckBox in $CheckedServices) {
function Set-CheckedServiceObject {
Set-Variable -Name "CheckedServiceObject" -Value (Get-Service -Name "$($CheckedServiceCheckBox.Uid)") -Scope Global
}
Set-CheckedServiceObject
if ($CheckedServiceCheckBox -ne $null) {
try {
if ($CheckedServiceObject.StartType -eq "Disabled") {
$WPFworkingOutputServices.AppendText("$(timestamp) ENABLING Service: '$($CheckedServiceCheckBox.Uid)'...`r`n")
Set-Service -Name $CheckedServiceObject.Name -StartupType Automatic -PassThru | Start-Service -PassThru
Set-CheckedServiceObject
if ($CheckedServiceObject.StartType -ne "Disabled") {
$WPFworkingOutputServices.AppendText("$(timestamp) SUCCESS: '$($CheckedServiceCheckBox.Uid)' Service has been Enabled.`r`n`r`n")
$CheckedServiceCheckBox.Content = "$($CheckedServiceObject.Name) ($($CheckedServiceObject.Status), $($CheckedServiceObject.StartType))"
$CheckedServiceCheckBox.IsChecked = $True
if ($CheckedServiceObject.Name -match $ServicesFilter) {
$CheckedServiceCheckBox.Content = "$($CheckedServiceObject.Name) ($($CheckedServiceObject.Status), $($CheckedServiceObject.StartType))"
$CheckedServiceCheckBox.Foreground = "#FF0000"
}
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) FAILURE: There was a problem enabling '$($CheckedServiceCheckBox.Uid)'.`r`n`r`n")
}
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) SKIPPING: '$($CheckedServiceCheckBox.Uid)' - Service is already in the 'Enabled' state.`r`n`r`n")
$CheckedServiceCheckBox.IsChecked = $False
}
}
catch [System.Exception] {
$WPFworkingOutputServices.AppendText("$(timestamp) FAILURE: Enabling of Service '$($CheckedServiceCheckBox.Uid)' failed: $($_.Exception.Message)`r`n`r`n")
}
} else {
$WPFworkingOutputServices.AppendText("$(timestamp) ERROR: Unable to locate Service: '$($CheckedServiceCheckBox.Uid)'`r`n`r`n")
}
}
}
})
#endregion

#===========================================================================
#region Export Services Log Button (Services Tab)
#===========================================================================

$WPFExportLogButtonServices.Add_Click({
$WPFworkingOutputServices.AppendText("`r`n$(timestamp) Exporting Services log...`r`n")
$SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveDialog.InitialDirectory = "$ENV:USERPROFILE\Desktop"
$SaveDialog.Filter = "LOG Files (*.log)|*.log|All files (*.*)|*.*"
$SaveDialog.ShowDialog() | Out-Null
$WPFworkingOutputServices.Text >> $SaveDialog.Filename
if ($SaveDialog.Filename) {
[System.Windows.Forms.MessageBox]::Show("Logs exported at $($SaveDialog.Filename)","Log Export | Windows 10 crAPP Remover Services")
} else {
$WPFworkingOutputServices.AppendText("`r`n$(timestamp) Log export cancelled.`r`n")
}
})
#endregion

#endregion

#endregion

#===========================================================================
#region Shows the form / GUI
#===========================================================================

#Detect Primary Display
Set-Variable -Name "Display" -Value ([system.windows.forms.screen]::AllScreens | Where-Object {$_.Primary -eq $True}) -Scope Global
function Set-HDRes {
$Form.Width = "1280"
$Form.Height = "650"
$WPFcrAPPListBoxGroupBox.Width = "350"
$WPFPrivacySettingsListBoxGroupBox.Width = "350"
$WPFScheduledTasksListBoxGroupBox.Width = "350"
$WPFServicesListBoxGroupBox.Width = "350"
}

#Set the window and list box sizes depending on screen resolution
#Designed for future planned changes
switch ($Display.Bounds.Width) {
1920 {
Set-HDRes
}
1680 {
Set-HDRes
}
default {
if ($Display.Bounds.Width -lt "1680") {
} elseif ($Display.Bounds.Width -gt "2048") {
Set-HDRes
} else {
Set-HDRes
}
}
}

[Void]($Form.ShowDialog())
#endregion