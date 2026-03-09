package.path = table.concat({
  "./src/?.lua",
  "./src/?/init.lua",
  "./src/?/?.lua",
  package.path,
}, ";")

local merge = require("pdfzus.merge")

local function assert_true(value, message)
  if not value then
    error(message or "Erwartet true", 2)
  end
end

local function assert_match(value, pattern, message)
  if not tostring(value):match(pattern) then
    error(message or ("Erwartet Muster " .. pattern .. ", bekommen: " .. tostring(value)), 2)
  end
end

local function read_command(command)
  local handle = io.popen(command)
  assert_true(handle ~= nil, "Befehl konnte nicht gestartet werden: " .. command)
  local output = handle:read("*a") or ""
  local ok = handle:close()
  assert_true(ok == true, "Befehl fehlgeschlagen: " .. command .. "\n" .. output)
  return output
end

local function shell_escape(value)
  return merge._test.shell_escape(value)
end

local tmp_root = "./tmp/spec"
os.execute("mkdir -p " .. shell_escape(tmp_root))

local fixtures = {
  a = "./fixtures/input-a.pdf",
  b = "./fixtures/input-b.pdf",
  multi = tmp_root .. "/input-multi.pdf",
}

local available, info = merge.is_qpdf_available()
assert_true(available, info)

assert_true(io.open(fixtures.a, "rb") ~= nil, "Fixture fehlt: " .. fixtures.a)
assert_true(io.open(fixtures.b, "rb") ~= nil, "Fixture fehlt: " .. fixtures.b)

local ok, err = merge.merge_files({ fixtures.a }, tmp_root .. "/too-few.pdf")
assert_true(ok == nil, "Einzeldatei hätte fehlschlagen müssen")
assert_match(err, "Mindestens zwei PDF", "Falsche Fehlermeldung bei zu wenigen Dateien")

local missing_ok, missing_err = merge.merge_files({ fixtures.a, "./fixtures/does-not-exist.pdf" }, tmp_root .. "/missing.pdf")
assert_true(missing_ok == nil, "Fehlende Datei hätte fehlschlagen müssen")
assert_match(missing_err, "nicht gefunden", "Falsche Fehlermeldung bei fehlender Datei")

local merged_output = tmp_root .. "/merged.pdf"
local merged_ok, merged_err = merge.merge_files({ fixtures.a, fixtures.b }, merged_output, { force = true })
assert_true(merged_ok == true, merged_err)
local merged_pages = read_command("qpdf --show-npages " .. shell_escape(merged_output))
assert_match(merged_pages, "^2%s*$", "Merged PDF sollte 2 Seiten haben")

local overwrite_ok, overwrite_err = merge.merge_files({ fixtures.a, fixtures.b }, merged_output, { force = false })
assert_true(overwrite_ok == nil, "Überschreiben ohne --force hätte fehlschlagen müssen")
assert_match(overwrite_err, "existiert bereits", "Falsche Fehlermeldung bei existierender Ausgabe")

local multi_command = table.concat({
  "qpdf --empty --pages",
  shell_escape(fixtures.a),
  shell_escape(fixtures.b),
  "--",
  shell_escape(fixtures.multi),
}, " ")
assert_true(os.execute(multi_command) == true, "Konnte Multi-Fixture nicht erzeugen")

local ranged_output = tmp_root .. "/ranged.pdf"
local ranged_ok, ranged_err = merge.merge_files({ fixtures.multi, fixtures.a }, ranged_output, {
  force = true,
  page_ranges = {
    [fixtures.multi] = "2",
    [fixtures.a] = "1",
  },
})
assert_true(ranged_ok == true, ranged_err)
local ranged_pages = read_command("qpdf --show-npages " .. shell_escape(ranged_output))
assert_match(ranged_pages, "^2%s*$", "Range-Ausgabe sollte 2 Seiten haben")

local cli_output = tmp_root .. "/cli.pdf"
local cli_command = table.concat({
  "lua",
  shell_escape("./bin/pdf-zusammenfuegen"),
  shell_escape(fixtures.a),
  shell_escape(fixtures.b),
  "--output",
  shell_escape(cli_output),
  "--force",
}, " ")
assert_true(os.execute(cli_command) == true, "CLI-Merge fehlgeschlagen")
local cli_pages = read_command("qpdf --show-npages " .. shell_escape(cli_output))
assert_match(cli_pages, "^2%s*$", "CLI-Ausgabe sollte 2 Seiten haben")

print("Alle Tests erfolgreich.")
