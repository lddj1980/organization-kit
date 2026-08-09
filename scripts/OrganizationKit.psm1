<#
.SYNOPSIS
    OrganizationKit PowerShell Module - shared functions for all org-kit scripts.
.DESCRIPTION
    Import this module in each script with:
        Import-Module (Join-Path $PSScriptRoot "OrganizationKit.psm1") -Force
#>

Set-StrictMode -Version Latest
$script:FrameworkRoot = Split-Path $PSScriptRoot -Parent

# ---------------------------------------------------------------------------
# YAML Extraction Helpers
# ---------------------------------------------------------------------------

function Get-YamlScalar {
    param([string]$Content, [string]$Key)
    if ($Content -match "(?m)^$Key\s*:\s*(.+)$") { return $matches[1].Trim() }
    return $null
}

function script:Get-YamlList {
    <# Extracts a top-level or nested list from YAML content. #>
    param([string]$Content, [string]$Key)
    # Match the key followed by a block of lines starting with at least 1 space + dash
    if ($Content -match "(?ms)(?:^|\n)$Key\s*:\s*\r?\n((?:[ \t]+-[^\r\n]*[\r\n]+)+)") {
        $block = $matches[1]
        return @($block -split '[\r\n]+' |
            Where-Object { $_ -match '^\s+-\s+' } |
            ForEach-Object { ($_ -replace '^\s+-\s+', '').Trim() } |
            Where-Object { $_ -ne '' })
    }
    return @()
}

function script:Get-YamlNestedList {
    <# Extracts a list nested under parent: -> child: #>
    param([string]$Content, [string]$ParentKey, [string]$ChildKey)
    # Grab from ParentKey section onward, then extract ChildKey list
    if ($Content -match "(?ms)^${ParentKey}\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)*)") {
        $section = $matches[1]
        return script:Get-YamlList -Content $section -Key $ChildKey
    }
    return @()
}

function script:Get-ResponseStructureFiles {
    <# Extracts response_structure.files entries with their required flag. #>
    param([string[]]$Lines)
    $files = @()
    $inRespStructure = $false
    $inFiles = $false
    $currentName = $null
    $currentRequired = $false
    $fileIndent = 4

    foreach ($line in $Lines) {
        if ($line -match '^response_structure\s*:') {
            $inRespStructure = $true; continue
        }
        if ($inRespStructure -and $line -match '^\s{2}files\s*:') {
            $inFiles = $true; continue
        }
        if ($inRespStructure -and $line -match '^[a-zA-Z]') {
            if ($currentName) {
                $files += @{ Name = $currentName; Required = $currentRequired }
                $currentName = $null
            }
            break
        }
        if ($inFiles) {
            if ($line -match "^\s{$fileIndent}([\w./\-]+)\s*:") {
                if ($currentName) {
                    $files += @{ Name = $currentName; Required = $currentRequired }
                }
                $currentName = $matches[1].Trim()
                $currentRequired = $false
            }
            elseif ($currentName -and $line -match '^\s{6}required\s*:\s*(true|false)') {
                $currentRequired = ($matches[1] -eq 'true')
            }
        }
    }
    if ($currentName) {
        $files += @{ Name = $currentName; Required = $currentRequired }
    }
    return $files
}

