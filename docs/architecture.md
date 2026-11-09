# 数值合同与实现边界

输入为2–128阶累计已支付赔款三角，第i行恰有n-i个观测。值有限非负且同行不下降；不支持负赔款、追偿、内部缺测或不规则发展期。Double的单位由调用者统一指定，不是精确货币记账。

三类完整工作流：准备金分析员从累计赔款估计因子/投影/IBNR；数据与定价工程师从暴露量和先验获得BF/Benktander/Cape Cod估计；模型复核者从历史截面、排除项和压力得到留出误差及支付日历。

Triangle私有存储，复制输入/输出。公开构造器校验维度和数值，溢出、非有限中间值、零分母、无可用配对显式报错。配对x=0跳过并披露，无可用样本须显式选择因子。

volume/simple/regression因子分别为Σy/Σx、mean(y/x)、Σxy/Σx²。CL: U=latest×CDF；BF: U=latest+prior×(1−1/CDF)；Benktander以prior为第0次估计反复应用BF；Cape Cod先验赔付率Σlatest/Σ(exposure/CDF)。尾因子≥1，尾支付独立标记。残差不是Mack标准误或资本分位数。

未来支付按剩余发展模式分配该方法ultimate−latest，尾支付单列。回测只使用历史截面，不借用完整三角因子。n≤128，情景及迭代有上限。

不提供寿险生命表、个体定价、监管报表、Mack/Bootstrap随机误差、自动尾拟合或财务建议。数学正确不等于假设适用于真实组合。

原创实现；数学/API概念参考casact/chainladder-python（MPL-2.0）、mages/ChainLadder（GPL），无源码/注释/夹具复制。AI参与设计、实现、测试和文档。
