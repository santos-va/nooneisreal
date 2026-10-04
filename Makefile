SHELL := /usr/bin/env bash
# Проводка локального забезпечення nooneisreal. Коментарі коротко; закон — у
# docs/system/constitution.md, адаптер Claude — у CLAUDE.md.
#
# Godot: бінар береться з GODOT_BIN, інакше `godot` на PATH.
#   GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check

GODOT ?= $(if $(GODOT_BIN),$(GODOT_BIN),godot)
GAME  := game
# Чесний run: відмова при другому Godot на ту саму теку + імпорт, коли HEAD змінився (tools/run/godot_guard.sh).
GUARD := bash tools/run/godot_guard.sh

.PHONY: roles gates check check-playable import run run-plane run-rig editor update fetch-assets hooks-check

# Таблиця ролей із tools/hooks/roles.map: аляс · тіло · Claude skill · мітка.
roles:
	@python3 -c 'import sys; rows=[[c.strip() for c in l.split("|")] for l in open("tools/hooks/roles.map", encoding="utf-8") if l.strip() and not l.lstrip().startswith("#")]; rows=[[r[0], r[1], r[2], r[5]] for r in rows]; w=[max(len(r[i]) for r in rows) for i in range(4)]; print("\n".join("  " + "  ".join(c.ljust(w[i]) for i, c in enumerate(r)) for r in rows))'

# Батарея гейтів: rc = кількість гейтів, що впали; rc=2 всередині блокує теж.
gates:
	bash tools/gates/run_gates.sh

