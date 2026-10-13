"""Step 3 - pick the most engaging 30-60s windows ("hook extraction").

This is a transparent heuristic scorer (no external API needed). To upgrade it, rerank the
top candidates from `plan_clips` with an LLM and keep the same `ClipPlan` output.
"""
import re
from dataclasses import dataclass

from ..config import settings
from .transcriber import Segment, Word

HOOK_OPENERS = ("why", "how", "what if", "stop", "never", "the secret", "here's", "here is",
                "nobody", "most people", "you won't", "imagine", "did you know", "this is",
                "the truth", "i wish", "listen")
POWER_WORDS = {"secret", "mistake", "truth", "insane", "crazy", "free", "money", "never", "always",
               "best", "worst", "biggest", "shocking", "proven", "easy", "fast", "changed",
               "warning", "hack", "simple", "love", "hate", "wrong", "fail", "win", "million"}


@dataclass
class ClipPlan:
    start: float
    end: float
    score: float
    title: str
    words: list[Word]

    @property
    def duration(self) -> float:
        return self.end - self.start


def _ends_sentence(text: str) -> bool:
    return text.rstrip().endswith((".", "!", "?"))


def _score(window: list[Segment], start: float, end: float) -> float:
    text = " ".join(s.text for s in window)
    low, first = text.lower(), window[0].text.lower().strip()
    duration = end - start
    score = 0.0

    # 1) Does it open with a hook?
    if "?" in window[0].text or first.startswith(HOOK_OPENERS):
        score += 3.0
    # 2) Emotional / curiosity vocabulary, numbers, emphasis.
    tokens = re.findall(r"[a-z']+", low)
    score += min(sum(t in POWER_WORDS for t in tokens) * 0.6, 3.0)
    score += min(len(re.findall(r"\d+", low)) * 0.5, 2.0)
    score += min((text.count("!") + text.count("?")) * 0.4, 2.0)
    # 3) Energetic pacing (words/second sweet spot) and ideal length around 45s.
    wps = len(tokens) / max(duration, 1)
    if 2.0 <= wps <= 3.8:
        score += 1.5
    score += max(0.0, 1.0 - abs(duration - 45) / 15)
    return round(score, 2)


def _title(text: str) -> str:
    sentence = re.split(r"(?<=[.!?])\s", text.strip(), maxsplit=1)[0]
    return (sentence[:77] + "...") if len(sentence) > 80 else sentence


def plan_clips(segments: list[Segment], video_duration: float) -> list[ClipPlan]:
    lo, hi = settings.min_clip_seconds, settings.max_clip_seconds
    candidates: list[ClipPlan] = []

    for i, first in enumerate(segments):
        ends: list[int] = []
        fallback: int | None = None
        for j in range(i, len(segments)):
            dur = segments[j].end - first.start
            if dur > hi:
                break
            if dur >= lo:
                fallback = j
                if _ends_sentence(segments[j].text):
                    ends.append(j)
        if not ends and fallback is not None:
            ends = [fallback]
        # Keep the shortest and longest valid cut per start to limit combinatorics.
        for j in ({ends[0], ends[-1]} if ends else ()):
            window = segments[i:j + 1]
            start, end = window[0].start, window[-1].end
            words = [w for s in window for w in s.words]
            candidates.append(ClipPlan(start, end, _score(window, start, end),
                                       _title(" ".join(s.text for s in window)), words))

    # Greedy non-overlapping selection, best score first.
    chosen: list[ClipPlan] = []
    for cand in sorted(candidates, key=lambda c: c.score, reverse=True):
        if all(cand.end + 2 <= c.start or cand.start >= c.end + 2 for c in chosen):
            chosen.append(cand)
        if len(chosen) >= settings.clips_per_video:
            break

    # Short or speechless videos: fall back to one clip from the start.
    if not chosen and video_duration >= 5:
        chosen.append(ClipPlan(0, min(video_duration, hi), 0.0, "Highlight", []))
    return chosen
