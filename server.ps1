$port = 8080
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Local Server Running!" -ForegroundColor Green
Write-Host "  http://localhost:$port" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Gray
Write-Host ""

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $req = $context.Request
            $res = $context.Response

            $urlPath = $req.Url.LocalPath
            if ($urlPath -eq "/" -or [string]::IsNullOrWhiteSpace($urlPath)) { 
                $urlPath = "/index.html" 
            }

            $cleanPath = $urlPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $filePath = [System.IO.Path]::Combine($root, $cleanPath)

            if ([System.IO.File]::Exists($filePath)) {
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $res.ContentType = $contentType
                $res.ContentLength64 = $bytes.Length

                if ($req.HttpMethod -ne "HEAD") {
                    $res.OutputStream.Write($bytes, 0, $bytes.Length)
                }
                Write-Host "[200] $($req.HttpMethod) $urlPath" -ForegroundColor Green
            } else {
                $res.StatusCode = 404
                $msg = [System.Text.Encoding]::UTF8.GetBytes("404 - Not Found")
                $res.ContentType = "text/plain; charset=utf-8"
                $res.ContentLength64 = $msg.Length
                if ($req.HttpMethod -ne "HEAD") {
                    $res.OutputStream.Write($msg, 0, $msg.Length)
                }
                Write-Host "[404] $($req.HttpMethod) $urlPath" -ForegroundColor Red
            }
        } catch {
            Write-Host "[ERR] $_" -ForegroundColor DarkYellow
        } finally {
            try { $context.Response.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped." -ForegroundColor Yellow
}
