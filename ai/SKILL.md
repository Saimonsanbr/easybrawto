---
name: easybrawto
description: "Use this skill whenever you need to write, generate, review, or fix `.auto` scripts for the easybrawto browser automation tool. Triggers include: any request to automate a website, fill a form, click buttons, navigate pages, take screenshots, scrape page structure, handle popups, or interact with web elements using easybrawto. Also use when the user asks to translate an existing script to another language (PT-BR or Japanese), debug a failing `.auto` script, or add new automation steps to an existing script. Do NOT use for general web scraping with Python/JavaScript, Selenium, Playwright, or Puppeteer tasks."
version: 0.2.7
---

# easybrawto — AI Agent Skill

easybrawto is a CLI tool for browser automation using Chrome DevTools Protocol (CDP). Scripts are written in `.auto` files with a simple DSL. This skill teaches you how to generate correct `.auto` scripts.

## Core concepts

- Scripts are `.auto` files run with `./easybrawto run script.auto`
- Functions are declared with `functions name { }` and executed with `run name`
- Commands inside functions start with `.`
- String arguments use single quotes `'value'`
- CSS selectors use `'#id'` or `'.class'` — single quotes required
- No variables, no conditionals yet (use `.runJS()` for logic)
- Commands execute sequentially — each waits for the previous to complete
- Languages can be mixed in the same script — EN, PT-BR, JP all work simultaneously

## Script structure

```
# comments start with #

# browser setup (optional — defaults to temp profile + chrome)
chrome.persistProfile('profile_name')

# function declaration
functions functionName {
  .command('argument')
  .command('arg1', 'arg2')
}

# execution — order matters
run functionName
```

## CLI commands (no script needed)

```bash
# Open or create a persistent profile — browser stays open until Ctrl+C
./easybrawto open profile_name
./easybrawto open profile_name brave    # specify browser

# List all saved profiles with metadata
./easybrawto profiles

# Run a script
./easybrawto run script.auto

# Capture full page as PNG (lazy load + fixed elements handled automatically)
./easybrawto fullscreenshot https://site.com
./easybrawto fullscreenshot https://site.com captura.png   # custom filename
```

**Aliases:** `abrir` = `open`, `perfis` = `profiles`

## Browser setup commands

```
# Persistent profile — saves cookies, sessions, logins between runs
chrome.persistProfile('profile_name')

# Specific system profile (base_path, profile_dir)
chrome.profile('/Users/you/Library/Application Support/Google/Chrome', 'Profile 3')

# Temporary clean profile (default if nothing specified)
chrome.tempProfile()

# Choose browser — default is chrome
chrome.browser('brave')
chrome.browser('edge')
```

## All commands — reference

### Navigation
```
.navigate('https://example.com')     # go to URL, waits for load
.reload()                             # reload current page
.goBack()                             # browser back button
.goForward()                          # browser forward button
```

### Waiting
```
.waitLoad()                           # wait for page to finish loading
.waitFor('#selector')                 # wait for element to appear in DOM
.waitForText('text')                  # wait for text to appear anywhere on page
.waitSeconds(3)                       # fixed wait — use as last resort
```

### Clicking
```
.clickButton('Sign in')               # by visible text
.clickButton('#btn-submit')           # by CSS id
.clickButton('.submit-btn')           # by CSS class
.clickIfExists('Accept cookies')      # click only if exists — never fails
```

### Typing
```
.insertText('search', 'query')        # by name attribute
.insertText('#email', 'user@mail.com')# by CSS id
.insertText('Enter your email', 'x')  # by placeholder
.clearField('#email')                 # clear field before typing
```

### Form controls
```
.selectOption('country', 'Brazil')    # dropdown by visible text
.selectOption('#select', 'BR')        # dropdown by value
.checkBox('#terms')                   # check checkbox by id
.checkBox('aceitar-termos')           # by name attribute
.pressKey('Enter')                    # keyboard keys: Enter, Tab, Escape, etc
```

### Scrolling
```
.scroll('down', 300)                  # scroll down 300px
.scroll('up', 200)                    # scroll up 200px
.scroll('bottom')                     # scroll to page bottom
.scroll('top')                        # scroll to page top
```

### Reading data
```
.getValue('#input')                   # prints input field value to terminal
.getAttribute('.link', 'href')        # prints any HTML attribute to terminal
```

### Page scraping for AI agents
```
.scrapePageTo('output/folder')        # saves raw.json + llm.txt
```

Saves two files:
- `raw.json` — full interactive element structure, readable by humans
- `llm.txt` — compact DSL format optimized for LLMs (low token cost)

**llm.txt format:**
```
P|/path|Page Title|H1 text

A|
1|cta|Contact Us|/contact
2|i|Search...|/search|name=q
3|b|Submit
4|l|About|/about

F|
1|GET|/search
```

