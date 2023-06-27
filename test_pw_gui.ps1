<#
    .NOTES
    ===========================================================================
        FileName:  test_pw_gui.ps1
        Author:  daniela.zednickova
        Created On:  2023/06/27
        Last Updated:  2023/06/27
        Organization:
        Version:      v0.1
    ===========================================================================

    .DESCRIPTION

    .DEPENDENCIES
#>

# Functional code








# ScriptBlock to Execute in STA Runspace
$sbGUI = {
    function HandleOption1Click {
        param($isChecked)
    
        # Add your logic here based on the value of $isChecked
        if ($isChecked) {
            Write-Host "Yess!"
        } else {
            Write-Host "No!!!"
        }
    }

    
    param($BaseDir)

    #region Functions

    function Update-ErrorLog {
        param(
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            [string]$Message,
            [switch]$Promote
        )

        if ( $Message -ne '' ) {[void][System.Windows.Forms.MessageBox]::Show("$($Message)`r`n`r`nCheck '$($BaseDir)\exceptions.txt' for details.",'Exception Occurred')}

        $date = Get-Date -Format 'yyyyMMdd HH:mm:ss'
        $ErrorRecord | Out-File "$($BaseDir)\tmpError.txt"

        Add-Content -Path "$($BaseDir)\exceptions.txt" -Value "$($date): $($(Get-Content "$($BaseDir)\tmpError.txt") -replace "\s+"," ")"

        Remove-Item -Path "$($BaseDir)\tmpError.txt"

        if ( $Promote ) {throw $ErrorRecord}
    }

    function ConvertFrom-WinFormsXML {
        param(
            [Parameter(Mandatory=$true)]$Xml,
            [string]$Reference,
            $ParentControl,
            [switch]$Suppress
        )

        try {
            if ( $Xml.GetType().Name -eq 'String' ) {$Xml = ([xml]$Xml).ChildNodes}

            if ( $Xml.ToString() -ne 'SplitterPanel' ) {$newControl = New-Object System.Windows.Forms.$($Xml.ToString())}

            if ( $ParentControl ) {
                if ( $Xml.ToString() -match "^ToolStrip" ) {
                    if ( $ParentControl.GetType().Name -match "^ToolStrip" ) {[void]$ParentControl.DropDownItems.Add($newControl)} else {[void]$ParentControl.Items.Add($newControl)}
                } elseif ( $Xml.ToString() -eq 'ContextMenuStrip' ) {$ParentControl.ContextMenuStrip = $newControl}
                elseif ( $Xml.ToString() -eq 'SplitterPanel' ) {$newControl = $ParentControl.$($Xml.Name.Split('_')[-1])}
                else {$ParentControl.Controls.Add($newControl)}
            }

            $Xml.Attributes | ForEach-Object {
                $attrib = $_
                $attribName = $_.ToString()

                if ( $Script:specialProps.Array -contains $attribName ) {
                    if ( $attribName -eq 'Items' ) {
                        $($_.Value -replace "\|\*BreakPT\*\|","`n").Split("`n") | ForEach-Object{[void]$newControl.Items.Add($_)}
                    } else {
                            # Other than Items only BoldedDate properties on MonthCalendar control
                        $methodName = "Add$($attribName)" -replace "s$"

                        $($_.Value -replace "\|\*BreakPT\*\|","`n").Split("`n") | ForEach-Object{$newControl.$attribName.$methodName($_)}
                    }
                } else {
                    switch ($attribName) {
                        FlatAppearance {
                            $attrib.Value.Split('|') | ForEach-Object {$newControl.FlatAppearance.$($_.Split('=')[0]) = $_.Split('=')[1]}
                        }
                        default {
                            if ( $null -ne $newControl.$attribName ) {
                                if ( $newControl.$attribName.GetType().Name -eq 'Boolean' ) {
                                    if ( $attrib.Value -eq 'True' ) {$value = $true} else {$value = $false}
                                } else {$value = $attrib.Value}
                            } else {$value = $attrib.Value}
                            $newControl.$attribName = $value
                        }
                    }
                }

                if (( $attrib.ToString() -eq 'Name' ) -and ( $Reference -ne '' )) {
                    try {$refHashTable = Get-Variable -Name $Reference -Scope Script -ErrorAction Stop}
                    catch {
                        New-Variable -Name $Reference -Scope Script -Value @{} | Out-Null
                        $refHashTable = Get-Variable -Name $Reference -Scope Script -ErrorAction SilentlyContinue
                    }

                    $refHashTable.Value.Add($attrib.Value,$newControl)
                }
            }

            if ( $Xml.ChildNodes ) {$Xml.ChildNodes | ForEach-Object {ConvertFrom-WinformsXML -Xml $_ -ParentControl $newControl -Reference $Reference -Suppress}}

            if ( $Suppress -eq $false ) {return $newControl}
        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered adding $($Xml.ToString()) to $($ParentControl.Name)"}
    }

    #endregion Functions

    #region Environment Setup

    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing


    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Environment Setup."}

    #endregion Environment Setup

    #region Form Initialization

    try {
        ConvertFrom-WinFormsXML -Reference refs -Suppress -Xml @"
  <Form Name="MainForm" Size="1478, 1100" WindowState="Maximized">
    <Label Name="label" Location="57, 58" Text="Instalace" />
    <CheckBox Name="option1" Location="81, 72" Text="Open VPN" />
  </Form>
"@
    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Form Initialization."}

    
    
    # Bind the event handler to the CheckBox control
    $refs['option1'].add_Click({
    HandleOption1Click $refs['option1'].Checked


})

    #endregion Form Initialization

    #region Other Actions Before ShowDialog

    try {
        Remove-Variable -Name eventSB
    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered before ShowDialog."}

    #endregion Other Actions Before ShowDialog

        # Show the form
    try {[void]$Script:refs['MainForm'].ShowDialog()} catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered unexpectedly at ShowDialog."}

    <#
    #region Actions After Form Closed

    try {

    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered after Form close."}

    #endregion Actions After Form Closed
    #>
}

#region Start Point of Execution

    # Initialize STA Runspace
$rsGUI = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
$rsGUI.ApartmentState = 'STA'
$rsGUI.ThreadOptions = 'ReuseThread'
$rsGUI.Open()

    # Create the PSCommand, Load into Runspace, and BeginInvoke
$cmdGUI = [Management.Automation.PowerShell]::Create().AddScript($sbGUI).AddParameter('BaseDir',$PSScriptRoot)
$cmdGUI.RunSpace = $rsGUI
$handleGUI = $cmdGUI.BeginInvoke()

    # Hide Console Window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)

    #Loop Until GUI Closure
while ( $handleGUI.IsCompleted -eq $false ) {Start-Sleep -Seconds 5}

    # Dispose of GUI Runspace/Command
$cmdGUI.EndInvoke($handleGUI)
$cmdGUI.Dispose()
$rsGUI.Dispose()

Exit

#endregion Start Point of Execution
