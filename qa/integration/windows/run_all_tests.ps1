Get-ChildItem '.' | ForEach-Object {
  & $_.FullName
}