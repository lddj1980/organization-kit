# Memory Standard

Este documento define o padrão para memória organizacional no Organization Kit.

## Estrutura de Memória

```
memory/
├── decisions.md       # log de decisões importantes
├── history.md         # histórico cronológico de eventos
├── lessons.md         # aprendizados extraídos
├── brand.json         # estado atual da marca
├── audience.json      # estado atual do público
└── capabilities.json  # estado atual das capacidades
```

## decisions.md

Log de decisões importantes tomadas pela organização.

### Estrutura

```markdown
# Decisions Log — {Organization Name}

*Created: {date} | Constitution: v{version}*

## Decision Template

### {Date} — {Decision Title}

**Context:** Why was this decision needed?

**Alternatives Considered:**
1. Alternative A — pros/cons
2. Alternative B — pros/cons
3. Alternative C — pros/cons

**Decision Made:** {description of decision}

**Rationale:** Why this decision?

**Constitution Reference:** Which part of Constitution informed this?

**Impact:** What changes as a result?

**Tags:** [tag1, tag2, tag3]

---

## Example Decisions

### 2026-06-29 — Use Open Source for Website

**Context:** Need to decide between proprietary CMS or open-source solution for our website.

**Alternatives Considered:**
1. WordPress — Established, but requires hosting and maintenance
2. Netlify + Hugo — Static, fast, but less flexible
3. Custom build — Maximum control, but high maintenance cost

**Decision Made:** Use Hugo + Netlify for static site.

**Rationale:** 
- Aligns with value of "authenticity and simplicity"
- Low maintenance overhead allows focus on music
- Fast performance serves our audience well
- Cost-effective for bootstrapping organization

**Constitution Reference:** Section 7 (Our languages) — "we prioritize direct connection over platform lock-in"

**Impact:** 
- Website will be built with Hugo
- Content will be in Markdown
- Deployed to Netlify
- Future work package: wp-2026-001

**Tags:** [technical, platform, website, infrastructure]

### 2026-07-05 — Release Music Every Month

**Context:** Need a consistent release cadence to build audience.

**Alternatives Considered:**
1. Quarterly releases — Lower pressure, harder to build momentum
2. Monthly releases — Consistent, higher pressure
3. Weekly releases — Very consistent, unsustainable

**Decision Made:** Release new music every month.

**Rationale:**
- Aligns with mission of "creating moments of connection"
- Monthly cadence balances quality and quantity
- Gives audience something to look forward to
- Feeds our content strategy

**Constitution Reference:** Section 2 (Why we exist) — "we exist to create moments of connection through music"

**Impact:**
- Calendar: 12 releases per year
- Need: music-kit capability mature
- Need: content-kit for promotion
- Schedule announced on website

**Tags:** [strategy, music, calendar, capability]

```

### Regras

1. **Decisões importantes** — não registrar micro-decisões
2. **Constitution reference** — sempre referenciar a parte relevante
3. **Alternativas** — listar alternativas consideradas
4. **Rationale** — explicar "por que" essa decisão
5. **Impacto** — o que muda na organização
6. **Tags** — facilitar busca posterior

## history.md

Histórico cronológico de eventos importantes.

### Estrutura

```markdown
# History — {Organization Name}

*Created: {date} | Constitution: v{version}*

## 2026

### June 2026

#### 2026-06-29 — Organization Initialized
- Created via `/org.init`
- Constitution v0.1 (draft) created
- Initial capabilities defined: music, website, content
- State: bootstrapping

#### 2026-06-30 — Brand Discovery Completed
- Completed `/org.discover brand`
- Brand profile documented
- Voice and tone defined
- State: bootstrapping

#### 2026-07-01 — Website Specification Created
- Completed `/org.spec website`
- Website structure defined
- Work package wp-2026-001 created
- State: active

#### 2026-07-02 — First Website Launched
- wp-2026-001 accepted
- Website live at luna-waves.com
- Capability: website → developing
- State: active

### July 2026

#### 2026-07-05 — Monthly Release Strategy Adopted
- Decision recorded in decisions.md
- Release calendar created
- Music-kit capability prioritized
- State: active

#### 2026-07-10 — First Single Released
- wp-2026-002 accepted
- Single "Connection" released
- Capability: music → developing
- State: active

#### 2026-07-15 — Constitution v0.2
- Revision based on learnings
- Values refined
- Capabilities updated
- State: evolving

#### 2026-07-20 — Constitution v0.2 Approved
- Revision reviewed and accepted
- State: active

## 2026 Statistics

- Work Packages: 15 created, 12 accepted
- Capabilities Mature: 0
- Capabilities Developing: 3 (website, music, content)
- Constitution Version: 0.2
- Active Work Packages: 3
```

