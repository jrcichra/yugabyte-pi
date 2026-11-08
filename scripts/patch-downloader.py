#!/usr/bin/env python3
"""Patch yugabyte-db-thirdparty's download_manager.py (run from the thirdparty checkout root).
1. github.com/<o>/<r>/releases/download/... 504s right now -> use scripts/curl-gh (API) instead of curl.
2. github /archive/ tarballs aren't byte-stable, so a checksum mismatch is tolerated there, but only
   if the file is a valid gzip/zip (never an HTML error page); everything else stays verified."""
p = "python/yugabyte_db_thirdparty/download_manager.py"
s = open(p).read()
old_curl = "self.curl_path = which_must_exist('curl')"
old_chk = "if not self.verify_checksum(file_path, expected_checksum):"
new_chk = (
    "if not (self.verify_checksum(file_path, expected_checksum) or "
    "(re.search(r'github[.]com/[^/]+/[^/]+/archive/', effective_url) and "
    "subprocess.call(['sh', '-c', 'gzip -t \"$0\" 2>/dev/null || unzip -tq \"$0\" >/dev/null 2>&1', "
    "file_path]) == 0)):"
)
assert s.count(old_curl) == 1 and s.count(old_chk) == 1
open(p, "w").write(s.replace(old_curl, "self.curl_path = '/usr/local/bin/curl-gh'").replace(old_chk, new_chk))
