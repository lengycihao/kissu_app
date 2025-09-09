使用方式

> # 方法1：一次性提及所有相关文件
claude
> 我有4个关联的Dart文件：a.dart, b.dart, c.dart, d.dart。请先分析它们之间的关系，然后在a.dart中帮我实现登录功能。

># 方法2：逐步引导Claude了解文件关系
claude
> 请先分析这几个文件的结构和关联关系：
> - a.dart
> - b.dart  
> - c.dart
> - d.dart
> 
> 然后在a.dart中实现登录功能，确保与其他文件的接口兼容

> # 方法3：明确说明文件职责
claude
> 我的项目结构：
> - a.dart: 主界面文件，需要添加登录功能
> - b.dart: 网络请求处理
> - c.dart: 数据模型定义  
> - d.dart: 工具函数
> 
> 请帮我在a.dart中实现登录功能，需要调用b.dart的网络请求，使用c.dart的用户模型，可能需要d.dart的工具函数

 ># 方法4：使用上下文管理
claude
> /context  # 查看当前上下文使用情况
> 
> 请分析我的Dart项目中a.dart, b.dart, c.dart, d.dart这四个文件的依赖关系，然后在a.dart中实现用户登录功能，确保：
> 1. 复用现有的网络请求逻辑
> 2. 使用正确的数据模型
> 3. 保持代码架构的一致性


> # 方法5：分步骤实现
claude
> 第一步：请分析a.dart, b.dart, c.dart, d.dart的当前架构
> 
> # 等Claude分析完成后：
> 第二步：基于现有架构，在a.dart中设计登录功能的接口
> 
> # 然后：
> 第三步：实现具体的登录逻辑，确保与b.dart的网络层、c.dart的模型层正确集成


> # 使用初始化命令了解项目：
> /init  # 让Claude分析整个项目并生成CLAUDE.md文档



> # 查看项目依赖：
> !find . -name "*.dart" -exec grep -l "import" {} \;   




> # 最佳实践示例：
claude
> 我正在开发Flutter应用，有以下文件：
> - a.dart: LoginScreen (登录界面)
> - b.dart: ApiService (API调用服务)  
> - c.dart: UserModel (用户数据模型)
> - d.dart: ValidationUtils (验证工具)
>
> 请帮我在a.dart中完善登录功能，要求：
> 1. 使用b.dart中的API服务进行认证
> 2. 将响应数据转换为c.dart中的UserModel
> 3. 使用d.dart中的表单验证
> 4. 遵循现有的错误处理模式