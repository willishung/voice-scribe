# Voice Scribe / 聲記

Flutter Android 本機錄音專案（開發中）。

## 目前功能
- WAV 本機錄音
- 錄音檔列表
- 分享錄音檔

## 尚未完成
- 完全離線即時中文 ASR
- 自動語者分群（speaker diarization）
- 完整逐字稿匯出

**請勿將此版本視為完成版。**

## GitHub Actions
進入 Actions → Build Android Debug APK → Run workflow，成功後在 Artifacts 下載 APK。

## 本機
```sh
flutter pub get
flutter create --platforms=android --project-name voice_scribe .
flutter build apk --debug
```

## 2026-10-20 增量功能
- 每筆錄音新增手動逐字稿編輯（存成與音檔對應的 .wav.txt）
- 可分享匯出 TXT
- 自動離線 ASR 與自動語者辨識仍未整合；不可將人工逐字稿誤認為 AI 輸出
