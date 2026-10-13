FROM python:3.11-slim
# ffmpeg does the rendering; fonts-liberation is metric-compatible with Arial for burned captions.
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg fonts-liberation fontconfig \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
EXPOSE 8000
# One worker on purpose: the MVP keeps job state in memory (see app/jobs.py).
CMD sh -c "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"