# Test Scripts

This directory contains test scripts for validating the ZeroToRunDevEnv tool functionality.

## Usage

All test scripts should be run from the ZeroToRunDevEnv root directory:

```bash
bash tests/test-<name>.sh
```

## Available Tests

- **`test-empty-folder.sh`** - Tests that an empty folder is treated as a greenfield project
- **`test-perfect-workflow.sh`** - Tests the recommended workflow: `make dev SUBDIR=test-app`
- **`test-workflow.sh`** - Tests creating a subfolder and manually copying Makefile
- **`test-simple-workflow.sh`** - Tests using the standalone `dev` script
- **`test-final-workflow.sh`** - Tests using the `make-wrapper.sh` script
- **`test-ultimate-workflow.sh`** - Tests using `make -C` with parent Makefile
- **`test-new-project.sh [project-name]`** - Helper script to set up a test project in a fresh directory

## Example

```bash
# From ZeroToRunDevEnv root:
bash tests/test-perfect-workflow.sh
```

This will create a `test-app` subdirectory and run the full development setup.

