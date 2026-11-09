# JSON 请求协议 v1

所有索引从 0 开始。输入根必须是对象，未知字段、重复键、无关模型字段均报错。字段类型不会按字符串自动转换。数组中的整数控制量必须数值精确为整数。

|字段|默认|合同|
|---|---|---|
|triangle|必填|二维数值上三角|
|incremental|false|true 时输入增量|
|action|reserve|reserve / diagnostics / backtest / stress|
|average|volume|volume / simple / regression|
|factors|自动拟合|n−1 个显式因子；不能和 recent/excluded/overrides 同用|
|tail|1|有限且≥1|
|recent|0|最近配对窗口，0 使用全部|
|excluded|[]|[[origin,age],...]，重复项拒绝|
|overrides|[]|[[age,factor],...]，重复发展期拒绝|
|estimator|chain-ladder|chain-ladder / bornhuetter-ferguson / benktander / cape-cod|
|prior|BF/BK必填|n 个非负预期最终赔款|
|exposure|Cape Cod必填|n 个严格正暴露量|
|iterations|2|只用于 Benktander，1–1000|
|shock|0.01|只用于 stress，非负单因子相对上调|

backtest 只接受 triangle/incremental/action/average，始终在每个历史截面重新拟合。diagnostics/stress 可指定发展模式和选择控制，不接受 estimator/prior/exposure/iterations。

reserve 返回 schema=moonrunoff/v1、estimator、origins、payments、total_latest/total_ultimate/total_reserve。diagnostics 返回 schema=moonrunoff/diagnostics/v1、配对数据及 MAE/RMSE。backtest 返回 moonrunoff/backtest/v1、逐留出单元格及 bias/MAE/RMSE/WAPE。WAPE=Σ绝对误差/Σ观测，分母 0 时 null。stress 返回 moonrunoff/stress/v1 和逐发展因子单独上调的结果；基准准备金 0 时 relative_change=null。

错误 API execute_request_result 返回 moonrunoff/error/v1 和 error 字符串。错误分类 API 以 RunoffError 为准；不依赖运行时错误文本的精确格式。

CSV 输入是坐标长表，表头固定 origin,age,value，数据顺序无关，允许行尾 CRLF 和字段首尾空白，只容许最后一行空行。JSON 数字语法约束同样用于 CSV value。列值不支持引号。缺失坐标不能视为 0。
