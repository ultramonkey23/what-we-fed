param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
	[string]$AudioDir = "assets/audio",
	[string]$OutputDir = "data/song_maps/drafts"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$source = @"
using System;
using System.Collections.Generic;
using System.IO;

public static class SongDraftAnalyzer
{
    public static string NormalizeSongId(string fileStem)
    {
        char[] chars = fileStem.ToLowerInvariant().ToCharArray();
        char[] mapped = new char[chars.Length];
        for (int i = 0; i < chars.Length; i++)
        {
            mapped[i] = Char.IsLetterOrDigit(chars[i]) ? chars[i] : '_';
        }

        string id = new string(mapped);
        while (id.IndexOf("__", StringComparison.Ordinal) >= 0)
            id = id.Replace("__", "_");
        return id.Trim('_');
    }

    public static SongDraft Analyze(string fullPath, string relativePath)
    {
        WavData wav = ReadWav(fullPath);
        return BuildDraft(wav, relativePath);
    }

    private static SongDraft BuildDraft(WavData wav, string relativePath)
    {
        int frameSize = Clamp((int)(wav.SampleRate * 0.046), 1024, 4096);
        int hopSize = Math.Max(frameSize / 2, 512);

        List<double> energyTimes = new List<double>();
        List<double> rms = new List<double>();
        List<double> envelope = new List<double>();
        BuildEnvelope(wav.Samples, wav.SampleRate, frameSize, hopSize, energyTimes, rms, envelope);

        TempoEstimate tempo = EstimateTempo(energyTimes, envelope);
        List<double> beats = BuildBeats(wav.DurationSeconds, tempo.BeatIntervalSeconds, tempo.OffsetSeconds);
        List<double> strongBeats = EveryNth(beats, 4);
        List<double> phraseBoundaries = EveryNth(beats, 32);

        List<IntensityWindow> windows = BuildIntensityWindows(wav.DurationSeconds, energyTimes, rms, envelope);
        List<double> structuralChanges = FindStructuralChanges(windows);
        double finalMovementFraction = EstimateFinalMovementFraction(wav.DurationSeconds, structuralChanges);
        List<double> sectionStarts = BuildDraftSections(wav.DurationSeconds, structuralChanges, finalMovementFraction, windows);

        List<SectionCandidate> sectionCandidates = new List<SectionCandidate>();
        List<DraftSection> draftSections = new List<DraftSection>();
        for (int i = 0; i < sectionStarts.Count; i++)
        {
            double time = sectionStarts[i];
            double intensity = SampleWindowIntensity(time, windows);
            double density = SampleWindowDensity(time, windows);

            SectionCandidate candidate = new SectionCandidate();
            candidate.time_seconds = Round3(time);
            candidate.start_fraction = Round4(time / wav.DurationSeconds);
            candidate.label = String.Format("SECTION {0:00}", i + 1);
            candidate.intensity = Round3(intensity);
            candidate.density = Round3(density);
            candidate.reason = i == 0 ? "song_start" : "draft_structural_change";
            candidate.confidence = i == 0 ? "high" : "draft";
            sectionCandidates.Add(candidate);

            DraftSection section = new DraftSection();
            section.id = String.Format("section_{0:00}", i + 1);
            section.label = String.Format("DRAFT SECTION {0:00}", i + 1);
            section.start_fraction = Round4(time / wav.DurationSeconds);
            section.intensity = Round3(intensity);
            section.spawn_interval_mult = Round2(ClampDouble(1.12 - intensity * 0.34, 0.78, 1.12));
            draftSections.Add(section);
        }

        List<string> notes = new List<string>();
        notes.Add("Waveform-generated draft only. Review by ear before wiring into gameplay.");
        notes.Add("Beat and phrase candidates are estimated from energy/onset analysis, not hand-authored timing.");
        if (tempo.Confidence < 0.18)
            notes.Add("Tempo confidence is low. BPM guidance may need manual correction.");
        if (relativePath.EndsWith("tricky.wav", StringComparison.OrdinalIgnoreCase))
            notes.Add("This song already has a live hand-authored map. Do not overwrite it blindly.");

        SongDraft draft = new SongDraft();
        draft.song_id = NormalizeSongId(Path.GetFileNameWithoutExtension(relativePath));
        draft.file_path = "res://" + relativePath.Replace("\\", "/");
        draft.duration_seconds = Round3(wav.DurationSeconds);
        draft.sample_rate = wav.SampleRate;
        draft.channels = wav.Channels;
        draft.bits_per_sample = wav.BitsPerSample;
        draft.estimated_bpm = Round2(tempo.Bpm);
        draft.bpm_confidence = Round3(tempo.Confidence);
        draft.beat_interval_seconds = Round4(tempo.BeatIntervalSeconds);
        draft.beat_timestamps = RoundList(beats, 3);
        draft.strong_beat_timestamps = RoundList(strongBeats, 3);
        draft.phrase_boundary_candidates = RoundList(phraseBoundaries, 3);
        draft.intensity_windows = windows;
        draft.section_candidates = sectionCandidates;
        draft.final_movement_fraction_candidate = Round4(finalMovementFraction);
        draft.confidence_notes = notes;
        draft.draft_song_map = new DraftSongMap();
        draft.draft_song_map.song_path = draft.file_path;
        draft.draft_song_map.bpm = Round2(tempo.Bpm);
        draft.draft_song_map.final_movement_fraction_candidate = Round4(finalMovementFraction);
        draft.draft_song_map.sections = draftSections;
        return draft;
    }

