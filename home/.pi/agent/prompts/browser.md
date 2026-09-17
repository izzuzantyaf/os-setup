---
description: Drive Brave via CDP MCP (navigate, click, type, screenshot)
argument-hint: "<what to do in the browser>"
---
Task: $@

Drive the `chrome-devtools` MCP server (chrome-devtools-mcp attached to Brave's CDP port). Tools are `chrome_devtools_*`.

1. Ensure browser is up: `curl -s -m 2 http://127.0.0.1:9222/json/version`. Empty → `open -a "$HOME/Applications/Brave CDP.app"`, then poll that URL until it answers. Never use plain `Brave Browser.app`: default profile refuses CDP (Chromium 136+).
2. If a call fails with `Server "chrome-devtools" is not connected`: `mcp({ connect: "chrome-devtools" })`, retry once.
3. `chrome_devtools_new_page` / `chrome_devtools_navigate_page` to the target. Every tool except page creation takes a required `pageId` (from `chrome_devtools_list_pages`) — pass it on each call.
4. `chrome_devtools_take_snapshot` → act with `chrome_devtools_click` / `chrome_devtools_fill` / `chrome_devtools_press_key` using snapshot uids. Re-snapshot after every action; uids do not survive navigation. Snapshots run ~300 lines: read only the region you need.
5. Verify, don't assume: fresh snapshot, `chrome_devtools_wait_for`, or `chrome_devtools_evaluate_script` for state — media playing is `document.querySelector('video')` with `paused === false && currentTime > 0`.
6. YouTube Music: go straight to `https://music.youtube.com/search?q=<url-encoded query>`, click the row's Play button (`button "Play <title>"`, not the title link), then verify playback per step 5. Play/pause is `chrome_devtools_press_key` with `space`. Without login there is no library, likes, or history — search playback only; say so if the task needs those.
7. Ask before destructive or irreversible actions (submit, buy, send, delete). On login wall, captcha, cookie wall, or payment prompt: stop and report. The CDP profile has no logins unless stated.
8. Yield: final URL, what changed, blockers. No play-by-play.
