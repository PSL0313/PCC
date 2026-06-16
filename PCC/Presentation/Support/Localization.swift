import Foundation

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case korean = "ko"
    case japanese = "ja"

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .korean:
            return "한국어"
        case .japanese:
            return "日本語"
        }
    }

    static var current: AppLanguage {
        get {
            // 저장된 언어가 없으면 기기 언어에서 한국어/일본어만 우선 적용한다.
            if let savedCode = UserDefaults.standard.string(forKey: L10n.languageKey),
               let language = AppLanguage(rawValue: savedCode) {
                return language
            }

            let languageCode = Locale.current.language.languageCode?.identifier
            return AppLanguage(rawValue: languageCode ?? "") ?? .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: L10n.languageKey)
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }
}

enum L10n {
    static let languageKey = "app.language"
    static let uncategorizedStorageValue = "미분류"

    enum Key: String {
        case add
        case addBinder
        case addCategory
        case addMember
        case addPhoto
        case addPhotoGuideBody
        case addPhotoGuideTitle
        case addPhotoSubtitle
        case alert
        case album
        case allCancel
        case backupRestorePlaceholder
        case binder
        case binderDeleteFailed
        case binderDeleteMessage
        case binderDeleteTitle
        case binderListLoadFailed
        case binderInfoLoadFailed
        case binderName
        case binderNameRequired
        case binderSaveFailed
        case binderSetting
        case binderSettingLoadFailed
        case camera
        case cameraUnavailable
        case cancel
        case cardCount
        case cardInfo
        case cardTitle
        case category
        case categoryAdd
        case categoryName
        case categorySort
        case columnCount
        case confirm
        case coreMLPlaceholder
        case currentCardCancel
        case dataBackupPlaceholder
        case delete
        case deleteSelection
        case display
        case done
        case editProfileImage
        case emptyBinder
        case emptyPhotocard
        case extractCard
        case extracting
        case imageAnalyzing
        case inAppPurchasePlaceholder
        case language
        case member
        case memberAdd
        case memberName
        case memberNameOption
        case memberNamePlaceholder
        case noTitle
        case noneMember
        case photoAnalyzePreparing
        case photocardDeleteFailed
        case photocardDeleteAction
        case photocardDeleteMessage
        case photocardDeleteTitle
        case photocardInfoLoadFailed
        case photocardNotFound
        case photocardSaveFailed
        case processingComplete
        case processingOpenCVComplete
        case processingOpenCVContour
        case processingVisionFallback
        case resultCount
        case resultReview
        case save
        case saveProfileImageFailed
        case saveProfileImageUnavailable
        case saveToBinderFailed
        case searchBinder
        case searchPhotocard
        case selectedBinderDeleteFailed
        case selectedBinderDeleteMessage
        case selectedBinderDeleteTitle
        case selectedPhotocardDeleteFailed
        case selectedPhotocardDeleteMessage
        case selectedPhotocardDeleteTitle
        case setting
        case sortByCreatedAt
        case sortByTitleAscending
        case sortByTitleDescending
        case sortOption
        case title
        case titleRequired
        case uncategorized
        case uncategorizedOption
        case originalCount
        case newBinder
        case noSaveableCard
    }

    static func text(_ key: Key) -> String {
        translations[AppLanguage.current]?[key] ?? translations[.english]?[key] ?? key.rawValue
    }

