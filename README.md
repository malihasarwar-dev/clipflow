Markdown# ClipFlow - AI YouTube Shorts Clipper

Flutter Web frontend + FastAPI backend. Paste a YouTube URL -> download (yt-dlp) -> transcribe (faster-whisper) -> pick the best 30-60s hooks -> FFmpeg 9:16 crop + burned captions -> gallery.

clipflow/backend/   FastAPI  (auth, job queue, pipeline)frontend/  Flutter Web (UI, AdSense slots)
## 1. Backend

Requirements: Python 3.10+, **FFmpeg** on PATH (`ffmpeg -version`).

```bash
cd backend
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env        # set SECRET_KEY and GOOGLE_CLIENT_ID
uvicorn app.main:app --reload --port 8000
Docs at http://localhost:8000/docs. Or: docker build -t clipflow-api . && docker run -p 8000:8000 --env-file .env clipflow-api.EndpointPurposePOST /api/v1/auth/signup, /loginEmail + password (bcrypt, JWT)POST /api/v1/auth/googleVerifies a Google id_token or access_token, creates the user, returns a session JWTGET  /api/v1/auth/meCurrent userPOST /api/v1/process-videoQueue { "url": "<youtube url>" }, returns job_id (HTTP 202)GET  /api/v1/jobs/{id}Stage, progress and finished clips[] with url / download_urlprocess-video is asynchronous because a download + transcription + render takes minutes; a single HTTP request would time out. The UI polls the job every 2 s to drive the progress stepper.2. FrontendBashcd frontend
flutter create . --platforms web --project-name clipflow   # adds icons/manifest; keeps the files here
flutter pub get
flutter run -d chrome --web-port 5000 \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=GOOGLE_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com
Production: flutter build web --release --dart-define=... and host build/web on any static host.Add that origin to CORS_ORIGINS (backend) and to Authorized JavaScript origins (Google Cloud Console).Google OAuth setupGoogle Cloud Console -> APIs & Services -> Credentials -> OAuth client ID -> Web application.Authorized JavaScript origins: http://localhost:5000 (+ your production domain).Put the client ID in backend/.env (GOOGLE_CLIENT_ID), in web/index.html (google-signin-client_id), and pass it as --dart-define=GOOGLE_CLIENT_ID=....AdSense setupweb/index.html: replace both ca-pub-XXXXXXXXXXXXXXXX values (script + meta). web/ads.txt: same ID.Create two display ad units in AdSense; pass their slot IDs and publisher ID at build time:--dart-define=ADSENSE_CLIENT=ca-pub-... --dart-define=ADSENSE_SLOT_SIDEBAR=123 --dart-define=ADSENSE_SLOT_RESULTS=456Placements: sidebar (300x250) and a banner under the results (728x90, 320x100 on mobile). While IDs contain XXXX, neutral "Ad space" placeholders show instead. Ads go live after Google approves the site.AdSense needs real public content (privacy policy, about/contact pages) to approve a site; a login-only app usually needs a public landing page too.3. Production notes (read before launching)State: jobs live in memory and one worker runs the pipeline. For scale, move to Redis + Celery/RQ and Postgres, and store clips in S3/R2 behind signed URLs.Compute: Whisper base on CPU is slow on long videos. Use WHISPER_DEVICE=cuda, WHISPER_COMPUTE_TYPE=float16, or a larger model for accuracy. Add cleanup (cron) for media/.Hook extraction is a transparent heuristic (services/segmenter.py). Swap plan_clips for an LLM re-rank to improve it.yt-dlp breaks when YouTube changes; keep it updated (pip install -U yt-dlp). Data-center IPs are sometimes blocked and may need cookies/proxy.Legal: downloading and republishing YouTube content can violate YouTube's Terms of Service and copyright. Add Terms/consent that users may only process content they own or are licensed to use.Set a strong SECRET_KEY, serve over HTTPS, and add rate limiting.