    private static void BuildEnvelope(
        double[] samples,
        int sampleRate,
        int frameSize,
        int hopSize,
        List<double> energyTimes,
        List<double> rms,
        List<double> envelope)
    {
        for (int start = 0; start + frameSize <= samples.Length; start += hopSize)
        {
            double sumSq = 0.0;
            for (int i = 0; i < frameSize; i++)
            {
                double s = samples[start + i];
                sumSq += s * s;
            }
            double value = Math.Sqrt(sumSq / frameSize);
            rms.Add(value);
            energyTimes.Add((start + frameSize * 0.5) / sampleRate);
        }

        for (int i = 0; i < rms.Count; i++)
        {
            int lookback = Math.Min(i, 4);
            double avg = 0.0;
            for (int j = 1; j <= lookback; j++)
                avg += rms[i - j];
            avg = lookback > 0 ? avg / lookback : rms[i];
            envelope.Add(Math.Max(0.0, rms[i] - avg));
        }

        double max = 0.0;
        for (int i = 0; i < envelope.Count; i++)
            if (envelope[i] > max)
                max = envelope[i];

        if (max > 0.0)
        {
            for (int i = 0; i < envelope.Count; i++)
                envelope[i] = envelope[i] / max;
        }
    }

    private static TempoEstimate EstimateTempo(List<double> energyTimes, List<double> envelope)
    {
        TempoEstimate estimate = new TempoEstimate();
        if (energyTimes.Count < 8)
        {
            estimate.Bpm = 120.0;
            estimate.Confidence = 0.0;
            estimate.BeatIntervalSeconds = 0.5;
            estimate.OffsetSeconds = 0.0;
            return estimate;
        }

        double hopSeconds = energyTimes.Count > 1 ? energyTimes[1] - energyTimes[0] : 0.023;
        double bestBpm = 120.0;
        double bestScore = Double.MinValue;
        double secondBest = Double.MinValue;
        int bestLag = 1;

        for (int bpm = 70; bpm <= 180; bpm++)
        {
            int lag = Math.Max(1, (int)Math.Round((60.0 / bpm) / hopSeconds));
            double score = 0.0;
            for (int i = lag; i < envelope.Count; i++)
                score += envelope[i] * envelope[i - lag];
            for (int i = lag * 2; i < envelope.Count; i++)
                score += 0.35 * envelope[i] * envelope[i - lag * 2];

            if (score > bestScore)
            {
                secondBest = bestScore;
                bestScore = score;
                bestBpm = bpm;
                bestLag = lag;
            }
            else if (score > secondBest)
            {
                secondBest = score;
            }
        }

        double confidence = 0.0;
        if (bestScore > 0.0)
            confidence = ClampDouble((bestScore - Math.Max(secondBest, 0.0)) / bestScore, 0.0, 1.0);

        int bestOffsetFrame = 0;
        double bestOffsetScore = Double.MinValue;
        for (int offset = 0; offset < bestLag; offset++)
        {
            double score = 0.0;
            for (int idx = offset; idx < envelope.Count; idx += bestLag)
                score += envelope[idx];
            if (score > bestOffsetScore)
            {
                bestOffsetScore = score;
                bestOffsetFrame = offset;
            }
        }

        estimate.Bpm = bestBpm;
        estimate.Confidence = confidence;
        estimate.BeatIntervalSeconds = 60.0 / bestBpm;
        estimate.OffsetSeconds = bestOffsetFrame * hopSeconds;
        return estimate;
    }

