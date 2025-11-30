# Minimal Project Types

Spinbox supports minimal Python and Node.js projects for developers who want just the essentials.

## Python Project

```bash
spinbox create myproject --python
```

Creates:
```
myproject/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── src/
│   ├── __init__.py
│   └── main.py
├── tests/
│   └── test_main.py
├── requirements.txt
├── .gitignore
└── README.md
```

## Node.js Project

```bash
spinbox create myproject --node
```

Creates:
```
myproject/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── src/
│   └── index.js
├── tests/
│   └── index.test.js
├── package.json
├── .gitignore
└── README.md
```

## Adding Components Later

```bash
cd myproject
spinbox add --fastapi       # Add API backend
spinbox add --postgresql    # Add database
spinbox add --nextjs        # Add frontend
```

## Configuration

Global defaults in `~/.spinbox/global.conf`:
```bash
PYTHON_VERSION=3.12
NODE_VERSION=20
```

See `docs/user/cli-reference.md` for full command options.
