import std/[os, osproc, strutils, strformat, streams]

const nimCommand = "nim"

proc help() =
  echo """
docunimit generates Nim docs for nimble packages, by using Nim.
usage:
  docunimit [packagename]
  docunimit [path to a nim file]
This will generate a Nim document directory inside '.cache/docunimit", and open that document inside your browser.
"""

if paramCount() < 1:
  help()
else:
  var target = paramStr(1)
  let 
    name = target.splitFile.name
    useNimble = not fileExists(target) # Probably daft
  
  if useNimble:
    var packages = newSeq[string](0)

    for package in walkDir(getHomeDir() / ".nimble" / "pkgs2"):
      let split = package.path.splitFile
      if split.name.startsWith(name):
        packages.add package.path

    if packages.len == 0:
      echo "No packages match: '", name, "'. "
      help()
      quit 0

    target = packages[0]
    if packages.len > 1:
      while true:
        for x in 0..<packages.len:
          echo fmt"{x + 1}) {packages[x]}"
        stdout.write fmt"Please select a package({1}-{packages.len}): "
        stdout.flushFile()
        try:
          let 
            input = stdin.readLine()
            ind = parseInt(input)
          if ind in 1..packages.len:
            target = packages[ind - 1]
            break
          echo "Invalid Number: ", ind
        except:
          echo "Invalid Response"        

    target = target / name.changeFileExt("nim")

  let tempPath =
    if useNimble: 
      getCacheDir() / "docunimit" / target.parentDir.extractFileName()
    else:
      getCacheDir() / "docunimit" / target.extractFileName().splitFile().name
  var process: Process
  try:
    echo fmt"Generating Docs to: {tempPath}"
    stdout.write "Using Command: "
    process = startProcess(nimCommand, args = ["doc", "--outDir:" & tempPath, "--project", "-r", "--showNonExports", "--index:on", target], options = {poUsePath, poEchoCmd})
    while process.running():
      discard
    if process.peekExitCode() != 0:
      echo process.errorStream.readAll()
      quit 1

  except:
    if process.peekExitCode != 0:
      echo process.errorStream.readAll()
      quit 1


