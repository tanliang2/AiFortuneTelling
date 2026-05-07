## ADDED Requirements

### Requirement: Auspicious date request
系统 SHALL 提供黄道吉日选择流程，允许用户选择目标事项、候选日期范围和可选个人生日信息。

#### Scenario: Submit auspicious date request
- **WHEN** 用户选择事项类型、日期范围并点击生成
- **THEN** 系统 MUST 校验日期范围并提交黄道吉日分析请求

#### Scenario: Invalid date range
- **WHEN** 用户选择的结束日期早于开始日期或范围超过系统限制
- **THEN** 系统 MUST 阻止提交并展示日期范围错误

### Requirement: Auspicious date result
系统 SHALL 展示服务端大模型返回的吉日推荐，包含推荐日期、适宜事项、避忌事项、推荐理由和备选日期。

#### Scenario: Display ranked auspicious dates
- **WHEN** 黄道吉日任务生成成功
- **THEN** 系统 MUST 按推荐优先级展示主推荐日期和备选日期

#### Scenario: No suitable date
- **WHEN** 服务端返回候选范围内无合适日期
- **THEN** 系统 MUST 展示原因并允许用户扩大日期范围重新生成

### Requirement: Auspicious date detail
系统 SHALL 允许用户查看单个吉日的详细解释，并支持保存到历史记录。

#### Scenario: Open auspicious date detail
- **WHEN** 用户点击某个推荐日期
- **THEN** 系统 MUST 展示该日期的详细宜忌、推荐理由和注意事项
