#!/usr/bin/env python3
"""Sinh site phap ly tinh tu assets/legal/*.md.

NGUON SU THAT LA assets/legal/*.md — cung file ma app doc. Khong bao gio sua
HTML sinh ra: ban trong app va ban tren web PHAI khop nhau, reviewer store co
the mo ca hai ra so.

Ho tro dung tap cu phap hai file dang dung (giong lib/features/legal/
presentation/legal_screen.dart): '#'/'##' heading, '- ' bullet, '**bold**'.

Dung:  python scripts/build_legal_site.py <thu_muc_dich>
"""
from __future__ import annotations

import html
import pathlib
import re
import sys

DOCS = [
    ("privacy_vi.md", "privacy.html", "Chính sách bảo mật"),
    ("tos_vi.md", "terms.html", "Điều khoản sử dụng"),
]

CSS = """
:root { color-scheme: light; }
body {
  margin: 0 auto; padding: 32px 20px 72px; max-width: 44rem;
  background: #F7EFD8; color: #1E3A2F;
  font: 17px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
h1 { font-size: 1.9rem; line-height: 1.2; margin: 0 0 .2em; }
h2 { font-size: 1.3rem; margin: 1.8em 0 .4em; }
h3 { font-size: 1.1rem; margin: 1.4em 0 .3em; }
ul { padding-left: 1.2em; }
li { margin: .3em 0; }
a { color: #942D0E; }
nav { margin-bottom: 2rem; font-size: .95rem; }
footer { margin-top: 3rem; padding-top: 1rem; border-top: 2px solid #1E3A2F;
         font-size: .9rem; }
"""


def inline(text: str) -> str:
    """Escape roi moi ap **bold** — khong bao gio de HTML tho tu markdown loc qua."""
    escaped = html.escape(text)
    return re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", escaped)


def to_html(md: str) -> str:
    out: list[str] = []
    in_list = False

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for raw in md.splitlines():
        line = raw.rstrip()
        if not line.strip():
            close_list()
            continue
        heading = re.match(r"^(#{1,3})\s+(.*)$", line)
        if heading:
            close_list()
            level = len(heading.group(1))
            out.append(f"<h{level}>{inline(heading.group(2))}</h{level}>")
            continue
        if line.lstrip().startswith("- "):
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{inline(line.lstrip()[2:])}</li>")
            continue
        close_list()
        out.append(f"<p>{inline(line)}</p>")
    close_list()
    return "\n".join(out)


def page(title: str, body: str) -> str:
    return f"""<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} — Cùng Hát</title>
<style>{CSS}</style>
</head>
<body>
<nav><a href="./">← Cùng Hát</a></nav>
{body}
<footer>Cùng Hát · <a href="privacy.html">Chính sách bảo mật</a> ·
<a href="terms.html">Điều khoản sử dụng</a></footer>
</body>
</html>
"""


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    src = pathlib.Path(__file__).resolve().parent.parent / "assets" / "legal"
    dst = pathlib.Path(sys.argv[1])
    dst.mkdir(parents=True, exist_ok=True)

    for md_name, out_name, title in DOCS:
        md = (src / md_name).read_text(encoding="utf-8")
        (dst / out_name).write_text(page(title, to_html(md)), encoding="utf-8")
        print(f"  {md_name} -> {out_name}")

    index = page(
        "Văn bản pháp lý",
        "<h1>Cùng Hát</h1>"
        "<p>Ứng dụng rủ nhau đi hát karaoke.</p>"
        "<ul>"
        '<li><a href="privacy.html">Chính sách bảo mật</a></li>'
        '<li><a href="terms.html">Điều khoản sử dụng</a></li>'
        "</ul>",
    )
    (dst / "index.html").write_text(index, encoding="utf-8")
    print("  index.html")
    # Khong chay Jekyll: tranh no bo qua file bat dau bang '_' va tranh build cham.
    (dst / ".nojekyll").write_text("", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
