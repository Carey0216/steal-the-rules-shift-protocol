<p align="center"><img src="../../assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL 로고"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

<p align="center">
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases"><img alt="버전 및 업데이트 기록" src="https://img.shields.io/badge/Versions-v1.4.0-398274?style=for-the-badge"></a>
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-windows-x64.zip"><img alt="Windows x64 ZIP 다운로드" src="https://img.shields.io/badge/Download-Windows%20x64-3b5d88?style=for-the-badge"></a>
  <a href="https://github.com/Carey0216/steal-the-rules-shift-protocol/releases/latest/download/shift-protocol-web.zip"><img alt="Web HTML5 ZIP 다운로드" src="https://img.shields.io/badge/Download-Web%20HTML5-825874?style=for-the-badge"></a>
  <a href="#플레이-가이드"><img alt="플레이 가이드" src="https://img.shields.io/badge/Guide-%ED%95%9C%EA%B5%AD%EC%96%B4-795c35?style=for-the-badge"></a>
</p>

[English](../../README.md) · [中文（简体）](../../docs/readme/zh-CN.md) · [中文（繁體）](../../docs/readme/zh-TW.md) · [日本語](../../docs/readme/ja.md) · **한국어**

전투의 규칙을 훔치는 2D 보스 러시. GitHub Game Off 2026을 위해 Godot와 GDScript로 만들었습니다.

## 게임 특징

| 기능 | 게임에서의 동작 |
| --- | --- |
| SHIFT 교환 | 공격을 피하고 열린 코어에 접근해 **Shift**를 누르세요. 보스의 능력을 얻고 가지고 있던 규칙을 보스에게 넘깁니다. |
| 8개 지역, 48개 구역 | 이동 발판, 연속 공격 중계기, 규칙 관문, 이동하는 감지기, 비상 점령 및 회피 충전이 등장합니다. 기존 구역을 조정하고 보스전 5개를 추가했습니다. |
| 지도와 저장 | 클리어하면 구역이 점등되고 다음 구역이 열립니다. 클리어한 구역에서 다시 평가와 보상을 받을 수 있습니다. Esc로 정지하고 톱니바퀴 메뉴에서 저장 종료 또는 진행 삭제를 선택합니다. |
| 실제 플레이 가이드 | 첫 5개 레슨은 직접 연습할 수 있습니다. 새로운 장치가 등장하기 전에 영상을 재생합니다. 로비의 **?**에서 영상과 장비 도감을 확인하세요. |
| 장비와 상점 | 장비 20종에 각각 아이콘이 있습니다. 클리어마다 코인 1000~3000개를 받고, 출격 전에 서로 다른 장비를 최대 3종 살 수 있습니다. 약화 장비는 전투에서만 떨어집니다. |
| 설정 | 언어, 화면 모드, 창 크기, 글자 크기를 조절하고 소리, 움직임 줄이기, 보조 모드를 설정할 수 있습니다. Windows판은 처음 전체 화면으로 시작하며 이후에는 설정을 기억합니다. 웹판은 페이지 안에서 시작하며 설정에서 전체 화면으로 전환할 수 있습니다. |

![협곡 관문의 로비](../lobby.png)

![8개 지역 구역 지도](../map.png)

![장비 6종이 열린 상점](../equipment.png)

## 조작 방법

| 동작 | 키보드 | 컨트롤러 |
| --- | --- | --- |
| 시작 / 계속 | Enter | Start / A |
| 이동 | A/D 또는 방향키 | 왼쪽 스틱 / 방향 패드 |
| 점프 | Space, W 또는 ↑ | A |
| 공격 (누르고 있으면 반복) | J 또는 Z | X |
| 회피 | K 또는 X | B |
| 훔치기 / 교환 | Shift 또는 Q | 오른쪽 범퍼 |
| 현재 규칙 사용 | E 또는 C | Y |
| 일시 정지 | Esc 또는 P | Start |
| 현재 구역 다시 시작 | R | Back / Select |

## 규칙과 회복

