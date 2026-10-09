# Moodle-Plugin-Health-Check

Prüft jede Woche (und bei PRs, die die Plugin-Liste ändern) alle Plugins, die das Image ausliefert.
Workflow: `.github/workflows/plugin-health-check.yaml`. Ergebnis: Job-Zusammenfassung, Artefakt
`plugin-health-report` (Markdown + JSON) und bei geplanten Läufen ein Issue mit Label `plugin-health`.

## Was geprüft wird

| Bereich | Quelle | Stufe bei Problem |
|---|---|---|
| Plugin fehlt in `plugins.json`, keine Version für die Moodle-Version | `pluginList.sh`, `plugins.json`, `Dockerfile` | FAIL |
| MD5 des Downloads passt nicht zu `plugins.json` | Moodle-Verzeichnis | FAIL |
| Artefakt enthält anderes Plugin als erwartet | `version.php` im ausgelieferten ZIP | FAIL |
| Versionsnummer in der Zukunft | `version.php` | WARN |
| Keine GPL-Kopfzeile | `version.php` | WARN |
| Repo archiviert / kein Commit seit 2 Jahren | Git, GitHub-API | FAIL |
| Kein Commit / kein Release seit 1 Jahr | Git, Verzeichnis | WARN |
| Pin auf Branch statt Tag; neuerer Tag in derselben Release-Linie; Tag existiert nicht | `downloadPlugins.sh` + Git | WARN / WARN / FAIL |
| Neuere Version im Live-Verzeichnis als in `plugins.json` | download.moodle.org | WARN |
| Gleiches Plugin aus zwei Quellen; Versions-Downgrade zwischen ihnen | alle Quellen | FAIL / WARN |
| CVE nennt das Plugin | CVEProject/cvelistV5 | FAIL bis bewertet |
| Veröffentlichtes GitHub-Security-Advisory | GitHub-API | FAIL bis bewertet |
| Gebündelte Bibliothek mit bekannter Lücke | `thirdpartylibs.xml` + OSV | FAIL bis bewertet |
| Bekannter Fix fehlt / verwundbares Muster vorhanden | `code_patterns` in `config.json` | FAIL |

Alles, was nicht geprüft werden konnte (Netzwerk, Bitbucket, Bibliothek ohne OSV-Zuordnung …),
steht als **UNCHECKED** im Bericht. UNCHECKED ist kein Erfolg.

## Bei einem Befund

* **CVE / Advisory / OSV-Treffer:** prüfen und in `config.json` → `vulnerability_triage` eintragen
  (`affected`, `not_affected`, `fixed` mit `fixed_version`, oder `accepted`) – immer mit `note`.
  Unbewertete Treffer bleiben FAIL.
* **Bewusst stabiles, aber altes Plugin:** `maintenance_exceptions` mit Begründung.
* **Fix, der nicht wieder verloren gehen darf** (z. B. im eLeDia-Fork): Regel in `code_patterns`.
* **Fehlalarm beim CVE-Abgleich durch zu allgemeinen Namen:** Begriff in `cve_generic_terms`.

In PRs zählen nur **neue** Befunde: Der Basisstand des Ziel-Branches wird mitgeprüft, dort schon
vorhandene Befunde erscheinen als INFO.

## Lokal ausführen

```bash
python -m unittest discover -s moodle/scripts/ci/plugin_health -p 'test_*.py'
python moodle/scripts/ci/plugin_health/check.py --offline --report-md /tmp/report.md   # nur Git
GITHUB_TOKEN=$(gh auth token) python moodle/scripts/ci/plugin_health/check.py \
  --cve-dir /pfad/zu/cvelistV5 --live-pluglist --report-md /tmp/report.md             # vollständig
```

## Grenzen

* Sonderfälle in `downloadPlugins.sh` werden statisch erkannt (git clone + `target_tag`/`target_branch`,
  GitHub-Archive, Marketplace-URLs, `download_github_release`). Neue Muster dort ergeben eine WARN
  „keine Quelle erkannt“ – dann Parser erweitern.
* Der CVE-Abgleich ist textbasiert (Komponentenname, Plugin-Name, Repo-Name, Aliase). Er findet
  Kandidaten, keine Gewissheit; deshalb die Pflicht zur Bewertung.
* Die Versionen in `thirdpartylibs.xml` sind Herstellerangaben und können falsch sein.
* Bitbucket-Repos (`format_tiles`) erhalten keine GitHub-Metadaten.
