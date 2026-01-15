# Changelog

All notable changes to this project will be documented in this file.

## [0.1] - 2026-01-15

### Fixed
- **Engine Connection Failure**: Resolved a critical issue where the Aria2 engine would fail to start or connect due to spaces in the macOS "Application Support" directory path.
- **App Crash during Logging**: Fixed a crash caused by concurrent write access to the same log file by both the Swift app and the Aria2 process.
- **Engine Startup Loop**: Fixed an issue where the engine would exit with code 28 when trying to load an empty or corrupted input file.
- **IPv6 Binding Conflicts**: Added `--disable-ipv6=true` to prevent the engine from failing to bind to ports on certain network configurations.

### Changed
- **Data Directory**: Migrated user data and engine logs to `~/Library/Application Support/Motrix` and optimized argument handling for paths with spaces.
- **Logging Architecture**: Separated application logs (`motrix.log`) from engine logs (`aria2.log`) and added a dedicated `aria2_stderr.log` for capturing runtime errors.
- **RPC Host**: Switched default RPC connection host from `127.0.0.1` to `localhost` to improve compatibility with local loopback interfaces.
- **Engine Arguments**: Simplified `aria2c` startup flags to increase reliability across different macOS environments.
