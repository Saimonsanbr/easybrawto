<div align="center">

<img src="assets/logo.png" width="120" alt="easybrawto logo" />

# easybrawto

**Simple browser automation via CDP**

*A personal project by an enthusiast — contributions welcome!*

[![Release](https://img.shields.io/github/v/release/Saimonsanbr/easybrawto?style=flat-square&color=black)](https://github.com/Saimonsanbr/easybrawto/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-black?style=flat-square)](LICENSE)
[![Built with Crystal](https://img.shields.io/badge/built_with-Crystal-black?style=flat-square)](https://crystal-lang.org)

<br/>

[**⬇ Download for macOS (Apple Silicon)**](https://github.com/Saimonsanbr/easybrawto/releases/latest/download/easybrawto-macos-arm64)
&nbsp;&nbsp;
[**⬇ Download for macOS (Intel)**](https://github.com/Saimonsanbr/easybrawto/releases/latest/download/easybrawto-macos-x64)
&nbsp;&nbsp;
[**⬇ Download for Linux**](https://github.com/Saimonsanbr/easybrawto/releases/latest/download/easybrawto-linux-x64)

</div>

---

## What is this?

easybrawto is a small CLI tool that lets you automate any website using a simple `.auto` script.

```
chrome.persistProfile('my_profile')

functions searchWikipedia {
  .navigate('https://en.wikipedia.org')
  .waitLoad()
  .insertText('search', 'Crystal language')
  .clickButton('Search')
  .waitLoad()
  .screenshot('result.png')
  .log('Done!')
}

run searchWikipedia
```

```bash
./easybrawto run script.auto
```

No Selenium. No WebDriver. No Python. No `npm install`.  
Just a binary and a `.auto` file.

---

## Honest intro

This is a personal project. I'm not a professional developer — I built this because I needed browser automation that wouldn't get blocked by websites, and I wanted something dead simple to write and read.

It talks directly to Chrome via the **Chrome DevTools Protocol (CDP)** — the same internal protocol the browser's DevTools uses. Real browser, real profile, no injected drivers.

It's rough around the edges. There are probably bugs. But it works for most common tasks, and the script format is simple enough that an AI agent can write it for you.

If you find it useful, great. If you find bugs or want to contribute, even better — I'm still learning Crystal and open to help.

---

## Quick start

**1. Download the binary** for your platform above

**2. Make it executable:**
```bash
chmod +x easybrawto
```

**3. Write a script** — save as `script.auto`:
```
chrome.persistProfile('my_profile')

functions openSite {
  .navigate('https://example.com')
  .waitLoad()
  .screenshot('result.png')
  .log('Done!')
}

run openSite
```

**4. Run:**
```bash
./easybrawto run script.auto
```

Requires Chrome, Brave, or Edge installed on your machine.

---

## Script syntax

### Browser setup
Place at the top of the script, before any functions.

```
# Persistent profile — saves cookies, logins, sessions between runs
# First run creates the profile. Next runs reuse it.
chrome.persistProfile('profile_name')

# Use a specific profile from your browser installation
chrome.profile('/Users/you/Library/Application Support/Google/Chrome', 'Profile 3')

# Clean temporary profile — deleted after the script ends (default)
chrome.tempProfile()

# Choose browser — default is chrome
chrome.browser('brave')
chrome.browser('edge')
```

### Commands

| Command | What it does |
|---|---|
| `.navigate('url')` | Go to a URL |
| `.waitLoad()` | Wait for the page to finish loading |
| `.waitFor('selector')` | Wait for a specific element to appear |
| `.waitSeconds(n)` | Wait a fixed number of seconds |
| `.insertText('selector', 'text')` | Type into a field |
| `.clickButton('text or selector')` | Click a button, link, or element |
| `.pressKey('key')` | Press Enter, Tab, Escape... |
| `.screenshot('file.png')` | Save a screenshot |
| `.log('message')` | Print a message in the terminal |

### Selectors

| What you write | What it matches |
|---|---|
| `'Sign in'` | Button or link with that visible text |
| `'search'` | Input field with `name="search"` |
| `'#email'` | Element with `id="email"` |
| `'.submit-btn'` | Element with `class="submit-btn"` |
| `'Enter your email'` | Input with that placeholder |

### Functions and run

```
functions login {
  .navigate('https://site.com/login')
  .waitLoad()
  .insertText('#email', 'user@mail.com')
  .insertText('#password', 'password')
  .clickButton('Sign in')
  .waitLoad()
}

functions doWork {
  .navigate('https://site.com/dashboard')
  .screenshot('dashboard.png')
}

run login
run doWork
```

---

## Examples

### Stay logged in across runs
```
chrome.persistProfile('work')

functions login {
  .navigate('https://site.com/login')
  .waitLoad()
  .insertText('#email', 'user@mail.com')
  .insertText('#password', 'password')
  .clickButton('Sign in')
  .waitLoad()
  .log('Logged in!')
}

run login
```
> Run once to log in. Next time it opens already logged in.

---

### Fill a form
```
chrome.persistProfile('automation')

functions fillForm {
  .navigate('https://site.com/contact')
  .waitLoad()
  .insertText('#name', 'John Doe')
  .insertText('#email', 'john@mail.com')
  .insertText('#message', 'Hello!')
  .clickButton('Send')
  .waitLoad()
  .screenshot('sent.png')
}

run fillForm
```

---

### Browse Chrome history
```
chrome.persistProfile('my_profile')

functions history {
  .navigate('chrome://history')
  .waitLoad()
  .screenshot('history.png')
}

run history
```

---

## Building from source

Requires [Crystal](https://crystal-lang.org/install/).

```bash
git clone https://github.com/Saimonsanbr/easybrawto
cd easybrawto
crystal build src/main.cr -o easybrawto --release
```

---

## How it works

1. Reads the `.auto` script and parses functions and commands
2. Launches Chrome/Brave/Edge with `--remote-debugging-port=9222`
3. Connects via WebSocket to the Chrome DevTools Protocol
4. Sends CDP commands and JavaScript directly to the open tab
5. Each command runs in sequence, waiting for the browser before continuing

No WebDriver. No browser extension. No persistent injected scripts.

---

## Current status — v0.1.0

This is an early release. It works for most common tasks but has rough edges.

**Working:**
- navigate, waitLoad, waitFor, waitSeconds
- insertText — compatible with React, Vue, Angular
- clickButton — finds by text, aria-label, or CSS selector
- pressKey
- screenshot
- Persistent, temporary, and system profiles
- Chrome, Brave, Edge on macOS

**Known limitations:**
- No Windows binaries yet
- No selectOption, checkBox, scroll, hover commands yet
- waitLoad can be slow on heavy SPAs — use waitFor when possible

**Coming next:**
- selectOption, checkBox, scroll, hover
- Windows support
- Variables in scripts
- Better error messages

---

## Contributing

Issues and PRs are welcome. I'm not an expert in Crystal — if you see something wrong or have a better approach, please open an issue or send a PR. This project exists because I needed it, and it'll get better with help.

---

## License

MIT