function script:Get-YamlArtifactDestination {
    <#
    .SYNOPSIS
        Extracts artifact_destination block from contract YAML.
    .RETURNS
        PSCustomObject with Default and Mappings hashtable, or $null.
    #>
    param([string]$Content)

    if ($Content -notmatch "(?ms)^artifact_destination\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)+)") {
        return $null
    }
    $block = $matches[1]

    $defaultValue = $null
    if ($block -match "(?m)^\s+default\s*:\s*(.+)$") {
        $defaultValue = $matches[1].Trim()
    }

    $mappings = @{}
    if ($block -match "(?ms)^\s+mappings\s*:\s*\r?\n((?:[ \t]+[^\r\n]+[\r\n]*)+)") {
        $mapBlock = $matches[1]
        foreach ($line in $mapBlock -split '[\r\n]+') {
            if ($line -match '^\s+([\w./\-]+)\s*:\s*(.+)$') {
                $mappings[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }

    return [PSCustomObject]@{
        Default  = $defaultValue
        Mappings = $mappings
    }
}

function script:Get-YamlArtifactBlock {
    <#
    .SYNOPSIS
        Extracts the artifact block from contract YAML.
    .RETURNS
        PSCustomObject with artifact_id, artifact_type, capability, destination,
        initial_version; or $null.
    #>
    param([string]$Content)

    if ($Content -notmatch "(?ms)^artifact\s*:\s*\r?\n((?:[ \t]+[^\r\n]*[\r\n]*)+)") {
        return $null
    }
    $block = $matches[1]
    $artifact = @{}
    foreach ($line in $block -split '[\r\n]+') {
        if ($line -match '^\s+([\w_-]+)\s*:\s*(.+)$') {
            $artifact[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    if (-not $artifact['artifact_type']) { $artifact['artifact_type'] = 'living' }
    return [PSCustomObject]$artifact
}

# ---------------------------------------------------------------------------
# Public: Get-OrgKitContract
# ---------------------------------------------------------------------------

function Get-OrgKitContract {
    <#
    .SYNOPSIS
        Reads a Capability Kit contract.yaml and returns a structured object.
    .PARAMETER Kit
        Kit name (e.g., website-kit, content-kit).
    .PARAMETER ProjectPath
        Organization project path - searched first.
    .PARAMETER WorkPackagePath
        Work-package path - reads the embedded contract.yaml (used in review/accept).
    .EXAMPLE
        $c = Get-OrgKitContract -Kit "website-kit" -ProjectPath "/path/to/luna-waves"
        $c = Get-OrgKitContract -WorkPackagePath "/path/to/luna-waves/work-packages/0001-build-website"
    #>
    param(
        [string]$Kit,
        [string]$ProjectPath,
        [string]$WorkPackagePath,
        [string]$FrameworkPath = $script:FrameworkRoot
    )

    $contractPath = $null

    if ($WorkPackagePath) {
        $contractPath = Join-Path $WorkPackagePath "contract.yaml"
        if (-not (Test-Path $contractPath)) {
            throw "No contract.yaml found in work-package: $WorkPackagePath"
        }
    } elseif ($Kit) {
        $candidates = @()
        if ($ProjectPath) { $candidates += Join-Path $ProjectPath "contracts/$Kit/contract.yaml" }
        $candidates += Join-Path $FrameworkPath "contracts/$Kit/contract.yaml"
        $contractPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $contractPath) {
            throw "Contract not found for kit '$Kit'. Searched: $($candidates -join ', ')"
        }
    } else {
        throw "Provide either -Kit or -WorkPackagePath."
    }

    $raw     = Get-Content $contractPath -Raw
    $lines   = Get-Content $contractPath

    $contract = @{
        SourcePath          = $contractPath
        Kit                 = (Get-YamlScalar $raw 'kit')
        Version             = (Get-YamlScalar $raw 'version')
        Description         = (Get-YamlScalar $raw 'description')
        RequiredInputs      = (script:Get-YamlList   $raw 'required_inputs')
        OptionalInputs      = (script:Get-YamlList   $raw 'optional_inputs')
        ExpectedOutputs     = (script:Get-YamlList   $raw 'expected_outputs')
        TargetProduct       = (Get-YamlScalar $raw 'target_product')
        DeliveryMode        = (Get-YamlScalar $raw 'delivery_mode')
        AcceptanceCriteria  = (script:Get-YamlList   $raw 'acceptance')
        AcceptanceConditions= (script:Get-YamlNestedList $raw 'acceptance_rules' 'conditions')
        AcceptanceActions   = (script:Get-YamlNestedList $raw 'acceptance_rules' 'actions')
        ResponseFiles       = (script:Get-ResponseStructureFiles $lines)
        ArtifactDestination = (script:Get-YamlArtifactDestination $raw)
        Artifact            = (script:Get-YamlArtifactBlock $raw)
    }

    # Metadata as hashtable
    $meta = @{}
    if ($raw -match "(?ms)^metadata\s*:\s*\r?\n((?:[ \t]+[^\r\n]+[\r\n]*)*)") {
        $matches[1] -split '[\r\n]+' | Where-Object { $_ -match '^\s+\w' } | ForEach-Object {
            if ($_ -match '^\s+([\w_-]+)\s*:\s*(.+)') {
                $meta[$matches[1].Trim()] = $matches[2].Trim()
            }
        }
    }
    $contract.Metadata = $meta

    return $contract
}

# ---------------------------------------------------------------------------
# Public: Find-OrgKitInputFile
# ---------------------------------------------------------------------------

function Find-OrgKitInputFile {
    <#
    .SYNOPSIS
        Searches standard project locations for a required input file.
    .RETURNS
        Full path if found, $null if not found.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$InputName,
        [Parameter(Mandatory)]
        [string]$ProjectPath
    )

    $base = [System.IO.Path]::GetFileNameWithoutExtension($InputName)

    # Canonical location table for well-known inputs
    $knownLocations = @{
        'constitution'     = @("constitution.md")
        'brand'            = @("knowledge/brand/brand.md", "knowledge/brand/overview.md", "knowledge/brand.md")
        'audience'         = @("knowledge/audience/audience.md", "knowledge/audience/overview.md", "knowledge/audience.md")
        'seo-requirements' = @("specifications/seo-requirements.md", "knowledge/seo/requirements.md")
        'content-map'      = @("knowledge/content/content-map.md", "specifications/content-map.md")
        'design-system'    = @("knowledge/brand/design-system.md", "knowledge/visual/design-system.md")
    }

    $candidates = @(Join-Path $ProjectPath $InputName)

    if ($knownLocations.ContainsKey($base)) {
        foreach ($rel in $knownLocations[$base]) {
            $candidates += Join-Path $ProjectPath $rel
        }
    } elseif ($base -match '-spec$') {
        $specDir = Join-Path $ProjectPath "specifications"
        if (Test-Path $specDir) {
            $found = Get-ChildItem -Path $specDir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName
            if ($found) { $candidates += $found }
        }
    } else {
        # Generic fallback: search knowledge/ and specifications/
        foreach ($searchDir in @("knowledge", "specifications")) {
            $dir = Join-Path $ProjectPath $searchDir
            if (Test-Path $dir) {
                $found = Get-ChildItem -Path $dir -Filter $InputName -Recurse -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty FullName -First 1
                if ($found) { $candidates += $found }
            }
        }
    }

    return ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
}

# ---------------------------------------------------------------------------
# Public: Get-OrgKitCapabilityRegistry
# ---------------------------------------------------------------------------

function Get-OrgKitCapabilityRegistry {
    <#
    .SYNOPSIS
        Reads registry/capabilities.yaml and returns the raw parsed structure.
    .RETURNS
        Hashtable with schema_version, description, capabilities map.
    #>
    param(
        [string]$ProjectPath,
        [string]$FrameworkPath = $script:FrameworkRoot
    )

    $candidates = @()
    if ($ProjectPath) { $candidates += Join-Path $ProjectPath "registry/capabilities.yaml" }
    $candidates += Join-Path $FrameworkPath "registry/capabilities.yaml"

    $registryPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $registryPath) {
        throw "registry/capabilities.yaml not found. Searched: $($candidates -join ', ')"
    }

    $raw = Get-Content $registryPath -Raw
    $registry = @{
        SourcePath     = $registryPath
        SchemaVersion  = (Get-YamlScalar $raw 'schema_version')
        Description    = (Get-YamlScalar $raw 'description')
        Capabilities   = @{}
    }

    # Parse top-level capability keys under capabilities:
    if ($raw -match "(?ms)^capabilities\s*:\s*\r?\n((?:[ \t]+[^\r\n]+[\r\n]*)+)") {
        $capBlock = $matches[1]
        $currentCap = $null
        foreach ($line in $capBlock -split '[\r\n]+') {
            if ($line -match '^\s+([a-zA-Z0-9_-]+)\s*:\s*$') {
                $capName = $matches[1].Trim()
                if ($capName -eq 'depends_on') {
                    # This is a list under the current capability; do not treat as a new capability.
                    continue
                }
                $currentCap = $capName
                $registry.Capabilities[$currentCap] = @{}
            }
            elseif ($currentCap -and $line -match '^\s+([\w_-]+)\s*:\s*(.+)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                if ($key -eq 'depends_on') {
                    # depends_on is a list; we will parse it separately below if needed.
                    $registry.Capabilities[$currentCap][$key] = @()
                } else {
                    $registry.Capabilities[$currentCap][$key] = $value
                }
            }
            elseif ($currentCap -and $line -match '^\s+-\s+(.+)$') {
                $listValue = $matches[1].Trim()
                if (-not $registry.Capabilities[$currentCap].ContainsKey('depends_on')) {
                    $registry.Capabilities[$currentCap]['depends_on'] = @()
                }
                $registry.Capabilities[$currentCap]['depends_on'] += $listValue
            }
        }
    }

    return $registry
}

function Get-OrgKitCapabilityForKit {
    <#
    .SYNOPSIS
        Finds the capability entry in registry whose kit matches the given kit name.
    .RETURNS
        Hashtable with capability name and entry, or $null.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Kit,
        [string]$ProjectPath
    )

    try {
        $registry = Get-OrgKitCapabilityRegistry -ProjectPath $ProjectPath
    } catch {
        return $null
    }

    foreach ($capName in $registry.Capabilities.Keys) {
        $entry = $registry.Capabilities[$capName]
        if ($entry['kit'] -eq $Kit) {
            return @{ Name = $capName; Entry = $entry }
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Public: Get-OrgKitOrganizationJson
# ---------------------------------------------------------------------------

function Get-OrgKitOrganizationJson {
    <#
    .SYNOPSIS
        Reads state/organization.json, creating the canonical minimal structure if missing.
    .RETURNS
        PSCustomObject representing organization state.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath
    )

    $stateDir  = Join-Path $ProjectPath "state"
    $stateFile = Join-Path $stateDir "organization.json"

    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    if (Test-Path $stateFile) {
        $json  = Get-Content $stateFile -Raw
        $state = $json | ConvertFrom-Json
        # Ensure legacy files have all canonical keys
        $canonicalKeys = @('organization','constitution','capabilities','products','health','work_packages','artifacts','recent_decisions','updated_at')
        foreach ($key in $canonicalKeys) {
            if (-not $state.PSObject.Properties[$key]) {
                $defaultValue = if ($key -in @('capabilities','products','artifacts')) { [PSCustomObject]@{} } elseif ($key -eq 'recent_decisions') { @() } elseif ($key -eq 'work_packages') { [PSCustomObject]@{ active = @(); completed = @(); accepted = @() } } elseif ($key -eq 'organization') { [PSCustomObject]@{ name = ""; purpose = ""; status = "active" } } elseif ($key -eq 'constitution') { [PSCustomObject]@{ exists = $false; last_updated = "" } } elseif ($key -eq 'health') { [PSCustomObject]@{} } else { "" }
                $state | Add-Member -MemberType NoteProperty -Name $key -Value $defaultValue -Force
            }
        }
        return $state
    }

    $state = [PSCustomObject]@{
        organization     = [PSCustomObject]@{ name = ""; purpose = ""; status = "active" }
        constitution     = [PSCustomObject]@{ exists = $false; last_updated = "" }
        capabilities     = [PSCustomObject]@{}
        products         = [PSCustomObject]@{}
        health           = [PSCustomObject]@{}
        work_packages    = [PSCustomObject]@{ active = @(); completed = @(); accepted = @() }
        artifacts        = [PSCustomObject]@{}
        recent_decisions = @()
        updated_at       = ""
    }
    $state | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Encoding utf8
    return $state
}

# ---------------------------------------------------------------------------
# Public: Update-OrgKitOrganizationJson
# ---------------------------------------------------------------------------

function Update-OrgKitOrganizationJson {
    <#
    .SYNOPSIS
        Reads state/organization.json, applies updates (hashtable), and saves.
    .PARAMETER Updates
        Hashtable of top-level keys to update/add. Supports dot-notation for nested
        keys: @{ 'work_packages.accepted' = @('0001-build-website') }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [hashtable]$Updates = @{},
        [switch]$EnsureExists
    )

    $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath

    foreach ($key in $Updates.Keys) {
        if ($key -match '\.') {
            # Nested update: e.g. "work_packages.accepted"
            $parts  = $key -split '\.', 2
            $parent = $parts[0]
            $child  = $parts[1]
            if ($state.PSObject.Properties[$parent]) {
                $state.$parent | Add-Member -MemberType NoteProperty -Name $child -Value $Updates[$key] -Force
            } else {
                $state | Add-Member -MemberType NoteProperty -Name $parent -Value ([PSCustomObject]@{ $child = $Updates[$key] }) -Force
            }
        } else {
            $state | Add-Member -MemberType NoteProperty -Name $key -Value $Updates[$key] -Force
        }
    }

    $state | Add-Member -MemberType NoteProperty -Name 'updated_at' -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') -Force
    $state | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $ProjectPath "state/organization.json") -Encoding utf8
}

# ---------------------------------------------------------------------------
# Public: Add-OrgKitActiveWorkPackage
# ---------------------------------------------------------------------------

function Add-OrgKitActiveWorkPackage {
    <#
    .SYNOPSIS
        Adds a work-package ID to organization.json.work_packages.active if not present.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$WorkPackageId
    )

    $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath
    $active = [System.Collections.ArrayList]@($state.work_packages.active)
    if (-not $active.Contains($WorkPackageId)) {
        $active.Add($WorkPackageId) | Out-Null
    }

    Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{
        'work_packages.active' = @($active)
        'work_packages.completed' = @($state.work_packages.completed)
        'work_packages.accepted' = @($state.work_packages.accepted)
    }
}

