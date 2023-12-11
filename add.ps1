#!/usr/bin/env pwsh
[CmdletBinding()]
param (
	[Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
	[object[]] $url,
	[switch] $noCommit,
	[switch] $noPush,
	[switch] $noPull
)

begin {
	if(!$noPull) {
		write-information -infa continue "pulling for changes"
		git -C $PSScriptRoot pull
	}
	$file = "$PSScriptRoot/list.txt"
	$ErrorActionPreference = "stop"
	$list = [Collections.Generic.SortedDictionary[string, bool]]::new()
	$new = [Collections.Generic.List[string]]::new(64)

	function get-domain([Uri] $x) {
		$dom = $x.host
		if($dom.startsWith("www.")) {
			$dom = $dom.substring(4)
		}
		$dom
	}

	foreach($s in get-content -lp $file) {
		$list.add($s, $false)
	}
}

process {
	foreach($x in $url) {
		if($x -notlike "?*://*") {
			$x = "https://$x"
		}
		$dom = script:get-domain $x
		if($list.ContainsKey($dom)) {
			write-warning "list already contains $dom"
		} else {
			[void] $list.Add($dom, $false)
			[void] $new.Add($dom)
		}
	}
}

end {
	if($new.count -eq 0) {
		write-warning "no changes"
		return
	}

	$list.keys `
	| join-string -separator "`n" -outputSuffix "`n" `
	| out-file -NoNewLine -Encoding UTF8 $file

	& "$PSScriptRoot/generate-lists.ps1"

	$msg = $new | sort | join-string -separator ", " -outputPrefix "add: "
	if($msg.length -gt 128) {
		$msg = "add: $($new.count) sites"
	}
	write-host $msg

	if($noCommit) {
		return
	}

	git -C $PSScriptRoot add list.txt lists
	if($LastExitCode -ne 0) {
		write-error "faield to add list.txt in git"
	}
	git -C $PSScriptRoot commit -m $msg
	if($LastExitCode -ne 0) {
		write-error "failed to commit changes"
	}
	if(!$noPush) {
		git -C $PSScriptRoot push
		if($LastExitCode -ne 0) {
			write-error "failed to push commit"
		}
	}
}
