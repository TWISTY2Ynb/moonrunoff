# 来源与许可边界

MoonRunoff 的 MoonBit 实现、测试、整数样本生成器及文档在本仓库原创编写，采用 MIT。没有移植第三方源代码或复制数据集。

数学方法和跨生态功能参考：

- casact/chainladder-python：https://github.com/casact/chainladder-python ，MPL-2.0；参考 CL、BF、Benktander、Cape Cod 的方法定义，独立编写 MoonBit 实现。可选差分工具仅导入独立安装的 Python 包，不将其分发进 MoonCakes。
- mages/ChainLadder：https://github.com/mages/ChainLadder ，GPL；用于确认赔款三角领域和确定性方法边界，没有取用其代码、文档段落或示例夹具。
- moonbitlang/core：官方工具链运行依赖，Apache-2.0；只通过公开 API 导入，不内嵌其源码。

合成测试数据无客户、保单或个人数据。AI 参与研究、设计、实现、修复、测试和文档；发布前以独立有理数计算和实际 CI 验证。
