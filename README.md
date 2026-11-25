# MoonRunoff：非寿险赔款发展与准备金

MoonRunoff 用 MoonBit 实现累计已支付赔款三角、确定性准备金模型、未来支付分解和历史留出回测。准备金分析人员、暴露量数据工程师和模型复核人员可以复用同一组校验与数值 API，也可以通过 JSON 请求引擎集成到服务或命令行任务。代码采用 MIT 许可证。

- 模块：`TWISTY2Ynb/moonrunoff@0.1.1`
- [GitHub 源码](https://github.com/TWISTY2Ynb/moonrunoff)
- [MoonCakes 中文说明及 API](https://mooncakes.io/docs/TWISTY2Ynb/moonrunoff)
- [CI](https://github.com/TWISTY2Ynb/moonrunoff/actions/workflows/ci.yml)
- [数值合同](docs/architecture.md)、[请求协议](docs/request.md)、[查重与参考边界](docs/competition/duplicate-check.md)、[验证方法](docs/verification.md)

## 已实现的完整范围

|输入和任务|处理|输出|
|---|---|---|
|准备金分析员的累计或增量赔款|校验三角、选择 volume/simple/regression 因子、Chain Ladder 投影|每事故期已付/最终赔款/未付准备金，发展期和支付日历|
|数据工程师的先验最终赔款或暴露量|BF、迭代 Benktander、Cape Cod|统一估计对象、可对账现金流、JSON/CSV|
|模型复核者的历史数据和因子选择|最近窗口、配对排除、手工因子、历史截面重新拟合、单因子压力|原始残差、留出 MAE/RMSE/WAPE、准备金变化|

此外提供组合相加、按事故期重述、完整累计投影和按远期利率贴现。贴现仅是确定性现金流运算；原始准备金不自动贴现。

## 环境和安装

需要 MoonBit **moonc 0.10.22 或更新版本**；本次验收与 CI 固定在 `v0.10.22+124d61d05`。该版本采用当前派生语法，且满足比赛的最低 0.10.16 要求。CI 固定下载官方同版本编译器及 core，避免 latest 漂移。运行 JavaScript 后端需要 Node.js 22；原生后端需要可用的 C 编译工具链。库只依赖随工具链提供的 `moonbitlang/core`。

在你的 MoonBit 项目目录运行：

```sh
moon update
moon add TWISTY2Ynb/moonrunoff@0.1.1
```

在消费者包的 `moon.pkg` 中声明：

```moonbit
import { "TWISTY2Ynb/moonrunoff" @runoff }
options("is-main": true)
```

在 `main.mbt` 中写入以下最小可运行样例：

```moonbit
fn main raise {
  let t = @runoff.Triangle::new([
    [100.0, 150.0, 180.0],
    [120.0, 180.0],
    [140.0],
  ])
  let p = @runoff.Pattern::fit(t)
  let estimate = @runoff.chain_ladder(t, p)
  assert_true((estimate.total_reserve() - 148.0).abs() < 1.0e-9)
  assert_true(estimate.reconcile().balanced)
  println(estimate.to_json())
}
```

执行 `moon run .`。按事故期的最终赔款约为 `[180,216,252]`，未付准备金约为 `[0,36,112]`，总计约为 `148`。输出是 `moonrunoff/v1` JSON。Double 有舍入误差，不要使用十进制字符串完全相等作为验收条件。

## 从源码运行三条工作流

```sh
git clone https://github.com/TWISTY2Ynb/moonrunoff.git
cd moonrunoff
moon run examples/claims
moon run examples/exposure
moon run examples/review
```

`claims` 从坐标 CSV 导入并估计 CL、对账、输出 JSON；`exposure` 在同一三角上分别运行 BF、Benktander 和 Cape Cod；`review` 使用因子窗口/手工覆盖和尾因子，输出残差、历史留出与压力报告。每个例子含结果断言，失败时进程返回非零。

## CLI 与服务接入

以下命令适用于 Bash 和 PowerShell；JSON 用单引号括起：

```sh
moon run cmd/moonrunoff -- --request '{"triangle":[[100,150,180],[120,180],[140]]}'
moon run cmd/moonrunoff -- --request '{"triangle":[[100,150,180],[120,180],[140]],"estimator":"bornhuetter-ferguson","prior":[200,220,240]}'
moon run cmd/moonrunoff -- --request '{"triangle":[[100,150,180],[120,190],[140]],"action":"backtest"}'
moon run cmd/moonrunoff -- --request '{"triangle":[[100,150,180],[120,180],[140]],"action":"stress","shock":0.02}'
```

CLI 非法请求返回非零状态，由 MoonBit 运行时报告错误。嵌入服务时直接调用 `execute_request(text)` 接收 `RunoffError`，或调用 `execute_request_result(text)` 得到版本化错误 JSON；后者只返回字符串，不替宿主设置退出码。CLI 不读文件、不联网，不把请求写入磁盘；大批量或敏感数据推荐直接调用库，不通过命令行参数传递。

## 因子选择和先验模型

`selected_factors(t, average=Volume, recent=2, excluded=[(1,0)], overrides=[(2,1.1)])` 返回逐发展期的 factor、样本数、零基数计数和分子/分母；坐标均从 0 开始。`recent=0` 使用全部配对；最近窗口按原始事故期选择，随后应用排除，不回填更早配对。手工覆盖对应统计样本数为 0，明确表示没有拟合。

`Pattern::new(factors, tail=1.05)` 构造固定模式。CDF 包含尾因子一次。`bornhuetter_ferguson(t,p,prior)` 的 prior 是预期最终赔款，不是保费；`benktander(...,iterations=2)` 从 prior 出发执行两次 BF，次数为 1–1000；`cape_cod(t,p,exposure)` 要求每个暴露量严格为正，返回拟合赔付率和估计。

`estimate.payments()` 给出 origin/age/calendar/amount/is_tail；尾支付位于 age=n 单独标记，不挤入最后一个观测发展期。BF 等模型的准备金按同一模式的剩余发展权重分配，并非把 CL 现金流直接照搬。`calendar_payments()` 数组索引为从 0 开始的日历期；历史期为 0。`discounted_reserves(rates)` 接受 n 个远期利率，第一项作用于第一个未来日历期，负利率必须大于 -1。

## 数据合同与失败行为

- 阶数 2–128；第 i 行恰有 n−i 个单元格；只接受有限、非负、同行不下降的累计已付赔款。增量模式也要求每个增量非负。不接受内部缺失、负追偿和不规则三角。
- `Triangle` 和 `Pattern` 复制构造输入及导出数组。单位由调用者统一，Double 不用于精确货币记账。
- x=0 的发展配对跳过并披露；没有正基数配对时拒绝估计，需要显式因子覆盖。溢出、零分母和非法选择会返回分类错误，不输出看似有效的 Infinity/NaN。
- JSON/CSV 最多 1 Mi 个 UTF-16 代码单元；JSON 深度最多 16、拒绝重复键；CSV 最多 8256 个单元格，要求 `origin,age,value` 表头，不支持引号、注释和额外列。
- 错误分类为 Shape、Value、Selection、Numerical、Parse。错误文本用于诊断，不作为稳定机器协议。
- 回测仅预测下一条已知对角线中已存在事故期的单元格，最早事故期缺乏下一期因子、新事故期没有历史基数，均不纳入。每个截面重新拟合；未来观测不会参与拟合。
- 残差是描述统计，不是 Mack 标准误；不提供 bootstrap、风险资本分位数、自动尾拟合、寿险生命表、IFRS/监管合规或财务建议。历史准确不证明模式适用于未来。

## 开发和复现

```sh
python tools/check_toolchain.py
moon info
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
python tools/differential.py
moon test --deny-warn --enable-coverage
moon coverage report -- -f summary
```

四个目标使用 `--target wasm-gc|wasm|js|native`。CI 在每个目标执行 check/build/test、三个例子和 CLI；在 wasm-gc 上额外执行标准库 Fraction 独立差分和覆盖率报告。差分生成固定种子的 12 个 2–9 阶正整数三角，3 类平均 × 4 类模型，共 144 组请求，不依赖复制自上游的数据夹具。更多结果、平台边界和审计口径见[验证说明](docs/verification.md)。

## 许可证、参考与 AI 使用

原创实现采用 [MIT](LICENSE)。数学方法及功能范围参考 [chainladder-python](https://github.com/casact/chainladder-python)（MPL-2.0）和 [R ChainLadder](https://github.com/mages/ChainLadder)（GPL）；没有复制它们的实现、注释或数据。core 为 MoonBit 官方运行依赖。权利边界见 [NOTICE](NOTICE.md)。AI 参与选题检索、设计、代码、测试和文档，验证记录以实际命令和 CI 结果为准。
