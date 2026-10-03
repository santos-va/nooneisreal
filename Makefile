SHELL := /usr/bin/env bash
# Проводка локального забезпечення nooneisreal. Коментарі коротко; закон — у
# docs/system/constitution.md, адаптер Claude — у CLAUDE.md.
#
# Godot: бінар береться з GODOT_BIN, інакше `godot` на PATH.
#   GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check

GODOT ?= $(if $(GODOT_BIN),$(GODOT_BIN),godot)
GAME  := game

.PHONY: roles gates check import run editor fetch-assets hooks-check

# Таблиця ролей із tools/hooks/roles.map: аляс · тіло · Claude skill · мітка.
roles:
	@python3 -c 'import sys; rows=[[c.strip() for c in l.split("|")] for l in open("tools/hooks/roles.map", encoding="utf-8") if l.strip() and not l.lstrip().startswith("#")]; rows=[[r[0], r[1], r[2], r[5]] for r in rows]; w=[max(len(r[i]) for r in rows) for i in range(4)]; print("\n".join("  " + "  ".join(c.ljust(w[i]) for i, c in enumerate(r)) for r in rows))'

# Батарея гейтів: rc = кількість гейтів, що впали; rc=2 всередині блокує теж.
gates:
	bash tools/gates/run_gates.sh

# Headless-імпорт проєкту + парсинг кожного .gd. Без бінаря — інструкція, не мовчазний пропуск.
check:
	@G="$(GODOT)"; case "$$G" in */*) ;; *) G="$$(command -v "$$G" 2>/dev/null)";; esac; \
	if [ -z "$$G" ] || [ ! -f "$$G" ] || [ ! -x "$$G" ]; then \
	  echo "godot не знайдено (GODOT_BIN='$(GODOT_BIN)'): постав Godot 4.7 і додай бінар на PATH або задай GODOT_BIN=/шлях/до/godot"; \
	  echo "  macOS: GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check"; \
	  exit 2; fi; \
	echo "── godot --headless --import ($$G) ──"; \
	OUT="$$("$$G" --headless --path $(GAME) --import 2>&1)"; rc=$$?; \
	printf '%s\n' "$$OUT" | grep -iE 'error|warning' | head -n 40; \
	[ $$rc -eq 0 ] || { echo "ІМПОРТ ВПАВ: rc=$$rc"; exit $$rc; }; \
	GODOT_BIN="$$G" bash tools/gates/gd_check_all.sh || exit $$?; \
	echo "── smoke test: godot --headless -- --smoke ──"; \
	"$$G" --headless --path $(GAME) --quit-after 12000 -- --smoke 2>&1 | grep -E '^\[smoke\]|SCRIPT ERROR|ERROR:' ; \
	rc=$${PIPESTATUS[0]}; [ $$rc -eq 0 ] && echo "SMOKE ЗЕЛЕНИЙ" || { echo "SMOKE ЧЕРВОНИЙ rc=$$rc"; exit $$rc; }

# Свіжий клон не має game/.godot/ (у .gitignore), а з ним — реєстру class_name.
# Без імпорту гра падає з «Could not find type CharacterData». Тому run/editor
# спершу імпортують проєкт, якщо реєстру ще немає (одноразово, до хвилини).
CLASS_CACHE := $(GAME)/.godot/global_script_class_cache.cfg

import:
	@echo "── імпорт проєкту ($(GODOT)) — перший раз до хвилини ──"
	@$(GODOT) --headless --path $(GAME) --import >/dev/null 2>&1; \
	if [ -f $(CLASS_CACHE) ]; then echo "імпорт готовий"; else echo "ІМПОРТ НЕ СТВОРИВ $(CLASS_CACHE): перевір, що GODOT_BIN вказує на Godot 4.7+"; exit 1; fi

# Запустити гру (головна сцена з project.godot).
run:
	@[ -f $(CLASS_CACHE) ] || $(MAKE) --no-print-directory import
	$(GODOT) --path $(GAME)

# Відкрити проєкт у редакторі.
editor:
	@[ -f $(CLASS_CACHE) ] || $(MAKE) --no-print-directory import
	$(GODOT) --editor --path $(GAME)

# Підтягнути ассети за реєстром (скрипт пише лід).
fetch-assets:
	bash tools/fetch_assets.sh

# Хуки мають бути виконуваними — інакше Claude Code їх мовчки не запустить.
hooks-check:
	@rc=0; for h in .claude/hooks/*.sh tools/hooks/*.sh tools/gates/*.sh; do \
	  test -x "$$h" || { echo "НЕ ВИКОНУВАНИЙ: $$h  (chmod +x $$h)"; rc=1; }; \
	done; [ $$rc -eq 0 ] && echo "хуки і гейти виконувані"; exit $$rc
