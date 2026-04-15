# AuraKit — Python / PyTorch Build Resolver

> FIX 모드 V1 빌드 실패 시 Python/PyTorch 프로젝트에서 자동 트리거.

---

## Python / PyTorch Resolver

### 에러 패턴 & 수정

```
ModuleNotFoundError: No module named '[package]'
→ 원인: 패키지 미설치 또는 venv 미활성화
→ 수정: pip install [package]
  또는: source .venv/bin/activate
  확인: which python → 올바른 인터프리터 경로인지 검증

ImportError: cannot import name '[name]' from '[module]'
→ 원인: API 변경 또는 잘못된 이름
→ 수정: 해당 버전 문서 확인, pip show [package]로 버전 확인
  흔한 사례: from collections import Mapping → Python 3.10+에서 제거됨
  → from collections.abc import Mapping 으로 변경

RuntimeError: CUDA out of memory
→ 원인: GPU 메모리 부족
→ 수정:
  torch.cuda.empty_cache()
  # 배치 사이즈 줄이기 (//2)
  # torch.cuda.amp.autocast() 활성화
  # gradient checkpointing: model.gradient_checkpointing_enable()

RuntimeError: Expected all tensors to be on the same device
→ 원인: CPU/GPU 텐서 혼용
→ 수정: .to(device) 통일, device 변수 일관성 확인
  device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
  model.to(device); inputs = inputs.to(device)

AttributeError: '[Module]' object has no attribute '[method]'
→ 원인: 버전 불일치 API
→ 수정: pip install --upgrade [package]
  또는 호환 API 사용

TypeError: [func]() got an unexpected keyword argument '[arg]'
→ 원인: API 변경 (구버전 파라미터)
→ 수정: 최신 API 문서 참조, 파라미터명 수정

SyntaxError: invalid syntax
→ 원인: Python 2/3 문법 혼용, 오타, 또는 f-string 내 백슬래시
→ 수정:
  print("x") (Python 3)
  f-string 내 백슬래시 불가 → 변수로 분리
  # bad:  f"path\\{name}"  → good: sep = "\\"; f"path{sep}{name}"

IndentationError: unexpected indent / unindent
→ 원인: 탭/스페이스 혼용 또는 들여쓰기 불일치
→ 수정: 에디터에서 탭 → 4 스페이스 자동 변환 설정
  python -tt script.py → 탭/스페이스 혼용 검출

RecursionError: maximum recursion depth exceeded
→ 원인: 무한 재귀 또는 재귀 깊이 초과
→ 수정: 재귀 로직 점검, 필요 시 sys.setrecursionlimit() 조정
  또는 반복문(iterative)으로 변환

ValueError: too many values to unpack / not enough values to unpack
→ 원인: 언패킹 대상과 변수 개수 불일치
→ 수정: 대상 객체 길이 확인 (len()), * 연산자로 가변 언패킹
  a, *rest = some_list
```

### 타입 시스템 에러 (mypy / pyright)

```
error: Incompatible types in assignment (expression has type "X", variable has type "Y")
→ 원인: 타입 어노테이션과 실제 값 불일치
→ 수정: 올바른 타입 어노테이션 적용 또는 Union 타입 사용
  x: Union[int, str] = get_value()
  # Python 3.10+: x: int | str = get_value()

error: Item "None" of "Optional[X]" has no attribute "Y"
→ 원인: Optional 타입에서 None 가능성 미처리
→ 수정: None 체크 후 접근
  if obj is not None:
      obj.method()

error: Argument of type "X" cannot be assigned to parameter of type "Y"
→ 원인: 함수 호출 시 타입 불일치
→ 수정: 캐스팅 또는 함수 시그니처 수정
  from typing import cast
  result = cast(TargetType, value)

error: "X" has no attribute "Y"
→ 원인: 타입 추론 실패 또는 동적 속성
→ 수정: Protocol 정의, TypedDict 사용, 또는 TYPE_CHECKING 분기
  from typing import TYPE_CHECKING
  if TYPE_CHECKING:
      from module import SomeClass

error: Cannot infer type argument [N] of "func"
→ 원인: 제네릭 함수에서 타입 추론 실패
→ 수정: 명시적 타입 인자 전달
  result = func[int](args)  # Python 3.12+ 또는 TypeVar 사용
```

### 패키지 관리자 문제 (pip / poetry / conda)

