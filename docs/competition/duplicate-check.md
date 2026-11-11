# 选题门禁与有界语义查重（2026-11-09）

执行已安装osc2026-guide的Project Research Guide：`moon search <词> --limit 100`、MoonCakes精确包/源码、GitHub repository/code查询per_page100，检查[官方清单](https://github.com/moonbitlang/awesome-moonbit)和永久注册表。固定规则沿用builder九月资料及本对话验收要求。

## 不同领域候选

|候选|需求基线与三类任务|广度/用户/复用/重合风险/深度/验证/可交付/维护，1–5|硬门禁|
|---|---|---|---|
|赔款发展MoonRunoff|Python/R ChainLadder；准备金分析、暴露量接入、模型历史回测|4/4/5/4/4/5/5/4=35|通过有界检索|
|删失生存分析|lifelines/survival；研究KM、设备寿命、组间比较|5/4/5/1/5/5/4/4=33|成熟直接替代，淘汰|
|CAN/J1939|成熟通信协议；汽车诊断、工业接入、仿真|5/5/5/1/5/4/3/3=31|成熟直接替代，淘汰|
|质谱峰处理|matchms/MSnbase；代谢组、峰库、流程接入|4/4/4/2/4/5/4/4=31|BioSeqs核心邻接，淘汰|

Touchstone/PLY/FCS/EDF/SEG-Y/GEDCOM探索也有直接实现，不开发。

## 实际检索与限制

Runoff扩词chainladder/reserving/actuarial/Mack/Bornhuetter/insurance/loss triangle/loss development/liability/IBNR/moonrunoff。GitHub反查chainladder、bornhuetter、age_to_age（language:MoonBit）无命中；IBNR的2条为PDF/AV1夹具；loss_ratio的3条为交易；cape_cod/Mack有escape/人名分词命中，非直接替代。reserving/insurance模糊结果达到100上限，不是穷尽检索。索引和语言标记有限制。

生存survival/kaplan，通信J1939/canbus；质谱mgf/mzml/MS/MS/precursor/proteomics/spectral library。

|邻接项目及证据|核心行为|分类/决策|
|---|---|---|
|[hua1104/moonactuary@0.1.1](https://mooncakes.io/docs/hua1104/moonactuary)：下载README、valuation/insurance源、valuation测试|生命表/利率→换算函数、寿险保费/保单准备金|同金融领域不同任务；链接GitHub404，公开包源可读|
|[Lyl66655/moon-survival@0.2.4](https://github.com/Lyl66655/moon-survival)：KM源、测试树、接口|删失观测→KM/Cox|直接替代，淘汰|
|[myc1234567/moonbit-canbus@0.1.2](https://github.com/myc1234567/moonbit-canbus)：j1939源/stack/transport测试树|CAN帧→J1939传输|直接替代，淘汰|
|[IvanAXu/BioSeqs@0.1.14](https://github.com/paipai-Studio/BioSeqs)：proteomics/chemminer/msnbase源及测试/README|序列/谱峰→消化/TIC/joinPeaks|高度邻接，放弃而非格式包装|
|[MoonJCAMP](https://github.com/zbhzs1/moonjcamp)/[MoonSpectrum](https://github.com/chgttyyr/MoonSpectrum)：README和谱源|JCAMP交换/FFT|谱邻接，非赔款任务|
|注册表MoonLedger|复式分录→账簿|无重合|
|注册表MoonBelief|焦元质量→证据融合|无重合|
|注册表MoonNormal/Choice/CoDA/QueueLab|规范化/排序/组成数据/排队|无核心重合|

MoonActuary围绕生命表和保单，Runoff围绕事故期×发展期损失；扩展前者会引入无关输入和生命周期，独立模块更清晰。

已对完整注册表reserved/completed/rejected/external-checked能力扫描，读相关完整指纹；遵守MoonBench/MoonContract/MoonRecur/MoonShard和所有既有边界。开发前排他句柄锁、重读、临时文件+原子替换追加MoonRunoff，保留并发记录。

[Python ChainLadder](https://github.com/casact/chainladder-python)（MPL-2.0）和[R ChainLadder](https://github.com/mages/ChainLadder)（GPL）证明成熟跨生态任务，不声称参赛者使用经验或访谈。原创公开数学方法，无源码/数据复制。验收以独立有理数oracle、安装参考对照、三工作流和四后端检查/测试/构建为准。

交付前复核中央行为和注册表。检查范围内未发现成熟维护的非寿险赔款发展直接替代，不声称全球唯一或主办方认可。原始响应和限制私存。

## 发布前反向复核（2026-11-09）

再次读取完整注册表中 runoff/chainladder/Bornhuetter/Cape Cod/赔款/准备金相关项，仍仅本项目预留；instant runoff voting 为选举算法不同语义。GitHub language:MoonBit bornhuetter 返回 0；cape_cod 返回 20 个转义/终端/PDF 字符串处理命中，逐项核对仓库和路径，非赔款模型。moonrunoff 仓库查询返回 0。上述结果 incomplete_results=false，单页限100；原始响应保存在仓库外，不以零同名替代语义对照。最终功能与开发前核心范围一致。

2026-11-11 补充独立语义验证：实际安装 chainladder 0.8.24，在自生成数据上完成 72 个四模型 CLI 对照、348 项逐事故期比较，详见验证方法。参考仅用于验证共同数学行为，未复制其源码或夹具。
