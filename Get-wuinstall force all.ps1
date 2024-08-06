    <# .SYNOPSIS
         
    .DESCRIPTION
         This routine is ment to install PSWindowsUpdate then force install all available updates including drivers and BIOS.

    .NOTES
         Author     : Ole Anders Herland
         Date       : 05.08.2024
         Revised    : 05.08.2024
         Version    : 1.00

         Comments   :
    .LINK
        
    #>

    Try {
        if(-not (Get-Module PSWindowsUpdate -ListAvailable)){
            Install-Module PSWindowsUpdate -Confirm:$False -Force
        }
        else{Write-Host "Updating PSWindowsUpdate"
        Update-Module PSWindowsUpdate -Confirm:$False -Force
        }
    }
    Catch {
        $ErrorArray = $_.Exception
        $ErrorRecord = $ErrorArray.ErrorRecord | Out-String
        #If the component fails write to the ouput and give a fail exit code
        Write-Host "Routine for installation of PSWindowsUpdate"
        Write-Host "$ErrorRecord"
    
        Exit 1
    }

     Try {
        Write-Host "Installing all available updates"
        Get-wuinstall -microsoftupdate -acceptall -autoreboot:$false -install
        
    }
    Catch {
        $ErrorArray = $_.Exception
        $ErrorRecord = $ErrorArray.ErrorRecord | Out-String
        #If the component fails write to the ouput and give a fail exit code
        Write-Host "Routine for installation of updates failed"
        Write-Host "$ErrorRecord"
    
        Exit 1
    }
    
    #On success write to the output and exit with a success code
    Write-Host "Routine for installation of updates completed successfully"
    #Write-Host "Restarting the computer"
    #Restart-computer -force
    
    Exit 0