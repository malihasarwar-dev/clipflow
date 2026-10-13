import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

enum JobPhase { idle, processing, done, failed }

class ClipResult {
  ClipResult.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        url = j['url'] as String,
        downloadUrl = j['download_url'] as String,
        thumbnailUrl = j['thumbnail_url'] as String,
        duration = (j['duration'] as num).toDouble(),
        score = (j['score'] as num).toDouble();

  final String id, title, url, downloadUrl, thumbnailUrl;
  final double duration, score;
}

/// Starts a job and polls it until the backend reports done/failed.
class ClipController extends ChangeNotifier {
  ClipController(this.api, {this.onUnauthorized});

  final ApiService api;
  final VoidCallback? onUnauthorized;

  static const stages = ['downloading', 'transcribing', 'extracting_hooks', 'rendering'];

  JobPhase phase = JobPhase.idle;
  int stageIndex = 0;
  double progress = 0;
  String? videoTitle;
  String? error;
  List<ClipResult> clips = [];

  Timer? _timer;
  bool _polling = false;

  Future<void> start(String url) async {
    _timer?.cancel();
    phase = JobPhase.processing;
    stageIndex = 0;
    progress = 0;
    error = null;
    videoTitle = null;
    clips = [];
    notifyListeners();
    try {
      final job = await api.processVideo(url);
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll(job['job_id'] as String));
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  Future<void> _poll(String jobId) async {
    if (_polling) return; // never overlap requests
    _polling = true;
    try {
      final j = await api.getJob(jobId);
      progress = (j['progress'] as num).toDouble();
      videoTitle = j['video_title'] as String?;
      final idx = stages.indexOf(j['stage'] as String);
      if (idx >= 0) stageIndex = idx;
      clips = (j['clips'] as List)
          .map((c) => ClipResult.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();

      switch (j['status']) {
        case 'done':
          _timer?.cancel();
          phase = JobPhase.done;
        case 'failed':
          _timer?.cancel();
          error = (j['error'] as String?) ?? 'Processing failed.';
          phase = JobPhase.failed;
      }
      notifyListeners();
    } on ApiException catch (e) {
      _fail(e);
    } finally {
      _polling = false;
    }
  }

  void _fail(ApiException e) {
    _timer?.cancel();
    if (e.status == 401) onUnauthorized?.call();
    error = e.message;
    phase = JobPhase.failed;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
