$ADsecurePassword = ConvertTo-SecureString -String '%aduser.password%' -AsPlainText -Force
$ADCredential = New-Object System.Management.Automation.PSCredential ('%aduser.username%', $ADSecurePassword)

$USER = "Kiuwan_API_User"

# PUT USER PASSWORD HERE <<
$password = 'PutPasswordHere'

$HeaderAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $USER, $password)))
$SessionHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$SessionHeader.Add('Authorization',('Basic {0}' -f $HeaderAuth))
$SessionHeader.Add('Accept','application/json')
$SessionHeader.Add('Content-Type','application/json')

# PUT KIUWAN ID HERE <<
$SessionHeader.Add('X-KW-CORPORATE-DOMAIN-ID','PutDomainIdHere')

$URL = "https://api.kiuwan.com/users"
$APIResponse = Invoke-RestMethod -Method Get -Uri $URL -Headers  $Sessionheader -Verbose -TimeoutSec 33

$KiuwanUsers = $APIResponse.username
$KiuwanADusers = (Get-ADGroupMember KiuwanSSO-users | Get-Aduser).UserPrincipalName

## CHECK IF WE NEED TO ADD SOMEONE TO AD GROUP AND DO IT
ForEach ($KiuwanUser in $KiuwanUsers){
if ($KiuwanADusers -contains $KiuwanUser){
write-host $KiuwanUser " already is added on AD side." -ForegroundColor Green
} elseif ($KiuwanADusers -notcontains $KiuwanUser -and $KiuwanUser -match "domain.com") {
write-host $KiuwanUser " will be added to the 'KiuwanSSO-users' AD group." -ForegroundColor Red
$KiuwanUser= $KiuwanUser.Replace("@domain.com","")
Get-ADGroup "KiuwanSSO-users" | Add-ADGroupMember -Members $KiuwanUser -Credential $ADCredential
} else {
write-host $KiuwanUser " is a local account and should not be in the AD group."  -ForegroundColor Yellow
}
}

## CHECK IF WE NEED TO REMOVE SOMEONE FROM AD GROUP AND DO IT
ForEach ($KiuwanADuser in $KiuwanADusers){
if ($KiuwanUsers -notcontains $KiuwanADUser){
Write-Host $KiuwanADuser "will be removed from the 'KiuwanSSO-users'AD group" -ForegroundColor Red
$KiuwanADuser = $KiuwanADuser.Replace("@domain.com","")
Get-ADGroup "KiuwanSSO-users" | Remove-ADGroupMember -Members $KiuwanADuser -Confirm:$false -Credential $ADCredential
}
}