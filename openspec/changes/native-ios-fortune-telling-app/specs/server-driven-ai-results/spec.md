## ADDED Requirements

### Requirement: Unified AI analysis task protocol
系统 SHALL 使用统一任务协议连接服务端大模型分析能力，覆盖生日命理、掌纹面相和黄道吉日三类请求。

#### Scenario: Create AI analysis task
- **WHEN** 任一业务流程提交分析请求
- **THEN** 系统 MUST 创建服务端分析任务并获得可追踪的 `taskId`

#### Scenario: Query AI analysis task
- **WHEN** 分析任务处于生成中
- **THEN** 系统 MUST 查询任务状态并展示 pending、running、succeeded 或 failed 状态

### Requirement: Structured AI result parsing
系统 SHALL 解析服务端返回的结构化结果，按业务类型映射为客户端结果模型。

#### Scenario: Parse known result schema
- **WHEN** 服务端返回符合当前 schema 的分析结果
- **THEN** 系统 MUST 将结果映射为对应业务页面的展示模型

#### Scenario: Handle unsupported schema version
- **WHEN** 服务端返回客户端不支持的 schema 版本
- **THEN** 系统 MUST 展示兼容性错误并记录诊断信息

### Requirement: AI task error handling
系统 SHALL 对网络错误、超时、服务端失败和内容生成失败提供一致的错误展示和重试策略。

#### Scenario: Retry recoverable task error
- **WHEN** 分析任务因网络错误或服务端临时错误失败
- **THEN** 系统 MUST 提供重试入口并保留用户已输入内容

#### Scenario: Stop unrecoverable task error
- **WHEN** 服务端返回参数非法、图片不合规或内容无法生成
- **THEN** 系统 MUST 展示明确原因并引导用户修改输入
