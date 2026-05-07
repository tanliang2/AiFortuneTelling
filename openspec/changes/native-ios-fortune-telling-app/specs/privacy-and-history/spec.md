## ADDED Requirements

### Requirement: Sensitive data permission disclosure
系统 SHALL 在采集生日、面部、掌纹等敏感信息前说明用途、上传范围和结果性质。

#### Scenario: Show birthday data disclosure
- **WHEN** 用户首次进入生日命理流程
- **THEN** 系统 MUST 展示生日资料用途和娱乐参考声明

#### Scenario: Show image data disclosure
- **WHEN** 用户首次进入掌纹面相流程
- **THEN** 系统 MUST 展示图片采集、上传分析和删除方式说明

### Requirement: Analysis history
系统 SHALL 保存用户的分析历史，支持按类型查看生日命理、掌纹面相和黄道吉日结果。

#### Scenario: Save successful analysis
- **WHEN** 任一分析任务成功生成结果
- **THEN** 系统 MUST 保存历史记录摘要、创建时间、分析类型和结果引用

#### Scenario: View history detail
- **WHEN** 用户从历史列表打开某条记录
- **THEN** 系统 MUST 展示该记录对应的完整分析结果

### Requirement: User data deletion
系统 SHALL 允许用户删除单条历史记录或清空全部历史，并对有关服务端数据发起删除请求。

#### Scenario: Delete one history item
- **WHEN** 用户删除单条分析历史
- **THEN** 系统 MUST 删除本地记录并请求服务端删除对应任务数据

#### Scenario: Clear all history
- **WHEN** 用户选择清空全部历史并二次确认
- **THEN** 系统 MUST 删除本地历史并批量请求服务端删除关联数据
