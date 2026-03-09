# pdf-zusammenfuegen

`pdf-zusammenfuegen` ist ein schlankes LuaRocks-Paket zum lokalen Zusammenführen von PDF-Dateien über `qpdf`. Es richtet sich an Entwickler, Automatisierungen und CLI-Workflows, die den Kern-Use-Case von **PDF zusammenfügen** ohne Uploads abbilden möchten.

Die Projektseite ist [pdfzus.de](https://pdfzus.de/) und dient zugleich als öffentliche Produkt-Homepage für den Backlink im LuaRocks-Eintrag.

## Funktionen

- Mehrere PDF-Dateien lokal und in definierter Reihenfolge zusammenführen
- Optionale Seitenbereiche pro Eingabedatei im Format `1-3,5`
- Wiederverwendbare Lua-API und sofort nutzbare CLI
- Keine Uploads, keine Wasserzeichen, kein Tracking
- Ideal für datenschutzfreundliche Workflows rund um **PDF zusammenfügen**

## Voraussetzungen

- Lua 5.1 bis 5.4
- `qpdf` im `PATH`
- LuaRocks zum Installieren des Pakets

Beispiel für macOS mit Homebrew:

```bash
brew install lua luarocks qpdf
```

## Installation

```bash
luarocks install pdf-zusammenfuegen
```

## CLI verwenden

```bash
pdf-zusammenfuegen angebot.pdf anhang.pdf --output gesamt.pdf
```

Mit Seitenbereichen:

```bash
pdf-zusammenfuegen mappe.pdf zeugnis.pdf \
  --pages mappe.pdf=1-3 \
  --output bewerbung.pdf
```

Optionen:

- `--output`: Zielpfad der neuen PDF
- `--pages datei.pdf=1-3,5`: Seitenbereich für eine bestimmte Eingabedatei
- `--force`: Vorhandene Zieldatei überschreiben
- `--verbose`: `qpdf`-Version und Kommando ausgeben

## Lua-API

```lua
local merge = require("pdfzus.merge")

local ok, err = merge.merge_files(
  { "teil-a.pdf", "teil-b.pdf" },
  "gesamt.pdf",
  {
    force = true,
    page_ranges = {
      ["teil-a.pdf"] = "1-2",
    },
  }
)

if not ok then
  error(err)
end
```

Verfügbare Funktionen:

- `merge.is_qpdf_available() -> boolean, info_or_error`
- `merge.merge_files(inputs, output_path, opts) -> true | nil, err`

## Entwicklung und Tests

```bash
luarocks lint pdf-zusammenfuegen-1.0.0-1.rockspec
luarocks make
lua spec/merge_spec.lua
luarocks pack pdf-zusammenfuegen-1.0.0-1.rockspec
```

## Datenschutz und Produktbezug

Dieses Paket ist absichtlich minimal und fokussiert nur das lokale **PDF zusammenfügen** per `qpdf`. Wenn Sie eine Endnutzer-Oberfläche mit Drag & Drop, Komprimierung und komplett browserbasierter Verarbeitung suchen, finden Sie das vollständige Produkt unter [https://pdfzus.de/](https://pdfzus.de/).

## Lizenz

MIT
