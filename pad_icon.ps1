Add-Type -AssemblyName System.Drawing
$inputFile = "c:\Work\Flutter\futeboladas\assets\icon\app_icon.png"
$outputFile = "c:\Work\Flutter\futeboladas\assets\icon\app_icon_android12.png"

$img = [System.Drawing.Image]::FromFile($inputFile)
$bmp = New-Object System.Drawing.Bitmap 1152, 1152
$g = [System.Drawing.Graphics]::FromImage($bmp)

# Set background color to match the app theme (#0F172A)
$g.Clear([System.Drawing.Color]::FromArgb(255, 15, 23, 42))

# Resize icon to a safe zone (around 384x384 is recommended for Android 12)
$w = 384
$h = 384
$x = [math]::Truncate((1152 - $w) / 2)
$y = [math]::Truncate((1152 - $h) / 2)

# High Quality rendering
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($img, $x, $y, $w, $h)

$g.Dispose()
$bmp.Save($outputFile, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
$bmp.Dispose()
Write-Output "Image successfully padded for Android 12 splash screen."
