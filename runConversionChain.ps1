param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]] $CliArguments
)

$PodmanArguments = @(
	'exec'
	'sspworkflow'
	'/bin/bash'
	'-c'
	'cd /root/sspworkflow/work && runConversionChain "$@"'
	'_'
) + $CliArguments

& podman @PodmanArguments
exit $LASTEXITCODE