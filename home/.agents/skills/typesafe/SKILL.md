---
name: typesafe
description: Ask TypeSafe's Jev (typesafe.ai) for a typed, calibrated decision - yes/no probability, a choice from a fixed set, or a rubric score - instead of guessing or parsing prose. Use when the task is classify, route, detect, score, rerank, or verify against explicit criteria.
---

# TypeSafe / Jev

Jev is a "System One" model: unstructured state in, typed decisions out, each with calibrated probabilities and a confidence score. It emits **no strings** - it cannot write prose or code, so it is a sidecar decision API, never the chat model.

Use it when the answer is one of a fixed set, a yes/no, or a rubric level, and you need a probability to act on.

## When to use

- Classify / route / detect / score / rerank / verify against explicit criteria
- The judgment is semantic but the output space is closed
- You need to act differently at different confidence levels
- You would otherwise hand-write brittle heuristics, or ask a chat model and parse JSON out of its prose

Not for: generating text or code, open-ended reasoning, summarization, anything needing free-form output.

## Setup

The script resolves the key itself, in this order: `TYPESAFE_API_KEY` if already exported, else the macOS keychain item `typesafe-api`. Key at https://console.typesafe.ai/keys.

```bash
# request JSON on stdin; prints the response JSON, timing on stderr
echo '{"state":"...","model":"jev-latest","questions":{...}}' | ~/.agents/skills/typesafe/scripts/jev.sh
```

**Never read the key directly.** Do not run `security find-generic-password -w`, `bw get`, or `cat ~/.zprofile` to obtain it: that prints the key to stdout, which lands in the session transcript. Always go through `scripts/jev.sh`, which captures the value internally. If the script exits 3, tell the user the key is missing rather than hunting for it.

## Request

POST https://api.typesafe.ai/v1/systemone, `Authorization: Bearer $TYPESAFE_API_KEY`, `content-type: application/json`.

```json
{
  "state": "Hi, I've been trying to connect my Stripe account for 3 days and it keeps failing. I'm losing sales. Please help ASAP.",
  "model": "jev-latest",
  "questions": {
    "department": {
      "type": "choice",
      "instructions": "Which team should handle this",
      "criteria": { "billing": "Payment or subscription issues", "technical": "Bugs or integration problems" }
    },
    "frustration": {
      "type": "score",
      "instructions": "How frustrated the customer appears",
      "criteria": ["Calm, just stating facts", "Frustrated but civil", "Very angry, strong language"]
    },
    "is_urgent": { "type": "noul", "instructions": "The message conveys urgency or time-sensitivity" }
  }
}
```

- `state` - what to judge. A string, or an object for structured program state.
- `choice` - pick one from `criteria`, a map of option key to description.
- `score` - ordered levels in `criteria`; the score is a weighted average, so it can land between levels (e.g. `1.035`), with a `legend` mapping level index to label.
- `noul` - yes/no; returns the probability that the answer is yes. No confidence field.
- Ask many questions in one call - it costs one round trip and answers in parallel.

## Response

```json
{
  "model": "jev-latest",
  "answers": {
    "department": { "type": "choice", "choice": "billing", "probabilities": { "billing": 0.84, "technical": 0.159 }, "confidence": 0.596 },
    "frustration": { "type": "score", "score": 1.035, "legend": { "0": "Calm...", "1": "Frustrated but civil" }, "confidence": 0.842 },
    "is_urgent": { "type": "noul", "noul": 0.999 }
  },
  "usage": { "input_tokens": 312, "output_tokens": 48 }
}
```

## Reading confidence

`confidence` (0-1) collapses how concentrated the probability distribution is. It is a separate axis from the answer: the answer says what, confidence says whether to act.

- **High** - act automatically. Clear read.
- **Medium** - proceed with caution: confirm with the user, flag for review, gather more input.
- **Low** - do not act. Treat as unknown, escalate, or fall back to other logic.

Thresholds scale with risk: a read-only action can act at lower confidence than a destructive one. The 0.5 floor catches "genuinely unsure". Tune thresholds with your own data - do not invent them from this page.

Low confidence usually means none of the options is a clear winner, or the `state` lacks what is needed. Fix the question before lowering the bar.

## Privacy

`state` leaves the machine to a third party. Send the minimum that answers the question: craft it deliberately. Do not dump whole files, tool output, logs, or credentials into `state` by default - ask the user before sending anything sensitive.

## Notes

- Self-reported by the vendor: ~70-500ms end-to-end, $0.042/MTok input, output free. Verify against your own `usage` numbers before relying on them.
- Early access, no SLA. Treat a failure as "no signal" rather than retrying in a loop.
- Docs: https://docs.typesafe.ai - evals: https://evals.typesafe.ai
