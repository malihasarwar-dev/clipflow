"""Step 2 - speech-to-text with faster-whisper (word-level timestamps for karaoke captions)."""
import threading
from dataclasses import dataclass, field
from pathlib import Path

from faster_whisper import WhisperModel

from ..config import settings


@dataclass
class Word:
    start: float
    end: float
    text: str


@dataclass
class Segment:
    start: float
    end: float
    text: str
    words: list[Word] = field(default_factory=list)


_model: WhisperModel | None = None
_lock = threading.Lock()


def _get_model() -> WhisperModel:
    """Lazy singleton: loading the model takes seconds, so do it once per process."""
    global _model
    with _lock:
        if _model is None:
            _model = WhisperModel(settings.whisper_model, device=settings.whisper_device,
                                  compute_type=settings.whisper_compute_type)
        return _model


def transcribe(media_path: Path) -> list[Segment]:
    # faster-whisper decodes the video's audio track directly through PyAV - no manual ffmpeg step.
    segments, _info = _get_model().transcribe(
        str(media_path), word_timestamps=True, vad_filter=True, beam_size=5)
    out: list[Segment] = []
    for s in segments:  # generator: transcription happens lazily while we iterate
        words = [Word(w.start, w.end, w.word.strip()) for w in (s.words or []) if w.word.strip()]
        out.append(Segment(s.start, s.end, s.text.strip(), words))
    return out
