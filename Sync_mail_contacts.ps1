$SourceOUUsers = "" #OU with users in sourse forest
$SourceOUGroups = "" #OU with distributions groups in sourse forest
$TargetOU = "" #there contacts will be stored
$ExchangeServerPSURL = "" #exchange server in target organiization like http://mailserver/PowerShell/
$DC = "" #FQDN of Domain controller it source forest
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeServerPSURL -Authentication Kerberos
Import-PSSession $session
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
Import-Module activedirectory
Get-MailContact -OrganizationalUnit $TargetOU|Set-MailContact -CustomAttribute15 "checking"
$Users = Get-ADUser -Server $DC -filter * -SearchBase $SourceOUUsers -SearchScope Subtree -Properties mail,company,department,l,mobile,physicalDeliveryOfficeName,streetAddress,telephoneNumber,title
$groups = Get-ADGroup -Server $DC -Filter * -SearchBase $SourceOUGroups -SearchScope Subtree -Properties mail,mailNickname
ForEach ($user in $users) {
    New-MailContact -name $user.name -Alias $user.SamAccountName -ExternalEmailAddress $user.mail -OrganizationalUnit $TargetOU
    Set-Contact -Identity $user.name -LastName $user.surname -FirstName $user.givenname -Phone $user.telephoneNumber -MobilePhone $User.mobile -Office $user.physicalDeliveryOfficeName -City $user.l -Title $user.title -Department $user.department -Company $user.company -StreetAddress $user.streetaddress
    Set-MailContact -Identity $user.name -CustomAttribute15 "updated"}
ForEach ($group in $groups) {
    New-MailContact -name $group.name -Alias $group.mailNickname -ExternalEmailAddress $group.mail -OrganizationalUnit $TargetOU
    Set-MailContact -Identity $group.name -CustomAttribute15 "updated"}
Get-MailContact -OrganizationalUnit $TargetOU|
    Where-Object -Property CustomAttribute15 -EQ "checking"|
        Remove-MailContact -Confirm:$false
