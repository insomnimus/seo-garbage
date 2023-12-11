#!/usr/bin/env pwsh
[CmdletBinding()]
param (
	[parameter()]
	[string] $out,

	[Parameter(Position = 0, ValueFromRemainingArguments)]
	[ValidateSet("ddg", "google", "brave", "startpage", "ecosia", "block-access")]
	[string[]] $filter
)

function join {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline, Position = 0)]
		[string] $str
	)

	begin {
		$list = [Collections.Generic.List[string]]::new(8)
	}
	process {
		if($str) {
			[void] $list.add($str)
		}
	}

	end {
		if($list.count -lt 3) {
			return $list -join " and "
		}

		$list `
		| select-object -skipLast 1 `
		| join-string -separator ", " -outputSuffix " and $($list[-1])"
	}
}

$ErrorActionPreference = "stop"

$rules = [ordered] @{
	"block-access" = {
		param([string] $domain)
		if($domain.contains("/")) {
			'||{0}$all' -f $domain
		} else {
			'||{0}^$all' -f $domain
		}
	}
	ddg = 'duckduckgo.com##.react-results--main > li:has(a[href*="{0}"])'
	# google = 'google.*###rso .MjjYud a[href*="{0}"]:upward(.MjjYud)'
	google = 'google.*##.g:has(a[href*="{0}"])' + "`n" + 'google.*##a[href*="{0}"]:upward(1)'
	brave = 'search.brave.com###results > div:has(a[href*="{0}"])'
	startpage = 'startpage.com##.w-gl__result:has(a[href*="{0}"])'
	ecosia = 'ecosia.org###main .result:has(a[href*="{0}"])'
}

if(!$filter) {
	$filter = $rules.keys
}

$header = @"
! Title: Insomnia's Garbage Sites Filter
! Expires: 1 day
! Description: $(
	$s = "AI generated  sites, sites that carry little real info but tons of SEO douchebaggery or otherwise sites with no useful content"
	if($filter.count -eq 1 -and $filter -eq "block-access") {
		"Blocks access to $s"
	} else {
		$engines = $filter | where-object { $_ -ne "block-access" } | join
		"Removes $s, from search results in $engines"
	}
)
! Homepage: https://github.com/insomnimus/seo-garbage
! License: https://github.com/insomnimus/seo-garbage/blob/main/LICENSE`n`n
"@.replace("`r", "")

$filters = $filter | foreach-object { $rules[$_] }

$data = get-content -lp "$PSScriptRoot/list.txt" `
| foreach-object Trim `
| where-object { $_ } `
| foreach-object {
	foreach($f in $filters) {
		if($f -is [ScriptBlock]) {
			&$f $_
		} else {
			$f -f $_
		}
	}
} `
| join-string -separator "`n" -outputPrefix $header -outputSuffix "`n"

if($out) {
	$data | out-file -noNewLine -encoding utf8 $out
} else {
	$data
}
