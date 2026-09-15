# Global

## Images / vision
- Images are handled by the 9router "vision adapter" (`capacityAdapter.vision`, configured in `~/.9router/db/data.sqlite` → `settings`). It reroutes image content to a vision-capable model (`deepseek-v4-flash-vision-exp` / `glm-5.3-flash`) even when the requested model declares text-only input.
- Models in `~/.pi/agent/models.json` whose `input` includes `"image"` send images inline; pi strips image parts otherwise. If an image is stripped, call the router directly (e.g. `/tmp/vis.py <image> "<prompt>"`) or use a vision-capable model listed in models.json.