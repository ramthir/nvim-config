# Neovim Config

## Pandora Notes

Notes live in Pandora. Neovim reads and writes them through Pandora's local API. The behaviour is specified in the Pandora note *Pandora — Neovim Notes* (note 1575).

| To do this | Use |
|---|---|
| Open a note | `:edit pandora://notes/<id>` |
| Open a note, short | `:Note <id>`, or `:note <id>` in lower case |
| Open the note whose number is under the cursor, or be asked for an ID | `:Note` with no ID, or `<leader>no` |
| Save it to Pandora | `:write` |
| Force save over a remote change | `:write!` |
| Reload it from Pandora, discarding local edits | `:edit!` |
| Create a note | `:NotesCreate` or `<leader>nn` |
| Follow a `[[link]]` | `<CR>` on the link |

- `<id>` is the note's number in Pandora. A `[[123]]` link shows the target's title, and the saved text keeps the ID.
- An open note reloads by itself when it is changed elsewhere in Pandora. If you have unsaved edits, they are kept and you get a warning.
- When the live connection returns after an outage, loaded notes are checked for missed changes. Unsaved edits are preserved; a changed remote version triggers a conflict warning.
- If opening or reloading a note fails, normal saves are blocked until `:edit!` successfully reloads it. `:write!` remains an explicit overwrite.
- Copilot attaches to note buffers, so text from your notes is sent to GitHub Copilot as context.
- There is no note search in Neovim.

## Pandora Diagrams

PlantUML diagrams live in Pandora. Neovim reads and writes them through Pandora's diagrams API. The behaviour is specified in the Pandora specification *Pandora — Neovim Diagrams* (note 1695).

| To do this | Use |
|---|---|
| Open a diagram | `:edit pandora://diagrams/<id>` |
| Open a diagram, short | `:Diagram <id>`, or `:diagram <id>` in lower case |
| Open the diagram whose number is under the cursor, or be asked for an ID | `:Diagram` with no ID |
| Save it to Pandora | `:write` |
| Force save over a remote change | `:write!` |
| Reload it from Pandora, discarding local edits | `:edit!` |

- `<id>` is the diagram's number in Pandora.
- Opened diagram buffers use the `plantuml` filetype.
- `:write` checks whether the diagram changed in Pandora since the buffer was loaded or last saved, and refuses to overwrite when it has changed. `:write!` forces the save over the remote change.
- `:edit!` discards unsaved edits and loads the current content from Pandora.
- If opening or reloading a diagram fails, normal saves are blocked until `:edit!` successfully reloads it. `:write!` remains an explicit overwrite.
- Copilot attaches to diagram buffers.

### Domain Model Syntax Highlighting

PlantUML buffers and fenced markdown blocks include custom syntax highlighting matching Pandora domain model conventions and Monokai Pro colors:
- **Stereotypes:** `<<Aggregate Root>>` (orange `#fc9867`), `<<Value Object>>` (green `#a9dc76`), `<<Enum>>` (purple `#ab9df2`), and `<<Interface>>` (pink `#ff61ae`) match Pandora's diagram theme palette.
- **Attributes & Types:** In class bodies, `name: type` declarations highlight field names as properties/identifiers (`#fcfcfa`), while colons and types (`ObjectId`, `string`, `KnowledgeSourceKind`, `datetime?`, `UserRole[]`) highlight in subtle muted gray (`#939293` dark, `#706b6e` light).
- **Relationship Labels:** Labels on relationship lines (e.g. `: sources`, `: index versions`) highlight in subtle muted gray (`#939293` dark, `#706b6e` light).
- **Enums:** `enum Name { ... }` blocks highlight bare member names matching class properties (`Identifier`).

### Connection

Neovim calls Pandora at `http://localhost`. To use another address, pass `base_url` to `require('notes').setup()` in `lua/plugins/notes.lua` or `require('diagrams').setup()` in `lua/plugins/diagrams.lua`.

### Where The Code Is

| File | Job |
|---|---|
| `lua/notes/buffer.lua` | Reads and writes `pandora://notes/<id>` and follows links |
| `lua/notes/live.lua` | Keeps an event-stream connection open and reloads changed notes |
| `lua/notes/pandora.lua` | Calls Pandora's notes API |
| `lua/notes/wikilinks.lua` | Shows link titles |
| `lua/notes/create.lua` | Creates notes |
| `lua/diagrams/buffer.lua` | Reads and writes `pandora://diagrams/<id>` |
| `lua/diagrams/api.lua` | Calls Pandora's diagrams API |
| `lua/plugins/diagrams.lua` | Registers `:Diagram` command and sets up diagram buffers |
| `after/syntax/plantuml.vim` | Domain model syntax highlighting and stereotype theme colors |