    private static List<double> BuildBeats(double durationSeconds, double beatIntervalSeconds, double offsetSeconds)
    {
        List<double> beats = new List<double>();
        if (beatIntervalSeconds <= 0.0)
            return beats;
        for (double t = Math.Max(0.0, offsetSeconds); t < durationSeconds; t += beatIntervalSeconds)
            beats.Add(t);
        return beats;
    }

    private static List<double> EveryNth(List<double> source, int step)
    {
        List<double> result = new List<double>();
        for (int i = 0; i < source.Count; i += step)
            result.Add(source[i]);
        return result;
    }

    private static List<IntensityWindow> BuildIntensityWindows(
        double durationSeconds,
        List<double> energyTimes,
        List<double> rms,
        List<double> envelope)
    {
        int windowCount = Clamp((int)Math.Round(durationSeconds / 14.0), 6, 12);
        double windowSize = durationSeconds / windowCount;
        List<IntensityWindow> windows = new List<IntensityWindow>();
        double[] avgRms = new double[windowCount];
        double[] avgDensity = new double[windowCount];

        for (int w = 0; w < windowCount; w++)
        {
            double start = w * windowSize;
            double end = (w + 1) * windowSize;
            double rmsSum = 0.0;
            double onsetHits = 0.0;
            int count = 0;
            for (int i = 0; i < energyTimes.Count; i++)
            {
                double t = energyTimes[i];
                if (t < start || t >= end)
                    continue;
                rmsSum += rms[i];
                if (envelope[i] >= 0.24)
                    onsetHits += 1.0;
                count++;
            }
            avgRms[w] = count > 0 ? rmsSum / count : 0.0;
            avgDensity[w] = count > 0 ? onsetHits / count : 0.0;
        }

        double maxRms = 0.0001;
        double maxDensity = 0.0001;
        for (int i = 0; i < avgRms.Length; i++)
        {
            if (avgRms[i] > maxRms)
                maxRms = avgRms[i];
            if (avgDensity[i] > maxDensity)
                maxDensity = avgDensity[i];
        }

        for (int w = 0; w < windowCount; w++)
        {
            IntensityWindow window = new IntensityWindow();
            window.start_time = Round3(w * windowSize);
            window.end_time = Round3((w + 1) * windowSize);
            window.intensity = Round3(avgRms[w] / maxRms);
            window.density = Round3(avgDensity[w] / maxDensity);
            windows.Add(window);
        }

        return windows;
    }

    private static List<double> FindStructuralChanges(List<IntensityWindow> windows)
    {
        List<StructuralChange> candidates = new List<StructuralChange>();
        for (int i = 1; i < windows.Count; i++)
        {
            double intensityDiff = Math.Abs(windows[i].intensity - windows[i - 1].intensity);
            double densityDiff = Math.Abs(windows[i].density - windows[i - 1].density);
            StructuralChange change = new StructuralChange();
            change.Time = windows[i].start_time;
            change.Score = intensityDiff * 0.7 + densityDiff * 0.3;
            candidates.Add(change);
        }

        candidates.Sort(delegate(StructuralChange a, StructuralChange b) { return b.Score.CompareTo(a.Score); });

        List<double> selected = new List<double>();
        for (int i = 0; i < candidates.Count; i++)
        {
            bool farEnough = true;
            for (int j = 0; j < selected.Count; j++)
            {
                if (Math.Abs(selected[j] - candidates[i].Time) < 8.0)
                {
                    farEnough = false;
                    break;
                }
            }
            if (farEnough)
                selected.Add(candidates[i].Time);
            if (selected.Count >= 6)
                break;
        }

        selected.Sort();
        return selected;
    }

    private static double EstimateFinalMovementFraction(double durationSeconds, List<double> changes)
    {
        double minTime = durationSeconds * 0.82;
        double maxTime = durationSeconds * 0.94;
        double chosen = durationSeconds * 0.88;
        for (int i = 0; i < changes.Count; i++)
        {
            double change = changes[i];
            if (change >= minTime && change <= maxTime)
                chosen = change;
        }
        return ClampDouble(chosen / durationSeconds, 0.70, 0.94);
    }

