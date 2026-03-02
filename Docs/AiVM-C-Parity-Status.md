# AiLang Zero-C# DoD Dashboard

Generated: 2026-03-02 19:48:26 UTC

Overall status: **FAIL**

## Gates

| Gate | Status | Details |
|---|---|---|
| Behavioral parity | FAIL | 0/66 (0.00%) with mode=native |
| Zero-C# | PASS | tracked_csharp=0, dotnet_refs_in_ci_scripts=0 |
| Test coverage | PASS | test-aivm-c=pass, test.sh=pass, determinism=pass |
| Benchmark | PASS | bench_run=pass, baseline=present, threshold=within-threshold, regressions=0, missing=0, max_pct=5 |
| Samples completion | PASS | complete=4/4 (manifest=Docs/Sample-Completion-Manifest.md) |
| Memory/GC | PASS | rc_test=yes, cycle_test=yes, leak_script=yes, profile_script=yes |

## Behavioral Sub-Gates

| Entrypoint | Status | Details |
|---|---|---|
| run source | FAIL | backed by canonical golden corpus parity |
| embedded bytecode | FAIL | vm=c run bytecode-oriented source failed (exit=1) |
| embedded bundle | FAIL | vm=c run .aibundle failed (exit=1) |
| serve | FAIL | vm=c serve failed to start (exit=1) |

## Behavioral Cases

| Result | Case | Canonical Exit | C VM Exit |
|---|---|---:|---:|
| FAIL | check_duplicate_ids | 2 | 1 |
| FAIL | check_if_shape | 2 | 1 |
| FAIL | check_missing_name | 2 | 1 |
| FAIL | fmt_basic | 0 | 1 |
| FAIL | http_health_route_refactor | 0 | 1 |
| FAIL | http_parse_basic | 3 | 1 |
| FAIL | http_parse_full | 3 | 1 |
| FAIL | http_route_basic | 3 | 1 |
| FAIL | json_basic | 3 | 1 |
| FAIL | json_key_ordering | 3 | 1 |
| FAIL | json_order_keys | 3 | 1 |
| FAIL | lifecycle_app_basic | 0 | 1 |
| FAIL | lifecycle_app_exit_code | 9 | 1 |
| FAIL | lifecycle_app_no_init_update | 0 | 1 |
| FAIL | lifecycle_command_emit_stdout | 0 | 1 |
| FAIL | lifecycle_command_exit_after_print | 7 | 1 |
| FAIL | lifecycle_command_print | 0 | 1 |
| FAIL | lifecycle_event_message_basic | 0 | 1 |
| FAIL | lifecycle_event_source_start | 0 | 1 |
| FAIL | lifecycle_loop_structure | 0 | 1 |
| FAIL | manifest_absolute_path | 2 | 1 |
| FAIL | manifest_include_absolute_path | 2 | 1 |
| FAIL | manifest_include_missing_version | 2 | 1 |
| FAIL | manifest_include_valid | 3 | 1 |
| FAIL | manifest_missing_field | 2 | 1 |
| FAIL | manifest_valid | 3 | 1 |
| FAIL | new_cli_success | 0 | 1 |
| FAIL | new_directory_exists | 0 | 1 |
| FAIL | new_gui_success | 0 | 1 |
| FAIL | new_http_success | 0 | 1 |
| FAIL | new_lib_success | 0 | 1 |
| FAIL | new_missing_name | 0 | 1 |
| FAIL | new_success | 0 | 1 |
| FAIL | new_unknown_template | 0 | 1 |
| FAIL | publish_binary_runs | 0 | 1 |
| FAIL | publish_bundle_cycle_error | 0 | 1 |
| FAIL | publish_bundle_single_file | 0 | 1 |
| FAIL | publish_bundle_with_import | 0 | 1 |
| FAIL | publish_include_missing_library | 0 | 1 |
| FAIL | publish_include_success | 0 | 1 |
| FAIL | publish_include_version_mismatch | 0 | 1 |
| FAIL | publish_missing_dir | 0 | 1 |
| FAIL | publish_missing_manifest | 0 | 1 |
| FAIL | publish_overwrite_bundle | 0 | 1 |
| FAIL | publish_writes_bundle | 0 | 1 |
| FAIL | run_import_cycle | 2 | 1 |
| FAIL | run_import_missing | 3 | 1 |
| FAIL | run_import_simple | 2 | 1 |
| FAIL | run_nontrivial | 0 | 1 |
| FAIL | run_var | 0 | 1 |
| FAIL | sample_cli_fetch | 3 | 1 |
| FAIL | sample_weather_api | 3 | 1 |
| FAIL | sample_weather_site | 3 | 1 |
| FAIL | stdlib_io | 2 | 1 |
| FAIL | stdlib_math | 2 | 1 |
| FAIL | stdlib_str | 2 | 1 |
| FAIL | trace_basic | 3 | 1 |
| FAIL | trace_with_args | 0 | 1 |
| FAIL | vm_default_is_canonical | 3 | 1 |
| FAIL | vm_echo | 3 | 1 |
| FAIL | vm_health_handler | 3 | 1 |
| FAIL | vm_hello | 3 | 1 |
| FAIL | vm_import_support | 3 | 1 |
| FAIL | vm_map_field | 3 | 1 |
| FAIL | vm_node_shapes | 3 | 1 |
| FAIL | vm_unsupported_construct | 3 | 1 |
