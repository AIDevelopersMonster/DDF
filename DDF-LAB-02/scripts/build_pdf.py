"""Reproducible PDF preparation; needs pandoc, WeasyPrint, local fonts."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parent.parent
BUILD=ROOT/'_build'
BUILD.mkdir(exist_ok=True)
PDF=ROOT/'pdf'
PDF.mkdir(exist_ok=True)
for lang in ('RU','EN'):
 md=ROOT/'docs'/f'DDF-LAB-02_v0.1_{lang}.md'
 html=BUILD/f'DDF-LAB-02_v0.1_{lang}.html'
 pdf=PDF/f'DDF-LAB-02_v0.1_{lang}.pdf'
 subprocess.run(['pandoc',str(md),'-f','gfm+raw_html','-t','html5','--standalone','--toc','--toc-depth=2','-o',str(html)],check=True)
 # CSS in a reliable local file reference rather than externally loaded assets
 source=html.read_text(encoding='utf-8')
 css=(ROOT/'scripts'/'pdf.css').read_text(encoding='utf-8')
 source=source.replace('</head>',f'<style>\n{css}\n</style>\n</head>')
 # Empty GFM image alt text often becomes <img>, not <figure>; force width via CSS
 html.write_text(source,encoding='utf-8')
 subprocess.run(['weasyprint',str(html),str(pdf)],check=True,timeout=120)
 print(pdf,pdf.stat().st_size)
