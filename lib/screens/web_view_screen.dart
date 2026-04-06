import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Next.js 등 웹 앱을 띄우고, Flutter에서 네비게이션·JS 실행·웹 브리지·카메라 권한을 다룹니다.
///
/// 웹에서 Flutter 호출:
/// ```js
/// window.flutter_inappwebview?.callHandler('flutterFromWeb', { type: 'ping' });
/// window.flutter_inappwebview?.callHandler('openNativeCamera');
/// ```
class WebViewScreen extends StatefulWidget {
  /// Next 라우트 경로 (예: `/`, `/attacker`).
  final String url;

  /// 스킴+호스트+포트 (경로 없는 오리진 권장).
  final String origin;

  const WebViewScreen({
    super.key,
    this.url = '/',
    this.origin = 'http://222.100.172.236:3000',
  });

  Uri get _initialUri => Uri.parse(origin).resolve(url.startsWith('/') ? url : '/$url');

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webController;
  String? _titleOrUrl;
  double _progress = 0;
  bool _canGoBack = false;

  static bool get _usePermissionHandler {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _syncBackState() async {
    final c = _webController;
    if (c == null) return;
    final back = await c.canGoBack();
    if (mounted) setState(() => _canGoBack = back);
  }

  Future<PermissionResponse> _handleWebPermissionRequest(PermissionRequest request) async {
    final resources = request.resources;
    var needsCamera = false;
    var needsMic = false;
    for (final r in resources) {
      if (r == PermissionResourceType.CAMERA) needsCamera = true;
      if (r == PermissionResourceType.MICROPHONE) needsMic = true;
      if (r == PermissionResourceType.CAMERA_AND_MICROPHONE) {
        needsCamera = true;
        needsMic = true;
      }
    }

    if (_usePermissionHandler && (needsCamera || needsMic)) {
      if (needsCamera) {
        final s = await Permission.camera.request();
        if (!s.isGranted) {
          return PermissionResponse(resources: resources, action: PermissionResponseAction.DENY);
        }
      }
      if (needsMic) {
        final s = await Permission.microphone.request();
        if (!s.isGranted) {
          return PermissionResponse(resources: resources, action: PermissionResponseAction.DENY);
        }
      }
    }

    return PermissionResponse(resources: resources, action: PermissionResponseAction.GRANT);
  }

  Future<void> _preGrantCameraAndMic() async {
    if (!_usePermissionHandler) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 플랫폼은 웹뷰 권한 프롬프트에 맡깁니다.')),
      );
      return;
    }
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!mounted) return;
    final camOk = cam.isGranted;
    final micOk = mic.isGranted;
    var msg = '카메라: ${camOk ? "허용" : "거부"} · 마이크: ${micOk ? "허용" : "거부"}';
    if (cam.isPermanentlyDenied || mic.isPermanentlyDenied) {
      msg += ' · 설정에서 권한을 켜 주세요.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  Future<void> _openAppSettingsIfNeeded() async {
    if (!_usePermissionHandler) return;
    await openAppSettings();
  }

  Future<void> _captureWithNativeCameraAndSendToWeb() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('웹 빌드에서는 지원하지 않습니다.')),
        );
      }
      return;
    }

    if (_usePermissionHandler) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cam.isPermanentlyDenied ? '설정에서 카메라를 허용해 주세요.' : '카메라 권한이 필요합니다.'),
            action: SnackBarAction(label: '설정', onPressed: openAppSettings),
          ),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final js = '''
(function () {
  var dataUrl = 'data:image/jpeg;base64,$b64';
  try {
    window.dispatchEvent(new CustomEvent('flutterPhoto', { detail: { dataUrl: dataUrl } }));
    if (typeof window.onFlutterPhoto === 'function') window.onFlutterPhoto(dataUrl);
  } catch (e) { console.error(e); }
})();
''';
    await _webController?.evaluateJavascript(source: js);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('촬영 이미지를 웹에 flutterPhoto 이벤트로 전달했습니다.')),
      );
    }
  }

  Future<void> _registerHandlers(InAppWebViewController c) async {
    c.addJavaScriptHandler(
      handlerName: 'flutterFromWeb',
      callback: (args) {
        debugPrint('[Web→Flutter] flutterFromWeb args=$args');
        if (!mounted || args.isEmpty) return;
        final first = args.first;
        final text = first is Map ? '$first' : '$first';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
        );
      },
    );
    c.addJavaScriptHandler(
      handlerName: 'openNativeCamera',
      callback: (args) async {
        await _captureWithNativeCameraAndSendToWeb();
      },
    );
  }

  Future<void> _showJsRunner() async {
    final code = TextEditingController(
      text: 'window.scrollTo({ top: 0, behavior: "smooth" });',
    );
    final run = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('JavaScript 실행'),
        content: TextField(
          controller: code,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '예: document.querySelector("button")?.click()',
          ),
          keyboardType: TextInputType.multiline,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('실행')),
        ],
      ),
    );
    if (run != true || !mounted) return;
    final result = await _webController?.evaluateJavascript(source: code.text);
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('반환: $result'), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topUrl = _titleOrUrl ?? widget._initialUri.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(topUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _canGoBack
              ? () async {
                  await _webController?.goBack();
                  await _syncBackState();
                }
              : null,
        ),
        actions: [
          IconButton(
            tooltip: '네이티브 카메라',
            onPressed: _captureWithNativeCameraAndSendToWeb,
            icon: const Icon(Icons.photo_camera_outlined),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _webController?.reload()),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'js':
                  await _showJsRunner();
                  break;
                case 'scroll_top':
                  await _webController?.evaluateJavascript(
                    source: 'window.scrollTo({ top: 0, behavior: "smooth" });',
                  );
                  break;
                case 'scroll_bottom':
                  await _webController?.evaluateJavascript(
                    source: 'window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" });',
                  );
                  break;
                case 'perm_camera':
                  await _preGrantCameraAndMic();
                  break;
                case 'open_settings':
                  await _openAppSettingsIfNeeded();
                  break;
                case 'native_camera':
                  await _captureWithNativeCameraAndSendToWeb();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'perm_camera', child: Text('카메라·마이크 권한 요청')),
              PopupMenuItem(value: 'open_settings', child: Text('앱 설정 열기')),
              PopupMenuItem(value: 'native_camera', child: Text('네이티브 카메라 → 웹으로 전달')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'js', child: Text('JavaScript 실행…')),
              PopupMenuItem(value: 'scroll_top', child: Text('맨 위로 스크롤')),
              PopupMenuItem(value: 'scroll_bottom', child: Text('맨 아래로 스크롤')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress >= 1
              ? const SizedBox.shrink()
              : LinearProgressIndicator(value: _progress, minHeight: 2),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget._initialUri.toString())),
        initialSettings: InAppWebViewSettings(
          javaScriptCanOpenWindowsAutomatically: true,
          javaScriptEnabled: true,
          useOnDownloadStart: true,
          useOnLoadResource: true,
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          verticalScrollBarEnabled: true,
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ),
        onPermissionRequest: (controller, request) => _handleWebPermissionRequest(request),
        onReceivedError: (controller, request, error) {
          debugPrint('WebView 오류: ${error.description}');
        },
        onWebViewCreated: (c) async {
          _webController = c;
          await _registerHandlers(c);
          await _syncBackState();
        },
        onLoadStart: (c, url) {
          if (!mounted) return;
          setState(() {
            _titleOrUrl = url?.toString();
            _progress = 0;
          });
        },
        onProgressChanged: (c, progress) {
          if (!mounted) return;
          setState(() => _progress = progress / 100);
        },
        onLoadStop: (c, url) async {
          if (!mounted) return;
          setState(() {
            _titleOrUrl = url?.toString();
            _progress = 1;
          });
          await _syncBackState();
          final t = await c.getTitle();
          if (t != null && t.isNotEmpty && mounted) {
            setState(() => _titleOrUrl = t);
          }
        },
        onUpdateVisitedHistory: (c, url, androidIsReload) async {
          if (!mounted) return;
          if (url != null) setState(() => _titleOrUrl = url.toString());
          await _syncBackState();
        },
      ),
    );
  }
}
