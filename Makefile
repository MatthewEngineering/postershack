.PHONY: pyenv-versions pyenv-list pyenv-install pyenv-global pyenv-local pyenv-shell pyenv-check

PYTHON_VERSION ?= 3.12.3

pyenv-versions:
	pyenv versions

pyenv-list:
	pyenv install --list

pyenv-install:
	pyenv install $(PYTHON_VERSION)

pyenv-global:
	pyenv global $(PYTHON_VERSION)

pyenv-local:
	pyenv local $(PYTHON_VERSION)

pyenv-shell:
	pyenv shell $(PYTHON_VERSION)

pyenv-check:
	python --version
	which python
