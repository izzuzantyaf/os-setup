# Global

## Images / vision
- Images are handled by the 9router "vision adapter" (`capacityAdapter.vision`, configured in `~/.9router/db/data.sqlite` → `settings`). It reroutes image content to a vision-capable model (`deepseek-v4-flash-vision-exp` / `glm-5.3-flash`) even when the requested model declares text-only input.
- Models in `~/.pi/agent/models.json` whose `input` includes `"image"` send images inline; pi strips image parts otherwise. If an image is stripped, call the router directly (e.g. `/tmp/vis.py <image> "<prompt>"`) or use a vision-capable model listed in models.json.

## Atlassian / Jira (MCP)
- Server `jira` → `https://mcp.atlassian.com/v2/mcp?tools=all`, OAuth 2.1 (DCR + PKCE, loopback callback). Tokens live in the macOS Keychain, managed automatically by pi-mcp-adapter — no token file, no manual setup. Re-auth `/mcp-auth jira`; clear `/mcp logout jira`.
- **cloudId `5ec7f679-2f7b-4148-a7b6-93960863b299`** (site `govtech-lkpp.atlassian.net`). Pass it explicitly on every call — it is never auto-resolved. Do NOT call `getAccessibleAtlassianResources` again.
- Account `izzu.fawwas@eproc-gov.tech`, accountId `712020:72669866-766f-4792-808e-82fc21586829`.
- **Granted access is read-only** across every product (jira, confluence, code-search, goals, projects, loom, talent, teams, focus). Don't attempt writes, transitions, or edits without confirming access first.
- 87 Jira projects, no default pinned. Resolve keys with `jira_listJiraProjects` (paginates on `maxResults`; `limit` is ignored).
- Keep responses small: pass `responseFields` or a `view` preset. Custom fields need site-specific `customfield_*` IDs. Prefer `jira_searchJiraIssuesUsingJql` for structured queries.