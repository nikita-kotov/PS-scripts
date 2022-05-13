$Folder = "" #path to folder for that you want create a security groups
$OU = "" #organization unit where you want create a security groups
$domainname = "" #name of domain where you want to create a security groups
Get-ChildItem $Folder -Directory|ForEach-Object {
    $Name = $_.name
    $TemplateName = $_.name -replace ",","_"
    $path = $Folder + "\" + $Name
    $RWGroup = $TemplateName + " (RW)"
    $ROGroup = $TemplateName + " (RO)"
    $TRVGroup = $TemplateName + " (TRV)"
    New-ADGroup -Name $RWGroup -GroupScope DomainLocal -GroupCategory Security -Path $OU
    New-ADGroup -Name $ROGroup -GroupScope DomainLocal -GroupCategory Security -Path $OU
    New-ADGroup -Name $TRVGroup -GroupScope DomainLocal -GroupCategory Security -Path $OU
    $TRVRuleFolder = New-Object System.Security.AccessControl.FileSystemAccessRule("$domainname\$TRVGroup", "ReadAndExecute", "None", "None", "Allow")
    $RWRuleFolder = New-Object System.Security.AccessControl.FileSystemAccessRule("$domainname\$RWGroup", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
    $RORuleFolder = New-Object System.Security.AccessControl.FileSystemAccessRule("$domainname\$ROGroup", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl1 = (Get-Item $path).GetAccessControl('Access')
	$acl1.SetAccessRule($TRVRuleFolder)
	Set-Acl $path -AclObject $acl1
    $acl2 = (Get-Item $path).GetAccessControl('Access')
	$acl2.SetAccessRule($RWRuleFolder)
	Set-Acl $path -AclObject $acl2
    $acl3 = (Get-Item $path).GetAccessControl('Access')
	$acl3.SetAccessRule($RORuleFolder)
	Set-Acl $path -AclObject $acl3}
