# easybrawto

**Simple browser automation via CDP**

> ⚠️ This is a personal project built by an enthusiast with limited experience. It works for my use cases, but expect rough edges. PRs, issues, and feedback are very welcome.

Automate any website with a simple script. No Selenium. No WebDriver. No Python. Just a binary and a `.auto` file.

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

---

## The honest story

I kept hitting the same wall: automation tools like Selenium and Playwright work great until a site decides it doesn't like bots. Then you spend hours fighting detection instead of actually automating things.

I noticed that controlling Chrome directly via CDP — the same protocol DevTools uses internally — worked without any of those problems. No injected scripts. No WebDriver fingerprint. Just a real browser doing real things.

So I built a small tool around that idea, with a syntax simple enough that I don't have to think about selectors and async timing every time I want to click a button.

It's written in [Crystal](https://crystal-lang.org), compiles to a single binary, and the script format is intentionally minimal. I'm not a professional developer — this is a side project I built while learning. The code probably has rough spots. If you know Crystal and see something wrong, I'd genuinely appreciate a PR or even just an issue pointing it out.

---

## Why CDP instead of Playwright/Puppeteer?

Fair question. Playwright is mature, well-documented, and has a huge ecosystem.

The difference that matters for my use case: when you use Playwright or Puppeteer, they inject JavaScript into the page to control it. Some sites detect this. CDP talks to the browser at a lower level — it's the same channel the browser uses to talk to its own DevTools. Combined with a real persistent browser profile (with your real cookies and session), most anti-bot systems don't trigger.

Your mileage may vary. This isn't a silver bullet. But for the automations I've tested, it's been more reliable than the alternatives.

---

## Download

**macOS (Apple Silicon)**
```bash
curl -L https://github.com/YOUR_USERNAME/easybrawto/releases/latest/download/easybrawto-macos-arm64 -o easybrawto
chmod +x easybrawto
```

**macOS (Intel)**
```bash
curl -L https://github.com/YOUR_USERNAME/easybrawto/releases/latest/download/easybrawto-macos-x64 -o easybrawto
chmod +x easybrawto
```

**Linux (x64)**
```bash
curl -L https://github.com/YOUR_USERNAME/easybrawto/releases/latest/download/easybrawto-linux-x64 -o easybrawto
chmod +x easybrawto
```

Requires Chrome, Brave, or Edge already installed on your machine.

---

## Quick start

**1. Download the binary**

**2. Write a script** — save as `script.auto`:

```
chrome.persistProfile('my_profile')

functions openYoutube {
  .navigate('https://youtube.com')
  .waitLoad()
  .screenshot('youtube.png')
  .log('Done!')
}

run openYoutube
```

**3. Run:**
```bash
./easybrawto run script.auto
```

---

## Script syntax

### Browser setup
Place at the top of your script, before functions.

```
# Persistent profile — saves cookies, sessions and logins between runs
# First run creates the profile. Next runs reuse it.
chrome.persistProfile('profile_name')

# Use a specific profile from your existing Chrome installation
chrome.profile('/Users/you/Library/Application Support/Google/Chrome', 'Profile 3')

# Clean temporary profile — deleted after the script ends (default)
chrome.tempProfile()

# Choose which browser to use — default is chrome
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
| `.clickButton('text or selector')` | Click a button or link |
| `.pressKey('key')` | Press a key (Enter, Tab, Escape...) |
| `.screenshot('file.png')` | Save a screenshot |
| `.log('message')` | Print a message to the terminal |

### Selectors

For `.insertText` and `.clickButton`, you can identify elements by:

```
# Visible button text
.clickButton('Sign in')

# Field name attribute
.insertText('search', 'my query')

# CSS id
.insertText('#email', 'user@mail.com')

# CSS class
.clickButton('.submit-button')

# Placeholder text
.insertText('Enter your email', 'user@mail.com')

# aria-label
.clickButton('Close dialog')
```

easybrawto tries each of these in order until it finds a match, so you usually don't need to inspect the HTML — just use whatever feels most natural.

### Functions

```
functions login {
  .navigate('https://site.com/login')
  .waitLoad()
  .insertText('#email', 'user@mail.com')
  .insertText('#password', 'mypassword')
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

### Login once, stay logged in forever
```
chrome.persistProfile('work_account')

functions login {
  .navigate('https://site.com/login')
  .waitLoad()
  .insertText('#email', 'user@mail.com')
  .insertText('#password', 'password')
  .clickButton('Sign in')
  .waitLoad()
  .screenshot('done.png')
  .log('Logged in!')
}

run login
```
Run once to log in. After that, every run opens already authenticated.

---

### Fill and submit a form
```
chrome.persistProfile('automation')

functions fillForm {
  .navigate('https://site.com/contact')
  .waitLoad()
  .insertText('#name', 'John Doe')
  .insertText('#email', 'john@mail.com')
  .insertText('#message', 'Hello from easybrawto!')
  .clickButton('Send')
  .waitLoad()
  .screenshot('sent.png')
}

run fillForm
```

---

### Open your browser history
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
git clone https://github.com/YOUR_USERNAME/easybrawto
cd easybrawto
crystal build src/main.cr -o easybrawto --release
./easybrawto run examples/test.auto
```

---

## How it works (roughly)

1. Reads and parses the `.auto` script
2. Launches Chrome/Brave/Edge with `--remote-debugging-port=9222`
3. Connects via WebSocket to the Chrome DevTools Protocol endpoint
4. Translates each command into CDP calls and JavaScript executed directly in the page
5. Runs everything in sequence, waiting for responses before moving on

The key insight: CDP commands run in the actual browser process, not through a separate driver layer. Combined with a persistent profile that has real cookies and history, the automation behaves much more like a real user.

---

## Known limitations

- **macOS only right now** — Linux builds should work but aren't tested. Windows is not supported yet.
- **No conditionals or variables in scripts** — the DSL is intentionally simple. For complex logic, you'd need to extend it or call it from a shell script.
- **Some dynamic sites are tricky** — sites that heavily use iframes or unusual Shadow DOM structures may need CSS selectors instead of text matching.
- **waitLoad isn't perfect** — on some SPAs, `waitLoad()` passes before the content is actually ready. Using `.waitFor('some-element')` is more reliable in those cases.

---

## What's next

Things I want to add (help welcome):

- [ ] `selectOption` for dropdowns
- [ ] `checkBox` / `uncheckBox`
- [ ] `scroll`
- [ ] `hover`
- [ ] `getValue` — read a field's current value
- [ ] Windows support
- [ ] Better error messages with automatic debug screenshots on failure
- [ ] Variables in scripts

---

## Contributing

This is my first real project in Crystal and I'm learning as I go. If you:

- Find a bug → open an issue, ideally with the `.auto` script that reproduces it
- Know Crystal and see something done the wrong way → PR or comment, I want to learn
- Have a site where it doesn't work → open an issue with the HTML of the element you're trying to interact with

I can't promise fast responses but I read everything.

---

## License

MIT