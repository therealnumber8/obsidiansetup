Import-Module WebAdministration; 
Get-ChildItem IIS:\Sites | ForEach-Object {
  $siteName = $_.Name
  (Get-WebConfigurationProperty -Location $siteName -Filter "system.webServer/aspNetCore" -Name hostingModel) | 
    ForEach-Object {
      [PSCustomObject]@{
        Site          = $siteName
        HostingModel  = $_.Value
      }
    }
}

