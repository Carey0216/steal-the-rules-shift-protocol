<p align="center"><img src="../../assets/icon.svg" width="112" height="112" alt="SHIFT PROTOCOL 로고"></p>
<h1 align="center">STEAL THE RULES: SHIFT PROTOCOL</h1>

![Version 1.2.0](https://img.shields.io/badge/version-1.2.0-4caa94) ![Godot 4.7.2](https://img.shields.io/badge/Godot-4.7.2-478cbf) ![Platform Windows and Web](https://img.shields.io/badge/platform-Windows%20%7C%20Web-30363d) [![MIT license](https://img.shields.io/badge/license-MIT-cc8850)](../../LICENSE)

[English](../../README.md) · [中文（简体）](../../docs/readme/zh-CN.md) · [中文（繁體）](../../docs/readme/zh-TW.md) · [日本語](../../docs/readme/ja.md) · **한국어**

전투의 규칙을 훔치는 2D 보스 러시. GitHub Game Off 2026을 위해 Godot와 GDScript로 만들었습니다.

## 게임 특징

| 기능 | 게임에서의 동작 |
| --- | --- |
| SHIFT 교환 | 공격을 피하고 열린 코어에 접근해 **Shift**를 누르세요. 보스의 능력을 얻고 가지고 있던 규칙을 보스에게 넘깁니다. |
| 구역 6곳 | 두 번째 구역의 바닥이 무너지면 위아래로 길이 갈립니다. 이후에는 통전 도관, 용광로 분출구, 이전 위치를 노리는 반사 공격과 넘겨받은 규칙을 강화하는 집행자가 등장합니다. |
| 구역 지도와 저장 | 구역을 완료하면 자동으로 저장되고 다음 구역이 열립니다. 로비에서 완료한 구역을 다시 플레이하고 시간, 피격, 재시도 횟수를 확인할 수 있습니다. Esc로 일시 정지하고 톱니바퀴 메뉴에서 저장하고 종료합니다. |
| 순서대로 보는 조작 가이드 | 처음 실행하면 실제 플레이 영상 다섯 편을 순서대로 봅니다. 로비의 **?**에서 다시 볼 수 있으며 각 레슨의 조작을 연습장에서 직접 해볼 수 있습니다. |
| 설정 | 언어, 화면 모드, 창 크기, 글자 크기를 조절하고 소리, 움직임 줄이기, 보조 모드를 설정할 수 있습니다. Windows판은 처음 전체 화면으로 시작하며 이후에는 설정을 기억합니다. 웹판은 페이지 안에서 시작하며 설정에서 전체 화면으로 전환할 수 있습니다. |

![두 구역을 돌파한 지도](../map.png)

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

## 실행과 빌드

Windows에서는 ZIP 전체를 풀고 `ShiftProtocol.exe`를 두 번 클릭하세요. 옆에 있는 `runtime` 폴더를 그대로 두세요. 데스크톱 브라우저에서는 게임 화면을 클릭한 뒤 조작하세요. 소스에서 실행하려면 일반 버전 Godot 4.7.2에서 `project.godot`를 열고 F5를 누르세요. 빌드 안내에 내보내기 템플릿, 테스트 및 웹·Windows ZIP 생성 방법이 있습니다.

[태그가 붙은 버전 다운로드](https://github.com/Carey0216/steal-the-rules-shift-protocol/releases) · [빌드 안내 (영어)](../BUILD.md) · [Game Off 2026](https://itch.io/jam/game-off-2026)

## 제작 및 라이선스

Carey가 GitHub Game Off 2026을 위해 만들었습니다. OpenAI Codex는 디자인, GDScript, 코드로 생성한 시각 효과와 소리, 테스트, 문서 작성을 지원했습니다. 게임 실행 중에는 AI를 사용하지 않습니다. 원본 프로젝트 파일은 MIT 라이선스를 따릅니다. Barlow Condensed, Space Mono, Noto Sans를 축소한 Shift Sans 폰트에는 각각 SIL Open Font License가 포함됩니다. Godot와 종속 라이브러리의 라이선스는 별도로 제공됩니다.

[MIT](../../LICENSE) · [SIL OFL](../../assets/) · [Godot](../GODOT_COPYRIGHT.txt)