Types: `cta` = call-to-action, `i` = input, `b` = button, `s` = select, `l` = link

### JavaScript
```
.runJS('document.title')              # single line JS
.runJS("(function() {                 # multiline JS — use double quotes outside
  document.querySelector('.banner').remove();
  return 'done';
})()")
```

**Important:** use double quotes `"` for the outer wrapper and single quotes `'` inside the JS code. `return` statements must be inside a function — use IIFE `(function(){ ... })()`.

### Utilities
```
.screenshot('filename.png')           # save screenshot — absolute or relative path
.log('message')                       # print message to terminal
```

## Selector strategy — how easybrawto finds elements

For `.clickButton()`, the cascade is:
1. Exact text match on `button`, `a`, `input[type=submit]`, `[role=button]`
2. `aria-label` match
3. Partial text match (contains)
4. CSS selector if starts with `#` or `.`

For `.insertText()`, the cascade is:
1. `name` attribute match
2. `placeholder` match
3. `aria-label` match
4. CSS selector if starts with `#` or `.`
5. Deep recursive search through Shadow DOM

**Best practice:** prefer `name` and `aria-label` over CSS classes — they survive framework rebuilds. CSS classes from Tailwind, CSS Modules, styled-components change on every build.

## Common patterns

### Login and stay logged in
```
chrome.persistProfile('work')

functions login {
  .navigate('https://site.com/login')
  .waitLoad()
  .insertText('#email', 'user@mail.com')
  .insertText('#password', 'password123')
  .clickButton('Sign in')
  .waitLoad()
  .screenshot('logged_in.png')
  .log('Login complete')
}

run login
```

### Handle popups safely
```
functions browse {
  .navigate('https://site.com')
  .waitLoad()
  .waitSeconds(3)
  .clickIfExists('Accept cookies')
  .scroll('down', 500)
  .waitSeconds(2)
  .clickIfExists('No thanks')
  .scroll('bottom')
  .screenshot('page.png')
}

run browse
```

### Fill a complete form
```
functions fillForm {
  .navigate('https://site.com/contact')
  .waitLoad()
  .waitSeconds(2)
  .clickIfExists('Accept cookies')
  .scroll('down', 400)
  .insertText('name', 'John Doe')
  .insertText('email', 'john@mail.com')
  .selectOption('subject', 'Support')
  .insertText('message', 'Hello!')
  .checkBox('#terms')
  .clickButton('Send')
  .waitForText('Message sent')
  .screenshot('confirmation.png')
  .log('Form submitted!')
}

run fillForm
```

### Scrape page structure for AI decision-making
```
chrome.persistProfile('scraper')

functions scrapePage {
  .navigate('https://site.com')
  .waitLoad()
  .waitSeconds(2)
  .clickIfExists('Accept cookies')
  .scroll('bottom')
  .waitSeconds(1)
  .scrapePageTo('output/site')
  .log('Scrape complete — check output/site/llm.txt')
}

run scrapePage
```

Use `llm.txt` as context for an AI agent to understand the page structure and decide what to automate next.

### Scrape multiple pages
```
chrome.persistProfile('scraper')

functions scrapeListPage {
  .navigate('https://site.com/products')
  .waitLoad()
  .scrapePageTo('output/list')
}

functions scrapeProductPage {
  .navigate('https://site.com/products/item-1')
  .waitLoad()
  .scrapePageTo('output/product-1')
}

run scrapeListPage
run scrapeProductPage
```

### React/Vue/Angular sites
```
functions reactForm {
  .navigate('https://react-app.com')
  .waitLoad()
  .waitFor('#root')
  .insertText('#email', 'user@mail.com')
  .insertText('#password', 'pass123')
  .clickButton('Submit')
  .waitForText('Success')
}

run reactForm
```

### Run custom JavaScript
```
functions customJs {
  .navigate('https://site.com')
  .waitLoad()
  .runJS("(function() {
    var price = document.querySelector('.price').innerText;
    return price;
  })()")
  .screenshot('result.png')
}

run customJs
```

### Multiple functions in sequence
```
chrome.persistProfile('automation')

functions step1 {
  .navigate('https://site.com')
  .waitLoad()
  .clickIfExists('Accept cookies')
}

functions step2 {
  .insertText('search', 'product name')
  .pressKey('Enter')
  .waitLoad()
  .scrapePageTo('output/results')
}

functions step3 {
  .navigate('https://site.com/product/1')
  .waitLoad()
  .scrapePageTo('output/product')
  .screenshot('product.png')
}

run step1
run step2
run step3
```

## Multilingual scripts

easybrawto supports English, Portuguese (PT-BR), and Japanese. Languages can be mixed freely.

### PT-BR aliases