# ---------------------------------------------------------------------------
# Public: Move-OrgKitWorkPackageToAccepted
# ---------------------------------------------------------------------------

function Move-OrgKitWorkPackageToAccepted {
    <#
    .SYNOPSIS
        Removes a work-package ID from active and adds it to accepted.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$WorkPackageId
    )

    $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath
    $active = [System.Collections.ArrayList]@($state.work_packages.active)
    $accepted = [System.Collections.ArrayList]@($state.work_packages.accepted)

    while ($active.Contains($WorkPackageId)) { $active.Remove($WorkPackageId) | Out-Null }
    if (-not $accepted.Contains($WorkPackageId)) {
        $accepted.Add($WorkPackageId) | Out-Null
    }

    Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{
        'work_packages.active' = @($active)
        'work_packages.completed' = @($state.work_packages.completed)
        'work_packages.accepted' = @($accepted)
    }
}

# ---------------------------------------------------------------------------
# Public: Add-OrgKitArtifact
# ---------------------------------------------------------------------------

function Add-OrgKitArtifact {
    <#
    .SYNOPSIS
        Registers an accepted artifact in organization.json.artifacts.
    #>
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [string]$WorkPackageId,
        [Parameter(Mandatory)] [string]$Kit,
        [Parameter(Mandatory)] [string]$ArtifactPath,
        [string]$ArtifactId = '',
        [string]$ArtifactType = 'living',
        [string]$Version = '',
        [string]$Capability = '',
        [string]$VersionStorage = 'snapshot'
    )

    $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath
    $artifacts = $state.artifacts
    if (-not $artifacts) { $artifacts = [PSCustomObject]@{} }

    $artifacts | Add-Member -MemberType NoteProperty -Name $WorkPackageId -Value ([PSCustomObject]@{
        kit             = $Kit
        artifact_id     = $ArtifactId
        artifact_type   = $ArtifactType
        version         = $Version
        version_storage = $VersionStorage
        capability      = $Capability
        path            = $ArtifactPath
        accepted_at     = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    }) -Force

    Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{
        'artifacts' = $artifacts
    }
}