**RUSH**는 전방 돌진 공격입니다. **LIFT**로 상승하면서 공격하면 장갑을 뚫을 수 있습니다. **AEGIS**는 공격을 한 번 막고 보스가 가까우면 피해를 반사합니다. 다음 보스 공격이 끝나거나 규칙을 교환하면 충전됩니다. 다음 구역에 들어갈 때 내구도가 최대 3 회복됩니다. 다시 시작하면 해당 구역 진입 시의 상태로 돌아갑니다.

## 플레이 가이드

1. **실행.** Windows x64는 ZIP 전체를 풀고 `ShiftProtocol.exe`를 실행합니다. Web HTML5는 HTTP 서버에서 `index.html`을 열거나 ZIP을 itch.io에 브라우저 게임으로 업로드합니다. 브라우저에서는 화면을 클릭해 입력을 활성화합니다.
2. **첫 교환.** 경고를 읽고 공격 직전 K로 회피합니다. 열린 코어에 접근해 범위 표시가 뜨면 Shift, Q 또는 오른쪽 범퍼를 누르세요. E 또는 Y로 규칙을 사용하고 J 또는 X로 공격합니다. 실패하면 다음에 코어가 열릴 때 더 가까이 가세요.
3. **시설 장치.** 반사 표식에서 경고가 끝나기 직전에 E로 AEGIS를 사용합니다. 잔향 잠금장치 옆에서 조준이 고정될 때까지 기다렸다가 벗어나세요. 화물은 옆에서 J로 연결한 뒤 순서대로 운반합니다.
4. **캡슐.** 거품이 없고 대기 시간이 끝났다면 유효타에 38% 확률로 떨어집니다. 6초 뒤 사라지며 접근하면 5~9초간 효과가 적용됩니다. 민트는 강화, 산호색은 5초 약화입니다. HUD에 남은 시간이 표시됩니다.
5. **코인과 점수.** 클리어하면 별 1개, 구역별 제한 시간과 피격 횟수 조건으로 최대 2개를 추가로 받습니다. 다시 플레이해도 별 하나당 코인 1000개입니다. 상점은 6000코인부터 시작하며 로비 카트 또는 출격 화면에서 열 수 있습니다. 장비는 종류당 1개만 구매할 수 있습니다.
6. **다시 플레이와 저장.** 결과에서 재도전, 로비 또는 다음 구역을 선택합니다. 톱니바퀴의 진행 삭제를 확인하면 기록, 별, 코인, 구매 장비가 지워집니다. 언어, 화면 및 접근성 설정은 유지됩니다.

영상은 절반 속도로 재생하거나 일시 정지하고 1초씩 이동할 수 있습니다. 상점은 각 효과의 지속 시간과 타이머 시작 시점을 표시합니다.

## 실행과 빌드

Windows에서는 ZIP 전체를 풀고 `ShiftProtocol.exe`를 두 번 클릭하세요. 옆에 있는 `runtime` 폴더를 그대로 두세요. 데스크톱 브라우저에서는 게임 화면을 클릭한 뒤 조작하세요. 소스에서 실행하려면 일반 버전 Godot 4.7.2에서 `project.godot`를 열고 F5를 누르세요. 빌드 안내에 내보내기 템플릿, 테스트 및 웹·Windows ZIP 생성 방법이 있습니다.

[태그가 붙은 버전 다운로드](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases) · [빌드 안내 (영어)](../BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## 제작 및 라이선스

Carey가 GitHub Game Off 2026을 위해 만들었습니다. OpenAI Codex는 디자인, GDScript, 코드로 생성한 시각 효과와 소리, 테스트, 문서 작성을 지원했습니다. 게임 실행 중에는 AI를 사용하지 않습니다. 원본 프로젝트 파일은 MIT 라이선스를 따릅니다. Barlow Condensed, Space Mono, Noto Sans를 축소한 Shift Sans 폰트에는 각각 SIL Open Font License가 포함됩니다. Godot와 종속 라이브러리의 라이선스는 별도로 제공됩니다.

[MIT](../../LICENSE) · [SIL OFL](../../assets/) · [Godot](../GODOT_COPYRIGHT.txt)
