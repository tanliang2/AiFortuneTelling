## ADDED Requirements

### Requirement: Birthday fortune input
系统 SHALL 提供生日命理输入流程，收集生成星座、生辰八字和五行分析所需的用户信息，并在提交前完成本地校验。

#### Scenario: Submit complete birthday profile
- **WHEN** 用户输入公历生日、出生时间、出生地区和必要个人信息后点击生成
- **THEN** 系统 MUST 校验字段完整性并提交生日命理分析请求

#### Scenario: Missing required birthday profile
- **WHEN** 用户缺少生日、出生时间或出生地区等必要字段时点击生成
- **THEN** 系统 MUST 阻止提交并展示具体缺失项

### Requirement: Birthday fortune result
系统 SHALL 展示服务端大模型返回的生日命理结果，至少包含星座、生辰八字、五行、性格、事业、感情、健康和娱乐参考声明。

#### Scenario: Display structured birthday result
- **WHEN** 生日命理任务生成成功
- **THEN** 系统 MUST 按结构化模块展示星座、生辰八字、五行与各维度解读

#### Scenario: Birthday result field missing
- **WHEN** 服务端结果缺少某个非核心解读字段
- **THEN** 系统 MUST 保留已返回模块并对缺失模块降级展示

### Requirement: Birthday fortune regeneration
系统 SHALL 允许用户修改生日资料后重新生成命理结果，并将新旧结果作为独立历史记录保存。

#### Scenario: Regenerate after profile edit
- **WHEN** 用户从结果页返回修改生日资料并重新生成
- **THEN** 系统 MUST 创建新的分析任务而不是覆盖旧结果
