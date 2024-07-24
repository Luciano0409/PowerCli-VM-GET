param (
    [string]$vmFilter,
    [string]$user,
    [string]$password,
    [string]$server
)

# Suprimir avisos e definir a configuração do PowerCLI
$WarningPreference = "SilentlyContinue"

#Não compartilhar informações
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Scope Session -Confirm:$false | Out-Null

#Liberar conectar sem certificado:
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

# Convertendo a senha para um SecureString
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $securePassword)

# Conectar ao servidor VMware
$null = Connect-VIServer -Server $server -Credential $cred

# Inicializar a lista de dicionários
$vmList = @()

# Obter os nomes das VMs e armazená-los na lista
Get-VM | ForEach-Object {
    $vm = $_
    $vmName = $_.Name

    if ($vmFilter -and $vmName -ne $vmFilter) {
        return
    }


    # Verifica qual o snapshot mais antigo
    $snapshots = Get-Snapshot -VM $vm
    $oldestSnapshot = $snapshots | Sort-Object -Property Created | Select-Object -First 1
    $snapshotDate = if ($oldestSnapshot) { $oldestSnapshot.Created } else { "No Snapshots" }
    $snapshotCount = $snapshots.Count # Quatidade de snapshot existente


    # Verifica se há nescessidade de consolidação
    $needsConsolidation = if ($vm.NeedsConsolidation) { "True" } else { "False" }


    # Verificar se a maquina esta ligada no host
    $poweredOn = if ($vm.PowerState -eq "PoweredOn") { "True" } else { "False" }


    $vmList += @{
        "{#NAME}" = $vmName
        "poweredOn" = $poweredOn
        "OldestSnapshotDate" = $snapshotDate
        "SnapshotCount" = $snapshotCount
        "NeedsConsolidation" = $needsConsolidation
    }

}

# Exibir a lista
$vmList | ConvertTo-Json

# Desconectar do servidor VMware suprimindo a saída
$null = Disconnect-VIServer -Confirm:$false
