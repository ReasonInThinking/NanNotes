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
2. Также сохраните файл **`logo.png`** из корня этого репозитория, если хотите добавить программу в меню приложений со штатной иконкой.

### 2. Добавление в меню приложений Linux 🖥️
Положите `NanNotes-x86_64.AppImage` и `logo.png` в одну папку (например, в `~/Documents/NanNotes`) и выполните эту команду в терминале:

```bash
python3 -c '
import os, glob, subprocess

matches = glob.glob(os.path.expanduser("~/**/NanNotes-x86_64.AppImage"), recursive=True)
if not matches:
    print("Файл NanNotes-x86_64.AppImage не найден в домашней папке")
else:
    app_path = matches[0]
    app_dir = os.path.dirname(app_path)
    os.chmod(app_path, 0o755)
    desktop_dir = os.path.expanduser("~/.local/share/applications")
    os.makedirs(desktop_dir, exist_ok=True)
    desktop_file = os.path.join(desktop_dir, "nannotes.desktop")
    with open(desktop_file, "w") as f:
        f.write(f"""[Desktop Entry]
Type=Application
Name=NanNotes
Comment=Быстрые заметки и закладки
Exec=env GDK_BACKEND=x11 {app_path}
Icon={app_dir}/logo.png
Categories=Utility;Office;
Terminal=false
StartupWMClass=nan_notes
""")
    subprocess.run(["update-desktop-database", desktop_dir])
    print("Ярлык успешно создан для:", app_path)
'
```

### 3. Запуск из терминала (опционально) ⌨️
Добавьте функцию `nannotes` в `~/.bashrc`, чтобы запускать программу из любой директории консоли:

```bash
python3 -c '
import os
p = os.path.expanduser("~/.bashrc")
content = open(p).read() if os.path.exists(p) else ""
if "nannotes()" not in content:
    func = """
nannotes() {
  local app
  app=`find ~ -maxdepth 4 -name "NanNotes-x86_64.AppImage" 2>/dev/null | head -n 1`
  if [ -n "\$app" ]; then
    nohup env GDK_BACKEND=x11 "\$app" >/dev/null 2>&1 &
  else
    echo "Файл NanNotes-x86_64.AppImage не найден"
  fi
}
"""
    open(p, "w").write(content.rstrip() + "\n" + func)
' && source ~/.bashrc
```

Запуск из терминала:
```bash
nannotes
```


---

## ⭐ Поддержка проекта
Если утилита помогла навести порядок в заметках и ссылках — поставьте **звёздочку (Star)** этому репозиторию в правом верхнем углу! 🙌
