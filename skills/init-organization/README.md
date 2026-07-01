# init-organization

Creates a new digital organization oriented by purpose. This skill bootstraps the entire Organization Kit structure: directory layout, constitution, initial state files, and memory files.

## Output Structure

`
organization-name/
â”œâ”€â”€ constitution.md
â”œâ”€â”€ knowledge/
â”‚   â”œâ”€â”€ brand/
â”‚   â”œâ”€â”€ audience/
â”‚   â””â”€â”€ ...
â”œâ”€â”€ memory/
â”‚   â”œâ”€â”€ decisions.md
â”‚   â”œâ”€â”€ learnings.md
â”‚   â””â”€â”€ history.md
â”œâ”€â”€ state/
â”‚   â”œâ”€â”€ status.json
â”‚   â”œâ”€â”€ health.json
â”‚   â”œâ”€â”€ capabilities.json
â”‚   â””â”€â”€ capabilities.md
â”œâ”€â”€ specifications/
â”œâ”€â”€ contracts/
â”œâ”€â”€ work-packages/
â”œâ”€â”€ artifacts/
â””â”€â”€ workspace/
`
"@

Write-File "C:\Users\User\organization-kit\skills/init-organization/prompt.md" @"
You are an Organization Kit initializer. Your task is to create a new digital organization.

If the user does not provide an organization name, ask for it.

Then ask these 8 discovery questions one at a time:
1. What is the mission of this organization?
2. Who is the primary audience?
3. What is the brand voice and tone?
4. What are the core values?
5. What capabilities does the organization need?
6. What languages will the organization operate in?
7. What are the boundaries â€” what will the organization never do?
8. What is the AI stance â€” how should AI act within this organization?

After gathering answers:
1. Create the directory structure
2. Write constitution.md v0.1 with the answers embedded
3. Write initial memory files (decisions.md, learnings.md, history.md)
4. Write initial state files (status.json, health.json, capabilities.json, capabilities.md)
5. Set the organization as active by writing status.json with state = "active"
6. Confirm completion with the organization name and path
