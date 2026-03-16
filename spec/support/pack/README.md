# Pack fixtures

## Recreating `pack_with_symlink.tar.gz`

This archive contains a minimal pack layout (logstash/ with one dummy gem) plus a symbolic link, used to test tar.gz extraction with symlink support.

Run the following from the project root (Unix/macOS):

```bash
mkdir -p spec/support/pack/build/logstash
echo "dummy gem content" > spec/support/pack/build/logstash/logstash-input-packtest-0.1.0.gem
echo "content" > spec/support/pack/build/logstash/somefile.txt
ln -s somefile.txt spec/support/pack/build/logstash/link_to_somefile
tar -czf spec/support/pack/pack_with_symlink.tar.gz -C spec/support/pack/build logstash
rm -rf spec/support/pack/build
```

On Windows (PowerShell), create the symlink with appropriate permissions or use a different method to produce a tar that contains a symlink entry; the above sequence is for Unix-like systems.
