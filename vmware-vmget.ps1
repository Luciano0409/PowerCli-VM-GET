param (
    [string]$vmFilter,
    [string]$user,
    [string]$password,
    [string]$server,
    [switch]$testConnection
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


# Tentar conectar ao servidor VMware
try {
    $connection = Connect-VIServer -Server $server -Credential $cred -ErrorAction Stop
    if ($testConnection) {
        Disconnect-VIServer -Confirm:$false
        Write-Output "True"
        exit 0
    }
} catch {
    Write-Output "False"
    exit 1
}


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
    $snapshotDateUnix = if ($oldestSnapshot) { [int][double]::Parse((Get-Date $oldestSnapshot.Created -UFormat %s)) } else { 0 } # Formata a data para Unixtime
    $snapshotCount = $snapshots.Count # Quatidade de snapshot existente


    # Verifica se há nescessidade de consolidação
    $needsConsolidation = if ($vm.NeedsConsolidation) { "True" } else { "False" }


    # Verificar se a maquina esta ligada no host
    $poweredOn = if ($vm.PowerState -eq "PoweredOn") { "True" } else { "False" }

    # Adicionar o valores coletados no dicionario
    $vmList += @{
        "{#NAME}" = $vmName
        "poweredOn" = $poweredOn
        "OldestSnapshotDate" = $snapshotDate
        "OldestSnapshotDateUnix" = $snapshotDateUnix
        "SnapshotCount" = $snapshotCount
        "NeedsConsolidation" = $needsConsolidation
    }

}

# Exibir a lista
$vmList | ConvertTo-Json

# Desconectar do servidor VMware suprimindo a saída
$null = Disconnect-VIServer -Confirm:$false
