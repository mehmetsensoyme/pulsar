# 🌐 Pulsar Internationalization & Localization Guide

Pulsar features a lightweight, zero-dependency, modular localization engine. All translations are stored in human-readable `.lang` files using standard `key = value` syntax.

Anyone can easily contribute new language translations without needing to write Swift code or compile the project!

---

## 🚀 How to Add a New Language (in 3 Minutes)

### Step 1: Fork and Clone
Fork the [Pulsar repository](https://github.com/mehmetsensoyme/pulsar) and clone it locally:
```bash
git clone https://github.com/<your-username>/pulsar.git
cd pulsar
```

### Step 2: Create Your Language File
Copy the master English template [`en.lang`](PulsarApp/Sources/Pulsar/Resources/Languages/en.lang) into your target language code (e.g., `de.lang` for German, `fr.lang` for French, `es.lang` for Spanish, `ja.lang` for Japanese):

```bash
cp PulsarApp/Sources/Pulsar/Resources/Languages/en.lang PulsarApp/Sources/Pulsar/Resources/Languages/de.lang
```

### Step 3: Update Header & Translate Values
Open your new file in any text editor. Update the language metadata at the top:

```ini
# ==============================================================================
# PULSAR LOCALIZATION FILE: DEUTSCH (de.lang)
# Language Name: Deutsch
# Language Code: de
# ==============================================================================

language.name = Deutsch
language.code = de
```

Translate the strings on the right side of the `=` sign. **Keep the keys on the left unchanged:**

```ini
# Example translation for German
main.empty_title = Pulsar
main.empty_subtitle = Ziehen Sie eine Archivdatei hierher, um sie zu öffnen
main.open_archive = Archiv öffnen (⌘O)
main.new_archive = Neues Archiv (⌘N)
```

> **Rules:**
> 1. Lines beginning with `#` or `//` are comments and will be ignored by the parser.
> 2. Do NOT change the keys (the left side of `=`).
> 3. If a key is missing from your file, Pulsar automatically falls back to `en.lang`.

---

## 🧪 Testing Your Language Locally (No Compilation Required!)

Pulsar supports dynamic external language loading. You can test your translation file immediately in the installed `Pulsar.app` on your Mac without compiling Swift:

1. Create the custom languages folder:
   ```bash
   mkdir -p ~/Library/Application\ Support/Pulsar/Languages
   ```
2. Copy your `.lang` file into it:
   ```bash
   cp PulsarApp/Sources/Pulsar/Resources/Languages/de.lang ~/Library/Application\ Support/Pulsar/Languages/
   ```
3. Open **Pulsar**, go to **Settings (⌘,) ➔ General ➔ Interface Language**, and select your language from the dropdown.

Alternatively, you can click **"Harici Dil Klasörünü Aç... / Open Custom Languages Folder..."** in Pulsar Settings to reveal the folder in Finder.

---

## 🛠️ Automated Testing & Validation

To verify dictionary completeness and ensure all required keys are present, run the automated test suite:

```bash
./Scripts/run_tests.sh
```

The test runner will validate key syntax, fallback safety, and language registration.

---

## 📬 Submitting Your Pull Request

Once your translation is verified:
1. Commit your `.lang` file:
   ```bash
   git checkout -b l10n/add-de-language
   git add PulsarApp/Sources/Pulsar/Resources/Languages/de.lang
   git commit -m "l10n: add German (de.lang) localization"
   git push origin l10n/add-de-language
   ```
2. Open a Pull Request on GitHub.

Thank you for helping make Pulsar accessible to everyone around the world! 🌌
