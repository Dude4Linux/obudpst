# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

OB-UDPST (Open Broadband-UDP Speed Test) is a C client/server utility that measures
maximum IP-layer capacity (per BBF TR-471, IETF RFC 9097/9946, ITU-T Y.1540) by sending
UDP load traffic in one direction while status feedback flows in the other. It builds a
single binary (`udpst`) that acts as either client or server depending on CLI flags.

## Build

Requires CMake (>=3.5) and a C compiler. OpenSSL >=3.0 (`libssl-dev`/`openssl-devel`) is
optional but needed for authentication (`-DAUTH_KEY_ENABLE`); the build succeeds without it.

```
cmake .
make
```

This produces `udpst_core` (static lib: control, data, srates, cJSON) linked into the
`udpst` executable. Useful CMake options (via `-DOPTION=ON/OFF` or `ccmake .`):
`RATE_LIMITING`, `AUTH_IS_OPTIONAL`, `HAVE_SENDMMSG`/`HAVE_RECVMMSG`/`HAVE_GSO`,
`DISABLE_INT_TIMER`, `ADD_HEADER_CSUM`, `SUPP_INVPDU_ALERT`, `SUPP_INVPDU_WARN`.

There is no separate lint step; `.clang-format` defines the formatting style used for C
source (run `clang-format` on touched files before committing).

## Running

```
./udpst                    # run as server, any interface, default control port 24601
./udpst -u <server>        # upstream test as client
./udpst -d <server>        # downstream test as client
./udpst -S                 # print the sending-rate table and exit
./udpst -?                 # list all CLI options
```

See README.md for the full option reference, multi-connection/distributed-server usage,
and tuning guidance (socket buffers, NUMA/CPU affinity, jumbo frames, etc.). BEST_PRACTICES.md
gives concrete flag combinations for structured/automated test campaigns.

## Functional tests (tests/)

The `tests/` directory is a separate, Python/Docker-based functional test framework (not
run by the C build). It spins up client/server containers, applies NetEm network emulation,
runs `udpst` between them, and asserts on the JSON output.

```
cd tests
./setup.sh                 # creates venv, installs requirements.txt, builds docker images
pytest                     # runs test_udpst.py against cases in test_cases.yaml
```

- Test cases (CLI flags for client/server, NetEm params, and pass/fail `metrics` — Python
  boolean expressions evaluated against the parsed JSON `results` and the `test_case`) are
  defined in `tests/test_cases.yaml` (see `tests/test_cases_sample.yaml` for the schema,
  documented in `tests/README.md`).
- Client CLI in a test case must include `-f json` for metrics to be evaluated.
- `netem_parser.py` turns the YAML `netem` blocks into `tc netem` commands; `conftest.py`
  wires pytest fixtures to docker-compose; `ci-test.sh` is the entrypoint run inside the
  containers.

## Architecture

Single-threaded, non-blocking C application built around one `epoll` loop (`epollFD` in
the global config struct, `udpst.h`) driving an array of `struct connection` (also
`udpst.h`) — one entry per control/test connection, each with its own state machine and
socket(s). There is no multithreading; concurrency across connections/multiple servers is
handled by multiplexing sockets through the same epoll loop.

Source is split by responsibility:

- **udpst.c** — `main()`, CLI parsing (`proc_parameters`), signal handling, key-file
  loading, JSON/performance-stats file output. Owns the global config/options struct and
  the top-level epoll dispatch loop.
- **udpst_control.c** — the control-channel protocol: connection setup/teardown
  (`send_setupreq`/`service_setupreq`/`service_setupresp`), test activation
  (`service_actreq`/`service_actresp`), socket management (`sock_mgmt`, `sock_connect`,
  `new_conn`), and authentication (HMAC-SHA256 key derivation and PDU signing/verification
  via `insert_auth`/`validate_auth`/`verify_ctrlpdu`, guarded by `AUTH_KEY_ENABLE`).
- **udpst_data.c** — the data-plane: building and sending load PDUs at controlled burst
  rates (`send_loadpdu` and the `_sendmmsg_gso`/`_sendmmsg_burst`/`_sendmsg_burst` send
  paths, selected by platform capability), receiving and validating load/status PDUs
  (`service_loadpdu`, `service_statuspdu`, `verify_datapdu`), the rate-adjustment/search
  algorithm (`adjust_sending_rate`, `proc_subinterval`), and result aggregation/output
  (`output_currate`, `output_maxrate`, JSON summary building via cJSON).
- **udpst_srates.c** — the static, pre-built table of discrete sending rates (dual
  transmitters per index for granularity); `-S` dumps this table.
- **cJSON.c/.h** — vendored third-party JSON library used for `-f json` output; treat as
  upstream code, avoid modifying unless fixing a vendoring-specific bug.
- **udpst.h** — global config struct, `struct connection`, shared constants/macros.
- **udpst_common.h**, **udpst_control.h**, **udpst_data.h**, **udpst_srates.h** — narrower
  per-module declarations.
- **udpst_protocol.h** — wire-format structs for control and load/status PDUs
  (`controlHdrSR`/`controlHdrTA`, `loadHdr`, `statusHdr`, etc.) and the protocol version.
  Any change here is a wire-protocol change and needs corresponding version bumps and
  backward-compatibility consideration (see the port-24601-vs-25000 note in README.md for
  what a breaking protocol change looks like in practice).

Client and server share the same binary and most of the state machine; behavior forks on
role (`Role: Sender/Receiver`, set via CLI) and on message type within `service_*`
handlers dispatched from the epoll loop.

## Conventions

- C90/C99-style code, BSD-3-Clause license header (see existing files) required on new
  source files.
- Feature availability (sendmmsg/recvmmsg, GSO, NUMA-related syscalls, etc.) is probed by
  CMake (`CHECK_FUNCTION_EXISTS`/`CHECK_SYMBOL_EXISTS`) into `config.h`; guard
  platform-specific code with the corresponding `HAVE_*` macro rather than assuming
  availability.
- Authentication code must stay compilable/optional when OpenSSL isn't found — guard with
  `AUTH_KEY_ENABLE`.
