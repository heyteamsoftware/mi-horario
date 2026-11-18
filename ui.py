# Busca en el volcado de uiautomator el primer elemento cuyo texto encaje con la expresión
# y escribe "x y" (su centro). Lo usa capturas.sh para tocar botones del emulador.
import re, sys, xml.etree.ElementTree as ET
patron = re.compile(sys.argv[2], re.I)
for n in ET.parse(sys.argv[1]).iter('node'):
    s = ((n.get('text') or '') + ' ' + (n.get('content-desc') or '')).strip()
    if s and patron.search(s):
        x1, y1, x2, y2 = map(int, re.findall(r'\d+', n.get('bounds')))
        if y2 > y1 and x2 > x1:
            print((x1 + x2) // 2, (y1 + y2) // 2)
            break
