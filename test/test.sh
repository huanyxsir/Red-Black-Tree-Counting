#!/bin/bash

# 红黑树计数算法性能测试脚本
# 自动编译和测试BF, DP, GF, NTT四种算法

WORKSPACE="/data/zhaohengyu/ads_p4/Red-Black-Tree-Counting"
SRC_DIR="${WORKSPACE}/src"
OUTPUT_FILE="${WORKSPACE}/benchmark_results.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "   红黑树计数算法性能测试"
echo "======================================"
echo ""

# 清空输出文件
> "$OUTPUT_FILE"

# 写入标题
echo "红黑树计数算法性能测试结果" >> "$OUTPUT_FILE"
echo "测试时间: $(date)" >> "$OUTPUT_FILE"
echo "编译选项: -O2" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 步骤1: 编译所有程序
echo "步骤 1: 编译所有程序 (使用 -O2 优化)..."
cd "$WORKSPACE"

compile_program() {
    local name=$1
    local src=$2
    local output=$3
    
    echo -n "  编译 ${name}... "
    if g++ -O2 "${SRC_DIR}/${src}" -o "${output}" 2>/dev/null; then
        echo -e "${GREEN}成功${NC}"
        return 0
    else
        echo -e "${RED}失败${NC}"
        return 1
    fi
}

compile_program "BF" "BF.cpp" "bf"
BF_SUCCESS=$?

compile_program "DP" "DP.cpp" "dp"
DP_SUCCESS=$?

compile_program "GF" "GF.cpp" "gf"
GF_SUCCESS=$?

compile_program "NTT" "NTT.cpp" "ntt"
NTT_SUCCESS=$?

echo ""
echo "步骤 2: 运行性能测试..."
echo ""

# 测试的N值
TEST_VALUES=(5 10 20 50 100 1000 5000 10000 50000 100000)

# 程序列表
declare -A PROGRAMS
PROGRAMS=(
    ["bf"]="BF.cpp"
    ["dp"]="DP.cpp"
    ["gf"]="GF.cpp"
    ["ntt"]="NTT.cpp"
)

declare -A COMPILED
COMPILED=(
    ["bf"]=$BF_SUCCESS
    ["dp"]=$DP_SUCCESS
    ["gf"]=$GF_SUCCESS
    ["ntt"]=$NTT_SUCCESS
)

# 存储结果的数组
declare -A RESULTS

# 超时时间（秒）
TIMEOUT=300

# 运行测试
for prog_name in bf dp gf ntt; do
    if [ ${COMPILED[$prog_name]} -ne 0 ]; then
        echo -e "${RED}跳过 $prog_name (编译失败)${NC}"
        for n in "${TEST_VALUES[@]}"; do
            RESULTS["${prog_name}_${n}"]="COMPILE_ERROR"
        done
        continue
    fi
    
    echo -e "${YELLOW}测试程序: $prog_name${NC}"
    
    # 标记该程序是否已经超时
    local has_timeout=false
    
    for n in "${TEST_VALUES[@]}"; do
        # 如果之前已经超时，跳过后续更大的N
        if [ "$has_timeout" = true ]; then
            RESULTS["${prog_name}_${n}"]="T/L"
            echo "  N=$n: 跳过 (前序已超时)"
            continue
        fi
        
        echo -n "  N=$n: "
        
        # 使用timeout命令限制运行时间，并使用time测量
        START_TIME=$(date +%s.%N)
        timeout $TIMEOUT bash -c "echo $n | ./${prog_name} > /dev/null 2>&1"
        EXIT_CODE=$?
        END_TIME=$(date +%s.%N)
        
        if [ $EXIT_CODE -eq 124 ]; then
            # 超时
            RESULTS["${prog_name}_${n}"]="T/L"
            has_timeout=true
            echo -e "${RED}超时 (>300s)${NC}"
        elif [ $EXIT_CODE -ne 0 ]; then
            # 运行错误
            RESULTS["${prog_name}_${n}"]="ERROR"
            has_timeout=true
            echo -e "${RED}错误${NC}"
        else
            # 计算运行时间
            ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
            RESULTS["${prog_name}_${n}"]="$ELAPSED"
            echo -e "${GREEN}${ELAPSED}s${NC}"
        fi
    done
    echo ""
done

echo "======================================"
echo "   测试完成"
echo "======================================"
echo ""

# 生成结果表格
echo "生成结果表格..."
echo "" >> "$OUTPUT_FILE"
echo "性能测试结果表格:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 表头
printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" "N" "BF (bf)" "DP (dp)" "GF (gf)" "NTT (ntt)" >> "$OUTPUT_FILE"
echo "-----------|-----------------|-----------------|-----------------|----------------" >> "$OUTPUT_FILE"

# 数据行
for n in "${TEST_VALUES[@]}"; do
    bf_result="${RESULTS[bf_${n}]}"
    dp_result="${RESULTS[dp_${n}]}"
    gf_result="${RESULTS[gf_${n}]}"
    ntt_result="${RESULTS[ntt_${n}]}"
    
    # 格式化输出（如果是数字，添加's'后缀）
    format_result() {
        if [[ $1 =~ ^[0-9.]+$ ]]; then
            echo "${1}s"
        else
            echo "$1"
        fi
    }
    
    printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" \
        "$n" \
        "$(format_result "$bf_result")" \
        "$(format_result "$dp_result")" \
        "$(format_result "$gf_result")" \
        "$(format_result "$ntt_result")" >> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"
echo "注释:" >> "$OUTPUT_FILE"
echo "- T/L: 超时 (Time Limit, >300s)" >> "$OUTPUT_FILE"
echo "- ERROR: 运行时错误" >> "$OUTPUT_FILE"
echo "- COMPILE_ERROR: 编译失败" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 添加算法分析
echo "算法复杂度分析:" >> "$OUTPUT_FILE"
echo "- BF.cpp:  O(8^N / N^(3/2)) - 暴力枚举，仅适用于N≤10" >> "$OUTPUT_FILE"
echo "- DP.cpp:  O(N^2 * log N) - 动态规划，适用于N≤5000" >> "$OUTPUT_FILE"
echo "- GF.cpp:  O(N^2 * log N) - 生成函数+Karatsuba乘法" >> "$OUTPUT_FILE"
echo "- NTT.cpp: O(N * log^2 N) - 生成函数+NTT快速乘法，适用于大规模数据" >> "$OUTPUT_FILE"

echo ""
echo "结果已保存到: $OUTPUT_FILE"
echo ""
cat "$OUTPUT_FILE"

