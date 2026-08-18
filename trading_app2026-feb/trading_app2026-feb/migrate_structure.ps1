
# ============================================================
# migrate_structure.ps1
# Moves lib dart files into feature folders and rewrites every
# import statement to use package: paths.
# ============================================================

$libPath  = "c:\Users\Admin\Desktop\trading_app\trading_app2026-feb\lib"
$pkg      = "package:test_project"

# ── [1] FILE → DESTINATION FOLDER MAP ───────────────────────
$fileMap = [ordered]@{
    'Investment_profile.dart'     = 'features/profile'
    'account.dart'                = 'features/profile'
    'alerts.dart'                 = 'features/notifications'
    'app_lock_wrapper.dart'       = 'features/security'
    'bio.dart'                    = 'features/profile'
    'biometric_service.dart'      = 'features/security'
    'buy.dart'                    = 'features/trading'
    'change_password.dart'        = 'features/profile'
    'conn.dart'                   = 'core/services'
    'edit_profile.dart'           = 'features/profile'
    'message_center.dart'         = 'features/notifications'
    'models.dart'                 = 'core/models'
    'news.dart'                   = 'features/news'
    'newsmail.dart'               = 'features/news'
    'notification.dart'           = 'features/notifications'
    'npref.dart'                  = 'features/profile'
    'order.dart'                  = 'features/trading'
    'pin_lock_screen.dart'        = 'features/security'
    'pinfo.dart'                  = 'features/profile'
    'portfolio.dart'              = 'features/portfolio'
    'privacy.dart'                = 'features/profile'
    'profile.dart'                = 'features/profile'
    'report.dart'                 = 'features/trading'
    'reward.dart'                 = 'features/trading'
    'screener.dart'               = 'features/screener'
    'secure_storage_service.dart' = 'features/security'
    'security_screen.dart'        = 'features/security'
    'security_settings_tile.dart' = 'features/security'
    'sell.dart'                   = 'features/trading'
    'set_pin_screen.dart'         = 'features/security'
    'simulator.dart'              = 'features/simulator'
    'stock.dart'                  = 'features/stock'
    'stock_details.dart'          = 'features/stock'
    'stock_stimulator.dart'       = 'features/simulator'
    'tax.dart'                    = 'features/trading'
    'topup.dart'                  = 'features/trading'
    'treanding.dart'              = 'features/trending'
    'two_factor.dart'             = 'features/security'
    'wishlist.dart'               = 'features/wishlist'
    'wishlistholding_section.dart'= 'features/wishlist'
}

# ── [2] MOVE FILES ───────────────────────────────────────────
Write-Host "`n=== STEP 1: Moving files ===" -ForegroundColor Cyan
foreach ($filename in $fileMap.Keys) {
    $src        = Join-Path $libPath $filename
    $destFolder = Join-Path $libPath ($fileMap[$filename] -replace '/', '\')
    $dest       = Join-Path $destFolder $filename

    if (Test-Path $src) {
        New-Item -ItemType Directory -Force -Path $destFolder | Out-Null
        Move-Item -Path $src -Destination $dest -Force
        Write-Host "  OK  $filename  ->  $($fileMap[$filename])/" -ForegroundColor Green
    } else {
        Write-Host "  --  $filename  (already moved or not found)" -ForegroundColor DarkGray
    }
}

# Also delete the badly named duplicate
$badFile = Join-Path $libPath "message_center.dart'.dart"
if (Test-Path $badFile) { Remove-Item $badFile -Force; Write-Host "  DEL message_center.dart'.dart (malformed duplicate)" -ForegroundColor Yellow }

# ── [3] BUILD REPLACEMENT PAIRS ─────────────────────────────
$pairs = [System.Collections.Generic.List[hashtable]]::new()
foreach ($filename in $fileMap.Keys) {
    $newPkg = "$pkg/$($fileMap[$filename])/$filename"
    # single-quoted  import 'file.dart'
    $pairs.Add(@{ Old = "'$filename'"; New = "'$newPkg'" })
    # double-quoted  import "file.dart"
    $pairs.Add(@{ Old = "`"$filename`""; New = "`"$newPkg`"" })
}

# ── [4] REWRITE IMPORTS IN EVERY .dart FILE ──────────────────
Write-Host "`n=== STEP 2: Rewriting imports ===" -ForegroundColor Cyan

$allDart = Get-ChildItem -Path $libPath -Recurse -Include "*.dart" |
           Where-Object { $_.Extension -eq ".dart" }

$updated = 0
foreach ($df in $allDart) {
    $content  = [System.IO.File]::ReadAllText($df.FullName, [System.Text.Encoding]::UTF8)
    $original = $content

    foreach ($p in $pairs) {
        if ($content.Contains($p.Old)) {
            $content = $content.Replace($p.Old, $p.New)
        }
    }

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($df.FullName, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  Updated: $($df.Name)" -ForegroundColor Green
        $updated++
    }
}

Write-Host "`n=== Done! ===========================================" -ForegroundColor Cyan
Write-Host "  Files moved : $($fileMap.Count)" -ForegroundColor White
Write-Host "  Files updated (imports): $updated" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
