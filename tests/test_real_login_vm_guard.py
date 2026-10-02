import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "real-login-vm-guard.py"
SPEC = importlib.util.spec_from_file_location("real_login_vm_guard", MODULE_PATH)
guard = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = guard
SPEC.loader.exec_module(guard)


class RealLoginVmGuardTests(unittest.TestCase):
    def qemu_evidence(self, **overrides):
        values = {
            "virtualizer": "kvm",
            "dmi_vendor": "QEMU",
            "dmi_product": "Standard PC (Q35 + ICH9, 2009)",
            "cpu_hypervisor_flag": True,
            "marker_present": True,
            "marker_regular": True,
            "marker_symlink": False,
            "marker_content": guard.MARKER_CONTENT,
            "marker_uid": 0,
            "marker_mode": 0o644,
        }
        values.update(overrides)
        return guard.Evidence(**values)

    def test_accepts_confirmed_qemu_vm_fixture(self):
        errors = guard.verification_errors(self.qemu_evidence(), confirmed=True)
        self.assertEqual(errors, [])

    def test_rejects_physical_host_fixture(self):
        host = self.qemu_evidence(
            virtualizer="",
            dmi_vendor="To Be Filled By O.E.M.",
            dmi_product="Example physical motherboard",
            cpu_hypervisor_flag=False,
        )
        errors = guard.verification_errors(host, confirmed=True)
        self.assertGreaterEqual(len(errors), 3)

    def test_requires_explicit_confirmation(self):
        errors = guard.verification_errors(self.qemu_evidence(), confirmed=False)
        self.assertTrue(any("explicit" in error for error in errors))

    def test_rejects_group_or_world_writable_marker(self):
        evidence = self.qemu_evidence(marker_mode=0o666)
        errors = guard.verification_errors(evidence, confirmed=True)
        self.assertTrue(any("writable" in error for error in errors))

    def test_rejects_symlink_marker(self):
        evidence = self.qemu_evidence(marker_symlink=True)
        errors = guard.verification_errors(evidence, confirmed=True)
        self.assertTrue(any("symlink" in error for error in errors))

    def test_rejects_unsafe_marker_directory(self):
        evidence = self.qemu_evidence(marker_parent_mode=0o777)
        errors = guard.verification_errors(evidence, confirmed=True)
        self.assertTrue(any("directory is writable" in error for error in errors))

    def test_guard_failure_never_calls_following_operation(self):
        host = self.qemu_evidence(virtualizer="", cpu_hypervisor_flag=False)
        operation = mock.Mock()
        accepted, errors = guard.run_guarded_operation(
            host, operation, confirmed=True, require_marker=False
        )
        self.assertFalse(accepted)
        self.assertTrue(errors)
        operation.assert_not_called()

    def test_verified_vm_runs_following_operation(self):
        operation = mock.Mock()
        accepted, errors = guard.run_guarded_operation(
            self.qemu_evidence(), operation, confirmed=True
        )
        self.assertTrue(accepted)
        self.assertEqual(errors, [])
        operation.assert_called_once_with()

    def test_bootstrap_is_create_only(self):
        with tempfile.TemporaryDirectory() as temporary:
            marker = Path(temporary) / "marker"
            guard._write_marker_file(marker, expected_uid=os.geteuid())
            self.assertEqual(marker.read_text(encoding="utf-8"), guard.MARKER_CONTENT)
            with self.assertRaises(FileExistsError):
                guard._write_marker_file(marker, expected_uid=os.geteuid())

    @mock.patch.object(guard, "_write_marker_file")
    @mock.patch.object(guard.os, "geteuid", return_value=0)
    def test_bootstrap_function_checks_vm_before_write(self, _geteuid, write_marker):
        host = self.qemu_evidence(virtualizer="none", cpu_hypervisor_flag=False)
        with self.assertRaises(ValueError):
            guard.bootstrap_marker(
                Path("/unused"), evidence=host, confirmed=True
            )
        write_marker.assert_not_called()

    @mock.patch.object(guard, "collect_evidence")
    @mock.patch.object(guard, "bootstrap_marker")
    def test_bootstrap_cli_rejects_host_before_write(self, create_marker, collect):
        collect.return_value = self.qemu_evidence(
            virtualizer="none",
            dmi_vendor="To Be Filled By O.E.M.",
            dmi_product="Example physical motherboard",
            cpu_hypervisor_flag=False,
        )
        result = guard.main(["--bootstrap", "--confirm-real-login-vm"])
        self.assertEqual(result, 1)
        create_marker.assert_not_called()


if __name__ == "__main__":
    unittest.main()