# ---------------------------------------------------------------------------
# Public: Artifact helpers
# ---------------------------------------------------------------------------

function Get-OrgKitArtifactManifest {
    <#
    .SYNOPSIS
        Reads artifacts/<artifact_id>/artifact.yaml if it exists.
    #>
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [string]$ArtifactId
    )

    $artifactFile = Join-Path $ProjectPath "artifacts/$ArtifactId/artifact.yaml"
    if (-not (Test-Path $artifactFile)) { return $null }

    $raw = Get-Content $artifactFile -Raw
    return [PSCustomObject]@{
        Path               = $artifactFile
        ArtifactId         = (Get-YamlScalar $raw 'artifact_id')
        ArtifactType       = (Get-YamlScalar $raw 'artifact_type')
        Capability         = (Get-YamlScalar $raw 'capability')
        Status             = (Get-YamlScalar $raw 'status')
        CurrentVersion     = (Get-YamlScalar $raw 'current_version')
        CurrentPath        = (Get-YamlScalar $raw 'current_path')
        SourceWorkPackages = (script:Get-YamlList $raw 'source_work_packages')
        LastUpdated        = (Get-YamlScalar $raw 'last_updated')
        Raw                = $raw
    }
}

function Update-OrgKitArtifactManifest {
    <#
    .SYNOPSIS
        Creates or updates artifacts/<artifact_id>/artifact.yaml.
    #>
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [string]$ArtifactId,
        [string]$ArtifactType = 'living',
        [string]$Capability = '',
        [string]$Status = 'active',
        [string]$CurrentVersion = 'v0.1',
        [string]$CurrentPath = '',
        [string]$VersionStorage = 'snapshot',
        [string]$Repository = '',
        [string[]]$SourceWorkPackages = @(),
        [string]$LastUpdated = ''
    )

    $artifactDir = Join-Path $ProjectPath "artifacts/$ArtifactId"
    if (-not (Test-Path $artifactDir)) {
        New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    }
    $artifactFile = Join-Path $artifactDir 'artifact.yaml'

    if (-not $CurrentPath) {
        $CurrentPath = if ($ArtifactType -eq 'living') { "artifacts/$ArtifactId/current/" } else { "artifacts/$ArtifactId/" }
    }
    if (-not $LastUpdated) { $LastUpdated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') }

    $swYaml = ($SourceWorkPackages | ForEach-Object { "  - $_" }) -join "`n"
    if (-not $swYaml) { $swYaml = '  - (none)' }

    $repoYaml = if ($Repository) { "repository: $Repository`n" } else { '' }

    $yaml = @"
artifact_id: $ArtifactId
artifact_type: $ArtifactType
capability: $Capability
status: $Status
current_version: $CurrentVersion
current_path: $CurrentPath
version_storage: $VersionStorage
${repoYaml}source_work_packages:
$swYaml
last_updated: $LastUpdated
"@

    $yaml | Set-Content $artifactFile -Encoding utf8
    return $artifactFile
}

