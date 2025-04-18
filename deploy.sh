#!/usr/bin/env pwsh
param(
    [string]$RepoName = "your-repo-name"
)

# 2. main ブランチを最新化
git checkout main
git pull origin main

# 3. Flutter Web をビルド
flutter build web --base-href="/$RepoName/"

# 4. gh-pages ブランチに切り替え
git checkout gh-pages

# 5. build/web の中身を gh-pages のルートに同期（PowerShell で代替）
$SourceDir = "build/web"
$TargetDir = "."

# コピー
Get-ChildItem -Path $SourceDir -Recurse | ForEach-Object {
    $RelativePath = $_.FullName.Substring($SourceDir.Length + 1)
    $TargetPath = Join-Path $TargetDir $RelativePath
    if ($_.PSIsContainer) {
        if (-not (Test-Path $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force
        }
    } else {
        Copy-Item -Path $_.FullName -Destination $TargetPath -Force
    }
}

# 削除 (ターゲットにのみ存在するファイルを削除)
$SourceFiles = Get-ChildItem -Path $SourceDir -Recurse | Select-Object -ExpandProperty FullName
$TargetFiles = Get-ChildItem -Path $TargetDir -Recurse | Where-Object {$_.FullName -notlike "*\.git*" -and $_.FullName -notlike "*\.github*"} | Select-Object -ExpandProperty FullName

foreach ($TargetFile in $TargetFiles) {
    if ($SourceFiles -notcontains $TargetFile.Replace($TargetDir + "\", $SourceDir + "\")) {
        Remove-Item -Path $TargetFile -Force
    }
}

# 6. コミット＆強制プッシュ
git add --all
git commit -m "Deploy Flutter Web build at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git push origin gh-pages --force

# 7. 作業ブランチ（main）に戻る
git checkout main

# 8. 完了メッセージの表示
Write-Host "✅ Deployed to gh-pages. URL: https://<あなたのユーザー名>.github.io/$RepoName/"