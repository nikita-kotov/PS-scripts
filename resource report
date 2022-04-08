#This script get all managers from special group, find all VM which belongs to these managers and their direct report workers and send them report about resource usage(include snapshots older than 30 days and thick hard drives) and life cycle (we use custom attributes for track this)
#For this script you need create in vSphere VM's Custom Attribute "Owner" and use in for store responcible for this VM person's e-mail

Import-Module VMware.PowerCLI
Import-Module activedirectory
$Username = "userprincipalname" #user with permissions for vSphere and mail service
$Password = 'password'
$Credentials = New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))
$Theme = "Theme"
$SenderEmail = "report sender address"
$SMTPServer = "FQDN for SMTP server"
$SMTPPort = "port"
$vSphereServer = "FQDN for vSphere server"
$ResourcePool = "resource pool" #you get a report for this pool
$ManagersGroupDN = "DN" #Distinguished name of group with  managers
$AdminMail = "e-mail of admin"
Connect-VIServer $vSphereServer -Credential $Credentials
$VMs = get-vm -Location $ResourcePool| Get-Annotation -CustomAttribute "owner" #we use custom attribute "owner" for email of VM's owners
function Add-ResourceReportRow {
    param (
        [Parameter(Mandatory=$true)]
        $VM
    )
    $row = "" | select Owner, Name, PowerState, NumCPU, MemoryGB, HDD_Used, IPAddress
    $row.Owner = (Get-Annotation $VM -CustomAttribute "Owner").value
    $row.Name = $VM
    $row.PowerState = $VM.powerState
    $row.NumCPU = $VM.NumCPU
    $row.MemoryGB = $VM.MemoryGB
    $row.HDD_Used = [math]::Round($VM.get_UsedSpaceGB(),2)
    $row.IPAddress = [string]$VM.Guest.IPAddress
    $script:resourcereport += $row}
function Add-ShapshotReportRow {
    param ($VM)
    get-snapshot $VM |where {$_.created -le (get-date).adddays(-30)} | %{
        $row = "" | Select Owner, VM, SizeGB, Created, Name, Description
        $row.owner = (Get-ADUser $manager).Name
        $row.VM = $_.VM
        $row.SizeGB = [math]::Round($_.SizeGB,2)
        $row.Created = $_.Created
        $row.Name = $_.Name
        $row.Description = $_.Description
        $script:snapshotreport += $row}}
function Add-ThickDiskReportRow {
    param ($VM)
    Get-HardDisk -VM $vm |Where-Object {$_.StorageFormat -ne "thin"} | ForEach-Object {
        $HardDisk = $_
        $row = "" | Select owner, VM, Datastore, HardDisk, HDD_Used, ProvisionType
        $row.Owner = (Get-Annotation $VM -CustomAttribute "Owner").value
        $row.VM = $VM.Name 
        $row.Datastore = $HardDisk.Filename.Split("]")[0].TrimStart("[") 
        $row.HardDisk = $HardDisk.Name 
        $row.HDD_Used = $HardDisk.CapacityGB
        $row.ProvisionType = $HardDisk.StorageFormat 
        $script:diskreport += $row}}
function New-ManagerReport {
    param (
        [Parameter(Mandatory=$true)]
        $manager
    )
    $Mail = (Get-ADUser $manager -Properties mail).mail
    $Body = ""
    $script:resourcereport = @()
    $script:snapshotreport = @()
    $script:diskreport = @()
    $DirectReports = Get-ADUser $manager -Properties directreports|select-object -ExpandProperty DirectReports
    $OwnerVMs = $VMs|where {$_.value -eq $Mail}
        foreach ($VM in $OwnerVMs.AnnotatedEntity) {
        add-ResourceReportRow -VM $VM
        add-ShapshotReportRow -vm $VM
        add-ThickDiskReportRow -vm $VM}
        ForEach ($user in $DirectReports) {
            $owner = (Get-ADUser $user -Properties mail).mail
            $Name = (Get-ADUser $user).Name
            $OwnerVMs = $VMs|where {$_.value -eq $owner}
            foreach ($VM in $OwnerVMs.AnnotatedEntity) {
                add-ResourceReportRow $VM
                add-ShapshotReportRow $VM
                add-ThickDiskReportRow $VM}}
            $SumCPU = ($resourcereport|Measure-Object -sum -property numcpu).sum
            $SumMem = ($resourcereport|Measure-Object -sum -property MemoryGB).sum
            $SumHDD = ($resourcereport|Measure-Object -sum -property HDD_Used).sum
            $SumSnapshotHDD = ($snapshotreport|Measure-Object -sum -property SizeGB).sum
            $SumThickHDD = ($diskreport|Measure-Object -sum -property HDD_Used).sum
            $Body = $Body + "<br />" + "  " + "Provisioned CPU: $SumCPU core"
            $Body = $Body + "<br />" + "  " + "Provisioned Memory: $SumMem GB"
            $Body = $Body + "<br />" + "  " + "Provisioned space on disks for VM: $SumHDD GB"
            $Body = $Body + "<br />" + "  " + "Old snapshot usage: $SumSnapshotHDD GB"
            $Body = $Body + "<br />" + "  " + "ThickHDD usage: $SumThickHDD GB"
            $Body = $Body + "<br />" + "Resource usage report" + ([PSCustomobject]$resourcereport| ConvertTo-Html -Fragment -As Table)
            $Body = $Body + "<br />" + "Old Snapshots report" + ([PSCustomobject]$snapshotreport| ConvertTo-Html -Fragment -As Table)
            $Body = $Body + "<br />" + "Thick drives report" + ([PSCustomobject]$diskreport| ConvertTo-Html -Fragment -As Table)
            Send-MailMessage -From $SenderEmail -to $AdminMail,$Mail -Subject $Theme -BodyAsHtml $Body -Credential $Credentials -SmtpServer $SMTPServer -Port $SMTPPort -Encoding utf8}
$managers = Get-ADGroupMember $ManagersGroupDN -Recursive
	ForEach ($manager in $managers) {New-ManagerReport -manager $manager}
