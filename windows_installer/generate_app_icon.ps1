Add-Type -AssemblyName System.Drawing

function Build-Ico {
    param(
        [string]$SourceImagePath,
        [string]$DestinationIcoPath,
        [int[]]$Sizes = @(256, 128, 64, 48, 32, 24, 16)
    )
    
    $src = [System.Drawing.Bitmap]::new($SourceImagePath)
    $imageBytesList = [System.Collections.Generic.List[byte[]]]::new()
    
    foreach ($size in $Sizes) {
        $scaled = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($scaled)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.DrawImage($src, 0, 0, $size, $size)
        $g.Dispose()
        
        if ($size -ge 256) {
            # Use PNG for 256x256
            $ms = [System.IO.MemoryStream]::new()
            $scaled.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $bytes = $ms.ToArray()
            $ms.Dispose()
        } else {
            # Use standard 32-bit DIB for sizes < 256
            $ms = [System.IO.MemoryStream]::new()
            $bw = [System.IO.BinaryWriter]::new($ms)
            
            # BITMAPINFOHEADER (40 bytes)
            $bw.Write([uint32]40)                      # biSize
            $bw.Write([int32]$size)                    # biWidth
            $bw.Write([int32]($size * 2))              # biHeight (doubled for XOR + AND masks)
            $bw.Write([uint16]1)                       # biPlanes
            $bw.Write([uint16]32)                      # biBitCount
            $bw.Write([uint32]0)                       # biCompression = BI_RGB
            $bw.Write([uint32]($size * $size * 4))     # biSizeImage
            $bw.Write([int32]0)                        # biXPelsPerMeter
            $bw.Write([int32]0)                        # biYPelsPerMeter
            $bw.Write([uint32]0)                       # biClrUsed
            $bw.Write([uint32]0)                       # biClrImportant
            
            # XOR mask: BGRA bottom-up
            for ($y = $size - 1; $y -ge 0; $y--) {
                for ($x = 0; $x -lt $size; $x++) {
                    $p = $scaled.GetPixel($x, $y)
                    $bw.Write([byte]$p.B)
                    $bw.Write([byte]$p.G)
                    $bw.Write([byte]$p.R)
                    $bw.Write([byte]$p.A)
                }
            }
            
            # AND mask: 1 bit per pixel, padded to 32-bit boundary per row
            $andRowBytes = [int][Math]::Ceiling($size / 32.0) * 4
            $andMask = [byte[]]::new($andRowBytes * $size)
            $bw.Write($andMask)
            
            $bw.Flush()
            $bytes = $ms.ToArray()
            $bw.Dispose()
            $ms.Dispose()
        }
        
        $scaled.Dispose()
        $imageBytesList.Add($bytes)
    }
    $src.Dispose()
    
    # Calculate file layout
    # Header: 6 bytes
    # Entries: 16 bytes * count
    $count = $Sizes.Length
    $headerSize = 6 + ($count * 16)
    $currentOffset = $headerSize
    
    $outMs = [System.IO.MemoryStream]::new()
    $outBw = [System.IO.BinaryWriter]::new($outMs)
    
    # Write ICONDIR
    $outBw.Write([uint16]0)          # idReserved
    $outBw.Write([uint16]1)          # idType (1 = ICO)
    $outBw.Write([uint16]$count)     # idCount
    
    for ($i = 0; $i -lt $count; $i++) {
        $size = $Sizes[$i]
        $bLen = $imageBytesList[$i].Length
        $dimByte = [byte]0
        if ($size -lt 256) {
            $dimByte = [byte]$size
        }
        
        $outBw.Write($dimByte)                         # bWidth
        $outBw.Write($dimByte)                         # bHeight
        $outBw.Write([byte]0)                          # bColorCount
        $outBw.Write([byte]0)                          # bReserved
        $outBw.Write([uint16]1)                        # wPlanes
        $outBw.Write([uint16]32)                       # wBitCount
        $outBw.Write([uint32]$bLen)                   # dwBytesInRes
        $outBw.Write([uint32]$currentOffset)          # dwImageOffset
        
        $currentOffset += $bLen
    }
    
    # Write image data
    for ($i = 0; $i -lt $count; $i++) {
        $outBw.Write($imageBytesList[$i])
    }
    
    $outBw.Flush()
    [System.IO.File]::WriteAllBytes($DestinationIcoPath, $outMs.ToArray())
    $outBw.Dispose()
    $outMs.Dispose()
    Write-Host ("Successfully generated: " + $DestinationIcoPath + " (" + (Get-Item $DestinationIcoPath).Length + " bytes)")
}

Build-Ico -SourceImagePath "frontend/assets/images/logo.png" -DestinationIcoPath "frontend/windows/runner/resources/app_icon.ico"
