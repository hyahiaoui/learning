<!-- markdownlint-disable MD013 -->
# FastAPI + HTMX

This is a study folder for [FastAPI + HTMX: The No-Build Full-Stack](https://blakecrosley.com/guides/fastapi-htmx), a guide/tutorial/reference about building an entire system (web application) using FastAPI and HTMX. No React. No Typescript. No builder. No `node_modules`.

## 1. New project setup

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

    * [fastapi](https://fastapi.tiangolo.com/) (without the `fastapi-cloud-cli`, which allows to deploy to FastAPI Cloud.)
    * [jinja2](https://jinja.palletsprojects.com/en/stable/)
    * [Pydantic](https://pydantic.dev/docs/validation/latest/get-started/)
    * [nh3](https://nh3.readthedocs.io/en/latest/), a Python bindings to the [ammonia](https://github.com/rust-ammonia/ammonia) HTML sanitization library (prevents cross-site scripting, layout breaking, and clickjacking caused by untrusted user-provided HTML being mixed into a larger web page).
    * [uvicorn](https://uvicorn.dev/)

    ```shell
    uv add fastapi[standard-no-fastapi-cloud-cli] jinja2 pydantic nh3 uvicorn
    ```

4. Create an initial `main.py` file, in `src/fastapi_htmx`

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
    entrypoint = "fastapi_htmx.main:app"
    ```

6. Run this initial app using

    ```shell
    uv run fastapi dev
    ```
