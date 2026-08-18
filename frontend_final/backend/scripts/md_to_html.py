#!/usr/bin/env python3
"""Convert plan.final_mobile.md to a standalone HTML document."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = ROOT / "plan.final_mobile.md"
DEFAULT_OUT = ROOT / "plan.final_mobile.html"

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{title}</title>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <style>
    :root {{
      --text: #1a1a2e;
      --muted: #5c5c7a;
      --border: #e8e8ef;
      --accent: #7061f3;
      --accent-soft: #f0eeff;
      --code-bg: #f6f8fa;
      --mobile-tag: #0d6efd;
    }}
    body {{
      margin: 0;
      font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      font-size: 16px;
      line-height: 1.65;
      color: var(--text);
      background: #fff;
    }}
    header.doc-header {{
      background: linear-gradient(135deg, #7061f3, #5a4fd4);
      color: #fff;
      padding: 2rem 1.5rem;
    }}
    header.doc-header h1 {{ margin: 0 0 0.5rem; font-size: 1.75rem; }}
    header.doc-header p {{ margin: 0; opacity: 0.92; }}
    nav#toc {{
      position: sticky;
      top: 0;
      z-index: 10;
      background: #fafafa;
      border-bottom: 1px solid var(--border);
      padding: 0.75rem 1.5rem;
      font-size: 0.875rem;
      overflow-x: auto;
    }}
    nav#toc a {{ color: var(--accent); margin-right: 1rem; text-decoration: none; }}
    main {{ max-width: 52rem; margin: 0 auto; padding: 2rem 1.5rem 4rem; }}
    main h1 {{ font-size: 1.75rem; border-bottom: 2px solid var(--accent); padding-bottom: 0.35rem; margin-top: 2.5rem; }}
    main h2 {{ font-size: 1.35rem; margin-top: 2rem; }}
    main h3 {{ font-size: 1.1rem; margin-top: 1.5rem; }}
    blockquote {{
      margin: 1rem 0;
      padding: 0.75rem 1rem;
      border-left: 4px solid var(--accent);
      background: var(--accent-soft);
    }}
    code {{
      font-family: ui-monospace, Menlo, Monaco, Consolas, monospace;
      font-size: 0.875em;
      background: var(--code-bg);
      padding: 0.15em 0.4em;
      border-radius: 4px;
    }}
    pre {{
      background: #1e1e2e;
      color: #e8e8ef;
      padding: 1rem;
      border-radius: 8px;
      overflow-x: auto;
      font-size: 0.85rem;
    }}
    pre code {{ background: none; padding: 0; color: inherit; }}
    table {{ width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 0.9rem; }}
    th, td {{ border: 1px solid var(--border); padding: 0.5rem 0.75rem; text-align: left; }}
    th {{ background: var(--accent-soft); }}
    tr:nth-child(even) {{ background: #fafafa; }}
    .mermaid {{
      margin: 1.5rem 0;
      padding: 1rem;
      background: #fafafa;
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow-x: auto;
    }}
    .tag-mobile {{
      display: inline-block;
      font-size: 0.7rem;
      font-weight: 600;
      color: #fff;
      background: var(--mobile-tag);
      padding: 0.1em 0.45em;
      border-radius: 4px;
      margin-right: 0.35em;
      vertical-align: middle;
    }}
    footer {{ text-align: center; padding: 2rem; color: var(--muted); font-size: 0.875rem; border-top: 1px solid var(--border); }}
  </style>
</head>
<body id="top">
  <header class="doc-header">
    <h1>Alpha Cues MVP — Mobile Edition Blueprint</h1>
    <p>HTML export of plan.final_mobile.md · Native iOS + Android</p>
  </header>
  <nav id="toc">{toc_links}</nav>
  <main>
{body}
  </main>
  <footer>Generated from plan.final_mobile.md</footer>
  <script>mermaid.initialize({{ startOnLoad: true, theme: "neutral" }});</script>
</body>
</html>
"""


def preprocess_mermaid(text: str) -> str:
    return re.sub(
        r"```mermaid\s*\n(.*?)```",
        lambda m: f'<div class="mermaid">\n{m.group(1).strip()}\n</div>',
        text,
        flags=re.DOTALL,
    )


def highlight_mobile_tags(html: str) -> str:
    return html.replace("[Mobile_5_17_26]", '<span class="tag-mobile">Mobile</span>')


def build_toc_nav(html: str) -> str:
    headings = re.findall(r'<h([23]) id="([^"]+)">([^<]+)</h\1>', html)
    links = ['<a href="#top">Top</a>']
    for level, hid, title in headings[:28]:
        prefix = "· " if level == "3" else ""
        links.append(f'<a href="#{hid}">{prefix}{title.strip()[:52]}</a>')
    return "\n    ".join(links)


def convert(src: Path, out: Path) -> None:
    raw = src.read_text(encoding="utf-8")
    prepped = preprocess_mermaid(raw)
    md = markdown.Markdown(
        extensions=["tables", "fenced_code", "toc", "nl2br"],
        extension_configs={"toc": {"permalink": False, "toc_depth": 3}},
    )
    body = highlight_mobile_tags(md.convert(prepped))
    toc_html = build_toc_nav(body)
    title_match = re.search(r"<h1[^>]*>([^<]+)</h1>", body)
    title = title_match.group(1) if title_match else "Alpha Cues Mobile Plan"
    out.write_text(HTML_TEMPLATE.format(title=title, toc_links=toc_html, body=body), encoding="utf-8")
    print(f"Wrote {out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SRC
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT
    convert(src, out)
