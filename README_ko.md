[English](README.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [日本語](README_ja.md) | [한국어](README_ko.md) | [Français](README_fr.md)

# MouseMapper

**마우스 사이드 버튼을 원하는 키보드 키에 매핑합니다.** macOS와 Windows 모두 지원.

## 왜 만들었나

로지텍 등 다버튼 마우스를 쓰다 보면 이런 문제에 부딪히게 됩니다:

**Logitech Options+의 문제점:**
- 사이드 버튼에는 "앞으로/뒤로" 같은 브라우저 동작만 할당 가능 — **임의의 키보드 키 매핑은 불가**
- 사이드 버튼을 fn / Command / Alt 단독 키로 쓰고 싶다면? 안 됩니다
- `Ctrl+C` 같은 조합 키를 매핑하고 싶다면? 지원하지 않습니다
- 소프트웨어 자체가 500MB 이상, 자동 시작에 메모리 점유, 로그인·동기화·업데이트 알림까지 성가심
- macOS에서 시스템 충돌이 잦고, 업데이트 후 매핑이 사라지기도 함

**다른 대안:** 유료(BetterTouchTool)이거나, 설정이 복잡(Karabiner)하거나, 단일 플랫폼만 지원.

**그래서 MouseMapper를 만들었습니다:**
- exe 하나 / 바이너리 하나, 더블클릭으로 실행, 의존성 제로
- 모든 키보드 키 매핑 가능 — 수식 키 단독 사용 포함 (fn, Command/Win, Alt/Option, Shift, Ctrl)
- 조합 키 지원 (`ctrl+c`, `shift+alt`, `command+space` 등)
- JSON 설정 파일, 한눈에 파악 가능, 수정 후 재시작하면 적용
- 프로그램 전체 500KB 미만 — 네트워크 연결 없음, 로그인 없음, 업데이트 없음, 귀찮음 없음

## 다운로드

**Windows:** [MouseMapper.exe 다운로드](https://github.com/vorojar/MouseMapper/releases) — 더블클릭으로 실행, 자동 시스템 트레이 상주, 자동 시작 프로그램 등록.

**macOS:** 소스 빌드 (아래 참조).

## 빠른 시작

### Windows

1. `MouseMapper.exe` 다운로드
2. 더블클릭으로 실행 → exe 위치에 `config.json` 자동 생성 → 시작 프로그램 자동 설정
3. `config.json`을 편집해 매핑 변경, 프로그램 재시작으로 적용
4. 우하단 트레이 아이콘 우클릭 → 시작 프로그램 관리 / 종료

### macOS

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

최초 실행 시 권한 부여 필요: `시스템 설정 → 개인 정보 보호 및 보안 → 손쉬운 사용`.

## 설정

두 플랫폼 모두 동일한 `config.json` 형식을 사용합니다:

```json
{
  "mappings": [
    {
      "button": 3,
      "key": "return",
      "action": "click"
    },
    {
      "button": 4,
      "key": "alt",
      "action": "hold"
    }
  ]
}
```

| 필드 | 설명 |
|------|------|
| `button` | 마우스 버튼 번호: `2`=가운데, `3`=사이드 뒤, `4`=사이드 앞 |
| `key` | 대상 키, `+`로 조합: `return`, `ctrl+c`, `shift+alt` |
| `action` | `"click"` (기본값) 한 번 눌러 실행 / `"hold"` 누르는 동안 유지 |

### 지원 키

**수식 키:** `shift`, `control`/`ctrl`, `alt`/`option`, `command`/`win`, `caps_lock` (모두 `left_`/`right_` 변형 지원)

**macOS 전용:** `fn`

**펑션 키:** `f1`-`f12`

**자주 쓰는 키:** `escape`/`esc`, `return`/`enter`, `tab`, `space`, `backspace`/`delete`, `forward_delete`, `insert`

**탐색 키:** `up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`

**문자/숫자/기호:** `a`-`z`, `0`-`9`, `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/`, `` ` ``

## 활용 예시

- 사이드 뒤 → `Enter` — 엄지로 확인, 코딩/채팅 효율 2배
- 사이드 앞 → `Alt` (홀드 모드) — 마우스 드래그와 조합 = 창 이동
- 가운데 → `Escape` — 즉시 취소
- 사이드 버튼 → `Ctrl+C` / `Ctrl+V` — 한 손으로 복사/붙여넣기
- 사이드 버튼 → `Command+Space` — 한 번에 Spotlight / 검색 호출

## 기술 구현

### Windows
- C + Win32 API, 약 960줄
- `SetWindowsHookEx(WH_MOUSE_LL)` 글로벌 훅 인터셉트
- `SendInput`을 비동기 워커 스레드에서 실행 (훅 타임아웃 방지)
- 시스템 트레이 아이콘 + 레지스트리 시작 프로그램 등록

### macOS
- Swift, 약 500줄
- `CGEventTap` 세션 레벨 이벤트 인터셉트
- 수식 키 이중 채널: IOKit (시스템 레벨) + CGEvent (앱 레벨)로 macOS 합성 이벤트 필터링 문제 해결
- launchd 시작 프로그램 등록

## 빌드

### Windows

GCC (MinGW-w64) 필요:

```bash
cd windows
build.bat
```

### macOS

Swift 5.9+ 필요:

```bash
swift build -c release
```

## License

MIT
