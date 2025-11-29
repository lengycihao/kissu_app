#1 架构与状态管理（GetX 专项） — P0

目标：把重绘范围限制在最小单元，避免 setState 全局刷新与重复订阅。

用法原则

控制器（GetxController）只放状态与业务逻辑；UI 只通过 Obx / GetBuilder 读取。

避免在同一个页面大量使用 Obx 监听整个模型；把可变子树拆成更小的 Rx 片段（细粒度观测）。

GetBuilder 用于不需要 Rx 的场景（手动调用 update()，开销更小）。Obx 用于频繁变动的小状态。

避免误用（常见反模式）

不要把大型对象（列表、复杂模型）直接设为 Rx 并在多处 Obx 监听同一对象。

不要在 build() 内创建 Controller。用 Get.put()/Get.lazyPut() 在路由或 binding 初始化。

示例（细粒度更新）

class CartController extends GetxController {
  final RxInt itemCount = 0.obs;
  final RxList<Product> items = <Product>[].obs;

  void add(Product p){
    items.add(p);
    itemCount.value = items.length; // 确保两个观察点是分离的
  }
}


在 UI：

Obx(()=> Text('总数: ${controller.itemCount.value}')); // 仅更新数字文字
Obx(()=> ListView.builder(... itemCount: controller.items.length ...)); // 列表单独更新


生命周期管理：在 onClose() 里取消监听 / 释放资源（流、Timer、订阅），避免内存泄露：

@override
void onClose(){
  _timer?.cancel();
  super.onClose();
}


（理由/实践参考：GetX 的智能重建与常见比较分析。）
Medium
+1

#2 渲染 & 帧率（最关键） — P0

目标：消除掉帧（jank），让滚动与动画顺滑。

开启 Impeller（优先尝试）
Impeller 是 Flutter 的新渲染后端，能显著降低 shader 编译导致的掉帧、滑动更稳定。安卓上视 Flutter 版本稳定性可启用或回滚（需在真实设备上充分验证）。
在 AndroidManifest（<application> 或 <activity>）添加 meta-data（视 Flutter 版本与引擎改动可能略有差异）：

<meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true"/>


（注意：在部分设备/版本会触发兼容性问题，启用后务必做回退测试）。
docs.flutter.dev
+1

预编译 SkSL（shader warm-up）以避免首次编译卡顿
流程（常用）：

在真实设备上运行：flutter run --profile --cache-sksl，触发所有动画/特效。

在控制台按 M 导出 sksl 文件（或在 build 目录找到 skia_shader_cache）。

打包时绑定：flutter build apk --bundle-sksl-path=./flutter_01.sksl.json 或 flutter build appbundle --bundle-sksl-path=...。
这会把 shader warm-up 数据打包到 release，显著减少运行时 shader 编译掉帧。
vibe-studio.ai
+1

减少 build/paint

用 const 构造子 widget（能跨 rebuild 复用）。

对昂贵子树包 RepaintBoundary（限制 paint 范围）。

避免 Opacity 或 BackdropFilter 在频繁动画中使用，代替用合成好的图片或预渲染资源。

开启 120Hz / 更高刷新率支持（若设备支持）
Ensure your app renders at the device refresh rate (Flutter already aims to do so; avoid forcing frame locks).

工具：flutter run --profile、DevTools 的 Performance/Timeline、flutter analyze --watch。

（参考：Impeller 与 SkSL 的官方与社区文档及实践总结。）
docs.flutter.dev
+1

#3 列表 / 图片 / 内存（P0）

目标：控制内存峰值，避免大图导致 OOM 与 GPU 卡顿。

列表

用 ListView.builder / SliverList，避免 Column + SingleChildScrollView 承载大量子节点。

设置 cacheExtent 和 addAutomaticKeepAlives 视场景优化。

对复杂 item 使用 RepaintBoundary 和 const 子部分。

图片

下载图片时设置 cacheWidth / cacheHeight 控制解码尺寸：Image.network(url, cacheWidth: 800)。

使用 cached_network_image 或 extended_image（可配置解码、占用内存）并开启磁盘缓存。

对大图做服务端压缩或 CDN 变尺寸，以减轻客户端压力。

内存

避免在短时间内加载大量大图（比如滑动到一个页面一次性加载 50 张高分辨图）。

使用 DevTools 的 Memory Snapshot 检查泄漏 —— 关注 Dart Heap 与 Image cache 大小。

Isolates

大计算（图片处理、加密、PDF 解析、JSON 大文件解析）放到 compute() / 自建 isolate，避免阻塞 UI。

final result = await compute(parseHugeJson, jsonString);

#4 平台交互 & 原生层（P1）

目标：减少 PlatformChannel 的高频调用与上下文切换。

合并调用：将多个小的 platform call 合并为一个批量调用（降低往返成本）。

缓存 native 数据：特别是设备信息、权限状态、文件路径等，避免每帧查询。

避免在 build() 中做原生调用。

图片 & 视频解码：优先用平台能力（ExoPlayer/MediaPlayer）在原生层播放大视频，Flutter 层只做渲染 view。

JNI/NDK：高性能计算可考虑走 native（慎重，只用于真正的热点）。

#5 构建 / 发布（P0）

目标：发布包既小又热启动快，同时带有 shader warm-up 和适配策略。

ProGuard/R8 & 压缩资源

minifyEnabled true、shrinkResources true。注意保留 Flutter plugin 需要的类配置。

Split per ABI（减小 apk 大小）：flutter build apk --split-per-abi

签名 & AAB：Google Play 使用 appbundle，在 CI 打包时做 split-per-abi 以减小下载体积。

SkSL bundle（见上）：务必在打 release 前做 sksl 捕获并打包。
Medium

构建脚本（示例）：

# 本地 warm-up 并导出 sksl (手动触发 app 的核心流程)
flutter run --profile --cache-sksl
# 导出文件（按 M 或在 build 找到）
# 打 release（绑定 sksl）
flutter build appbundle --bundle-sksl-path=./flutter_01.sksl.json --split-per-abi


注意 Impeller 的兼容性：不同 Flutter 版本/设备组合会不同。启用后务必回归测试（有设备出现兼容问题时需要回退）。
GitHub
+1
 

#7 具体工程级建议（为 kissu_app 定制）

（小结 + 快速落地 checklist）

7.1 目录 & 模块化（P1）

feature-first（每个功能一个 module）：/modules/home, /modules/cart。

每模块提供 binding.dart 负责 Get.put()、依赖注入、懒加载。

大型 widget 拆为小组件、使用 const 构造器。

7.2 GetX 具体实践（P0）

每个 Controller 只管理该页面或模块状态。

列表/大数据使用分页（不要一次拉完所有数据），用 RxList + .assignAll() 而非每次重建整个列表。

用 GetBuilder(id: 'xxx') 精准更新：update(['item_123'])。

示例：

// 更新单个 item
GetBuilder<CartController>(
  id: 'item_${product.id}',
  builder: (_) => ItemWidget(product: controller.get(product.id)),
);

// 在 controller 中：
void updateItem(Product p){
  // 更新逻辑...
  update(['item_${p.id}']);
}

7.3 启动速度优化（P0）

精简 main()：把 heavy init（数据库迁移、网络预热）放到后台 isolate 或 splash 后异步完成。

使用 WidgetsFlutterBinding.ensureInitialized(); 但避免在 main 同步做大量工作。

7.4 关键动画/交互（P0）

用 AnimatedBuilder / ValueListenableBuilder 替代过重的 setState。

用 PageStorageKey / AutomaticKeepAliveClientMixin 缓存复杂页面状态，避免重复 rebuild。