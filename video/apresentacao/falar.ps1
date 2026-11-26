# Gera um WAV com a voz neural "Microsoft Daniel" (pt-BR) do Windows.
# Uso: powershell -ExecutionPolicy Bypass -File falar.ps1 -Texto "Olá" -Saida "saida.wav" [-Velocidade 0.97]
param(
    [Parameter(Mandatory = $true)][string]$Texto,
    [Parameter(Mandatory = $true)][string]$Saida,
    [double]$Velocidade = 0.97
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media.SpeechSynthesis, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.DataReader, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

function Esperar($op, [Type]$tipo) {
    $t = $asTask.MakeGenericMethod($tipo).Invoke($null, @($op))
    $t.Wait(-1) | Out-Null
    $t.Result
}

$sintese = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer
$sintese.Voice = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices |
    Where-Object { $_.DisplayName -like '*Daniel*' } | Select-Object -First 1
$sintese.Options.SpeakingRate = $Velocidade
# Menos silêncio nas vírgulas, nos pontos e no fim da fala: a narração fica mais corrida e menos robótica.
$sintese.Options.PunctuationSilence = [Windows.Media.SpeechSynthesis.SpeechPunctuationSilence]::Min
$sintese.Options.AppendedSilence = [Windows.Media.SpeechSynthesis.SpeechAppendedSilence]::Min

$fluxo = Esperar ($sintese.SynthesizeTextToStreamAsync($Texto)) ([Windows.Media.SpeechSynthesis.SpeechSynthesisStream])
$tamanho = [uint32]$fluxo.Size
$leitor = New-Object Windows.Storage.Streams.DataReader($fluxo.GetInputStreamAt(0))
Esperar ($leitor.LoadAsync($tamanho)) ([uint32]) | Out-Null
$bytes = New-Object byte[] $tamanho
$leitor.ReadBytes($bytes)
[System.IO.File]::WriteAllBytes($Saida, $bytes)