# Headless-імпорт проєкту + парсинг кожного .gd + smoke. Без бінаря — інструкція, не мовчазний пропуск.
# Smoke іде з --fixed-fps 60: одна ітерація = один фізкадр, тож --quit-after 40000 — це 40000 кадрів на будь-якій
# машині (без нього headless крутить цикл швидше за 60 Гц і бюджет кадрів залежить від швидкості). «Зелений» —
# лише rc=0 І рядок «[smoke] ALL OK»: вихід по --quit-after дає rc=0 без цього рядка, і це червоне.
check:
	@G="$(GODOT)"; case "$$G" in */*) ;; *) G="$$(command -v "$$G" 2>/dev/null)";; esac; \
	if [ -z "$$G" ] || [ ! -f "$$G" ] || [ ! -x "$$G" ]; then \
	  echo "godot не знайдено (GODOT_BIN='$(GODOT_BIN)'): постав Godot 4.7 і додай бінар на PATH або задай GODOT_BIN=/шлях/до/godot"; \
	  echo "  macOS: GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check"; \
	  exit 2; fi; \
	$(GUARD) busy $(GAME) || exit $$?; \
	echo "── godot --headless --import ($$G) ──"; \
	OUT="$$("$$G" --headless --path $(GAME) --import 2>&1)"; rc=$$?; \
	printf '%s\n' "$$OUT" | grep -iE 'error|warning' | head -n 40; \
	[ $$rc -eq 0 ] || { echo "ІМПОРТ ВПАВ: rc=$$rc"; exit $$rc; }; \
	$(GUARD) stamp $(GAME); \
	GODOT_BIN="$$G" bash tools/gates/gd_check_all.sh || exit $$?; \
	echo "── smoke test: godot --headless --fixed-fps 60 -- --smoke ──"; \
	SMOKE="$$("$$G" --headless --path $(GAME) --fixed-fps 60 --quit-after 40000 -- --smoke 2>&1)"; rc=$$?; \
	printf '%s\n' "$$SMOKE" | grep -E '^\[smoke\]|SCRIPT ERROR|ERROR:'; \
	if [ $$rc -ne 0 ]; then echo "SMOKE ЧЕРВОНИЙ rc=$$rc"; exit $$rc; fi; \
	printf '%s\n' "$$SMOKE" | grep -q '^\[smoke\] ALL OK' || { echo "SMOKE ЧЕРВОНИЙ: немає рядка «[smoke] ALL OK» — тест не дійшов до кінця (--quit-after?)"; exit 1; }; \
	J="$$(printf '%s\n' "$$SMOKE" | grep -c 'not supported by Jolt')"; \
	[ "$$J" -eq 0 ] || { echo "SMOKE ЧЕРВОНИЙ: $$J попереджень Jolt про масштаб тіла (Н7, запуск 7.1)"; exit 1; }; \
	echo "SMOKE ЗЕЛЕНИЙ"

# Retain the full smoke, then verify the playable presentation and its negative controls.
check-playable: check
	GODOT_BIN="$(GODOT)" bash tools/gates/playable_check.sh

# Свіжий клон не має game/.godot/ (у .gitignore), а з ним — реєстру class_name.
# Без імпорту гра падає з «Could not find type CharacterData». Тому run/editor
# спершу імпортують проєкт, якщо реєстру ще немає АБО HEAD змінився з останнього
# імпорту (штамп game/.godot/nir_import_head) — інакше після pull/checkout кеш
# класів старий («Could not find type Printer»). І відмовляють, коли на цю ж теку
# вже працює інший Godot (агент, make check, редактор).
PREP = @$(GUARD) busy $(GAME) || exit $$?; \
	if $(GUARD) need-import $(GAME); then $(MAKE) --no-print-directory import || exit $$?; fi
CLASS_CACHE := $(GAME)/.godot/global_script_class_cache.cfg

import:
	@echo "── імпорт проєкту ($(GODOT)) — перший раз до хвилини ──"
	@$(GODOT) --headless --path $(GAME) --import >/dev/null 2>&1; \
	if [ -f $(CLASS_CACHE) ]; then $(GUARD) stamp $(GAME); echo "імпорт готовий"; else echo "ІМПОРТ НЕ СТВОРИВ $(CLASS_CACHE): перевір, що GODOT_BIN вказує на Godot 4.7+"; exit 1; fi

# Запустити гру (головна сцена з project.godot).
run:
	$(PREP)
	$(GODOT) --path $(GAME)

# Бій 0.2 у площині (з 0.3 за замовчуванням — вільний 3D-рух; `make run` грає саме його).
run-plane:
	$(PREP)
	$(GODOT) --path $(GAME) -- --plane

# Запуск 4 (C1): манекен UAL з кліпами замість капсул (`-- --skeletal-rig`).
run-rig:
	$(PREP)
	$(GODOT) --path $(GAME) -- --skeletal-rig

# Відкрити проєкт у редакторі.
editor:
	$(PREP)
	$(GODOT) --editor --path $(GAME)

# Оновити гру з GitHub і переімпортувати проєкт (нові class_name інакше не видно).
#   make update                                   # поточна гілка
#   make update BRANCH=claude/friendly-ritchie-3ti2sm   # перейти на гілку PR і оновити
# Незакомічені зміни → відмова (нічого не стирає). Лише fast-forward: розійшлася історія → відмова.
update:
	@set -e; \
	if [ -n "$$(git status --porcelain --untracked-files=no)" ]; then \
	  echo "ВІДМОВА: є незакомічені зміни — закоміть або git stash, потім знову make update"; \
	  git status --short --untracked-files=no; exit 1; fi; \
	git fetch origin; \
	if [ -n "$(BRANCH)" ]; then git checkout "$(BRANCH)"; fi; \
	CUR="$$(git rev-parse --abbrev-ref HEAD)"; OLD="$$(git rev-parse HEAD)"; \
	git merge --ff-only "origin/$$CUR" || { echo "ВІДМОВА: гілка $$CUR розійшлася з origin/$$CUR — потрібне ручне злиття"; exit 1; }; \
	NEW="$$(git rev-parse HEAD)"; \
	if [ "$$OLD" = "$$NEW" ]; then echo "гілка $$CUR: уже актуальна ($$(git log --oneline -1))"; \
	else echo "гілка $$CUR: нові коміти"; git log --oneline "$$OLD..$$NEW"; fi; \
	$(MAKE) --no-print-directory import; \
	echo "готово: make run"

# Підтягнути ассети за реєстром (скрипт пише лід).
fetch-assets:
	bash tools/fetch_assets.sh

# Хуки мають бути виконуваними — інакше Claude Code їх мовчки не запустить.
hooks-check:
	@rc=0; for h in .claude/hooks/*.sh tools/hooks/*.sh tools/gates/*.sh; do \
	  test -x "$$h" || { echo "НЕ ВИКОНУВАНИЙ: $$h  (chmod +x $$h)"; rc=1; }; \
	done; [ $$rc -eq 0 ] && echo "хуки і гейти виконувані"; exit $$rc