### Regras

1. **Cronológico** — eventos em ordem temporal
2. **Conciso** — descrições curtas e claras
3. **Links** — referenciar work packages e decisões
4. **Resumos** — incluir resumos mensais/anuais
5. **Estados** — registrar mudanças de estado da organização

## lessons.md

Aprendizados extraídos de work packages e experiência.

### Estrutura

```markdown
# Lessons — {Organization Name}

*Created: {date} | Constitution: v{version}*

## Lessons from Work Packages

### wp-2026-001 — Website Build

#### What Worked Well
- Brief was clear and complete
- Website kit delivered on spec
- Technical review identified accessibility improvements early
- Strategic review confirmed brand alignment

#### What Could Be Improved
- Should have included SEO requirements in brief
- Content mapping would have sped up copywriting
- Design system could have been more detailed

#### Learning
Include SEO requirements and content mapping in all future website briefs.

#### Applied To
- wp-2026-005 (blog launch)
- wp-2026-008 (redesign)

---

### wp-2026-003 — First Music Release

#### What Worked Well
- Music kit delivered high-quality tracks
- Brief captured creative direction well
- Strategic review confirmed mission alignment

#### What Could Be Improved
- Release timeline was too aggressive
- Promotion strategy wasn't detailed enough
- Should have started promotion 2 weeks earlier

#### Learning
Allow 2 weeks of promotion for each music release.

#### Applied To
- All subsequent music releases (wp-2026-006 onwards)

---

## Lessons from Organizational Evolution

### Constitution Revision v0.1 → v0.2

#### What We Learned
- Our values evolved as we acted
- "Authenticity" became more nuanced
- "Simplicity" needed better definition
- Audience understanding deepened

#### What Changed
- Values refined from 4 to 5
- Added "direct connection" as core principle
- Clarified boundaries around content types
- Expanded mission statement

#### Learning
Constitution is living document — revision is natural and healthy.

#### Applied To
- Scheduled quarterly constitution reviews
- Constitution v0.3 planned for Q4 2026

---

## Cross-Cutting Patterns

### 1. Brief Quality Predicts Success
- Work packages with complete, detailed briefs have 90% acceptance rate
- Incomplete briefs have 40% acceptance rate
- Pattern consistent across all capabilities

### 2. Strategic Review Often Reveals Brand Drift
- Technical reviews rarely find brand issues
- Strategic reviews identify brand inconsistencies 30% of time
- Early strategic review saves rework

### 3. Capability Maturity Requires Iteration
- First work package: learning
- Second work package: refinement
- Third+ work package: mastery
- Pattern consistent across all capabilities

### 4. Constitution Provides North Star
- When in doubt, Constitution provides answer
- Decisions referencing Constitution have 95% satisfaction rate
- Constitution violations always lead to rework

## Lessons for Future

1. **Invest in briefs** — time spent on brief pays off in acceptance
2. **Do strategic review early** — catch brand issues before implementation
3. **Iterate to mastery** — expect first attempts to be learning experiences
4. **Trust the Constitution** — it's your best guide for alignment
```

### Regras

1. **Work package focused** — cada lição deve vir de um work package
2. **Actionable** — cada lição deve poder ser aplicada
3. **Applied to** — documentar onde foi aplicado
4. **Patterns** — identificar padrões cross-cutting
5. **Positive and negative** — incluir o que funcionou e o que não

## brand.json

Estado atual da marca em JSON.

### Estrutura

```json
{
  "version": "1.0.0",
  "last_updated": "2026-07-20T10:00:00Z",
  "name": "Luna Waves",
  "tagline": "Moments of connection through music",
  "voice": {
    "tone": ["authentic", "intimate", "thoughtful", "warming"],
    "style": "conversational but not casual",
    "examples": {
      "do": [
        "We believe music connects us all",
        "Thank you for being part of this journey",
        "This song came from a moment of quiet reflection"
      ],
      "dont": [
        "Buy our music now",
        "We're the best band ever",
        "Check out our sick beats"
      ]
    }
  },
  "visual_identity": {
    "colors": {
      "primary": "#2C3E50",
      "secondary": "#E74C3C",
      "accent": "#3498DB",
      "neutral": "#ECF0F1"
    },
    "typography": {
      "headings": "Montserrat",
      "body": "Open Sans"
    },
    "style": "minimal, modern, with warmth"
  },
  "values": [
    "authenticity",
    "connection",
    "simplicity",
    "reflection",
    "directness"
  ],
  "boundaries": [
    "never use clickbait",
    "never buy fake followers",
    "never chase trends that contradict our voice",
    "never compromise artistic integrity for views"
  ],
  "keywords": [
    "authentic",
    "intimate",
    "connection",
    "music",
    "moments",
    "reflection",
    "simplicity"
  ]
}
```

