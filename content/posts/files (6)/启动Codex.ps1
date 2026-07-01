# ============================================================
# 一键启动 Codex + Moon Bridge
# 使用前修改下方两个变量：
#   MOONBRIDGE_DIR → moon-bridge 文件夹的实际路径
#   WORK_DIR       → 你想让 Codex 操作的项目目录
# ============================================================

$MOONBRIDGE_DIR = "E:\git download\moon-bridge"   # ← 改成你的 moon-bridge 路径
$WORK_DIR       = "C:\Users\Y\Desktop\文献"        # ← 改成你的工作目录

# ---------- 第一个窗口：启动 Moon Bridge ----------
Start-Process powershell -ArgumentList "-NoExit", "-Command",
    "cd '$MOONBRIDGE_DIR'; go run ./cmd/moonbridge --config config.yml"

# 等待 Moon Bridge 启动完成
Write-Host "等待 Moon Bridge 启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# ---------- 第二个窗口：启动 Codex ----------
Start-Process powershell -ArgumentList "-NoExit", "-Command",
    "cd '$WORK_DIR'; `$env:CODEX_HOME = `"$env:USERPROFILE\.codex`"; codex"

Write-Host "已启动！请在新开的两个窗口中操作。" -ForegroundColor Green
