---
description: Summarize a YouTube video into the zupedia vault (Knowledge/Youtube Video Summary)
argument-hint: "<youtube-url>"
---
Summarize the YouTube video at $@ and file it into the zupedia Obsidian vault.

Vault: `/Users/izzu/Library/Mobile Documents/iCloud~md~obsidian/Documents/zupedia`
Read `<Vault>/AGENTS.md` first — its rules win over anything here.

## 1. Metadata + subtitles

```bash
cd /tmp && rm -f zt.*
yt-dlp --no-warnings --print "%(title)s|%(uploader)s|%(upload_date)s|%(id)s|%(duration_string)s" --skip-download "$URL"
yt-dlp --skip-download --write-subs --write-auto-subs --sub-langs "en,en-orig,id,id-orig" --convert-subs vtt -o "zt.%(ext)s" "$URL"
```

Languages are listed explicitly on purpose: globs like `id.*` also match junk tracks (`id-ar`), which triggers `HTTP Error 429: Too Many Requests`. If the video is in another language, add its exact code from `yt-dlp --list-subs "$URL"`.

Failure modes:
- `HTTP Error 429` / bot check → rerun the subtitle command with `--cookies-from-browser brave`, once.
- No `zt.*.vtt` produced (no captions at all) → stop and report; do not invent content.

## 2. VTT → plain text

```bash
cd /tmp && perl -ne 'next if /^(WEBVTT|Kind:|Language:|\s*$)/; next if /-->/; s/<[^>]*>//g; s/^\s+//; s/\s+$//; print "$_\n" unless $s{$_}++' zt.*.vtt > zt.txt
wc -l -c zt.txt
```

Global dedupe is required — YouTube rolling captions repeat every line several times. A ~25 min video lands around 500 lines / 20 KB.

## 3. Note

Path: `<Vault>/Knowledge/Youtube Video Summary/<Title>.md`
Filename = video title, strip `:` `/` `\` and replace `|` with `-` (a literal `|` breaks wikilinks). Keep emoji, em dashes, `?`, original casing.

Before writing, check the basename is unique — Obsidian resolves links by basename, so two notes with the same name make the hub link ambiguous:

```bash
find "<Vault>" -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.trash/*' -not -path '*/.pi/*' | grep -F "<Title>.md"
```

Hit in another folder → report it and ask which copy wins before writing. Never delete the other note.

**No frontmatter.** Body, nothing else:

```markdown
![](https://www.youtube.com/watch?v=<id>)

## TLDR
<2-4 sentences: what the video argues and what it is useful for.>

## Key Points
- <concrete point, not a teaser>
```

Rules:
- No `# <Title>` heading — the filename already carries the title.
- Language = the video's language. Indonesian video → Indonesian note. Never translate.
- TLDR and Key Points come from `zt.txt` only. No filler, no invented facts, no "this video discusses...".
- Key Points: 4-8 bullets, each one claim/framework/step from the video with its specifics (numbers, names, steps).
- One `write` call. Never rewrite other notes.
- Obsidian may have the note open — write once and tell the user to reload it.

## 4. Link it from the hub

Append exactly one line, `[[<Title>]]`, to `<Vault>/Knowledge/Videos.md` (append-only, never reorder, never `write` over it — that file is a large watchlist and iCloud dataless placeholders revert overwrites). Force the download first:

```bash
brctl download "<Vault>/Knowledge/Videos.md"
sleep 3
stat -f "%z" "<Vault>/Knowledge/Videos.md"   # non-zero, otherwise stop
printf '\n[[<Title>]]\n' >> "<Vault>/Knowledge/Videos.md"
sleep 3 && tail -2 "<Vault>/Knowledge/Videos.md"   # confirm it stuck
```

Skip if the line is already there.

## 5. Cleanup

```bash
rm -f /tmp/zt.*
```

Vault safety: no `rm`, no renames, no bulk edits, never touch `.obsidian/`, `.trash/`, `.pi/`. If the note already exists, overwrite it only after saying so.

Yield: note path, key points count, video language, anything skipped.
