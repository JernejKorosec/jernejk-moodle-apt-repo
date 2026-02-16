# map.md

This file is the visual map of how this repository builds and releases the APT package.

## 1) End-to-End Release Workflow
```mermaid
flowchart TD
  U["Run deploy.bat"] --> C["Read commit.ver"]
  C --> V{"Config valid and scripts/release exists?"}
  V -- No --> E1["Stop with error"]
  V -- Yes --> D1["docker build image"]
  D1 --> D2["docker compose up -d apt-repo"]
  D2 --> W1["Write docker-script/00_config.env"]
  W1 --> R1["Run docker-script/run_all.sh"]
  R1 --> S1["01_prepare_build_tree.sh"]
  S1 --> S2["02_build_deb.sh"]
  S2 --> S3["03_repo_add_package.sh"]
  S3 --> S4["04_repo_generate_metadata.sh"]
  S4 --> S5["05_repo_sign_metadata.sh"]
  S5 --> K{"GPG_KEY_ID set?"}
  K -- No --> K0["Skip signing"]
  K -- Yes --> K1["Create InRelease and Release.gpg"]
  K0 --> S6["06_smoke_test.sh"]
  K1 --> S6
  S6 --> G1["Run commit_new.bat"]
  G1 --> G2["git add -A"]
  G2 --> G3{"Staged changes exist?"}
  G3 -- No --> E2["Stop: nothing to commit"]
  G3 -- Yes --> G4["git commit"]
  G4 --> G5["git tag -a"]
  G5 --> P{"PUSH is true?"}
  P -- No --> Z1["Release complete (local only)"]
  P -- Yes --> G6["git push branch and tag"]
  G6 --> Z2["Release complete (remote)"]
```

## 2) Script/Data Read-Write Flow
```mermaid
flowchart LR
  CV["commit.ver"] --> DEP["deploy.bat"]
  CV --> COM["commit_new.bat"]
  EX["docker-script/00_config.env.example"] --> DEP
  DEP --> CFG["docker-script/00_config.env"]

  DEP --> RUN["docker-script/run_all.sh"]
  RUN --> P1["01_prepare_build_tree.sh"]
  RUN --> P2["02_build_deb.sh"]
  RUN --> P3["03_repo_add_package.sh"]
  RUN --> P4["04_repo_generate_metadata.sh"]
  RUN --> P5["05_repo_sign_metadata.sh"]
  RUN --> P6["06_smoke_test.sh"]

  SRC["scripts/release/*.sh"] --> P1
  CFG --> P1
  CFG --> P2
  CFG --> P3
  CFG --> P4
  CFG --> P5
  CFG --> P6

  P1 --> BDIR["repo/build/pkg_version_all/"]
  P1 --> CTRL["repo/build/pkg_version_all/DEBIAN/control"]
  P2 --> DEB["repo/build/pkg_version_all.deb"]
  DEB --> P3
  P3 --> POOL["repo/pool/main/m/moodle-admin-scripts/*.deb"]
  P3 --> PKGS["repo/dists/stable/main/binary-all/Packages and Packages.gz"]
  P4 --> REL["repo/dists/stable/Release"]
  P5 --> SIG["repo/dists/stable/InRelease and Release.gpg (if key set)"]

  COM --> EX
  COM --> GIT["git commit + tag (+ optional push)"]
```

## 3) Swimlane View (Who Runs What)
```mermaid
flowchart LR
  subgraph HOST["Windows Host"]
    H1["start.bat / login.bat"]
    H2["deploy.bat"]
    H3["commit_new.bat"]
  end

  subgraph CONT["Docker Container"]
    C1["run_all.sh"]
    C2["01-06 build scripts"]
  end

  subgraph ARTS["Repository Artifacts"]
    A1["repo/build/*.deb"]
    A2["repo/dists/stable/*"]
    A3["repo/pool/main/*"]
  end

  subgraph REM["GitHub Remote"]
    R1["main branch"]
    R2["release tag"]
  end

  H2 --> C1
  C1 --> C2
  C2 --> A1
  C2 --> A2
  C2 --> A3
  H3 --> R1
  H3 --> R2
```

## 4) Release Lifecycle States
```mermaid
stateDiagram-v2
  [*] --> Draft
  Draft --> Built: run 01 and 02
  Built --> Indexed: run 03 and 04
  Indexed --> Signed: run 05 with GPG key
  Indexed --> Tested: run 06 without signing
  Signed --> Tested: run 06
  Tested --> Committed: commit_new.bat
  Committed --> Tagged: git tag
  Tagged --> Pushed: PUSH=true
  Tagged --> LocalOnly: PUSH=false
  Pushed --> [*]
  LocalOnly --> [*]
```
