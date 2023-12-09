[CmdletBinding()]
param ()

$dir = join-path $PSScriptRoot "lists"
if(-not (test-path -lp $dir)) {
	$null = new-item $dir -type directory
}

$combos = @{
	"all-engines" = "ddg", "google", "startpage", "brave", "ecosia"
	"ddg-and-google" = "ddg", "google"
	ddg = "ddg"
	google = "google"
	brave = "brave"
	startpage = "startpage"
	ecosia = "ecosia"
	"block-access" = "block-access"
}

foreach($x in $combos.GetEnumerator()) {
	$target = join-path $dir "$($x.name).txt"
	& "$PSScriptRoot/generate.ps1" -out $target -filter $x.value
}
