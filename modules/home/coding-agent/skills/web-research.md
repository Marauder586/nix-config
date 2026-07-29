# Web research skill

## Tool order of preference

1. **`searxng` MCP** — meta-search. Set `SEARXNG_URL` to a self-host or a
   public instance like `https://searx.be`.
2. **`duckduckgo` MCP** — backup search if SearXNG is down.
3. **`fetch` MCP** (`mcp-server-fetch`) — single URL → markdown.
4. **`playwright` MCP** — JS-rendered sites, SPAs, paywalls behind a login.

## CLI fallbacks (when MCP isn't available)

```bash
# Quick JSON probe
xh GET "$URL" Accept:application/json | jq .

# Full archive of a page (single self-contained .html)
monolith "$URL" -o page.html

# YouTube / video metadata without download
yt-dlp --skip-download --print '%(title)s | %(uploader)s | %(upload_date)s' "$URL"

# DuckDuckGo from the shell
python -c "from duckduckgo_search import DDGS; \
  print('\n'.join(r['href'] for r in DDGS().text('$QUERY', max_results=5)))"

# HTML scraping
curl -sL "$URL" | pup 'article p text{}'
curl -sL "$URL" | htmlq -t 'h1, h2'
```

## Citation discipline

- Every factual claim gets an inline citation `[short label](URL)`.
- Drop a "Sources:" section at the bottom with full URLs.
- Don't fabricate URLs. If you can't open it, don't cite it.

## When to stop

- Three corroborating sources for a contested claim.
- One canonical source (vendor docs, RFC, primary repo) for a definitional
  one.
- Don't keep fetching once the answer is converged.