    private static List<double> BuildDraftSections(
        double durationSeconds,
        List<double> changes,
        double finalMovementFraction,
        List<IntensityWindow> windows)
    {
        List<double> starts = new List<double>();
        starts.Add(0.0);
        double[] targets = new double[] { 0.18, 0.40, 0.62, 0.78 };

        for (int i = 0; i < targets.Length; i++)
        {
            double targetTime = durationSeconds * targets[i];
            double best = targetTime;
            if (changes.Count > 0)
            {
                double bestDistance = Double.MaxValue;
                for (int j = 0; j < changes.Count; j++)
                {
                    double distance = Math.Abs(changes[j] - targetTime);
                    if (distance < bestDistance)
                    {
                        bestDistance = distance;
                        best = changes[j];
                    }
                }
                if (Math.Abs(best - targetTime) > durationSeconds * 0.10)
                    best = targetTime;
            }
            if (IsFarEnough(starts, best, 6.0))
                starts.Add(best);
        }

        double latestAllowed = durationSeconds * finalMovementFraction;
        List<double> filtered = new List<double>();
        for (int i = 0; i < starts.Count; i++)
        {
            if (starts[i] < latestAllowed)
                filtered.Add(starts[i]);
        }
        filtered.Sort();

        if (filtered.Count < 5)
        {
            for (int i = 0; i < windows.Count; i++)
            {
                double start = windows[i].start_time;
                if (start <= 0.0 || start >= latestAllowed)
                    continue;
                if (IsFarEnough(filtered, start, 6.0))
                    filtered.Add(start);
                if (filtered.Count >= 5)
                    break;
            }
        }

        filtered.Sort();
        if (filtered.Count > 5)
            filtered = filtered.GetRange(0, 5);
        return filtered;
    }

    private static bool IsFarEnough(List<double> values, double candidate, double minDistance)
    {
        for (int i = 0; i < values.Count; i++)
        {
            if (Math.Abs(values[i] - candidate) < minDistance)
                return false;
        }
        return true;
    }

    private static double SampleWindowIntensity(double time, List<IntensityWindow> windows)
    {
        IntensityWindow match = null;
        for (int i = 0; i < windows.Count; i++)
        {
            if (time >= windows[i].start_time)
                match = windows[i];
            else
                break;
        }
        return match != null ? match.intensity : 0.0;
    }

    private static double SampleWindowDensity(double time, List<IntensityWindow> windows)
    {
        IntensityWindow match = null;
        for (int i = 0; i < windows.Count; i++)
        {
            if (time >= windows[i].start_time)
                match = windows[i];
            else
                break;
        }
        return match != null ? match.density : 0.0;
    }

    private static List<double> RoundList(List<double> values, int digits)
    {
        List<double> rounded = new List<double>();
        for (int i = 0; i < values.Count; i++)
            rounded.Add(Math.Round(values[i], digits));
        return rounded;
    }

    private static int Clamp(int value, int min, int max)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    private static double ClampDouble(double value, double min, double max)
    {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    private static double Round2(double value) { return Math.Round(value, 2); }
    private static double Round3(double value) { return Math.Round(value, 3); }
    private static double Round4(double value) { return Math.Round(value, 4); }

    private static WavData ReadWav(string path)
    {
        FileStream stream = null;
        BinaryReader reader = null;
        try
        {
            stream = File.OpenRead(path);
            reader = new BinaryReader(stream);

            string riff = new string(reader.ReadChars(4));
            if (riff != "RIFF")
                throw new InvalidDataException("Not a RIFF file: " + path);
            reader.ReadUInt32();
            string wave = new string(reader.ReadChars(4));
            if (wave != "WAVE")
                throw new InvalidDataException("Not a WAVE file: " + path);

            short audioFormat = 0;
            short channels = 0;
            int sampleRate = 0;
            short bitsPerSample = 0;
            short blockAlign = 0;
            byte[] data = new byte[0];

            while (reader.BaseStream.Position + 8 <= reader.BaseStream.Length)
            {
                string chunkId = new string(reader.ReadChars(4));
                int chunkSize = reader.ReadInt32();
                long nextPos = reader.BaseStream.Position + chunkSize;

                if (chunkId == "fmt ")
                {
                    audioFormat = reader.ReadInt16();
                    channels = reader.ReadInt16();
                    sampleRate = reader.ReadInt32();
                    reader.ReadInt32();
                    blockAlign = reader.ReadInt16();
                    bitsPerSample = reader.ReadInt16();
                }
                else if (chunkId == "data")
                {
                    data = reader.ReadBytes(chunkSize);
                }

                reader.BaseStream.Position = nextPos;
                if ((chunkSize & 1) == 1 && reader.BaseStream.Position < reader.BaseStream.Length)
                    reader.BaseStream.Position += 1;
            }

            if (sampleRate <= 0 || channels <= 0 || bitsPerSample <= 0 || blockAlign <= 0 || data.Length == 0)
                throw new InvalidDataException("Incomplete WAV data: " + path);

            int bytesPerSample = bitsPerSample / 8;
            int frameCount = data.Length / blockAlign;
            double[] samples = new double[frameCount];

            for (int frame = 0; frame < frameCount; frame++)
            {
                int frameOffset = frame * blockAlign;
                double mono = 0.0;
                for (int channel = 0; channel < channels; channel++)
                {
                    int offset = frameOffset + channel * bytesPerSample;
                    mono += ReadSample(data, offset, bitsPerSample, audioFormat);
                }
                samples[frame] = mono / channels;
            }

            WavData wav = new WavData();
            wav.SampleRate = sampleRate;
            wav.Channels = channels;
            wav.BitsPerSample = bitsPerSample;
            wav.Samples = samples;
            wav.DurationSeconds = samples.Length / (double)sampleRate;
            return wav;
        }
        finally
        {
            if (reader != null) reader.Close();
            else if (stream != null) stream.Close();
        }
    }

    private static double ReadSample(byte[] data, int offset, int bitsPerSample, short audioFormat)
    {
        if (audioFormat == 3 && bitsPerSample == 32)
            return BitConverter.ToSingle(data, offset);

        if (audioFormat != 1)
            throw new InvalidDataException("Unsupported WAV format: " + audioFormat);

        if (bitsPerSample == 8)
            return (data[offset] - 128) / 128.0;
        if (bitsPerSample == 16)
            return BitConverter.ToInt16(data, offset) / 32768.0;
        if (bitsPerSample == 24)
            return Read24Bit(data, offset) / 8388608.0;
        if (bitsPerSample == 32)
            return BitConverter.ToInt32(data, offset) / 2147483648.0;

        throw new InvalidDataException("Unsupported PCM bit depth: " + bitsPerSample);
    }

    private static int Read24Bit(byte[] data, int offset)
    {
        int value = data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16);
        if ((value & 0x800000) != 0)
            value |= unchecked((int)0xFF000000);
        return value;
    }
}