## audience.json

Estado atual do público em JSON.

### Estrutura

```json
{
  "version": "1.0.0",
  "last_updated": "2026-07-20T10:00:00Z",
  "primary_audience": {
    "name": "Authentic Music Seekers",
    "age_range": "18-35",
    "psychographics": [
      "Value authenticity over popularity",
      "Seek meaningful connection through art",
      "Prefer depth over breadth",
      "Appreciate simplicity and honesty"
    ],
    "behaviors": [
      "Discover music through recommendations",
      "Listen to full albums, not just singles",
      "Support artists directly when possible",
      "Share music that means something to them"
    ]
  },
  "secondary_audience": {
    "name": "Casual Listeners",
    "age_range": "25-45",
    "psychographics": [
      "Enjoy music as background",
      "Open to discovering new artists",
      "Follow trends moderately"
    ],
    "behaviors": [
      "Listen to curated playlists",
      "Follow artists on social media",
      "Attend concerts occasionally"
    ]
  },
  "channels": [
    "Spotify",
    "YouTube Music",
    "Instagram",
    "Website",
    "Email newsletter"
  ],
  "preferences": {
    "content_type": ["music", "behind-the-scenes", "artist story", "reflection"],
    "frequency": "monthly releases, weekly updates",
    "tone": "authentic, intimate, not promotional",
    "interaction": "comments, DMs, email replies"
  }
}
```

## capabilities.json

Estado atual das capacidades em JSON.

### Estrutura

```json
{
  "version": "1.0.0",
  "last_updated": "2026-07-20T10:00:00Z",
  "capabilities": {
    "music": {
      "name": "Music Production",
      "maturity": "developing",
      "work_packages_completed": 5,
      "work_packages_accepted": 4,
      "kit": "music-kit",
      "last_work_package": "wp-2026-010",
      "description": "Produce and release original music"
    },
    "website": {
      "name": "Website Development",
      "maturity": "mature",
      "work_packages_completed": 8,
      "work_packages_accepted": 8,
      "kit": "website-kit",
      "last_work_package": "wp-2026-008",
      "description": "Build and maintain website"
    },
    "content": {
      "name": "Content Creation",
      "maturity": "developing",
      "work_packages_completed": 6,
      "work_packages_accepted": 5,
      "kit": "content-kit",
      "last_work_package": "wp-2026-012",
      "description": "Create written and visual content"
    },
    "social": {
      "name": "Social Media",
      "maturity": "nascent",
      "work_packages_completed": 0,
      "work_packages_accepted": 0,
      "kit": null,
      "last_work_package": null,
      "description": "Manage social media presence"
    }
  },
  "statistics": {
    "total_capabilities": 4,
    "nascent": 1,
    "developing": 2,
    "mature": 1,
    "mastered": 0,
    "total_work_packages": 19,
    "accepted_work_packages": 17,
    "acceptance_rate": 0.89
  }
}
```

## Atualização de Memória

### Quando Atualizar

- **decisions.md** — após cada decisão importante
- **history.md** — após cada evento significativo
- **lessons.md** — após cada work package aceito
- **brand.json** — após mudanças na marca
- **audience.json** — após novos insights sobre público
- **capabilities.json** — após cada work package aceito

### Como Atualizar

Use comandos do framework:

```bash
# Após aceitar um work package
/org.accept wp-2026-001

# Após aprender algo novo
/org.learn

# Após tomar decisão
/org.status  # check current state
# Edit decisions.md manually
```

### Validação

```json
{
  "validation": {
    "brand.json": {
      "required": ["name", "voice", "values"],
      "version": "must increment on change"
    },
    "audience.json": {
      "required": ["primary_audience", "channels"],
      "version": "must increment on change"
    },
    "capabilities.json": {
      "required": ["capabilities", "statistics"],
      "version": "must increment on change"
    }
  }
}
```

## Princípios

> **Sem memória, cada work package começa do zero.**
> **Com memória, cada work package constrói sobre o aprendizado.**

A memória organizacional é o que permite que a organização evolua e melhore. Sem ela, estamos condenados a repetir erros e re-descobrir o que já sabemos.

---

*A memória é tão importante quanto a Constitution.*
*Ela registra quem somos e como chegamos até aqui.*