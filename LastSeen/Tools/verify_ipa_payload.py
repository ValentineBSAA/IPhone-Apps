"""Verify the entire unsigned app payload against its compiled source directory."""
from pathlib import Path, PurePosixPath
import hashlib
import stat
import zipfile

def hash_stream(stream):
    digest = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
    return digest.digest()

def verify_payload(archive, app):
    app = Path(app)
    if not app.is_dir() or app.is_symlink():
        raise ValueError("Compiled app directory missing or invalid")
    prefix = "Payload/LastSeen.app/"
    expected = {}
    for path in app.rglob("*"):
        if path.is_symlink():
            raise ValueError("Unexpected symlink in compiled iPhone app: " + str(path))
        if path.is_file():
            expected[prefix + path.relative_to(app).as_posix()] = path
    if not expected:
        raise ValueError("Compiled app contains no files")
    seen = set()
    files = set()
    for entry in archive.infolist():
        name = entry.filename
        parts = PurePosixPath(name).parts
        if (not parts or name.startswith("/") or "\\" in name or
                ".." in parts or "." in name.split("/") or
                "//" in name or name in seen):
            raise ValueError("Unsafe or duplicate archive member: " + name)
        seen.add(name)
        if stat.S_ISLNK(entry.external_attr >> 16):
            raise ValueError("Unexpected symlink in IPA: " + name)
        if entry.is_dir():
            if name not in {"Payload/", prefix} and not name.startswith(prefix):
                raise ValueError("Unexpected directory outside app payload: " + name)
            continue
        if name not in expected:
            raise ValueError("Unexpected IPA file: " + name)
        files.add(name)
        with archive.open(entry) as packaged, expected[name].open("rb") as original:
            if hash_stream(packaged) != hash_stream(original):
                raise ValueError("IPA file differs from compiled app: " + name)
    if files != set(expected):
        raise ValueError("Missing IPA files: " + ", ".join(sorted(set(expected) - files)))
    return len(files)