function Update-OrgKitArtifactHistory {
    <#
    .SYNOPSIS
        Appends a version entry to artifacts/<artifact_id>/history.md.
    #>
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [Parameter(Mandatory)] [string]$ArtifactId,
        [Parameter(Mandatory)] [string]$Version,
        [Parameter(Mandatory)] [string]$WorkPackageId,
        [string]$Summary = ''
    )

    $artifactDir = Join-Path $ProjectPath "artifacts/$ArtifactId"
    $historyFile = Join-Path $artifactDir 'history.md'
    if (-not (Test-Path $artifactDir)) {
        New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
    }
    if (-not (Test-Path $historyFile)) {
        "# $ArtifactId History`n" | Set-Content $historyFile -Encoding utf8
    }

    $entry = @"

## $Version — $(Get-Date -Format 'yyyy-MM-dd')

Created from Work Package: $WorkPackageId

Summary:
$Summary
"@
    Add-Content -Path $historyFile -Value $entry -Encoding utf8
    return $historyFile
}

function Get-OrgKitArtifactsJson {
    <#
    .SYNOPSIS
        Reads state/artifacts.json, creating canonical structure if missing.
    #>
    param([Parameter(Mandatory)] [string]$ProjectPath)

    $stateDir = Join-Path $ProjectPath 'state'
    $file = Join-Path $stateDir 'artifacts.json'
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
    if (Test-Path $file) {
        return Get-Content $file -Raw | ConvertFrom-Json
    }
    return [PSCustomObject]@{
        artifacts  = [PSCustomObject]@{}
        updated_at = ''
    }
}

