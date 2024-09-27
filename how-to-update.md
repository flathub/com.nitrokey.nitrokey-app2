### How To Update NitrokeyApp2 Flatpak/Flathub Builder

* copy `poetry.lock` & `pyproject.toml` from origin repository
* adapt `Makefile`
    * update `pre-requirements.txt` target versions
    * update `rust-requirements.txt` target versions
* if needed:
    * update `python3-hidapi.json` 
    * update `python3-poetry.json`
* remove old build-artifacts: `make reset`
* run `make` to (re)-create all needed files
* run `make pkg` to test the build
* run `make lint` to check for linting issues