| English | Português |
|---|---|
| `functions` | `funcoes` |
| `run` | `rodar` |
| `chrome.persistProfile` | `navegador.manterPerfil` |
| `chrome.browser` | `navegador.tipo` |
| `.navigate` | `.navegar` / `.irPara` |
| `.waitLoad` | `.esperarCarregar` / `.aguardarCarregamento` |
| `.waitFor` | `.esperarPor` / `.aguardarElemento` |
| `.waitForText` | `.esperarTexto` |
| `.waitSeconds` | `.esperarSegundos` / `.aguardar` |
| `.clickButton` | `.clicarBotao` / `.clicar` |
| `.clickIfExists` | `.clicarSeExistir` |
| `.insertText` | `.inserirTexto` / `.digitar` |
| `.clearField` | `.limparCampo` |
| `.selectOption` | `.selecionarOpcao` |
| `.checkBox` | `.marcarCaixa` / `.marcar` |
| `.pressKey` | `.pressionarTecla` |
| `.scroll` | `.rolar` |
| `.reload` | `.recarregar` |
| `.goBack` | `.voltarPagina` |
| `.goForward` | `.avancarPagina` |
| `.getValue` | `.obterValor` |
| `.getAttribute` | `.obterAtributo` |
| `.runJS` | `.executarJS` |
| `.screenshot` | `.capturarTela` / `.printarTela` |
| `.log` | `.registrar` / `.imprimir` |

### PT-BR example
```
navegador.manterPerfil('meu_perfil')

funcoes rasparPagina {
  .navegar('https://site.com.br')
  .esperarCarregar()
  .esperarSegundos(2)
  .clicarSeExistir('Aceitar cookies')
  .rolar('bottom')
  .scrapePageTo('dados/site')
  .imprimir('Raspagem concluída!')
}

rodar rasparPagina
```

## Error messages and what to do

| Error | Cause | Fix |
|---|---|---|
| `[ERRO] Elemento não encontrado: 'X'` | Button/element not found | Check text case, add `.waitLoad()` or `.waitFor()` before, use `.screenshot('debug.png')` |
| `[ERRO] Campo não encontrado: 'X'` | Input field not found | Use `name` or `#id` selector, check Shadow DOM |
| `[ERRO] Dropdown não encontrado: 'X'` | Select element not found | Use `name` attribute of the `<select>` |
| `[ERRO] Checkbox não encontrado: 'X'` | Checkbox not found | Use `#id` or `name` attribute |
| `[AVISO] Timeout no waitLoad` | Page didn't reach readyState | Use `.waitFor('known-selector')` instead |
| `[ERRO] Timeout: elemento não apareceu` | waitFor timed out | Element may not exist — use `.screenshot('debug.png')` |
| `[ERRO] JavaScript: Illegal return statement` | `return` outside function in runJS | Wrap JS in IIFE: `(function(){ ... })()` |
| `[aviso] Comando desconhecido ignorado` | Typo or missing alias | Check spelling, verify alias in `lang/*.yml` |

## Debugging tips

1. Add `.screenshot('debug.png')` before any failing command
2. Add `.waitSeconds(3)` after `.navigate()` on slow sites
3. Use `.waitFor('#known-element')` instead of `.waitLoad()` on SPAs
4. Use `name` and `aria-label` selectors — stable across framework rebuilds
5. For React/Vue sites, `.waitFor('#app')` or `.waitFor('#root')` before interacting
6. `.clickIfExists()` for all optional elements — popups, modals, cookie banners
7. Use `.scrapePageTo('debug/')` to understand page structure before writing selectors
8. For multiline `.runJS()`, always wrap in `(function(){ ... })()`

## What NOT to do

```
# DON'T rely on hashed CSS classes from frameworks
.clickButton('.sc-bdXxxt.hYBOTF')     # breaks on next build

# DO use semantic selectors
.clickButton('Submit')                 # text
.insertText('email', 'x@x.com')       # name attribute
.clickButton('#btn-submit')            # stable id

# DON'T use waitSeconds as primary wait strategy
.waitSeconds(5)                        # slow and fragile

# DO wait for specific elements or text
.waitFor('#dashboard')                 # fast and reliable
.waitForText('Welcome back')           # confirms action worked

# DON'T use return at top level in runJS
.runJS('return document.title')        # ERROR: Illegal return statement

# DO wrap in IIFE
.runJS("(function(){ return document.title; })()")
```

## Limitations (as of v0.2.6)

- No Windows binaries yet (macOS arm64, macOS x64, Linux x64 available)
- No variables or conditionals — use `.runJS()` for logic
- No multi-tab coordination yet
- `waitLoad()` unreliable on heavy SPAs — prefer `waitFor()`
- No file upload support yet
- `scrapePageTo` does not auto-scroll before capture (scroll manually first with `.scroll('bottom')`)
- `fullscreenshot` caps page height at 15000px — pages taller than that are cropped