```
pip:
  ERROR: Could not find a version that satisfies the requirement [pkg]==[ver]
  → 원인: 해당 버전이 현재 Python 버전과 호환 불가 또는 존재하지 않음
  → 수정: pip install [pkg] (최신 호환 버전), 또는 Python 버전 확인
    pip index versions [pkg] → 사용 가능한 버전 목록 확인

  ERROR: pip's dependency resolver does not currently support backtracking
  → 원인: 의존성 간 버전 충돌
  → 수정: pip install --upgrade pip → 최신 resolver 사용
    pip install [pkg1] [pkg2] 동시 설치로 충돌 해결
    최종 수단: pip install --no-deps [pkg] → 의존성 무시 (위험)

  ERROR: Cannot uninstall '[pkg]'. It is a distutils installed project
  → 원인: 시스템 패키지와 충돌
  → 수정: pip install --ignore-installed [pkg]
    또는 venv 사용 (권장)

poetry:
  SolverProblemError: ... is not compatible ...
  → 원인: pyproject.toml 버전 범위 충돌
  → 수정: poetry update 또는 버전 범위 완화
    poetry add [pkg]@latest → 최신 호환 버전 추가
    poetry lock --no-update → lock 파일 재생성 (버전 유지)

  PackageNotFoundError: Package [pkg] not found
  → 원인: private index 미설정 또는 패키지명 오타
  → 수정: pyproject.toml에 [[tool.poetry.source]] 추가
    또는 poetry source add [name] [url]

conda:
  ResolvePackageNotFound / UnsatisfiableError
  → 원인: 채널에 해당 패키지/버전 없음
  → 수정: conda install -c conda-forge [pkg]
    또는: conda config --add channels conda-forge
    pip와 conda 혼용 시 → conda 환경 내에서 pip 사용 주의
```

### 의존성 해결 전략

```
1. 가상 환경 격리 (필수)
   python -m venv .venv && source .venv/bin/activate  # Unix
   python -m venv .venv && .venv\Scripts\activate      # Windows
   → 시스템 Python 오염 방지

2. 의존성 고정
   pip freeze > requirements.txt             # 현재 환경 스냅샷
   pip-compile requirements.in               # pip-tools 사용 (권장)
   poetry lock                               # poetry lock 파일 생성

3. 충돌 진단
   pip check                                 # 호환성 확인
   pipdeptree                                # 의존성 트리 시각화
   pipdeptree --reverse --packages [pkg]     # 특정 패키지 역추적
   poetry show --tree                        # poetry 의존성 트리

4. 클린 재설치
   pip install --force-reinstall -r requirements.txt
   poetry install --no-cache                 # 캐시 무시 재설치

5. Python 버전별 분기
   python_requires >= "3.8" 확인 (setup.cfg / pyproject.toml)
   tox / nox 로 멀티버전 테스트
```

### 환경별 주의사항 (Environment Gotchas)

```
Windows:
  - 경로 구분자: os.path.join() 또는 pathlib.Path 사용 (하드코딩 금지)
  - 인코딩: open(file, encoding="utf-8") 명시 (기본이 cp949/cp1252)
  - 긴 경로: Windows 10+에서 LongPathsEnabled 레지스트리 설정 필요
  - pip install 빌드 실패 → Visual C++ Build Tools 설치 필요
    (Microsoft C++ Build Tools 또는 Visual Studio Installer)

macOS:
  - system Python 사용 금지 → brew install python 또는 pyenv 사용
  - SSL 인증서: pip install certifi && /Applications/Python*/Install\ Certificates.command
  - Apple Silicon (M1/M2/M3):
    일부 패키지 arm64 미지원 → arch -x86_64 pip install [pkg]
    또는 conda-forge에서 arm64 빌드 확인
  - tensorflow-macos / tensorflow-metal → Apple GPU 가속 별도 패키지

Linux:
  - python3-dev / python3-devel 패키지 필요 (C extension 빌드 시)
  - libffi-dev, libssl-dev → 암호화 관련 패키지 빌드 의존성
  - deadsnakes PPA (Ubuntu): 최신 Python 버전 설치
    sudo add-apt-repository ppa:deadsnakes/ppa

Docker:
  - 멀티스테이지 빌드: builder 단계에서 pip install → 최종 이미지에 복사
  - --no-cache-dir 사용 → 이미지 크기 축소
  - requirements.txt 변경 시만 레이어 재빌드:
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY . .

PyTorch 전용:
  - CUDA 버전 불일치: nvidia-smi 버전과 torch CUDA 버전 일치 필수
    torch.version.cuda → 설치된 CUDA 런타임 확인
    nvcc --version → 시스템 CUDA Toolkit 확인
  - CPU 전용 설치: pip install torch --index-url https://download.pytorch.org/whl/cpu
  - nightly 빌드: pip install --pre torch --index-url https://download.pytorch.org/whl/nightly/cu121
```

### 자동 수정 명령

```bash
pip install -r requirements.txt      # 의존성 설치
pip check                            # 의존성 충돌 확인
python -m py_compile *.py            # 문법 검사
ruff check . --fix                   # 린트 자동 수정 (ruff 있는 경우)
mypy . --ignore-missing-imports      # 타입 체크 (mypy)
pyright .                            # 타입 체크 (pyright)
black . --check                      # 포맷 확인
black .                              # 포맷 자동 수정
isort . --check-only                 # import 정렬 확인
isort .                              # import 정렬 수정
python -m pytest --tb=short          # 테스트 실행 (짧은 트레이스백)
pip-audit                            # 보안 취약점 스캔
```

---
