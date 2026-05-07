## ADDED Requirements

### Requirement: Palm and face image capture
系统 SHALL 提供掌纹与面相图片采集流程，支持拍摄或从相册选择，并在上传前展示预览确认。

#### Scenario: Capture palm image
- **WHEN** 用户选择拍摄掌纹并完成拍照
- **THEN** 系统 MUST 展示掌纹图片预览并允许确认、重拍或取消

#### Scenario: Capture face image
- **WHEN** 用户选择拍摄面相并完成拍照
- **THEN** 系统 MUST 展示面部图片预览并允许确认、重拍或取消

#### Scenario: Camera permission denied
- **WHEN** 用户拒绝相机权限
- **THEN** 系统 MUST 展示权限说明和跳转系统设置的入口

### Requirement: Palm and face analysis submission
系统 SHALL 在用户确认图片后上传掌纹和面相素材，并创建服务端大模型分析任务。

#### Scenario: Submit confirmed images
- **WHEN** 用户确认掌纹和面相图片
- **THEN** 系统 MUST 压缩图片、提交上传请求并进入任务状态页

#### Scenario: Upload failed
- **WHEN** 图片上传失败
- **THEN** 系统 MUST 展示失败原因并提供重试和取消入口

### Requirement: Palm and face result
系统 SHALL 展示服务端返回的掌纹命理和面相分析结果，并区分娱乐参考信息与敏感风险提示。

#### Scenario: Display palm and face reading
- **WHEN** 掌纹面相任务生成成功
- **THEN** 系统 MUST 展示掌纹特征解读、面相特征解读、综合建议和娱乐参考声明

#### Scenario: Image quality rejected
- **WHEN** 服务端返回图片质量不足或无法识别
- **THEN** 系统 MUST 提示用户重新拍摄并说明最低图片要求