function Update-OrgKitArtifactsJson {
    <#
    .SYNOPSIS
        Adds or replaces entries in state/artifacts.json.
    #>
    param(
        [Parameter(Mandatory)] [string]$ProjectPath,
        [hashtable]$ArtifactEntries = @{}
    )

    $state = Get-OrgKitArtifactsJson -ProjectPath $ProjectPath
    $artifacts = $state.artifacts
    if (-not $artifacts) { $artifacts = [PSCustomObject]@{} }

    foreach ($key in $ArtifactEntries.Keys) {
        $artifacts | Add-Member -MemberType NoteProperty -Name $key -Value $ArtifactEntries[$key] -Force
    }

    $state | Add-Member -MemberType NoteProperty -Name 'artifacts' -Value $artifacts -Force
    $state.updated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    $state | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $ProjectPath 'state/artifacts.json') -Encoding utf8
}

function Get-NextArtifactVersion {
    <#
    .SYNOPSIS
        Returns the next artifact version in vX.Y format.
    #>
    param(
        [string]$CurrentVersion,
        [string]$Action = 'create'
    )

    if ($Action -eq 'create' -or -not $CurrentVersion) { return 'v0.1' }
    if ($CurrentVersion -match '^v(\d+)\.(\d+)$') {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        if ($Action -eq 'update') { return "v$major.$($minor + 1)" }
        return "v$($major + 1).0"
    }
    return 'v0.1'
}

