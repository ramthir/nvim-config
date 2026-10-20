# Neovim Config

## Pandora Notes

Notes live in Pandora. Neovim reads and writes them through Pandora's local API. The behaviour is specified in the Pandora note *Pandora — Neovim Notes* (note 1575).

| To do this | Use |
|---|---|
| Open a note | `:edit pandora://notes/<id>` |
| Open a note, short | `:Note <id>`, or `:note <id>` in lower case |
| Open the note whose number is under the cursor, or be asked for an ID | `:Note` with no ID, or `<leader>no` |
| Save it to Pandora | `:write` |
| Reload it from Pandora, discarding local edits | `:edit!` |
| Create a note | `:NotesCreate` or `<leader>nn` |
| Follow a `[[link]]` | `<CR>` on the link |

- `<id>` is the note's number in Pandora. A `[[123]]` link shows the target's title, and the saved text keeps the ID.
- An open note reloads by itself when it is changed elsewhere in Pandora. If you have unsaved edits, they are kept and you get a warning.
- Copilot attaches to note buffers, so text from your notes is sent to GitHub Copilot as context.
- There is no note search in Neovim.

### Connection

Neovim calls Pandora at `http://localhost`. To use another address, pass `base_url` to `require('notes').setup()` in `lua/plugins/notes.lua`.

### Where The Code Is

| File | Job |
|---|---|
| `lua/notes/buffer.lua` | Reads and writes `pandora://notes/<id>` and follows links |
| `lua/notes/live.lua` | Keeps an event-stream connection open and reloads changed notes |
| `lua/notes/pandora.lua` | Calls Pandora's API |
| `lua/notes/wikilinks.lua` | Shows link titles |
| `lua/notes/create.lua` | Creates notes |
