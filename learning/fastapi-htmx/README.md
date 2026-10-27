<!-- markdownlint-disable MD013 -->
# FastAPI + HTMX

This is a study folder for [FastAPI + HTMX: The No-Build Full-Stack](https://blakecrosley.com/guides/fastapi-htmx), a guide/tutorial/reference about building an entire system (web application) using FastAPI and HTMX. No React. No Typescript. No builder. No `node_modules`.

## 1. New project setup

The following is not part of the tutorial, per se. It only setups a new `fastapi` application, with modern tools (`uv`, `pydantic`, `uvicorn` and `jinja2`).

1. Add `uv` and `python314` to the flake `packages`, then run `nix develop` (if you did not already set-up `direnv`).
2. Init the Python project

    ```shell
    cd fastapi-htmx
    uv init \
        --name fastapi-htmx \
        --app \
        --description "Study project for `FASTAPI + HTMX: The no-build full-stack`" \
        --no-readme \
        --python ">=3.14" \
        --no-managed-python
    ```

3. Add the first requirements (we will only need `fastapi` in this first step)

    * [fastapi](https://fastapi.tiangolo.com/), without `standard` dependencies, nor the `fastapi-cloud-cli` (which allows to deploy to FastAPI Cloud), as development server will run using `uvicorn`.
    * [jinja2](https://jinja.palletsprojects.com/en/stable/)
    * [Pydantic](https://pydantic.dev/docs/validation/latest/get-started/)
    * [nh3](https://nh3.readthedocs.io/en/latest/), a Python bindings to the [ammonia](https://github.com/rust-ammonia/ammonia) HTML sanitization library (prevents cross-site scripting, layout breaking, and clickjacking caused by untrusted user-provided HTML being mixed into a larger web page).
    * [uvicorn](https://uvicorn.dev/)

    ```shell
    uv add fastapi jinja2 pydantic nh3 uvicorn
    ```

4. Create an initial `main.py` file, in `src/app`

    ```python
    from fastapi import FastAPI

    app = FastAPI()


    @app.get("/")
    async def root():
        return {"message": "Hello World"}
    ```

5. Configure the app `entrypoint` in `pyproject.toml`:

    ```toml
    [tool.fastapi]
    entrypoint = "app.main:app"
    ```

6. Run this initial app using

    ```shell
    uv run uvicorn app.main:app --reload
    ```

## 2. "The No-Build Thesis"

The tutorial's main thesis is

> ... for content-driven sites with a solo developer or small team, build tools solve problems you do not have while creating problems you do.

This has some implications:

* No typescript: The few Javascript code needed for the (very few) interactivity in the browser, is vanilla Javascript, with no compiler. Errors are caught with test and code analysis. This could work for a very small team, probabmy not for a large one (Personal note: Why not? This needs to be tested in a real environment).
* No Hot Module Replacement (HMR). With HTMX, CSS changes require a manual browser refresh. Development using HTMX should be fast enough that full refreshes are tolerable. But this could be annoying, in the long run.
* JS code written is JS code shipped. This forces to build small, focused files.
* No components libraries. No `shadcn/ui`, etc (Personal note: probably because these libraries **require** a build phase ...).
* No (Javascript/Typescript) "Build failures".
* Debugging with browser "View Source".
* Instant local development server start (Personal note: in particular with `uv` :-) ).
* "Lightweight" browsing: the HTML document, one CSS file, HTMX and the page's JS (and potentially `alpine.js`). Around 60 Kilo Bytes (!!!) for the first, uncached visit. And, a lot can be cached.
* A frontend that resists the births and deaths of JS frameworks.

> Personal questions: Does it provide a frontend that could resist, easily, the change of the backend technology?

## 3. Architecture Overview

Every request follows a single path through four layers:

* A full page load (for example, `/about`, in the diagram above) returns complete HTML documents (base template + page template).

```md
Browser                FastAPI                        Jinja2
  |                      |                              |
  |--- GET /about ------>|                              |
  |                      |------ render template ------>|
  |                      |  ( base.html+ about.html )   |
  |                      |                              |
  |                      |<------- full HTML -----------|
  |<--- HTML response ---|                              |
```

* HTMX requests return HTML fragments (partials). The server decides what to render based on the request type.

```md
Browser               HTMX                 FastAPI                Jinja2
  |-- hx-get /search -->|                     |                     |
  |                     |--- HTMX request --->|                     |
  |                     |                     |-- render partial -->|
  |                     |                     |  ( _results.html )  |
  |                     |                     |                     |
  |                     |                     |<-- HTML fragment ---|
  |                     |<-- HTML fragment ---|                     |
  |<--- DOM swap -------|                     |                     |
```

* `Alpine.js` manages client-only state that never touches the server.

## 4. Component Roles

### FastAPI

* **Role:** Routing, business logic, data access, validation
* **Scope:** Server

### Jinja2

* **Role:** Template rendering, inheritance, macros
* **Scope:** Server

### Pydantic

* **Role:** Request/response validation, settings
* **Scope:** Server

### HTMX

* **Role:** Server-driven interactivity (forms, pagination, search)
* **Scope:** Client <-> Server

### [Alpine.js](https://alpinejs.dev/)

* **Role:** Client-only state (dropdowns, modals, toggles)
* **Scope:** Client only

### [Pico CSS](https://picocss.com/), or [Blades CSS](https://blades.dev/), instead of Bootstrap 5

* **Role:** Grid system, utility classes, responsive layout
* **Scope:** Client (CSS)

## 5. Project Structure

The structure follows a single principle: **each directory contains one type of thing**. Routes live in `routes/`. Templates live in `templates/`. Static assets live in `static/`. **No build step transforms one into another**.

```md
app/
├── main.py              # FastAPI app, middleware, templates
├── config.py            # Pydantic settings management
├── routes/
│   ├── pages.py         # Page routes (HTML responses)
│   └── api.py           # API routes (JSON/HTML fragment responses)
├── content.py           # Markdown loading, blog post parsing
├── security/
│   ├── headers.py       # CSP, HSTS, security headers middleware
│   ├── csrf.py          # HMAC-signed CSRF tokens
│   ├── rate_limit.py    # 3-tier rate limiting
│   └── logging.py       # Security event logging
├── i18n/
│   ├── config.py        # Supported locales, mappings
│   ├── middleware.py    # URL-based locale detection
│   ├── jinja.py         # Translation functions for templates
│   └── d1_client.py     # Cloudflare D1 translation storage
├── cache_assets.py      # Content-hash asset versioning
└── templates/
    ├── base.html        # Base layout with Alpine.js state
    ├── components/      # Reusable partials (_language_switcher.html, etc.)
    └── pages/           # Page templates (home.html, about.html, etc.)

content/
├── blog/                # Markdown blog posts with YAML frontmatter
└── guides/              # Multi-section guide markdown

static/
├── css/                 # Plain CSS (no preprocessors)
├── js/                  # Vanilla JavaScript (no bundlers)
│   └── vendor/          # Self-hosted HTMX, Alpine.js
└── images/              # Optimized images with WebP srcset
```

> The above structure has been copy-pasted from [Project Structure](https://blakecrosley.com/guides/fastapi-htmx#project-structure), to be abme to reference it, later. The structure _could_ change in this repo, if the need arises, without an update on the above.

## 6. FastAPI Patterns

> **TODO** Continue on [FastAPI Patterns](https://blakecrosley.com/guides/fastapi-htmx#fastapi-patterns).
