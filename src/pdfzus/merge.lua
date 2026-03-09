local merge = {}

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shell_escape(value)
  return "'" .. tostring(value):gsub("'", [["'"']]) .. "'"
end

local function file_exists(path)
  local handle = io.open(path, "rb")
  if handle then
    handle:close()
    return true
  end
  return false
end

local function dirname(path)
  local normalized = tostring(path):gsub("/+$", "")
  local dir = normalized:match("^(.*)/[^/]+$")
  if dir and dir ~= "" then
    return dir
  end
  return "."
end

local function path_basename(path)
  return tostring(path):match("([^/]+)$") or tostring(path)
end

local function path_join(left, right)
  if left:sub(-1) == "/" then
    return left .. right
  end
  return left .. "/" .. right
end

local function ensure_writable_output(output_path, force)
  if file_exists(output_path) and not force then
    return nil, "Die Ausgabedatei existiert bereits. Verwenden Sie --force, um sie zu überschreiben."
  end

  local directory = dirname(output_path)
  local probe = path_join(directory, ".pdfzus-write-test-" .. tostring(os.time()) .. "-" .. path_basename(output_path))
  local handle = io.open(probe, "wb")
  if not handle then
    return nil, "Der Ausgabeordner ist nicht beschreibbar: " .. directory
  end
  handle:close()
  os.remove(probe)

  return true
end

local function validate_page_range(page_range)
  if page_range == nil then
    return nil
  end

  local normalized = trim(tostring(page_range))
  if normalized == "" then
    return nil
  end

  if not normalized:match("^[%d,%-%s]+$") then
    return nil, "Ungültiger Seitenbereich: " .. normalized
  end

  return normalized
end

local function popen_read(command)
  local handle = io.popen(command)
  if not handle then
    return nil, "Befehl konnte nicht gestartet werden."
  end

  local output = handle:read("*a") or ""
  local ok, _, code = handle:close()
  if ok then
    return output
  end

  return nil, trim(output) ~= "" and trim(output) or ("Befehl fehlgeschlagen mit Code " .. tostring(code))
end

function merge.is_qpdf_available()
  local version, err = popen_read("command -v qpdf >/dev/null 2>&1 && qpdf --version 2>&1")
  if not version then
    return false, "qpdf ist nicht installiert oder nicht im PATH verfügbar."
  end

  local first_line = trim((version:match("([^\n]+)") or version))
  if first_line == "" then
    first_line = "qpdf verfügbar"
  end

  return true, first_line
end

function merge.merge_files(inputs, output_path, opts)
  opts = opts or {}

  if type(inputs) ~= "table" then
    return nil, "Die Eingaben müssen als Tabelle mit Dateipfaden übergeben werden."
  end

  if #inputs < 2 then
    return nil, "Mindestens zwei PDF-Dateien sind erforderlich."
  end

  if type(output_path) ~= "string" or trim(output_path) == "" then
    return nil, "Ein Ausgabepfad ist erforderlich."
  end

  local ok, qpdf_info = merge.is_qpdf_available()
  if not ok then
    return nil, qpdf_info
  end

  local writable, writable_err = ensure_writable_output(output_path, opts.force == true)
  if not writable then
    return nil, writable_err
  end

  local command_parts = { "qpdf", "--empty", "--pages" }
  local page_ranges = opts.page_ranges or {}

  for _, input in ipairs(inputs) do
    if type(input) ~= "string" or trim(input) == "" then
      return nil, "Jeder Eingabepfad muss ein nicht-leerer String sein."
    end

    if not file_exists(input) then
      return nil, "Eingabedatei nicht gefunden: " .. input
    end

    command_parts[#command_parts + 1] = "--file=" .. shell_escape(input)

    local page_range, range_err = validate_page_range(page_ranges[input])
    if range_err then
      return nil, range_err
    end

    if page_range then
      command_parts[#command_parts + 1] = "--range=" .. page_range
    end
  end

  command_parts[#command_parts + 1] = "--"
  command_parts[#command_parts + 1] = shell_escape(output_path)
  local command = table.concat(command_parts, " ")

  if opts.verbose then
    io.stderr:write("[pdf-zusammenfuegen] " .. qpdf_info .. "\n")
    io.stderr:write("[pdf-zusammenfuegen] " .. command .. "\n")
  end

  local run_ok, _, exit_code = os.execute(command)
  if run_ok ~= true and run_ok ~= 0 then
    return nil, "qpdf konnte die PDFs nicht zusammenführen. Exit-Code: " .. tostring(exit_code or run_ok)
  end

  if not file_exists(output_path) then
    return nil, "qpdf wurde ausgeführt, aber die Ausgabedatei wurde nicht erzeugt."
  end

  return true
end

merge._test = {
  shell_escape = shell_escape,
  trim = trim,
}

return merge
