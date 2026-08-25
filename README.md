# UIKit 기반 iOS

`Coordinator`, `MVVM`, `Clean Architecture`, `DIContainer`를 적용하여 화면 이동, 비즈니스 로직, 데이터 접근 및 의존성 조립의 책임을 분리했습니다.

이미지 처리에는 OpenCV와 Vision을 사용하며, 로컬 데이터 관리는 CoreData를 사용합니다.

## 주요 구현

- 로컬 데이터 생성, 조회, 수정, 삭제
- 이미지 추가 및 저장
- 이미지 영역 검출 및 원근 보정
- 이미지 처리 결과 미리보기
- 사용자 정의 메타데이터 관리
- OpenCV 기반 이미지 처리
- Vision 기반 이미지 처리 fallback
- 한국어, 영어, 일본어 localization
- Firebase Analytics 연동
- Firebase Crashlytics 연동 준비
- Firebase Remote Config 연동 준비

## 기술 스택

- Swift
- UIKit
- MVVM
- Coordinator
- Clean Architecture
- DIContainer
- CoreData
- SnapKit
- OpenCV
- Vision
- Firebase

## Architecture

> MVVM-C & Clean Architecture

PCC는 화면 이동, 객체 생성, 비즈니스 로직 및 데이터 접근의 책임을 분리하는 방향으로 구성했습니다.

### Coordinator

`AppCoordinator`는 애플리케이션의 화면 흐름을 관리합니다.

ViewController가 다른 ViewController를 직접 생성하거나 화면 전환을 수행하지 않고, 화면 이동이 필요한 경우 callback을 통해 Coordinator에 요청하도록 구성했습니다.

### DIContainer

`AppDIContainer`는 애플리케이션에서 사용하는 주요 객체의 생성과 의존성 조립을 담당합니다.

```text
ViewController
└── ViewModel
    └── UseCase
        └── Repository
            └── DataSource
```

이를 통해 ViewController 또는 ViewModel이 구체적인 Repository와 DataSource 구현체를 직접 생성하지 않도록 구성했습니다.

### Domain

애플리케이션의 핵심 비즈니스 로직을 담당합니다.

```text
Domain
├── Entity
├── Repository
└── UseCase
```

Repository는 Protocol로 정의하여 Domain 계층이 구체적인 데이터 저장 방식에 의존하지 않도록 구성했습니다.

### Data

데이터 저장 및 이미지 처리 구현을 담당합니다.

```text
Data
├── DataSource
└── Repository
```

CoreData 기반 로컬 데이터 저장과 이미지 저장 및 처리에 필요한 구현체가 위치합니다.

### Presentation

화면 표시와 사용자 입력 처리를 담당합니다.

```text
Presentation
├── View
├── ViewController
├── ViewModel
└── Support
```

ViewController는 사용자 입력을 ViewModel에 전달하고 ViewModel의 상태를 화면에 반영합니다.

## 프로젝트 구조

```text
PCC
├── App
│   ├── AppCoordinator.swift
│   ├── AppDIContainer.swift
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Domain
│   ├── Entity
│   ├── Repository
│   └── UseCase
├── Data
│   ├── DataSource
│   └── Repository
└── Presentation
    ├── View
    ├── ViewController
    ├── ViewModel
    └── Support
```

## 화면 구성

- `HomeViewController`: 메인 화면
- `BinderDetailViewController`: 데이터 상세 화면
- `BinderSettingViewController`: 데이터 생성 및 수정 화면
- `AddPhotocardViewController`: 이미지 추가 화면
- `PhotocardPreviewViewController`: 이미지 처리 결과 미리보기
- `PhotocardMetadataViewController`: 메타데이터 수정 화면
- `AppSettingViewController`: 애플리케이션 설정
- `StringListManagementViewController`: 사용자 정의 목록 관리

`UITableView`, `UICollectionView`, `UITextField` 관련 `delegate`와 `dataSource` 구현은 각 ViewController 파일 하단의 extension으로 분리하여 역할을 구분했습니다.
