# GeoIP downloader spec fixtures

## Recreating `sample_with_symlink.tgz`

This archive is the same as `sample.tgz` plus a symbolic link `GeoLite2-City-alias.mmdb` → `GeoLite2-City.mmdb` at the archive root. Run from this directory (Unix/macOS):

```bash
cd "$(dirname "$0")"  # or: cd x-pack/spec/geoip_database_management/fixtures
rm -rf _symlink_build && mkdir _symlink_build && tar -xzf sample.tgz -C _symlink_build
ln -s GeoLite2-City.mmdb _symlink_build/GeoLite2-City-alias.mmdb
tar -czf sample_with_symlink.tgz -C _symlink_build .
rm -rf _symlink_build
```
