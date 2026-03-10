import sys
import argparse

sys.stdout.reconfigure(encoding='utf-8')

import pymupdf


def main():
    parser = argparse.ArgumentParser(description='Extract text from PDF')
    parser.add_argument('pdf_path', help='Path to PDF file')
    parser.add_argument('--pages', help='Page range (e.g. "1-5", "3,7,10")', default=None)
    args = parser.parse_args()

    doc = pymupdf.open(args.pdf_path)
    total = doc.page_count
    print(f'Total pages: {total}')

    if args.pages:
        indices = parse_pages(args.pages, total)
    else:
        indices = range(total)

    for i in indices:
        text = doc[i].get_text()
        print(f'--- PAGE {i + 1} ---')
        print(text)


def parse_pages(spec, total):
    result = []
    for part in spec.split(','):
        part = part.strip()
        if '-' in part:
            start, end = part.split('-', 1)
            start = max(0, int(start) - 1)
            end = min(total, int(end))
            result.extend(range(start, end))
        else:
            idx = int(part) - 1
            if 0 <= idx < total:
                result.append(idx)
    return result


if __name__ == '__main__':
    main()
