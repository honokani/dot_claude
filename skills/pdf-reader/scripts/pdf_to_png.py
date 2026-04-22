"""PDF to PNG converter using pymupdf.

Usage:
    uv run --python ~/.claude/workspace_for_claude/.venv/Scripts/python pdf_to_png.py <pdf> [options]
"""
import sys
import argparse
from pathlib import Path

import fitz  # pymupdf


def parse_pages(pages_str: str, total: int) -> list[int]:
    """Parse page spec like '1-5', '1,3,7', '22-23,47-48,50' into 0-based indices."""
    result = []
    for part in pages_str.split(","):
        part = part.strip()
        if "-" in part:
            start, end = part.split("-", 1)
            start, end = int(start), int(end)
            result.extend(range(start - 1, min(end, total)))
        else:
            idx = int(part) - 1
            if 0 <= idx < total:
                result.append(idx)
    return sorted(set(result))


def main():
    parser = argparse.ArgumentParser(description="Convert PDF pages to PNG images")
    parser.add_argument("pdf_path", help="Path to the PDF file")
    parser.add_argument("--output", "-o", help="Output directory (default: same dir as PDF)")
    parser.add_argument("--pages", "-p", help="Page spec: '1-5', '1,3,7-10' (default: all)")
    parser.add_argument("--dpi", type=int, default=200, help="Resolution in DPI (default: 200)")
    parser.add_argument("--prefix", default=None, help="Filename prefix (default: PDF stem)")
    args = parser.parse_args()

    pdf_path = Path(args.pdf_path)
    if not pdf_path.exists():
        print(f"Error: {pdf_path} not found", file=sys.stderr)
        sys.exit(1)

    out_dir = Path(args.output) if args.output else pdf_path.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    prefix = args.prefix or pdf_path.stem

    doc = fitz.open(str(pdf_path))
    total = doc.page_count

    pages = parse_pages(args.pages, total) if args.pages else list(range(total))

    zoom = args.dpi / 72.0
    matrix = fitz.Matrix(zoom, zoom)

    print(f"Total pages: {total}, converting {len(pages)} page(s) at {args.dpi} DPI")

    for idx in pages:
        page = doc[idx]
        pix = page.get_pixmap(matrix=matrix)
        out_file = out_dir / f"{prefix}_p{idx + 1:03d}.png"
        pix.save(str(out_file))
        print(f"  {out_file.name}")

    doc.close()
    print(f"Done. Output: {out_dir}")


if __name__ == "__main__":
    main()
