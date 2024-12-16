# 한국어

## LimeSignal
불필요한 부분을 제거하고 여러 기능을 추가한 [LemonSignal](https://github.com/Data-Oriented-House/LemonSignal)의 포크입니다.

### 특징
- 이론적으로 성능과 속도는 `LemonSignal`보다 좋지않습니다.
- 페키지 `caveful_games/threadpool`를 사용하여 한가지의 공유된 threadpool 공간에 스레드를 보관할 수 있습니다.
- `LemonSignal`에서 여러 다양한 도움이되는 클래스들이 추가되었습니다.
- 모든 클래스의 메소드, 속성은 camelCase입니다. 원래 `RBXScriptSignal`과 `Signal` 모듈들의 메소드가 PascalCase였다는 점에서 유의하세요.
- 순수 luau 지원이 삭제되었습니다. (로블록스 전용)

### 설치 (via pesde)
- 노트: 이 패키지는 `wally`에서 더 이상 업데이트되지 않습니다.
```sh
pesde add caveful_games/limesignal
```