    static func format(_ key: Key, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale(identifier: AppLanguage.current.rawValue), arguments: arguments)
    }

    static func displayCategory(_ category: String) -> String {
        let defaultValues = [uncategorizedStorageValue, "Uncategorized", "未分類"]
        return defaultValues.contains(category) || category.isEmpty
            ? text(.uncategorized)
            : category
    }

    static func displayMember(_ memberName: String) -> String {
        memberName.isEmpty ? text(.noneMember) : memberName
    }

    private static let translations: [AppLanguage: [Key: String]] = [
        .english: [
            .add: "Add",
            .addBinder: "Add binder",
            .addCategory: "Add category",
            .addMember: "Add member",
            .addPhoto: "Add photos",
            .addPhotoGuideBody: "Extraction works best when all four corners are visible against a slightly contrasting background. Reduce glare and shadows, and shoot one flat card at a time.",
            .addPhotoGuideTitle: "Keep the whole card in view",
            .addPhotoSubtitle: "Take a photo or choose from album",
            .alert: "Notice",
            .album: "Album",
            .allCancel: "Cancel all",
            .backupRestorePlaceholder: "Backup/restore placeholder",
            .binder: "Binder",
            .binderDeleteFailed: "Could not delete the binder.",
            .binderDeleteMessage: "Deleted binders and photocards cannot be restored.",
            .binderDeleteTitle: "Delete this binder?",
            .binderListLoadFailed: "Could not load binders.",
            .binderInfoLoadFailed: "Could not load binder info.",
            .binderName: "Binder name",
            .binderNameRequired: "Enter a binder name.",
            .binderSaveFailed: "Could not save the binder.",
            .binderSetting: "Binder settings",
            .binderSettingLoadFailed: "Could not load binder settings.",
            .camera: "Camera",
            .cameraUnavailable: "Camera is not available on this device.",
            .cancel: "Cancel",
            .cardCount: "%d cards",
            .cardInfo: "Card info",
            .cardTitle: "Card title",
            .category: "Category",
            .categoryAdd: "Add category",
            .categoryName: "Category name",
            .categorySort: "Category",
            .columnCount: "Columns",
            .confirm: "OK",
            .coreMLPlaceholder: "CoreML model placeholder",
            .currentCardCancel: "Cancel current card",
            .dataBackupPlaceholder: "Backup/restore placeholder",
            .delete: "Delete",
            .deleteSelection: "Select delete",
            .display: "Display",
            .done: "Done",
            .editProfileImage: "Change profile image",
            .emptyBinder: "No binders yet.",
            .emptyPhotocard: "No saved photocards yet.",
            .extractCard: "Extract cards",
            .extracting: "Extracting",
            .imageAnalyzing: "%d/%d analyzing image",
            .inAppPurchasePlaceholder: "In-App Purchase placeholder",
            .language: "Language",
            .member: "Member",
            .memberAdd: "Add member",
            .memberName: "Member name",
            .memberNameOption: "Member name",
            .memberNamePlaceholder: "Member name",
            .noTitle: "Untitled",
            .noneMember: "Unassigned",
            .photoAnalyzePreparing: "Preparing photocard analysis",
            .photocardDeleteFailed: "Could not delete the photocard.",
            .photocardDeleteAction: "Delete photocard",
            .photocardDeleteMessage: "Deleted photocards cannot be restored.",
            .photocardDeleteTitle: "Delete this photocard?",
            .photocardInfoLoadFailed: "Could not load photocard info.",
            .photocardNotFound: "Photocard not found.",
            .photocardSaveFailed: "Could not save the photocard.",
            .processingComplete: "%d/%d processed",
            .processingOpenCVComplete: "%d/%d OpenCV processing complete",
            .processingOpenCVContour: "%d/%d analyzing outline",
            .processingVisionFallback: "Vision fallback: %@",
            .resultCount: "%d extracted",
            .resultReview: "Review results",
            .save: "Save",
            .saveProfileImageFailed: "Could not save the profile image.",
            .saveProfileImageUnavailable: "Could not prepare the profile image.",
            .saveToBinderFailed: "Could not save photocards.",
            .searchBinder: "Search binders",
            .searchPhotocard: "Search category, title, or member",
            .selectedBinderDeleteFailed: "Could not delete selected binders.",
            .selectedBinderDeleteMessage: "Deleted binders and photocards cannot be restored.",
            .selectedBinderDeleteTitle: "Delete %d binders?",
            .selectedPhotocardDeleteFailed: "Could not delete selected photocards.",
            .selectedPhotocardDeleteMessage: "Deleted photocards cannot be restored.",
            .selectedPhotocardDeleteTitle: "Delete %d photocards?",
            .setting: "Settings",
            .sortByCreatedAt: "Created date",
            .sortByTitleAscending: "Card title A-Z",
            .sortByTitleDescending: "Card title Z-A",
            .sortOption: "Sort by",
            .title: "Title",
            .titleRequired: "Enter a title.",
            .uncategorized: "Uncategorized",
            .uncategorizedOption: "Uncategorized",
            .originalCount: "%d originals",
            .newBinder: "New binder",
            .noSaveableCard: "No cards to save."
        ],
        .korean: [
            .add: "추가",
            .addBinder: "바인더 추가",
            .addCategory: "카테고리 추가",
            .addMember: "멤버 추가",
            .addPhoto: "사진 추가",
            .addPhotoGuideBody: "네 모서리가 모두 보이고 배경과 살짝 대비되면 추출이 더 정확해요. 반사와 그림자는 줄이고, 카드는 한 장씩 평평하게 놓아주세요.",
            .addPhotoGuideTitle: "카드가 한눈에 보이게 찍어주세요",
            .addPhotoSubtitle: "촬영하거나 앨범에서 선택",
            .alert: "알림",
            .album: "앨범",
            .allCancel: "전체 취소",
            .backupRestorePlaceholder: "데이터 백업/복원 준비 영역",
            .binder: "바인더",
            .binderDeleteFailed: "바인더를 삭제하지 못했습니다.",
            .binderDeleteMessage: "삭제한 바인더와 포토카드는 되돌릴 수 없습니다.",
            .binderDeleteTitle: "바인더를 삭제할까요?",
            .binderListLoadFailed: "바인더 목록을 불러오지 못했습니다.",
            .binderInfoLoadFailed: "바인더 정보를 불러오지 못했습니다.",
            .binderName: "바인더 이름",
            .binderNameRequired: "바인더 이름을 입력해주세요.",
            .binderSaveFailed: "바인더를 저장하지 못했습니다.",
            .binderSetting: "바인더 설정",
            .binderSettingLoadFailed: "바인더 설정을 불러오지 못했습니다.",
            .camera: "촬영",
            .cameraUnavailable: "이 기기에서는 카메라를 사용할 수 없습니다.",
            .cancel: "취소",
            .cardCount: "%d cards",
            .cardInfo: "카드 정보",
            .cardTitle: "카드 제목",
            .category: "카테고리",
            .categoryAdd: "카테고리 추가",
            .categoryName: "카테고리 이름",
            .categorySort: "카테고리 기준",
            .columnCount: "열 개수",
            .confirm: "확인",
            .coreMLPlaceholder: "CoreML 모델 관리 준비 영역",
            .currentCardCancel: "현재 카드만 취소",
            .dataBackupPlaceholder: "데이터 백업/복원 준비 영역",
            .delete: "삭제",
            .deleteSelection: "선택 삭제",
            .display: "보기",
            .done: "완료",
            .editProfileImage: "프로필 이미지 변경",
            .emptyBinder: "아직 만든 바인더가 없습니다.",
            .emptyPhotocard: "아직 저장된 포토카드가 없습니다.",
            .extractCard: "카드 추출하기",
            .extracting: "추출 중",
            .imageAnalyzing: "%d/%d 이미지 분석 중",
            .inAppPurchasePlaceholder: "In-App Purchase 준비 영역",
            .language: "언어",
            .member: "멤버",
            .memberAdd: "멤버 추가",
            .memberName: "멤버 이름",
            .memberNameOption: "멤버 이름",
            .memberNamePlaceholder: "멤버 이름",
            .noTitle: "제목 없음",
            .noneMember: "미지정",
            .photoAnalyzePreparing: "포토카드 분석 준비 중",
            .photocardDeleteFailed: "포토카드를 삭제하지 못했습니다.",
            .photocardDeleteAction: "포토카드 삭제",
            .photocardDeleteMessage: "삭제한 포토카드는 되돌릴 수 없습니다.",
            .photocardDeleteTitle: "포토카드를 삭제할까요?",
            .photocardInfoLoadFailed: "포토카드 정보를 불러오지 못했습니다.",
            .photocardNotFound: "포토카드를 찾을 수 없습니다.",
            .photocardSaveFailed: "포토카드를 저장하지 못했습니다.",
            .processingComplete: "%d/%d 처리 완료",
            .processingOpenCVComplete: "%d/%d OpenCV 처리 완료",
            .processingOpenCVContour: "%d/%d 외곽선 분석 중",
            .processingVisionFallback: "Vision 폴백: %@",
            .resultCount: "추출 결과 %d장",
            .resultReview: "결과 확인",
            .save: "저장",
            .saveProfileImageFailed: "프로필 이미지를 저장하지 못했습니다.",
            .saveProfileImageUnavailable: "프로필 이미지를 저장할 수 없습니다.",
            .saveToBinderFailed: "포토카드를 저장하지 못했습니다.",
            .searchBinder: "바인더 이름 검색",
            .searchPhotocard: "카테고리, 제목, 멤버명 검색",
            .selectedBinderDeleteFailed: "선택한 바인더를 삭제하지 못했습니다.",
            .selectedBinderDeleteMessage: "삭제한 바인더와 포토카드는 되돌릴 수 없습니다.",
            .selectedBinderDeleteTitle: "%d개의 바인더를 삭제할까요?",
            .selectedPhotocardDeleteFailed: "선택한 포토카드를 삭제하지 못했습니다.",
            .selectedPhotocardDeleteMessage: "삭제한 포토카드는 되돌릴 수 없습니다.",
            .selectedPhotocardDeleteTitle: "%d개의 포토카드를 삭제할까요?",
            .setting: "설정",
            .sortByCreatedAt: "생성일 기준",
            .sortByTitleAscending: "카드 제목 오름차순",
            .sortByTitleDescending: "카드 제목 내림차순",
            .sortOption: "정렬 기준",
            .title: "제목",
            .titleRequired: "제목을 입력해주세요.",
            .uncategorized: "미분류",
            .uncategorizedOption: "미분류",
            .originalCount: "원본 %d장",
            .newBinder: "새 바인더",
            .noSaveableCard: "저장할 카드가 없습니다."
        ],
        .japanese: [
            .add: "追加",
            .addBinder: "バインダーを追加",
            .addCategory: "カテゴリーを追加",
            .addMember: "メンバーを追加",
            .addPhoto: "写真を追加",
            .addPhotoGuideBody: "四隅がすべて見え、背景と少し差があると抽出が安定します。反射や影を抑え、カードは1枚ずつ平らに置いてください。",
            .addPhotoGuideTitle: "カード全体が見えるように撮影してください",
            .addPhotoSubtitle: "撮影するかアルバムから選択",
            .alert: "お知らせ",
            .album: "アルバム",
            .allCancel: "すべてキャンセル",
            .backupRestorePlaceholder: "バックアップ/復元の準備エリア",
            .binder: "バインダー",
            .binderDeleteFailed: "バインダーを削除できませんでした。",
            .binderDeleteMessage: "削除したバインダーとフォトカードは復元できません。",
            .binderDeleteTitle: "このバインダーを削除しますか？",
            .binderListLoadFailed: "バインダー一覧を読み込めませんでした。",
            .binderInfoLoadFailed: "バインダー情報を読み込めませんでした。",
            .binderName: "バインダー名",
            .binderNameRequired: "バインダー名を入力してください。",
            .binderSaveFailed: "バインダーを保存できませんでした。",
            .binderSetting: "バインダー設定",
            .binderSettingLoadFailed: "バインダー設定を読み込めませんでした。",
            .camera: "撮影",
            .cameraUnavailable: "この端末ではカメラを使用できません。",
            .cancel: "キャンセル",
            .cardCount: "%d枚",
            .cardInfo: "カード情報",
            .cardTitle: "カードタイトル",
            .category: "カテゴリー",
            .categoryAdd: "カテゴリーを追加",
            .categoryName: "カテゴリー名",
            .categorySort: "カテゴリー順",
            .columnCount: "列数",
            .confirm: "確認",
            .coreMLPlaceholder: "CoreMLモデル管理の準備エリア",
            .currentCardCancel: "現在のカードだけキャンセル",
            .dataBackupPlaceholder: "バックアップ/復元の準備エリア",
            .delete: "削除",
            .deleteSelection: "選択削除",
            .display: "表示",
            .done: "完了",
            .editProfileImage: "プロフィール画像を変更",
            .emptyBinder: "まだバインダーがありません。",
            .emptyPhotocard: "保存されたフォトカードはまだありません。",
            .extractCard: "カードを抽出",
            .extracting: "抽出中",
            .imageAnalyzing: "%d/%d 画像を解析中",
            .inAppPurchasePlaceholder: "アプリ内課金の準備エリア",
            .language: "言語",
            .member: "メンバー",
            .memberAdd: "メンバーを追加",
            .memberName: "メンバー名",
            .memberNameOption: "メンバー名",
            .memberNamePlaceholder: "メンバー名",
            .noTitle: "無題",
            .noneMember: "未指定",
            .photoAnalyzePreparing: "フォトカード解析を準備中",
            .photocardDeleteFailed: "フォトカードを削除できませんでした。",
            .photocardDeleteAction: "フォトカードを削除",
            .photocardDeleteMessage: "削除したフォトカードは復元できません。",
            .photocardDeleteTitle: "このフォトカードを削除しますか？",
            .photocardInfoLoadFailed: "フォトカード情報を読み込めませんでした。",
            .photocardNotFound: "フォトカードが見つかりません。",
            .photocardSaveFailed: "フォトカードを保存できませんでした。",
            .processingComplete: "%d/%d 処理完了",
            .processingOpenCVComplete: "%d/%d OpenCV処理完了",
            .processingOpenCVContour: "%d/%d 輪郭を解析中",
            .processingVisionFallback: "Visionフォールバック: %@",
            .resultCount: "抽出結果 %d枚",
            .resultReview: "結果確認",
            .save: "保存",
            .saveProfileImageFailed: "プロフィール画像を保存できませんでした。",
            .saveProfileImageUnavailable: "プロフィール画像を保存できません。",
            .saveToBinderFailed: "フォトカードを保存できませんでした。",
            .searchBinder: "バインダー名を検索",
            .searchPhotocard: "カテゴリー、タイトル、メンバー名を検索",
            .selectedBinderDeleteFailed: "選択したバインダーを削除できませんでした。",
            .selectedBinderDeleteMessage: "削除したバインダーとフォトカードは復元できません。",
            .selectedBinderDeleteTitle: "%d個のバインダーを削除しますか？",
            .selectedPhotocardDeleteFailed: "選択したフォトカードを削除できませんでした。",
            .selectedPhotocardDeleteMessage: "削除したフォトカードは復元できません。",
            .selectedPhotocardDeleteTitle: "%d枚のフォトカードを削除しますか？",
            .setting: "設定",
            .sortByCreatedAt: "作成日順",
            .sortByTitleAscending: "カードタイトル 昇順",
            .sortByTitleDescending: "カードタイトル 降順",
            .sortOption: "並び替え",
            .title: "タイトル",
            .titleRequired: "タイトルを入力してください。",
            .uncategorized: "未分類",
            .uncategorizedOption: "未分類",
            .originalCount: "元画像 %d枚",
            .newBinder: "新しいバインダー",
            .noSaveableCard: "保存するカードがありません。"
        ]
    ]
}
