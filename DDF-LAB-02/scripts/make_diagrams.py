from pathlib import Path
from html import escape
ROOT=Path(__file__).resolve().parent.parent/'assets'
ROOT.mkdir(exist_ok=True)

for lang in ('RU','EN'):
    ru=lang=='RU'
    D = {
       'title': 'Из архитектурной модели в регистры и логику' if ru else 'From architecture to registers and logic',
       'sample':'Текущий отсчёт' if ru else 'Current sample',
       'history':'История (3 регистра)' if ru else 'History (3 registers)',
       'sum':'Сумма 14 бит' if ru else '14-bit sum',
       'shift':'Сдвиг на 2' if ru else 'Shift by 2',
       'output':'Регистр выхода' if ru else 'Output register',
       'note':'Каждый valid_in=1 сдвигает историю; недействительные отсчёты игнорируются.' if ru else 'Each valid_in=1 advances history; invalid samples are ignored.',
       'foot':'Сброс очищает историю, data_out и valid_out. Нет ready/backpressure.' if ru else 'Reset clears history, data_out and valid_out. No ready/backpressure.'
    }
    svg='''<svg xmlns="http://www.w3.org/2000/svg" width="960" height="300" viewBox="0 0 960 300">
    <defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#0891b2"/></marker></defs>
    <rect width="960" height="300" rx="14" fill="#f3f8fc" />
    <text x="30" y="37" font-size="21" font-family="DejaVu Sans" font-weight="bold" fill="#0b2440">{title}</text>
    <g font-family="DejaVu Sans" font-size="15" text-anchor="middle" fill="#0b2440">
      <rect x="29" y="80" width="150" height="66" rx="10" fill="#dcf2fb" stroke="#0891b2" stroke-width="2"/><text x="104" y="106">{sample}</text><text x="104" y="128" font-weight="bold">data_in[11:0]</text>
      <rect x="29" y="163" width="246" height="64" rx="10" fill="#f0f0ff" stroke="#7a75b7" stroke-width="2"/><text x="152" y="190">{history}</text><text x="152" y="213" font-weight="bold">d1, d2, d3 · 12b</text>
      <rect x="329" y="113" width="171" height="68" rx="10" fill="#d4f3e8" stroke="#12845b" stroke-width="2"/><text x="414" y="143">{sum}</text><text x="414" y="164">Σ = x + d1+d2+d3</text>
      <rect x="562" y="113" width="154" height="68" rx="10" fill="#fff1df" stroke="#d88c23" stroke-width="2"/><text x="639" y="143">{shift}</text><text x="639" y="164">sum[13:2]</text>
      <rect x="782" y="113" width="156" height="68" rx="10" fill="#dcf2fb" stroke="#0891b2" stroke-width="2"/><text x="860" y="142">{output}</text><text x="860" y="165">data_out[11:0]</text>
    </g>
    <g fill="none" stroke="#0891b2" stroke-width="3" marker-end="url(#a)"><path d="M179 113 L305 113 L305 135 L329 135"/><path d="M275 195 L306 195 L306 159 L329 159"/><path d="M500 147 L562 147"/><path d="M716 147 L782 147"/></g>
    <text x="29" y="255" font-family="DejaVu Sans" font-size="15" fill="#123f5d">{note}</text>
    <text x="29" y="282" font-family="DejaVu Sans" font-size="13.5" fill="#476173">{foot}</text>
    </svg>'''.format(**{k:escape(v) for k,v in D.items()})
    (ROOT/f'architecture_{lang.lower()}.svg').write_text(svg,encoding='utf-8')
    d2={
       'title':'Контракт регистрации результата: фронт + обновления NBA' if ru else 'Registered-result contract: edge + NBA updates',
       'at':'До фронта' if ru else 'Before edge',
       'edge':'Фронт такта' if ru else 'Clock edge',
       'after':'После NBA' if ru else 'After NBA',
       'valid':'valid_in = 1' if ru else 'valid_in = 1',
       'result':'valid_out=1; data_out=ожидаемое' if ru else 'valid_out=1; data_out=expected',
       'note':'Это семантическая схема, не результат VCD и не оценка задержек FPGA.' if ru else 'Semantic diagram only: not measured VCD or FPGA timing.'
    }
    svg2='''<svg xmlns="http://www.w3.org/2000/svg" width="960" height="245" viewBox="0 0 960 245">
    <rect width="960" height="245" rx="14" fill="#f3f8fc"/>
    <text x="28" y="38" font-size="20" font-weight="bold" font-family="DejaVu Sans" fill="#0b2440">{title}</text>
    <path d="M55 100 H350 V72 H450 V100 H910" stroke="#12845b" stroke-width="4" fill="none"/>
    <line x1="450" y1="62" x2="450" y2="202" stroke="#d88c23" stroke-width="3" stroke-dasharray="9 6"/>
    <g font-size="15.5" font-family="DejaVu Sans" fill="#0b2440"><text x="40" y="78">clk</text><text x="125" y="135">{at}</text><text x="395" y="59">{edge}</text><text x="645" y="135">{after}</text>
    <text x="115" y="167">{valid}</text><text x="520" y="167">{result}</text>
    <text x="29" y="225" font-size="14" fill="#476173">{note}</text></g>
    <path d="M520 171 L900 171" stroke="#0891b2" stroke-width="3"/>
    </svg>'''.format(**{k:escape(v) for k,v in d2.items()})
    (ROOT/f'timing_{lang.lower()}.svg').write_text(svg2,encoding='utf-8')
print('SVG diagrams generated')
