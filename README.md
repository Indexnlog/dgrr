# DGRR (지구공) 📱

Flutter로 개발한 축구 동호회 관리 앱

## 🎯 주요 기능

### 구현 완료
- [x] 로그인/회원가입 (Firebase Auth)
- [x] 팀 선택 및 가입
- [x] 매치 일정 관리 (참석/불참)
- [x] 회원 관리
- [x] 라운드별 기록 관리
- [x] 투표 기능 (polls)

### 개발 중
- [ ] 출석 체크 시스템
- [ ] 공지사항 게시판
- [ ] 구장 예약 관리
- [ ] 채팅 기능

## 🏗️ 기술 스택

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Auth)
- **State Management**: Provider
- **Architecture**: teams/{teamId} 기반 멀티테넌트

## 📁 프로젝트 구조

```
lib/
├── models/          # 데이터 모델
├── services/        # Firebase 서비스
├── screens/         # 화면 위젯
├── widgets/         # 재사용 위젯
└── providers/       # 상태 관리
```

## 🚀 실행 방법

```bash
# 의존성 설치
flutter pub get

# Firebase 설정 (firebaserc, firebase.json 필요)
firebase login

# iOS 실행
flutter run -d ios

# Android 실행  
flutter run -d android
```

## 📋 Firestore 구조

```
teams/{teamId}/
├── members/         # 팀 멤버
├── matches/         # 매치 일정
├── polls/           # 투표
├── notices/         # 공지사항
└── reservations/    # 구장 예약
```

## 🎮 개발 현황

- **개발 기간**: 2025.07 ~ 현재

## 📝 개발 일지

상세한 개발 과정은 에서 확인할 수 있습니다.

## 👥 

- [@Indexnlog](https://github.com/Indexnlog) - Main Developer

---
*Made with ❤️ for 지구공 축구 동호회*
