# Regenerate launcher assets from the supplied logo without altering its artwork.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = [System.Drawing.Bitmap]::FromFile((Join-Path $projectRoot 'assets/branding/olt_logo.png'))
$generated = [System.Collections.Generic.List[string]]::new()
function Export-Icon([string]$RelativePath, [int]$Size, [bool]$Opaque = $false, [double]$Scale = 1.0) {
    $pixelFormat = if ($Opaque) { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, $pixelFormat)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $background = if ($Opaque) { [System.Drawing.Color]::FromArgb(255, 250, 240, 208) } else { [System.Drawing.Color]::Transparent }
        $graphics.Clear($background)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $edge = [int][Math]::Round($Size * $Scale)
        $offset = [int][Math]::Floor(($Size - $edge) / 2)
        $graphics.DrawImage($source, [System.Drawing.Rectangle]::new($offset, $offset, $edge, $edge))
        $path = Join-Path $projectRoot $RelativePath
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $generated.Add($RelativePath)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}
try {
    foreach ($entry in @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}.GetEnumerator()) {
        Export-Icon "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher.png" $entry.Value
    }
    foreach ($platform in @('ios', 'macos')) {
        $folder = "$platform/Runner/Assets.xcassets/AppIcon.appiconset"
        $catalog = Get-Content (Join-Path $projectRoot "$folder/Contents.json") -Raw | ConvertFrom-Json
        foreach ($entry in $catalog.images) {
            $size = [int]([double]($entry.size.Split('x')[0]) * [double]($entry.scale.Replace('x', '')))
            Export-Icon "$folder/$($entry.filename)" $size ($platform -eq 'ios')
        }
    }
    foreach ($size in @(192, 512)) {
        Export-Icon "web/icons/Icon-$size.png" $size
        # The whole logo fits inside the circular maskable safe zone.
        Export-Icon "web/icons/Icon-maskable-$size.png" $size $true 0.56
    }
    Export-Icon 'web/favicon.png' 32
    # A Windows ICO containing PNG images at each supported launcher size.
    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    $frames = [System.Collections.Generic.List[byte[]]]::new()
    foreach ($size in $sizes) {
        $bitmap = [System.Drawing.Bitmap]::new($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $stream = [System.IO.MemoryStream]::new()
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $size, $size))
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $frames.Add($stream.ToArray())
        } finally { $graphics.Dispose(); $bitmap.Dispose(); $stream.Dispose() }
    }
    $iconPath = Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'
    $writer = [System.IO.BinaryWriter]::new([System.IO.File]::Create($iconPath))
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Length)
        $offset = 6 + 16 * $sizes.Length
        for ($i = 0; $i -lt $sizes.Length; $i++) {
            $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
            $writer.Write([byte]0); $writer.Write([byte]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$frames[$i].Length); $writer.Write([uint32]$offset)
            $offset += $frames[$i].Length
        }
        foreach ($frame in $frames) { $writer.Write($frame) }
    } finally { $writer.Dispose() }
    foreach ($path in $generated | Select-Object -Unique) {
        $check = [System.Drawing.Bitmap]::FromFile((Join-Path $projectRoot $path))
        if ($check.Width -ne $check.Height) { throw "Non-square icon: $path" }
        $check.Dispose()
    }
    $checkIcon = [System.Drawing.Icon]::new($iconPath, 256, 256)
    $checkIcon.Dispose()
    Write-Output "Generated and verified $(($generated | Select-Object -Unique).Count) PNG icons and Windows ICO."
} finally { $source.Dispose() }