# ---------------------------------------------------------------------------
# Public: Add-OrgKitRecentDecision
# ---------------------------------------------------------------------------

function Add-OrgKitRecentDecision {
    <#
    .SYNOPSIS
        Appends a decision entry to organization.json.recent_decisions (keeps last 20).
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [hashtable]$Decision
    )

    $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath
    $decisions = [System.Collections.ArrayList]@($state.recent_decisions)
    $decisions.Add([PSCustomObject]$Decision) | Out-Null
    if ($decisions.Count -gt 20) {
        $decisions = $decisions[$decisions.Count - 20..($decisions.Count - 1)]
    }

    Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{
        'recent_decisions' = @($decisions)
    }
}

# ---------------------------------------------------------------------------
# Public: Update-OrgKitWorkPackageStatus
# ---------------------------------------------------------------------------

function Update-OrgKitWorkPackageStatus {
    <#
    .SYNOPSIS
        Merges fields into a work-package's status.json.
    .RETURNS
        Updated status as hashtable.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$WpPath,
        [Parameter(Mandatory)]
        [hashtable]$Updates
    )

    $statusFile = Join-Path $WpPath "status.json"

    if (Test-Path $statusFile) {
        $existing = Get-Content $statusFile -Raw | ConvertFrom-Json
        $current  = @{}
        $existing.PSObject.Properties | ForEach-Object { $current[$_.Name] = $_.Value }
    } else {
        $current = @{}
    }

    foreach ($key in $Updates.Keys) { $current[$key] = $Updates[$key] }

    $current | ConvertTo-Json -Depth 5 | Set-Content $statusFile -Encoding utf8
    return $current
}

# ---------------------------------------------------------------------------
# Public: Product helpers
# ---------------------------------------------------------------------------

function Get-OrgKitProductManifest {
    <#
    .SYNOPSIS
        Reads products/<product>/product.yaml if it exists.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$ProductId
    )

    $productDir  = Join-Path $ProjectPath "products/$ProductId"
    $productFile = Join-Path $productDir "product.yaml"

    if (Test-Path $productFile) {
        $raw = Get-Content $productFile -Raw
        return @{
            Path        = $productFile
            Id          = (Get-YamlScalar $raw 'product.id')
            Capability  = (Get-YamlScalar $raw 'product.capability')
            Status      = (Get-YamlScalar $raw 'product.status')
            Version     = (Get-YamlScalar $raw 'product.version')
            CreatedBy   = (Get-YamlScalar $raw 'product.created_by')
            UpdatedBy   = (script:Get-YamlList   $raw 'product.updated_by')
            Raw         = $raw
        }
    }

    return $null
}

function Update-OrgKitProductManifest {
    <#
    .SYNOPSIS
        Creates or updates products/<product>/product.yaml.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$ProductId,
        [Parameter(Mandatory)]
        [string]$Capability,
        [string]$Status = 'active',
        [string]$Version = '1.0.0',
        [string]$CreatedBy = '',
        [string[]]$UpdatedBy = @()
    )

    $productDir  = Join-Path $ProjectPath "products/$ProductId"
    $productFile = Join-Path $productDir "product.yaml"

    if (-not (Test-Path $productDir)) {
        New-Item -ItemType Directory -Path $productDir -Force | Out-Null
    }

    $updatedByYaml = ($UpdatedBy | ForEach-Object { "    - $_" }) -join "`n"
    if (-not $updatedByYaml) { $updatedByYaml = '    - (none)' }

    $yaml = @"
product:
  id: $ProductId
  capability: $Capability
  status: $Status
  version: $Version
  created_by: $CreatedBy
  updated_by:
$updatedByYaml
"@

    $yaml | Set-Content $productFile -Encoding utf8
    return $productFile
}

function Add-OrgKitProductHistoryEntry {
    <#
    .SYNOPSIS
        Appends a version entry to products/<product>/history/versions.md and changes.md.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$ProductId,
        [Parameter(Mandatory)]
        [string]$Version,
        [Parameter(Mandatory)]
        [string]$WorkPackageId,
        [string]$DeliveryMode = 'update',
        [string]$Notes = ''
    )

    $historyDir = Join-Path $ProjectPath "products/$ProductId/history"
    if (-not (Test-Path $historyDir)) {
        New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
    }

    $versionsFile = Join-Path $historyDir "versions.md"
    $changesFile  = Join-Path $historyDir "changes.md"
    $timestamp    = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'

    $versionEntry = @"

