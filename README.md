# 📝 NanNotes

Лёгкий, быстрый и визуально выразительный менеджер коротких заметок и закладок для **Linux (x86_64)**, написанный на Flutter. ✨

## ✨ Возможности
- 🎨 **Визуальное разделение контента:** текстовые заметки выполнены в тёплых янтарных тонах, а ссылки — в неоново-голубых с векторными фоновыми иллюстрациями.
- ⚡ **Мгновенный ввод прямо в главном окне:** переключайтесь между режимами «Заметка» и «Ссылка», выбирайте папку и добавляйте записи по нажатию `Enter`.
- 🔗 **Ссылки с описанием:** сохраняйте не просто голый URL, а понятное название сайта, статьи или видео вместе с адресом.
- 📁 **Умные папки с иконками:** создавайте отдельные категории для заметок (фильмы, идеи, книги) и для ссылок (видео, сервисы, статьи).
- 🖱️ **Действия в один клик:** клик по заметке мгновенно копирует её в буфер обмена, а клик по ссылке открывает её в браузере.
- 💾 **Локальное и лёгкое хранение:** все записи хранятся в одном аккуратном JSON-файле `~/.nan_notes.json`.

---

## 📦 Быстрая установка (Linux x86_64)

Приложение распространяется в формате автономного **AppImage** и подходит для любых 64-битных дистрибутивов Linux (Ubuntu, Zorin OS, Linux Mint, Debian, Fedora, Arch и др.).

### 1. Скачивание файлов ⬇️
1. Перейдите во вкладку **[Releases](../../releases)** справа и скачайте файл **`NanNotes-x86_64.AppImage`**.
2. Также сохраните файл **`logo.png`** из корня этого репозитория в ту же папку (например, в `~/Documents/NanNotes`), чтобы подтянулась иконка приложения.

### 2. Добавление в меню приложений и запуск из терминала 🖥️
Просто скопируйте и выполните эту команду в терминале — она сама найдёт скачанные файлы, создаст ярлык в меню приложений и добавит команду `nannotes` для запуска из консоли:

```bash
python3 -c '
import os, glob, shutil, subprocess

matches = sorted(glob.glob(os.path.expanduser("~/**/NanNotes-x86_64.AppImage"), recursive=True))
if not matches:
    print("Файл NanNotes-x86_64.AppImage не найден в домашней папке")
    exit(1)

app_path = matches.pop(0)
app_dir = os.path.dirname(app_path)
os.chmod(app_path, 0o755)

bin_dir = os.path.expanduser("~/.local/bin")
os.makedirs(bin_dir, exist_ok=True)
bin_file = os.path.join(bin_dir, "nannotes")
with open(bin_file, "w") as f:
    f.write(f"""#!/bin/sh
nohup env GDK_BACKEND=x11 "{app_path}" >/dev/null 2>&1 &
""")
os.chmod(bin_file, 0o755)

icons_dir = os.path.expanduser("~/.local/share/icons")
os.makedirs(icons_dir, exist_ok=True)
icon_dest = os.path.join(icons_dir, "nannotes.png")
logo_src = os.path.join(app_dir, "logo.png")
if os.path.exists(logo_src):
    shutil.copy2(logo_src, icon_dest)

desktop_dir = os.path.expanduser("~/.local/share/applications")
os.makedirs(desktop_dir, exist_ok=True)
desktop_file = os.path.join(desktop_dir, "nannotes.desktop")
with open(desktop_file, "w") as f:
    f.write(f"""[Desktop Entry]
Type=Application
Name=NanNotes
Comment=Быстрые заметки и закладки
Exec={bin_file}
Icon={icon_dest}
Categories=Utility;Office;
Terminal=false
StartupWMClass=nan_notes
""")
os.chmod(desktop_file, 0o755)
subprocess.run(["update-desktop-database", desktop_dir])

bashrc = os.path.expanduser("~/.bashrc")
if os.path.exists(bashrc):
    content = open(bashrc).read()
    if ".local/bin" not in content:
        with open(bashrc, "a") as f:
            f.write("\nexport PATH=\"HOME/.local/bin:PATH\"\n")

print("Готово! Ярлык создан, запуск из терминала: nannotes")
'
```

После этого программу можно открыть из меню приложений или из любой директории терминала командой:
```bash
nannotes
```

---

## ⭐ Поддержка проекта
Если утилита помогла навести порядок в заметках и ссылках — поставьте **звёздочку (Star)** этому репозиторию в правом верхнем углу! 🙌
