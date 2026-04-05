# AGENTS.md

## Project goal
Ship a field-testable iPhone MVP for evaluating arrow-hit dispersion from photos as quickly as possible.

## Current priority
Prefer a working end-to-end flow over full automation.

## Development rules
- Keep changes small and focused.
- One pull request should implement one visible improvement.
- Do not refactor unrelated files.
- Keep the app building in Xcode.
- Prefer manual fallback over incomplete automation.
- If automation is not reliable yet, expose a manual workflow instead.

## UX priority
The user must be able to:
1. load a real photo,
2. calibrate the target area,
3. set the target point,
4. add/edit hit points,
5. see dispersion metrics.

## Code style
- Prefer clear SwiftUI code over clever abstractions.
- Reuse coordinate-mapping helpers across screens.
- Add comments only for non-obvious logic.

## Pull request expectations
Every PR should include:
- what changed
- what user-visible behavior now works
- remaining limitations
- a short manual test checklist

# User-provided custom instructions

Project rules:
- Keep the repo runnable on Windows + Python 3.12.
- Prefer existing deps (numpy/pandas/matplotlib). If you need extra libs, add them as OPTIONAL and guard imports in notebooks with a clear install note.
- Each notebook must be "tutorial style": Markdown (concept + formula) -> code -> printed numeric examples -> plot -> "what to observe" bullets.
- Add docs/ markdown files that summarize key takeaways and link to notebooks.
- Do not rewrite core engine logic unless explicitly requested.

PRを作成することになった際は、その本文は日本語と英語を併記して書くようにしてください。そして、抽象度を高めた目的と全体要約に加え、プログラムの技術的な視点で、どのファイルのどこをどのような考え方で変更したか、読む人が生徒だと思い、つまづきやすいポイントや覚えるとスキルアップにつながる点を意識して教える気持ちを持って具体的かつ教育的に記述するようにお願いいたします。コードの中身にもコメントアウトで丁寧な説明付与を心がけてください。
