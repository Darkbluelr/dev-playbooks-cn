#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def _eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def _run(cmd: List[str], *, dry_run: bool) -> subprocess.CompletedProcess[str]:
    pretty = " ".join([_sh_quote(x) for x in cmd])
    if dry_run:
        print(f"[dry-run] {pretty}")
        return subprocess.CompletedProcess(cmd, 0, "", "")
    return subprocess.run(cmd, text=True, capture_output=True)


def _sh_quote(s: str) -> str:
    if s == "":
        return "''"
    if re.fullmatch(r"[A-Za-z0-9_./:@=-]+", s):
        return s
    return "'" + s.replace("'", "'\"'\"'") + "'"


def _load_json(path: Path) -> Dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"error: missing Claude config: {path}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"error: invalid JSON in {path}: {exc}")


def _extract_claude_mcp_servers(data: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    servers = data.get("mcpServers")
    if servers is None:
        raise SystemExit("error: Claude config missing top-level 'mcpServers'")
    if not isinstance(servers, dict):
        raise SystemExit("error: Claude config 'mcpServers' must be an object")

    normalized: Dict[str, Dict[str, Any]] = {}
    for name, cfg in servers.items():
        if not isinstance(name, str) or not name:
            continue
        if not isinstance(cfg, dict):
            raise SystemExit(f"error: mcpServers['{name}'] must be an object")
        normalized[name] = cfg
    return normalized


def _ensure_rmcp_client(config_toml: Path, *, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] ensure features.rmcp_client = true in {config_toml}")
        return

    text = ""
    try:
        text = config_toml.read_text(encoding="utf-8")
    except FileNotFoundError:
        config_toml.parent.mkdir(parents=True, exist_ok=True)
        config_toml.write_text("[features]\nrmcp_client = true\n", encoding="utf-8")
        return

    section_re = re.compile(r"(?ms)^\[features\]\s*(.*?)(?=^\[|\Z)")
    match = section_re.search(text)

    if match:
        section_body = match.group(1)
        if re.search(r"(?m)^\s*rmcp_client\s*=", section_body):
            new_body = re.sub(
                r"(?m)^\s*rmcp_client\s*=\s*(true|false)\s*$",
                "rmcp_client = true",
                section_body,
            )
        else:
            new_body = "rmcp_client = true\n" + section_body
        text = text[: match.start(1)] + new_body + text[match.end(1) :]
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        if text and not text.endswith("\n\n"):
            text += "\n"
        text += "[features]\nrmcp_client = true\n"

    config_toml.write_text(text, encoding="utf-8")


def _codex_list_servers(*, dry_run: bool) -> Optional[List[str]]:
    if dry_run:
        return None

    if not shutil_which("codex"):
        return None

    json_cmd = ["codex", "mcp", "list", "--json"]
    proc = subprocess.run(json_cmd, text=True, capture_output=True)
    if proc.returncode == 0:
        try:
            data = json.loads(proc.stdout)
            if isinstance(data, list):
                names = []
                for item in data:
                    if isinstance(item, dict) and isinstance(item.get("name"), str):
                        names.append(item["name"])
                if names:
                    return sorted(set(names))
        except json.JSONDecodeError:
            pass

    proc = subprocess.run(["codex", "mcp", "list"], text=True, capture_output=True)
    if proc.returncode != 0:
        return None

    names: List[str] = []
    for line in proc.stdout.splitlines():
        s = line.strip()
        if not s:
            continue
        if s.lower().startswith("no mcp"):
            continue
        if s.lower().startswith("name"):
            continue
        if s.startswith("---") or s.startswith("==="):
            continue
        token = s.split()[0]
        if token.lower() in {"name"}:
            continue
        names.append(token)

    return sorted(set(names)) if names else []


def shutil_which(cmd: str) -> Optional[str]:
    paths = os.environ.get("PATH", "").split(os.pathsep)
    for p in paths:
        candidate = Path(p) / cmd
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


def _write_node_preload(codex_home: Path, *, dry_run: bool) -> Path:
    preload_dir = codex_home / "mcp-preloads"
    preload_path = preload_dir / "stderr-console-preload.cjs"
    content = (
        "const util = require('util');\n"
        "function toStderr(...args) {\n"
        "  try {\n"
        "    process.stderr.write(util.format(...args) + '\\n');\n"
        "  } catch (_) {}\n"
        "}\n"
        "console.log = toStderr;\n"
        "console.info = toStderr;\n"
        "console.warn = toStderr;\n"
        "console.debug = toStderr;\n"
    )

    if dry_run:
        print(f"[dry-run] write Node preload: {preload_path}")
        return preload_path

    preload_dir.mkdir(parents=True, exist_ok=True)
    preload_path.write_text(content, encoding="utf-8")
    return preload_path


def _as_str_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        out: List[str] = []
        for item in value:
            if item is None:
                continue
            out.append(str(item))
        return out
    return [str(value)]


def _as_env_dict(value: Any) -> Dict[str, str]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise SystemExit("error: mcp server 'env' must be an object")
    out: Dict[str, str] = {}
    for k, v in value.items():
        if k is None:
            continue
        out[str(k)] = "" if v is None else str(v)
    return out


def _apply_fixups(
    name: str,
    cfg: Dict[str, Any],
    *,
    codex_home: Path,
    apply_fixups: bool,
    dry_run: bool,
) -> Dict[str, Any]:
    if not apply_fixups:
        return cfg

    cfg = dict(cfg)

    if name == "tree-sitter-mcp":
        args = _as_str_list(cfg.get("args"))
        if "--mcp" not in args:
            cfg["args"] = args + ["--mcp"]

    if name in {"tree-sitter-mcp", "task-master"}:
        preload_path = _write_node_preload(codex_home, dry_run=dry_run)
        env = _as_env_dict(cfg.get("env"))
        node_opts = env.get("NODE_OPTIONS", "")
        require_flag = f"--require={preload_path}"
        if require_flag not in node_opts:
            node_opts = (node_opts + " " + require_flag).strip() if node_opts else require_flag
        env["NODE_OPTIONS"] = node_opts
        cfg["env"] = env

    return cfg


def _codex_remove(name: str, *, dry_run: bool) -> None:
    proc = _run(["codex", "mcp", "remove", name], dry_run=dry_run)
    if dry_run:
        return
    if proc.returncode != 0:
        return


def _codex_add(name: str, cfg: Dict[str, Any], *, dry_run: bool) -> None:
    cmd: List[str] = ["codex", "mcp", "add", name]

    url = cfg.get("url")
    command = cfg.get("command")

    if url is not None and command is not None:
        raise SystemExit(f"error: mcp server '{name}' has both 'url' and 'command'")

    env = _as_env_dict(cfg.get("env"))
    for k in sorted(env.keys()):
        cmd.extend(["--env", f"{k}={env[k]}"])

    if url is not None:
        cmd.extend(["--url", str(url)])
    else:
        if command is None:
            raise SystemExit(f"error: mcp server '{name}' missing 'command' (or 'url')")
        args = _as_str_list(cfg.get("args"))
        cmd.append("--")
        cmd.append(str(command))
        cmd.extend(args)

    proc = _run(cmd, dry_run=dry_run)
    if dry_run:
        return
    if proc.returncode != 0:
        _eprint(proc.stdout.strip())
        _eprint(proc.stderr.strip())
        raise SystemExit(f"error: failed to add MCP server '{name}'")


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        prog="sync_mcp_from_claude_to_codex.py",
        description="Sync MCP servers from Claude Code (~/.claude.json) to Codex CLI ($CODEX_HOME/config.toml).",
    )
    parser.add_argument(
        "--claude-config",
        default=str(Path.home() / ".claude.json"),
        help="Path to Claude config JSON (default: ~/.claude.json)",
    )
    parser.add_argument(
        "--codex-home",
        default=os.environ.get("CODEX_HOME", str(Path.home() / ".codex")),
        help="Codex home directory (default: $CODEX_HOME or ~/.codex)",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print actions without changing anything")
    parser.add_argument(
        "--no-codex-fixups",
        action="store_true",
        help="Disable Codex compatibility fixups (NODE_OPTIONS preload, tree-sitter --mcp).",
    )
    parser.add_argument(
        "--no-ensure-rmcp-client",
        action="store_true",
        help="Do not enforce features.rmcp_client = true in config.toml.",
    )
    args = parser.parse_args(argv)

    claude_path = Path(os.path.expanduser(args.claude_config))
    codex_home = Path(os.path.expanduser(args.codex_home))
    codex_config = codex_home / "config.toml"

    if not args.no_ensure_rmcp_client:
        _ensure_rmcp_client(codex_config, dry_run=args.dry_run)

    data = _load_json(claude_path)
    claude_servers = _extract_claude_mcp_servers(data)

    if not shutil_which("codex"):
        raise SystemExit("error: 'codex' command not found (install Codex CLI, or ensure it is in PATH)")

    desired = {}
    for name in sorted(claude_servers.keys()):
        desired[name] = _apply_fixups(
            name,
            claude_servers[name],
            codex_home=codex_home,
            apply_fixups=not args.no_codex_fixups,
            dry_run=args.dry_run,
        )

    existing = _codex_list_servers(dry_run=args.dry_run)
    if existing is not None:
        for name in existing:
            if name not in desired:
                _codex_remove(name, dry_run=args.dry_run)

    for name, cfg in desired.items():
        _codex_remove(name, dry_run=args.dry_run)
        _codex_add(name, cfg, dry_run=args.dry_run)

    if not args.no_ensure_rmcp_client:
        _ensure_rmcp_client(codex_config, dry_run=args.dry_run)

    print("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

