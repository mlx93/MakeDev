# Using the Tool from a Subdirectory

## Option 1: One-Line Makefile (Recommended)

```bash
# 1. Create subdirectory
mkdir test-app
cd test-app

# 2. Create Makefile with one line (references parent Makefile)
echo 'include ../Makefile' > Makefile

# 3. Run make dev - magic happens!
make dev
```

## Option 2: Use the dev Script

```bash
# 1. Create subdirectory  
mkdir test-app
cd test-app

# 2. Copy dev script
cp ../dev .

# 3. Run it
./dev
```

## Option 3: Use Parent Makefile Directly

```bash
# 1. Create subdirectory
mkdir test-app
cd test-app

# 2. Run from parent Makefile
make -C . -f ../Makefile dev
```

**Option 1 is recommended** - it's the simplest and lets you use `make dev` normally.
