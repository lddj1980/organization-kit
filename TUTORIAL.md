# Tutorial Organization Kit v1.0

Guia passo a passo para usar o Organization Kit com um projeto real.

> Este tutorial usa o exemplo **Luna Waves** — um projeto musical minimalista — mas os mesmos passos funcionam para qualquer organização digital.

---

## O que você vai construir

Um projeto Organization Kit completo, com:

- Constituição, brand e audience documentados
- Um Work Package `website-kit` chamado `build-website`
- Entrega simulada em `response/`
- Review técnico e estratégico
- Artefatos aceitos em `artifacts/`
- Estado consolidado em `state/organization.json`

---

## Pré-requisitos

- Windows, Linux ou macOS
- PowerShell 5.1+ (Windows, nativo) ou PowerShell 7+ / `pwsh` (Linux/macOS — [instale aqui](https://learn.microsoft.com/powershell/scripting/install/installing-powershell))
- Bash (Linux/macOS/Windows com Git Bash) — usado apenas pelo `setup.sh`

> Todos os scripts em `scripts/` (`init-project.ps1`, `create-work-package.ps1`, etc.) rodam em PowerShell nos três sistemas. No Windows use `.\scripts\...\arquivo.ps1`; no Linux/macOS use `pwsh ./scripts/.../arquivo.ps1`.

---

## 1. Instalar o framework

O Organization Kit não precisa ser "instalado" globalmente. Basta clonar/copiar o repositório e rodar o setup para o seu agente/IDE.

### Windows (cmd)

```cmd
setup.bat C:\projetos\luna-waves
```

### Windows (PowerShell)

```powershell
.\setup.ps1 -Integration claude
# ou, para instalar no projeto alvo:
.\setup.ps1 -TargetPath "C:\projetos\luna-waves"
```

### Linux/macOS

```bash
./setup.sh --integration claude
```

Isso copia os comandos canônicos de `commands/` para `.claude/commands/` (ou outro adapter escolhido).

> A fonte canônica dos comandos é `commands/`. Se você precisar editar um comando, edite lá e reexecute o setup.

---

## 2. Inicializar a organização

Crie o projeto Luna Waves:

```powershell
# Windows
.\scripts\init-project.ps1 -OrganizationName "Luna Waves" -TargetPath "C:\projetos"
```

```bash
# Linux/macOS
pwsh ./scripts/init-project.ps1 -OrganizationName "Luna Waves" -TargetPath "/home/user/projetos"
```

Isso cria:

```text
luna-waves/
├── constitution.md
├── knowledge/
│   ├── brand/
│   └── audience/
├── specifications/
├── work-packages/
├── artifacts/
├── memory/
│   ├── decisions.md
│   ├── history.md
│   └── learnings.md
├── state/
│   ├── organization.json      ← estado consolidado
│   ├── status.json
│   ├── capabilities.json
│   └── health.json
└── workspace/
```

---

## 3. Preencher o conhecimento organizacional

O Work Package `website-kit` exige quatro inputs obrigatórios:

- `constitution.md`
- `knowledge/brand/brand.md`
- `knowledge/audience/audience.md`
- `specifications/website-spec.md`

### 3.1 Constitution

Edite `luna-waves/constitution.md`:

```markdown
# Constitution — Luna Waves
## Version 0.1

## 1. Who we are
Luna Waves is a minimalist ambient electronic music project.

## 2. Why we exist
Mission: to create meditative soundscapes that help people slow down.

## 3. Who we speak to
Audience: adults 25-45 who practice meditation and mindfulness.

## 4. How we speak
Calm, reflective, unhurried. We never shout.

## 5. What we value
Depth over volume. Atmosphere over energy.

## 6. Our capabilities
Music production, visual identity, digital presence.

## 7. Our languages
Portuguese (primary), English (secondary).

## 8. What we will never do
Aggressive marketing, clickbait, trend-chasing.
```

### 3.2 Brand

Edite `luna-waves/knowledge/brand/brand.md`:

```markdown
# Brand — Luna Waves
Voice: calm, minimalist, reflective.
Color palette: deep blues, muted grays.
Typography: clean sans-serif.
Logo concept: minimalist wave form.
```

### 3.3 Audience

Edite `luna-waves/knowledge/audience/audience.md`:

```markdown
# Audience — Luna Waves
Primary: meditation practitioners, 25-45.
Secondary: ambient music listeners.
Platform: Spotify, Bandcamp, Instagram.
```

### 3.4 Website specification

Edite `luna-waves/specifications/website-spec.md`:

```markdown
# Website Specification — Luna Waves
## Pages
- Home: minimal hero with music player
- About: artist story
- Music: discography
- Contact: booking and press

## Technical requirements
- Mobile-first responsive
- Minimal JS, fast loading
- SEO meta for each page
```

---

## 4. Criar um Work Package

Agora que os inputs existem, crie o Work Package:

```powershell
# Windows
.\scripts\create-work-package.ps1 `
    -Kit "website-kit" `
    -Name "build-website" `
    -ProjectPath "C:\projetos\luna-waves"
```

```bash
# Linux/macOS
pwsh ./scripts/create-work-package.ps1 \
    -Kit "website-kit" \
    -Name "build-website" \
    -ProjectPath "/home/user/projetos/luna-waves"
```

O script:

- Carrega `contracts/website-kit/contract.yaml`
- Verifica se o kit existe no `registry/capabilities.yaml`
- Copia os inputs para `work-packages/0001-build-website/request/`
- Cria o scaffolding em `work-packages/0001-build-website/response/`
- Registra o WP em `state/organization.json.work_packages.active`

Saída esperada:

```text
Work Package created: 0001-build-website
Status: READY FOR EXECUTION
```

---

## 5. Simular a entrega do Capability Kit

Em um fluxo real, um agente/kit leria `request/` e preencheria `response/`. Neste tutorial, simulamos a entrega manualmente.

Crie os arquivos de entrega:

```powershell
# Windows
$wp = "C:\projetos\luna-waves\work-packages\0001-build-website"

# Página inicial
"<!DOCTYPE html><html><head><title>Luna Waves</title></head><body><h1>Luna Waves</h1></body></html>" |
    Set-Content "$wp\response\website\index.html" -Encoding utf8

# Sobre
"<!DOCTYPE html><html><head><title>About</title></head><body><p>Artist story.</p></body></html>" |
    Set-Content "$wp\response\website\about.html" -Encoding utf8

# Documentação
"# Documentation`nWebsite built with HTML and CSS." |
    Set-Content "$wp\response\documentation\README.md" -Encoding utf8

# Report
@"
# Implementation Report — Luna Waves Website

## Objective
Build a minimal website for Luna Waves ambient music project.

## Decisions
- Used semantic HTML5 for accessibility
- Mobile-first responsive design
- No JavaScript dependencies for core pages
- SEO meta tags on all pages

## Delivered pages
- index.html — Home
- about.html — Artist story

## Status
All required pages delivered. Responsive layout implemented.
Brand voice maintained: calm, minimal. No aggressive CTAs.
"@ | Set-Content "$wp\response\report.md" -Encoding utf8
```

```bash
# Linux/macOS
wp="/home/user/projetos/luna-waves/work-packages/0001-build-website"

# Página inicial
echo '<!DOCTYPE html><html><head><title>Luna Waves</title></head><body><h1>Luna Waves</h1></body></html>' \
    > "$wp/response/website/index.html"

# Sobre
echo '<!DOCTYPE html><html><head><title>About</title></head><body><p>Artist story.</p></body></html>' \
    > "$wp/response/website/about.html"

# Documentação
printf '# Documentation\nWebsite built with HTML and CSS.\n' \
    > "$wp/response/documentation/README.md"

# Report
cat > "$wp/response/report.md" <<'EOF'
# Implementation Report — Luna Waves Website

## Objective
Build a minimal website for Luna Waves ambient music project.

## Decisions
- Used semantic HTML5 for accessibility
- Mobile-first responsive design
- No JavaScript dependencies for core pages
- SEO meta tags on all pages

## Delivered pages
- index.html — Home
- about.html — Artist story

## Status
All required pages delivered. Responsive layout implemented.
Brand voice maintained: calm, minimal. No aggressive CTAs.
EOF
```

---

## 6. Revisar a entrega

Execute o review:

```powershell
# Windows
.\scripts\review-work-package.ps1 `
    -WorkPackage "0001-build-website" `
    -ProjectPath "C:\projetos\luna-waves"
```

```bash
# Linux/macOS
pwsh ./scripts/review-work-package.ps1 \
    -WorkPackage "0001-build-website" \
    -ProjectPath "/home/user/projetos/luna-waves"
```

O script:

- Valida os `expected_outputs` do contrato
- Verifica se há placeholders não substituídos
- Executa o review estratégico (condicionalmente `approved_with_notes` quando há constitution + report.md)
- Gera `review/technical.md`, `review/strategic.md` e `review/review-report.md`
- Atualiza `status.json` e `state/organization.json`

Saída esperada:

```text
Review status: approved_with_notes
Technical score: 0.83
Strategic score: 0.5
```

> O status `approved_with_notes` significa que a entrega passou nos checks técnicos, mas o review estratégico está anotado para confirmação humana.

---

## 7. Aceitar a entrega

Com o status `approved_with_notes`, use `-AllowNotes`:

```powershell
# Windows
.\scripts\accept-work-package.ps1 `
    -WorkPackage "0001-build-website" `
    -ProjectPath "C:\projetos\luna-waves" `
    -AllowNotes
```

```bash
# Linux/macOS
pwsh ./scripts/accept-work-package.ps1 \
    -WorkPackage "0001-build-website" \
    -ProjectPath "/home/user/projetos/luna-waves" \
    -AllowNotes
```

O script:

- Lê `artifact_destination` do contrato
- Copia os artefatos para os destinos mapeados (`artifacts/website/0001-build-website/...`)
- Escreve `provenance.md`
- Atualiza memória, `state/status.json`, `state/capabilities.json` e `state/organization.json`

Saída esperada:

```text
Work Package accepted: 0001-build-website
Artifacts: luna-waves/artifacts/website-kit/0001-build-website/
```

---

## 8. Verificar o estado consolidado

Abra `luna-waves/state/organization.json`:

```json
{
  "organization": {
    "name": "Luna Waves",
    "purpose": "",
    "status": "active"
  },
  "work_packages": {
    "active": [],
    "completed": [],
    "accepted": ["0001-build-website"]
  },
  "artifacts": {
    "0001-build-website": {
      "kit": "website-kit",
      "path": "luna-waves/artifacts/website-kit/0001-build-website",
      "accepted_at": "2026-06-29T17:42:16Z"
    }
  },
  "recent_decisions": [
    {
      "date": "2026-06-29T17:42:16Z",
      "type": "accepted",
      "work_package": "0001-build-website",
      "kit": "website-kit",
      "note": "Artifacts accepted to ..."
    }
  ]
}
```

Também verifique:

```text
artifacts/
└── website/
    └── 0001-build-website/
        ├── website/
        │   ├── index.html
        │   └── about.html
        ├── documentation/
        │   └── README.md
        └── report.md
```

---

## 9. Próximos passos

Depois do primeiro Work Package aceito, você pode:

### Sugerir a próxima ação

Use `/org.next` (ou leia `commands/org.next.md`) para obter uma recomendação baseada em:

- `state/organization.json`
- `registry/capabilities.yaml`
- `memory/decisions.md`
- `constitution.md`

### Evoluir a organização

Use `/org.evolve` para uma análise estratégica completa:

- Coerência de identidade
- Maturidade de capabilities
- Padrões de memória
- Fitness da Constituição

### Criar mais Work Packages

Exemplos:

```powershell
# Windows
.\scripts\create-work-package.ps1 -Kit "content-kit" -Name "write-about-page" -ProjectPath "C:\projetos\luna-waves"
.\scripts\create-work-package.ps1 -Kit "visual-kit" -Name "design-logo" -ProjectPath "C:\projetos\luna-waves"
```

```bash
# Linux/macOS
pwsh ./scripts/create-work-package.ps1 -Kit "content-kit" -Name "write-about-page" -ProjectPath "/home/user/projetos/luna-waves"
pwsh ./scripts/create-work-package.ps1 -Kit "visual-kit" -Name "design-logo" -ProjectPath "/home/user/projetos/luna-waves"
```

---

## 10. Resolução de problemas

### Review retornou `rejected`

Leia `work-packages/<wp>/review/review-report.md` e corrija os itens BLOCKER/ERROR. Depois reexecute o review.

### Review retornou `requires_human_review`

Isso acontece quando não há `constitution.md` ou `report.md`. Preencha ambos e execute o review novamente.

### Accept falhou com `review_status is 'approved_with_notes'`

Use `-AllowNotes`:

```powershell
# Windows
.\scripts\accept-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "C:\projetos\luna-waves" -AllowNotes
```

```bash
# Linux/macOS
pwsh ./scripts/accept-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "/home/user/projetos/luna-waves" -AllowNotes
```

### Kit não encontrado no registry

O `create-work-package.ps1` emite um aviso, mas continua. Para registrar um novo kit, adicione uma entrada em `registry/capabilities.yaml`.

---

## Comandos úteis

```powershell
# Windows — rodar todos os testes
Get-ChildItem tests/*.ps1 | ForEach-Object { powershell -ExecutionPolicy Bypass -File $_.FullName }

# Validar estrutura do projeto
.\scripts\validate-structure.ps1 -ProjectPath "C:\projetos\luna-waves"

# Ler um contrato
.\scripts\read-contract.ps1 -KitName "website-kit" -ContractsDir "contracts"
```

```bash
# Linux/macOS — rodar todos os testes (o loop é PowerShell, por isso via -Command)
pwsh -Command 'Get-ChildItem tests/*.ps1 | ForEach-Object { pwsh -File $_.FullName }'

# Validar estrutura do projeto
pwsh ./scripts/validate-structure.ps1 -ProjectPath "/home/user/projetos/luna-waves"

# Ler um contrato
pwsh ./scripts/read-contract.ps1 -KitName "website-kit" -ContractsDir "contracts"
```

---

## Checklist de fluxo completo

- [ ] Instalar o framework (`setup.bat`, `setup.ps1` ou `setup.sh`)
- [ ] Inicializar a organização (`init-project.ps1`)
- [ ] Criar `constitution.md`, `brand.md`, `audience.md` e `website-spec.md`
- [ ] Criar Work Package (`create-work-package.ps1`)
- [ ] Simular entrega em `response/`
- [ ] Revisar (`review-work-package.ps1`)
- [ ] Aceitar (`accept-work-package.ps1 -AllowNotes`)
- [ ] Verificar `state/organization.json` e `artifacts/`

---

*Este tutorial reflete o Organization Kit v1.0. Para mais detalhes, veja `README.md`, `CLAUDE.md` e `protocol/`.*