## $Version

- Work Package: $WorkPackageId
- Delivery Mode: $DeliveryMode
- Date: $timestamp
- Notes: $Notes
"@

    if (-not (Test-Path $versionsFile)) {
        "# Version History - $ProductId`n" | Set-Content $versionsFile -Encoding utf8
    }
    $versionEntry | Add-Content $versionsFile -Encoding utf8

    $changeEntry = @"

## $timestamp - $Version ($WorkPackageId)

- Mode: $DeliveryMode
- Notes: $Notes
"@

    if (-not (Test-Path $changesFile)) {
        "# Change Log - $ProductId`n" | Set-Content $changesFile -Encoding utf8
    }
    $changeEntry | Add-Content $changesFile -Encoding utf8
}

function Get-SemverBumpForDeliveryMode {
    <#
    .SYNOPSIS
        Returns the next SemVer version given a current version and delivery mode.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$CurrentVersion,
        [Parameter(Mandatory)]
        [string]$DeliveryMode
    )

    $parts = $CurrentVersion -split '\.'
    if ($parts.Count -lt 3) { $parts = @('1', '0', '0') }
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($DeliveryMode.ToLower()) {
        'initial_build' { return '1.0.0' }
        'migration'     { return "$($major + 1).0.0" }
        'update'        { return "$major.$($minor + 1).0" }
        'patch'         { return "$major.$minor.$($patch + 1)" }
        default         { return "$major.$($minor + 1).0" }
    }
}

function Update-OrgKitProductInOrganizationJson {
    <#
    .SYNOPSIS
        Updates the products entry in state/organization.json.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$ProductId,
        [Parameter(Mandatory)]
        [string]$Version,
        [string]$Status = 'active',
        [string]$Capability = '',
        [string]$UpdatedByWp = ''
    )

    $state = Get-OrgKitOrganizationJson -ProjectPath $ProjectPath

    $products = if ($state.PSObject.Properties['products']) { $state.products } else { $null }
    if (-not $products) { $products = [PSCustomObject]@{} }

    $existing = @{}
    if ($products.PSObject.Properties[$ProductId]) {
        $products.$ProductId.PSObject.Properties | ForEach-Object { $existing[$_.Name] = $_.Value }
    }

    $updatedBy = @()
    if ($existing.ContainsKey('updated_by')) {
        $updatedBy = @($existing['updated_by'])
    }
    if ($UpdatedByWp -and -not $updatedBy.Contains($UpdatedByWp)) {
        $updatedBy += $UpdatedByWp
    }

    $productEntry = [PSCustomObject]@{
        version    = $Version
        status     = $Status
        capability = if ($Capability) { $Capability } else { $existing['capability'] }
        updated_by = $updatedBy
        updated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    }

    $products | Add-Member -MemberType NoteProperty -Name $ProductId -Value $productEntry -Force

    Update-OrgKitOrganizationJson -ProjectPath $ProjectPath -Updates @{
        'products' = $products
    }
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

Export-ModuleMember -Function `
    Get-YamlScalar, `
    Get-OrgKitContract, `
    Find-OrgKitInputFile, `
    Get-OrgKitCapabilityRegistry, `
    Get-OrgKitCapabilityForKit, `
    Get-OrgKitOrganizationJson, `
    Update-OrgKitOrganizationJson, `
    Add-OrgKitActiveWorkPackage, `
    Move-OrgKitWorkPackageToAccepted, `
    Add-OrgKitArtifact, `
    Add-OrgKitRecentDecision, `
    Update-OrgKitWorkPackageStatus, `
    Get-OrgKitProductManifest, `
    Update-OrgKitProductManifest, `
    Add-OrgKitProductHistoryEntry, `
    Get-SemverBumpForDeliveryMode, `
    Update-OrgKitProductInOrganizationJson, `
    Get-OrgKitArtifactManifest, `
    Update-OrgKitArtifactManifest, `
    Update-OrgKitArtifactHistory, `
    Get-OrgKitArtifactsJson, `
    Update-OrgKitArtifactsJson, `
    Get-NextArtifactVersion
