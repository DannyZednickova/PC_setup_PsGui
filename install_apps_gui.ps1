Add-Type -AssemblyName System.Windows.Forms
$succes_7zip = 0
# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Install Soft / X9"
$form.Size = New-Object System.Drawing.Size(300, 400)

$label = New-Object System.Windows.Forms.Label
$label.Text = "Choose the SW you you want to install on PC:"
$label.AutoSize = $true
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Dock = [System.Windows.Forms.DockStyle]::Top
$label.Padding = New-Object System.Windows.Forms.Padding(0, 20, 0, 0)

#openVPN
$cb_openVPN = New-Object System.Windows.Forms.CheckBox
$cb_openVPN.Text = "openVPN"
$cb_openVPN.Location = New-Object System.Drawing.Point(100, 50)


# 7zip
$cb_7zip = New-Object System.Windows.Forms.CheckBox
$cb_7zip.Text = "7zip"
$cb_7zip.Location = New-Object System.Drawing.Point(100, 80)

# VLC
$cb_vlc = New-Object System.Windows.Forms.CheckBox
$cb_vlc.Text = "VLC"
$cb_vlc.Location = New-Object System.Drawing.Point(100, 110)

# Adobe
$cb_Adobe = New-Object System.Windows.Forms.CheckBox
$cb_Adobe.Text = "Adobe"
$cb_Adobe.Location = New-Object System.Drawing.Point(100, 140)

# Hibernate
$cb_Hibernate = New-Object System.Windows.Forms.CheckBox
$cb_Hibernate.Text = "Hibernate enabled"
$cb_Hibernate.Location = New-Object System.Drawing.Point(100, 170)
$cb_Hibernate.Width = 150



# Create submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Submit"
$submitButton.Location = New-Object System.Drawing.Point(100, 230)
$submitButton.Add_Click({



if ($cb_openVPN.Checked) {
    $openvpnUrl = 'https://openvpn.net/downloads/openvpn-connect-v3-windows.msi'
    $installerPath = "$env:TEMP\openvpn-connect-v3-windows.msi"
    
    # Download OpenVPN Connect V3 installer
    Invoke-WebRequest -Uri $openvpnUrl -OutFile $installerPath
    
    # Install OpenVPN Connect V3 silently
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet" -Wait
    
    # Verify installation by checking if the OpenVPN Connect V3 executable exists
    if (Test-Path (Join-Path $env:ProgramFiles 'OpenVPN Connect\OpenVPNConnect.exe')) {
        Write-Host "OpenVPN Connect V3 has been successfully installed."
        $succes_openVPN = 1
    } else {
        Write-Host "Installation of OpenVPN Connect V3 failed."
    }
     
    }



if ($cb_7zip.Checked) {
        
    #7zip install
    $7zipUrl = 'https://www.7-zip.org/a/7z2201-x64.exe'
    $installerPath = "$env:TEMP\7z2201-x64.exe"
    $installPath = "C:\Program Files\7-Zip"
    
    # Download 7-Zip installer
    Invoke-WebRequest -Uri $7zipUrl -OutFile $installerPath
    
    # Install 7-Zip silently
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    
    # Verify installation by checking if the 7-Zip executable exists
    
    if (Test-Path (Join-Path $installPath "7z.exe")) {
        Write-Host "7-Zip has been successfully installed."
        $succes_7zip = 1
    } else {
        Write-Host "Installation of 7-Zip failed."
    }
    

    $7ZipPath = "C:\Program Files\7-Zip\7z.exe"  # Path to the 7-Zip program

    # Set associations for specific file types
    $associations = @{
        ".zip" = "7-Zip"
        ".rar" = "7-Zip"
        ".7z" = "7-Zip"
        # Add more file types and their respective associations
    }
    
    foreach ($extension in $associations.Keys) {
        $progId = $associations[$extension]
        
        # Set the association for the file type
        $command = "cmd.exe /c assoc $extension=$progId"
        Invoke-Expression -Command $command
        
        # Set the default program for the file type
        $command = "cmd.exe /c ftype $progId=`"$7ZipPath`" `"%1`""
        Invoke-Expression -Command $command
    }
    
    Write-Host "7-Zip associations have been set."
     
}


if ($cb_vlc.Checked) {
    $vlcUrl = 'https://mirror.kku.ac.th/videolan/vlc/3.0.18/win64/vlc-3.0.18-win64.exe'
    $installerPath = "$env:TEMP\vlc-installer.exe"
    
    # Download VLC installer
    Invoke-WebRequest -Uri $vlcUrl -OutFile $installerPath
    
    # Install VLC silently
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    
    # Verify installation by checking if the VLC executable exists
    if (Test-Path (Join-Path $env:ProgramFiles 'VideoLAN\VLC\vlc.exe')) {
        Write-Host "VLC media player has been successfully installed."
        $succes_vlc = 1
    } else {
        Write-Host "Installation of VLC media player failed."
    }
    
     
    }


    if ($cb_Adobe.Checked) {
        $adobeReaderUrl = 'https://xcloud.x9.cz/index.php/s/ysCFK7rLWcwjcCc/download?path=%2F_nove_PC&files=readerdc64_cz_ha_mdr_install.exe'
        $installerPath = "$env:TEMP\adobe-reader-installer.exe"
        
        # Download Adobe Reader installer
        Invoke-WebRequest -Uri $adobeReaderUrl -OutFile $installerPath
        
        # Install Adobe Reader silently
        Start-Process -FilePath $installerPath -ArgumentList "/sAll" -Wait
        
        # Verify installation by checking if the Adobe Reader executable exists
        if (Test-Path (Join-Path $env:ProgramFiles 'Adobe\Acrobat Reader DC\Reader\AcroRd32.exe')) {
            Write-Host "Adobe Reader has been successfully installed."
            $succes_Adobe = 1
        } else {
            Write-Host "Installation of Adobe Reader failed."
        }
         
        }




        if ($cb_Hibernate.Checked) {
             # Disable hibernate
            powercfg.exe /hibernate off

            # Enable full shutdown
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
            $regName = "HiberbootEnabled"

            Set-ItemProperty -Path $regPath -Name $regName -Value 0

            Write-Host "Hibernate disabled and full shutdown enabled."

            # Check hibernation status
            $hibernateStatus = powercfg.exe /a

            if ($hibernateStatus -match 'Hibernation is not available') {
                Write-Host "Hibernation is disabled."
                $succes_Hibernate = 1
            } else {
                Write-Host "Hibernation is enabled."
            }

            # Check full shutdown status
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
            $regName = "HiberbootEnabled"

            $fullShutdownStatus = (Get-ItemProperty -Path $regPath -Name $regName).$regName

            if ($fullShutdownStatus -eq 0) {
                Write-Host "Full shutdown is enabled."
            } else {
                Write-Host "Full shutdown is disabled."
            }
             
            }


        


 if(($succes_7zip -eq 1) -or ($succes_Adobe -eq 1) -or ($succes_vlc -eq 1) -or ($succes_vlc -eq 1) ) {
    Write-Host $succes_7zip
    [System.Windows.Forms.MessageBox]::Show("All installed Succesfully! ")
}

})



# Add checkboxes and submit button to the form
$form.Controls.AddRange(@($cb_openVPN, $cb_7zip, $submitButton, $label, $cb_vlc, $cb_Adobe, $cb_Hibernate ))

# Show the form
$form.ShowDialog()
