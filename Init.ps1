## Prerequisites:
# https://github.com/microsoft/navcontainerhelper?tab=readme-ov-file#3-install-bccontainerhelper
# Install-PackageProvider -Name NuGet -force
# Install-Module BcContainerHelper -force

$ArtifactUrl = Get-BCArtifactUrl -type OnPrem  -select latest
$Settings = get-content .\Settings.json | ConvertFrom-Json
$ContainerName = $Settings.ContainerName
$UserName = $Settings.UserName
$PassWord = $Settings.Password
$Credential = (New-Object System.Management.Automation.PSCredential($UserName,(ConvertTo-SecureString $PassWord -AsPlainText -Force)))

New-BCContainer -accept_eula `
    -containerName $containerName `
    -artifactUrl $ArtifactUrl `
    -auth NavUserPassword `
    -credential $credential `
    -updateHosts `
    -accept_outdated `
    -includeTestFrameworkOnly `
    -assignPremiumPlan `
    -includeTestToolkit `
    -includeTestLibrariesOnly `

    