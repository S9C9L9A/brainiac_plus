# Instagram CLI Setup

This project can invoke `instagram-cli` on desktop (Linux/macOS/Windows). Mobile targets are not supported because they cannot execute local CLI binaries.

## Linux-only integration in Settings

The Instagram setup wizard shows CLI tools only on Linux. The panel lets you check availability and run quick commands (whoami, feed, stories, notify).

## Prerequisites

- Node.js + npm installed
- `instagram-cli` installed globally

```bash
npm install -g instagram-cli
```

## Verify installation

```bash
instagram-cli --help
```

## Use the Dart runner

```bash
dart tool/instagram_cli_runner.dart check
```

```bash
dart tool/instagram_cli_runner.dart feed
```

```bash
dart tool/instagram_cli_runner.dart stories
```

```bash
dart tool/instagram_cli_runner.dart notify
```

```bash
dart tool/instagram_cli_runner.dart chat --user <username> --title <title>
```

```bash
dart tool/instagram_cli_runner.dart raw --args --help
```

## Notes

- This runner uses the desktop `instagram-cli` binary in PATH.
- If the command is missing, `check` returns exit code 1.
- `instagram-cli` is old and may break if Instagram changes.