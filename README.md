# 探索諸羅 Explore Chiayi 🦃

探索諸羅（Explore Chiayi）是一款以 **Flutter** 開發的嘉義旅遊行動應用程式，目標是整合分散的景點、美食、交通與旅遊資訊，讓使用者可以在單一 App 中完成旅遊資訊查詢與行程規劃。

本專案整合 **Firebase、中央氣象署、TDX 運輸資料、OpenStreetMap 與 Google Gemini AI**，提供即時天氣、景點與美食探索、公共運輸資訊、自訂行程以及 AI 智慧旅遊規劃等功能。

## 🎯 專案動機

嘉義擁有豐富的歷史文化、特色景點與在地美食，但旅遊資訊往往分散於社群媒體、地圖、部落格與不同交通 App 中。

本專案希望透過一站式旅遊 App，整合：

- 景點與美食資訊
- 即時天氣資訊
- 公車與 YouBike 動態
- 個人收藏
- 自訂旅遊行程
- AI 智慧行程規劃

降低旅客規劃自由行時需要跨平台搜尋資訊的負擔。

## ✨ 主要功能

### 🏠 首頁

- 嘉義即時天氣資訊
- 景點與美食快速分類
- 嘉義市最新觀光消息
- 熱門景點與美食推薦

### 🔍 景點與美食探索

- 景點 / 美食分類
- 關鍵字搜尋
- 標籤篩選
- 詳細資訊頁面
- 收藏功能
- 加入旅遊行程

### 🚌 即時交通資訊

串接 **TDX 運輸資料流通服務**，並將交通資訊顯示於 OpenStreetMap 地圖。

提供：

- YouBike 站點位置
- 可借車輛數
- 可還車位數
- 公車站點資訊
- 公車即時到站狀態

### 🗺 自訂行程規劃

使用者可以：

- 建立旅遊行程
- 加入景點與美食
- 調整景點順序
- 刪除或新增行程項目
- 查看行程在地圖上的位置

### 🤖 Gemini AI 行程助手

整合 **Google Gemini AI**，使用者可透過自然語言輸入：

- 旅遊天數
- 興趣與偏好
- 預算
- 想去的景點或美食

AI 會依據條件產生個人化的嘉義旅遊行程建議。

### 👤 使用者系統

使用 Firebase Authentication 提供：

- 帳號註冊
- 使用者登入
- 訪客模式
- 個人收藏
- 個人行程管理

## 🛠 使用技術

### Frontend

- Flutter
- Dart
- Material Design

### Backend / Database

- Firebase Authentication
- Cloud Firestore
- Google Drive

### External APIs

- TDX 運輸資料流通服務
- 中央氣象署 Open Data API
- Google Gemini API
- OpenStreetMap

### Flutter

- Stream / StreamBuilder
- FutureBuilder
- HTTP RESTful API
- flutter_map

## 🏗 系統架構

```text
                Explore Chiayi
                      │
        ┌─────────────┼─────────────┐
        │             │             │
    Firebase       External API   Gemini AI
        │             │             │
 ┌──────┴─────┐   ┌───┴────────┐    │
 │            │   │            │    │
Auth      Firestore TDX       CWA   AI 行程
                    │            │
                 交通資訊      天氣資訊
```

App 主要整合多種資料來源：

- **Firestore**：景點、美食、收藏與行程等資料
- **Firebase Authentication**：使用者帳號驗證
- **TDX API**：公車與 YouBike 即時資訊
- **中央氣象署 API**：嘉義天氣資訊
- **Gemini API**：AI 行程規劃
- **OpenStreetMap**：地圖與位置呈現

## 💡 技術實作重點

### 多來源非同步資料整合

地圖頁面需要同時處理：

```text
Firestore 景點資料
        +
使用者自訂行程
        +
TDX 即時交通資料
```

為降低多個非同步資料來源同時載入造成的畫面卡頓：

- Firestore 即時資料使用 `StreamBuilder` 管理
- 交通等一次性網路資料於 `initState` 階段非同步取得

### Gemini AI 行程生成

專案導入 Generative AI SDK，並使用 Gemini 模型產生旅遊行程。

AI 助手可根據使用者輸入的：

```text
天數 + 偏好 + 預算
```

動態產生較完整的旅遊規劃內容。

### Firestore 即時資料

利用 Dart Stream 監聽 Firestore。

當景點、美食或使用者資料變更時，App 可即時取得最新資料並重新更新 UI。

## 📁 專案結構

```text
explore-chiayi/
├── android/
├── assets/
│   └── images/
├── lib/
│   ├── app/
│   ├── constants/
│   ├── data/
│   ├── models/
│   ├── pages/
│   ├── services/
│   ├── widgets/
│   └── main.dart
├── macos/
├── test/
├── .env.example
├── .gitignore
├── firebase.json
├── pubspec.yaml
└── README.md
```

其中：

```text
lib/pages/
```

負責 App 各功能頁面，例如首頁、探索、地圖、AI 助手與個人中心。

```text
lib/services/
```

負責外部服務與資料介接，例如：

- AI Service
- Authentication Service
- Firestore Database
- News Service
- Traffic Service
- Weather Service

## 🔐 API Key 與安全性

本 Repository **不包含實際 API Key 與私人 Firebase 設定檔**。

以下檔案已透過 `.gitignore` 排除：

```text
.env
android/app/google-services.json
lib/firebase_options.dart
macos/Runner/GoogleService-Info.plist
```

Repository 提供：

```text
.env.example
```

作為環境變數格式範例。

## ⚙️ 環境設定

Clone Repository：

```bash
git clone https://github.com/tienhsin-bob/explore-chiayi.git
cd explore-chiayi
```

安裝 Flutter 套件：

```bash
flutter pub get
```

建立：

```text
.env
```

並依照 `.env.example` 填入自己的 API Key：

```env
GEMINI_API_KEY=your_gemini_api_key
CWA_API_KEY=your_cwa_api_key
TDX_CLIENT_ID=your_tdx_client_id
TDX_CLIENT_SECRET=your_tdx_client_secret
```

由於 Firebase 專案設定未公開，若要完整執行專案，需自行建立 Firebase Project，並加入自己的：

```text
android/app/google-services.json
lib/firebase_options.dart
```

之後執行：

```bash
flutter run
```

## 👥 專案性質

本專案為兩人合作完成的「行動裝置應用程式設計」期末專題。

### 我的主要負責內容

- 最新觀光消息功能
- TDX 即時交通頁面
- Gemini AI 行程助手
- App UI 設計
- 功能整合與除錯

其他功能則由組員共同協作完成。

## 📚 專案學習收穫

透過本專案實際練習：

- Flutter 行動 App 開發
- Firebase Authentication
- Firestore 即時資料處理
- RESTful API 串接
- TDX 即時交通資料解析
- OpenStreetMap 地圖整合
- Gemini AI API 應用
- 非同步資料處理
- StreamBuilder 與 FutureBuilder
- API Key 與環境變數管理
- 多來源資料整合與 UI 設計
