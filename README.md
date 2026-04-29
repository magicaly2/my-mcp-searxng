# SearXNG MCP Server

An [MCP server](https://modelcontextprotocol.io/introduction) that integrates the [SearXNG](https://docs.searxng.org) API, giving AI assistants web search capabilities.

[![https://nodei.co/npm/my-mcp-searxng.png?downloads=true&downloadRank=true&stars=true](https://nodei.co/npm/my-mcp-searxng.png?downloads=true&downloadRank=true&stars=true)](https://www.npmjs.com/package/my-mcp-searxng)

[![https://badgen.net/docker/pulls/isokoliuk/my-mcp-searxng](https://badgen.net/docker/pulls/isokoliuk/my-mcp-searxng)](https://hub.docker.com/r/isokoliuk/my-mcp-searxng)

<a href="https://glama.ai/mcp/servers/0j7jjyt7m9"><img width="380" height="200" src="https://glama.ai/mcp/servers/0j7jjyt7m9/badge" alt="SearXNG Server MCP server" /></a>

## Quick Start

Add to your MCP client configuration (e.g. `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "searxng": {
      "command": "npx",
      "args": ["-y", "my-mcp-searxng"],
      "env": {
        "SEARXNG_URL": "YOUR_SEARXNG_INSTANCE_URL"
      }
    }
  }
}
```

Replace `YOUR_SEARXNG_INSTANCE_URL` with the URL of your SearXNG instance (e.g. `https://search.example.com`).

## Features

- **Web Search**: General queries, news, articles, with pagination.
- **URL Content Reading**: Advanced content extraction with pagination, section filtering, and heading extraction.
- **Intelligent Caching**: URL content is cached with TTL (Time-To-Live) to improve performance and reduce redundant requests.
- **Pagination**: Control which page of results to retrieve.
- **Time Filtering**: Filter results by time range (day, month, year).
- **Language Selection**: Filter results by preferred language.
- **Safe Search**: Control content filtering level for search results.

## How It Works

`my-mcp-searxng` is a standalone MCP server — a separate Node.js process that your AI assistant connects to for web search. It queries any SearXNG instance via its HTTP JSON API.

> **Not a SearXNG plugin:** This project cannot be installed as a native SearXNG plugin. Point it at any existing SearXNG instance by setting `SEARXNG_URL`.

```
AI Assistant (e.g. Claude)
        │  MCP protocol
        ▼
  my-mcp-searxng  (this project — Node.js process)
        │  HTTP JSON API  (SEARXNG_URL)
        ▼
  SearXNG instance
```

## Tools

- **searxng_web_search**
  - Execute web searches with pagination
  - Inputs:
    - `query` (string): The search query. This string is passed to external search services.
    - `pageno` (number, optional): Search page number, starts at 1 (default 1)
    - `time_range` (string, optional): Filter results by time range - one of: "day", "month", "year" (default: none)
    - `language` (string, optional): Language code for results (e.g., "en", "fr", "de") or "all" (default: "all")
    - `safesearch` (number, optional): Safe search filter level (0: None, 1: Moderate, 2: Strict) (default: instance setting)

- **web_url_read**
  - Read and convert the content from a URL to markdown with advanced content extraction options
  - Inputs:
    - `url` (string): The URL to fetch and process
    - `startChar` (number, optional): Starting character position for content extraction (default: 0)
    - `maxLength` (number, optional): Maximum number of characters to return
    - `section` (string, optional): Extract content under a specific heading (searches for heading text)
    - `paragraphRange` (string, optional): Return specific paragraph ranges (e.g., '1-5', '3', '10-')
    - `readHeadings` (boolean, optional): Return only a list of headings instead of full content

## Installation

<details>
<summary>NPM (global install)</summary>

```bash
npm install -g my-mcp-searxng
```

```json
{
  "mcpServers": {
    "searxng": {
      "command": "my-mcp-searxng",
      "env": {
        "SEARXNG_URL": "YOUR_SEARXNG_INSTANCE_URL"
      }
    }
  }
}
```

</details>

<details>
<summary>Docker</summary>

The Docker image runs `mcpo` in front of the stdio MCP server and exposes an OpenAPI-compatible HTTP server on port `8005` by default.

```bash
docker build -t my-mcp-searxng:latest -f Dockerfile .
```

Run it locally:

```bash
docker run --rm -p 8005:8005 \
  -e SEARXNG_URL=https://search.example.com \
  my-mcp-searxng:latest
```

Optional API key:

```bash
docker run --rm -p 8005:8005 \
  -e SEARXNG_URL=https://search.example.com \
  -e MCPO_API_KEY=top-secret \
  my-mcp-searxng:latest
```

Interactive docs will be available at `http://localhost:8005/docs`.

</details>

<details>
<summary>Docker Compose</summary>

`docker-compose.yml`:

```yaml
services:
  my-mcp-searxng:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8005:8005"
    environment:
      - SEARXNG_URL=YOUR_SEARXNG_INSTANCE_URL
      # Add optional variables as needed — see CONFIGURATION.md
```

MCP client config:

```json
{
  "mcpServers": {
    "searxng": {
      "command": "docker-compose",
      "args": ["run", "--rm", "my-mcp-searxng"]
    }
  }
}
```

</details>

<details>
<summary>HTTP Transport</summary>

By default the Node server uses STDIO. If you need the native MCP HTTP transport instead of `mcpo`, set `MCP_HTTP_PORT`:

```json
{
  "mcpServers": {
    "searxng-http": {
      "command": "my-mcp-searxng",
      "env": {
        "SEARXNG_URL": "YOUR_SEARXNG_INSTANCE_URL",
        "MCP_HTTP_PORT": "3000"
      }
    }
  }
}
```

**Endpoints:** `POST/GET/DELETE /mcp` (MCP protocol), `GET /health` (health check)

**Test it:**

```bash
MCP_HTTP_PORT=3000 SEARXNG_URL=http://localhost:8080 my-mcp-searxng
curl http://localhost:3000/health
```

</details>

## Configuration

Set `SEARXNG_URL` to your SearXNG instance URL. All other variables are optional.

Full environment variable reference: [CONFIGURATION.md](CONFIGURATION.md)

## Troubleshooting

### 403 Forbidden from SearXNG

Your SearXNG instance likely has JSON format disabled. Edit `settings.yml` (usually `/etc/searxng/settings.yml`):

```yaml
search:
  formats:
    - html
    - json
```

Restart SearXNG (`docker restart searxng`) then verify:

```bash
curl 'http://localhost:8080/search?q=test&format=json'
```

You should receive a JSON response. If not, confirm the file is correctly mounted and YAML indentation is valid.

See also: [SearXNG settings docs](https://docs.searxng.org/admin/settings/settings.html) · [discussion](https://github.com/searxng/searxng/discussions/1789)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT — see [LICENSE](LICENSE) for details.
