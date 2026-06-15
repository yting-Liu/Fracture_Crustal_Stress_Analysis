#!/bin/bash

RESULT_DIR="/xxx/organize_wid_amp_shear_normal"
MATLAB_BIN="/xxx/matlab"  # MATLAB path

for file in "$RESULT_DIR"/*.txt; do
    filename=$(basename "$file")
    id=${filename:0:4}

    echo "🔍 正在准备处理 ID: $id"
    read -p "是否处理该 ID？输入 y 执行，n 跳过，q 退出: " choice

    case "$choice" in
        y|Y)
            echo "▶️ 开始处理 ID: $id"
            "$MATLAB_BIN" -nosplash -r "try, process_profile('$id'); catch e, disp(getReport(e)); end; quit"
            ;;
        q|Q)
            echo "❌ 用户退出处理流程。"
            break
            ;;
        *)
            echo "⏭️ 跳过 ID: $id"
            ;;
    esac
done

echo "✅ 批处理流程已完成。"