public class TempoEstimate
{
    public double Bpm;
    public double Confidence;
    public double BeatIntervalSeconds;
    public double OffsetSeconds;
}

public class StructuralChange
{
    public double Time;
    public double Score;
}

public class WavData
{
    public int SampleRate;
    public int Channels;
    public int BitsPerSample;
    public double[] Samples;
    public double DurationSeconds;
}

public class SongDraft
{
    public string song_id;
    public string file_path;
    public double duration_seconds;
    public int sample_rate;
    public int channels;
    public int bits_per_sample;
    public double estimated_bpm;
    public double bpm_confidence;
    public double beat_interval_seconds;
    public List<double> beat_timestamps;
    public List<double> strong_beat_timestamps;
    public List<double> phrase_boundary_candidates;
    public List<IntensityWindow> intensity_windows;
    public List<SectionCandidate> section_candidates;
    public double final_movement_fraction_candidate;
    public List<string> confidence_notes;
    public DraftSongMap draft_song_map;
}

public class IntensityWindow
{
    public double start_time;
    public double end_time;
    public double intensity;
    public double density;
}

public class SectionCandidate
{
    public double time_seconds;
    public double start_fraction;
    public string label;
    public double intensity;
    public double density;
    public string reason;
    public string confidence;
}

public class DraftSongMap
{
    public string song_path;
    public double bpm;
    public double final_movement_fraction_candidate;
    public List<DraftSection> sections;
}

public class DraftSection
{
    public string id;
    public string label;
    public double start_fraction;
    public double intensity;
    public double spawn_interval_mult;
}
"@

Add-Type -TypeDefinition $source -Language CSharp

$audioRoot = Join-Path $ProjectRoot $AudioDir
$outputRoot = Join-Path $ProjectRoot $OutputDir
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$wavFiles = Get-ChildItem -Path $audioRoot -Filter *.wav -File | Sort-Object Name
if (-not $wavFiles) {
	throw "No WAV files found under $audioRoot"
}

foreach ($wav in $wavFiles) {
	$relativePath = $wav.FullName.Substring($ProjectRoot.Length).TrimStart('\')
	$songId = [SongDraftAnalyzer]::NormalizeSongId($wav.BaseName)
	$analysis = [SongDraftAnalyzer]::Analyze($wav.FullName, $relativePath)
	$json = $analysis | ConvertTo-Json -Depth 8
	$outputPath = Join-Path $outputRoot ($songId + "_draft.json")
	Set-Content -Path $outputPath -Value $json -Encoding UTF8
	Write-Host "Generated draft map: $outputPath"
}
