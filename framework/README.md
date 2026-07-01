# Framework

O Framework implementa o Purpose Organization Framework sobre o Protocol (EKP).

## Responsabilidades

- Slash commands — interface de interação
- Templates — estruturas reutilizáveis
- Skills — comportamentos especializados
- Memory — preservação de identidade e aprendizado
- Review — validação técnica e estratégica
- Evolution — análise e sugestão de próximos passos

## Slash Commands

| Comando    | Função                                          |
|------------|-------------------------------------------------|
| `/init`    | Cria uma nova organização                       |
| `/discover`| Descobre e extrai conhecimento da organização   |
| `/spec`    | Cria especificações para um trabalho            |
| `/package` | Transforma especificação em Work Package        |
| `/invoke`  | Entrega Work Package a um Capability Kit        |
| `/review`  | Valida entrega (técnica + estratégica)          |
| `/accept`  | Aceita artefato e atualiza registros            |
| `/learn`   | Registra aprendizado na memória                 |
| `/status`  | Estado atual da organização                     |
| `/health`  | Maturidade das capacidades                      |
| `/next`    | Sugere próxima evolução prioritária             |
| `/evolve`  | Análise completa da organização                 |

## Componentes

```
framework/
├── commands/     # definição de cada slash command
├── templates/    # templates reutilizáveis
├── skills/       # behaviors especializados
└── review/       # protocolo de review
```
