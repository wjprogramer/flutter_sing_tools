import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/utilities/assets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TuningForkPage extends StatefulWidget {
  const TuningForkPage({super.key});

  @override
  State<TuningForkPage> createState() => _TuningForkPageState();
}

class _TuningForkPageState extends State<TuningForkPage> {
  late WebViewController _controller;

  var _frequency = 440.0;
  var _volume = 0.1;
  var _waveform = 'sine';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset(Assets.tuning_fork_html);
    // initialUrl: 'about:blank', // 預設空白
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('電子振盪器'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 可選：隱藏 WebView（設成 1px）
          IgnorePointer(
            child: Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: WebViewWidget(
                  controller: _controller,
                ),
              ),
            ),
          ),
          // Flutter 控制面板
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Slider(
                  min: 100,
                  max: 2000,
                  value: _frequency,
                  onChanged: (value) {
                    setState(() {
                      _frequency = value;
                    });
                    _controller.runJavaScript("setFrequency(${value.toInt()})");
                  },
                ),
                Slider(
                  min: 0,
                  max: 1,
                  value: _volume,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
                    _controller.runJavaScript("setVolume(${value.toStringAsFixed(2)})");
                  },
                ),
                DropdownButton<String>(
                  value: _waveform,
                  items: ['sine', 'square', 'triangle', 'sawtooth']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _waveform = value;
                      });
                      _controller.runJavaScript("setWaveform('$value')");
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _controller.runJavaScript("play()"),
                      child: Text('Play'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _controller.runJavaScript("stop()"),
                      child: Text('Stop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
