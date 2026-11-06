# 基本設計書：老人・物忘れ激しい人向けToDoアプリ

- チーム番号：チーム02
- メンバー：渡会亮太、新堀裕一郎

## 課題
- **選んだ課題**：老人や物忘れが激しい人がその日のやることを忘れる
- **誰の課題か**：老人、物忘れが激しい人
- **なぜこの課題を選んだか**：買い物をするときに紙に書いている人がいるが履歴を残せたら後から振り返れて効率的だと思ったから

## 0. 考えを整理する3つの問い
- **開発目的**：その時やった事を情報として残す
- **想定ユーザ**：老人、物忘れが激しい人
- **機能**：履歴に時間を表示する、優先度、検索機能、通知

## 1. ユーザーストーリー
- ストーリー1：課題の時間を忘れたときに確認したい
- ストーリー2：買い物する時に履歴を残したい

## 2. 画面イメージ（ワイヤーフレーム）
手書き・PowerPoint・Figma・Excalidrawなどで作った画面ラフを、画像として貼る。

![ホームの画面イメージ](design/Top.png)
![履歴詳細画面イメージ](design/History.png)
![予定を追加の画面イメージ](design/NewForm.png)
![設定の画面イメージ](design/Config.png)
![履歴の画面イメージ](design/HistoryHome.png)
![タスク詳細の画面イメージ](design/tsk.png)

> ここは実際に手を動かして描いた画像に差し替えてください。きれいである必要はなく、「どこに何があるか」「押したらどこへ行くか」が伝わればOKです。

## 3. ページ遷移図
```mermaid
flowchart LR
    Top[ホーム画面]

    Top --> Settings[設定画面]
    Settings -->|戻る| Top

    Top --> Search[検索画面]
    Search --> SearchResult[検索結果]
    SearchResult --> TaskDetail[タスク詳細画面]

    Top -->|タスクを押す| TaskDetail
    TaskDetail -->|戻る| Top
    TaskDetail -->|できた| Complete[タスク完了]
    Complete --> Top

    Top --> NewForm[予定追加画面]
    NewForm -->|追加| Saved[予定追加完了]
    Saved --> Top
    NewForm -->|戻る| Top

    Top --> History[履歴画面]
    History -->|タスクを押す| HistoryDetail[履歴詳細画面]
    HistoryDetail -->|戻る| History
    History -->|戻る| Top
```

## 4. データモデル（ER図）
```mermaid
erDiagram
  TASK {
    int task_id PK
    string title
    datetime scheduled_at
    string memo
    string location
    boolean is_priority
    string notification_type
    string status
    datetime completed_at
  }

  TASK_PHOTO {
    int photo_id PK
    int task_id FK
    string image_path
  }

  SETTINGS {
    int settings_id PK
    string font_size
  }

  TASK ||--o{ TASK_PHOTO : "写真を添付"
```
## 5. 開発着手の許可基準に対する自己チェック
- [✔] 課題の具体性：身近な実在のペインに基づいているか？
- [✔] 連動性：ユーザーストーリーと画面・データモデルが破綻なく繋がっているか？
- [✔] ボリュームの妥当性：第14回までに2名で作りきれる規模感か？
