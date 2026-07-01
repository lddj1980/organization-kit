> **⚠️ DEPRECATED**: Esta pasta foi movida para `examples/capability-kits/`.
> Os contratos canônicos ficam em `contracts/`.
> Veja `DEPRECATED.md` para detalhes.

---

# Capability Kits

Os Capability Kits são especialistas.

Cada Kit sabe fazer uma coisa muito bem.
Todos seguem o mesmo protocolo (EKP).
Todos recebem Work Packages e entregam respostas.

## Kits planejados

| Kit | Capacidade | Status |
|-----|------------|--------|
| Website Kit | Presença digital | planejado |
| Content Kit | Produção editorial | planejado |
| SEO Kit | Descoberta orgânica | planejado |
| Music Kit | Identidade sonora | planejado |
| Visual Kit | Identidade visual | planejado |
| Video Kit | Narrativa audiovisual | planejado |
| Newsletter Kit | Relacionamento por email | planejado |
| Analytics Kit | Inteligência de dados | planejado |
| Release Kit | Lançamentos e releases | planejado |

## Estrutura de um Kit

```
{kit-name}/
├── README.md           # o que este kit faz e como funciona
├── constitution.md     # instruções de sistema para a IA do kit
├── protocol.md         # como receber e entregar Work Packages
├── prompts/            # prompts especializados
└── examples/           # exemplos de request/response
```

## Como um Kit funciona

1. Recebe um Work Package (diretório `request/`)
2. Lê a Constitution da organização (presente em `request/context.md`)
3. Executa o trabalho dentro dos limites da Constitution
4. Entrega a resposta em `response/`
5. Sinaliza conclusão (status `in-review`)
6. Nunca atualiza memória ou state diretamente

## Princípio fundamental

Um Kit que produz algo que contradiz a Constitution da organização está falhando — independente da qualidade técnica da entrega.
