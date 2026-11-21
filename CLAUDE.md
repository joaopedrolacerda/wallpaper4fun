# wallpaper4fun

App de wallpaper animado para **macOS** (no estilo dos apps de wallpaper animado), feito em SwiftUI + AppKit.
Toca vídeos em loop ou shaders Metal atrás dos ícones do desktop, em todos os monitores.

O projeto é **só macOS** de propósito: o iOS não deixa apps trocarem o fundo da tela. Não adicione de volta as plataformas iPhone/iPad/Vision.

## Build e testes

O `xcode-select` desta máquina aponta para as Command Line Tools, então no terminal use `DEVELOPER_DIR`:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project wallpaper4fun.xcodeproj -scheme wallpaper4fun -destination 'platform=macOS' test
```

Troque `test` por `build` para só compilar.

- Os shaders (`Shaders.metal`) precisam do **Metal Toolchain**. Sem ele o build falha com "missing Metal Toolchain". Para instalar: `xcodebuild -downloadComponent MetalToolchain` (download grande, peça confirmação ao usuário antes). Enquanto não estiver instalado, dá para rodar os testes tirando o `Shaders.metal` da pasta temporariamente (e devolvendo depois).
- Testes ficam em `wallpaper4funTests/` (Swift Testing, hospedados no app). O scheme compartilhado `wallpaper4fun` já roda esse target.
- Quando o app roda como host dos testes, o `AppDelegate` não abre as janelas do desktop.
- O projeto usa grupos sincronizados com a pasta (`fileSystemSynchronizedGroups`): arquivos novos em `wallpaper4fun/` ou `wallpaper4funTests/` entram no target sozinhos, sem editar o `project.pbxproj`.

## Arquitetura

A lógica fica em tipos sem AppKit, testados. O AppKit fica numa camada fina que só repassa eventos.

| Arquivo | Papel | Testado em |
|---|---|---|
| `WallpaperSettings.swift` | `WallpaperSettings` (tudo que o usuário escolhe, com `sourceID` e `shaderID`) e `SettingsStore` (salva como JSON no `UserDefaults`). | `SettingsStoreTests` |
| `WallpaperSource.swift` | Protocolo `WallpaperSource` (um tipo de wallpaper: título, wallpaper e controles do painel) e `WallpaperSourceRegistry` (único ponto de registro). | `WallpaperSourceRegistryTests` |
| `ShaderSource.swift` | `ShaderStyle`, `ShaderCatalog` (lista de shaders), `ShaderSource`, `ShaderWallpaperView` e o seletor de shader. | `ShaderCatalogTests` |
| `VideoSource.swift` | `VideoSource`, `VideoWallpaperView`/`LoopingPlayerView` e a linha de escolher vídeo. | — (views/AVFoundation) |
| `VideoLibrary.swift` | Copia vídeos para a pasta do app, substitui o anterior, encontra o vídeo salvo. | `VideoLibraryTests` |
| `WallpaperManager.swift` | Estado `@Observable` e regras: salvar configurações, mostrar/esconder, pausa, importar vídeo. Fala com a tela pelo protocolo `WallpaperDisplay`. | `WallpaperManagerTests` |
| `ShaderClock.swift` | Tempo acumulado da animação. | `ShaderClockTests` |
| `DockPolicy.swift` | Decide Dock ou só barra de menus. | `DockPolicyTests` |
| `DesktopWindows.swift` | AppKit: `DesktopWindowPresenter` (implementa `WallpaperDisplay`, uma janela por monitor), `DesktopWindow`, `SystemEventObserver` (telas dormindo), `VideoPicker`. | — (camada fina) |
| `WallpaperViews.swift` | `Playback` e `WallpaperContent`, que pede ao registro o tipo atual. | — (views) |
| `ContentView.swift` | Painel, dividido em subviews pequenas. O seletor de tipo e os controles vêm do registro. | — (views) |
| `Wallpaper4FunApp.swift` | `AppDelegate` monta e liga as peças; janela `main` e `MenuBarExtra`. | — |
| `Shaders.metal` | Shaders `[[stitchable]]` usados via `colorEffect`. | — |

Como funciona:
- **Fluxo**: o painel e o menu alteram `manager.settings`. O manager salva e, se `isEnabled` mudou, chama `display.show()`/`hide()`. As views observam o manager e se atualizam sozinhas.
- **Janelas do desktop**: `DesktopWindow` é borderless, no nível `CGWindowLevelForKey(.desktopWindow)` (abaixo dos ícones), ignora mouse e aparece em todos os Spaces. O presenter recria as janelas quando os monitores mudam.
- **Tipos de wallpaper**: nenhuma view conhece shader ou vídeo diretamente. `WallpaperContent` e o painel pedem a `WallpaperSourceRegistry.standard` o tipo do `settings.sourceID`, e cada tipo devolve o próprio wallpaper e os próprios controles.
- **Uma view para tudo**: cada janela mostra `WallpaperContent(manager:)` num `NSHostingView`, e o painel usa a mesma view como prévia.
- **Pausa**: use `effectivePaused` (pausa do usuário ou telas dormindo), não `settings.isPaused` direto.
- **Vídeo**: o arquivo escolhido é **copiado** para `Application Support/Wallpapers` dentro do container do sandbox, assim continua acessível depois de reiniciar. O player é mudo e não impede a tela de dormir.
- **Shader**: `TimelineView` limitado a 30 fps (`ShaderWallpaperView.frameInterval`).
- **Fechar o painel**: o app não encerra. `ContentView` chama `DockPolicy.apply` no `onAppear`/`onDisappear`.

## Ícone

Café numa mesa com paisagem noturna (lua, montanhas e uma aurora suave).

- Fontes: `Design/Icon/icon-full.svg` (64 px para cima) e `Design/Icon/icon-small.svg` (versão simplificada, 32 px para baixo, porque os detalhes somem). As mesmas fontes estão no repo Windows, em `design/icon/`. Mantenha as duas cópias iguais.
- `wallpaper4fun/Assets.xcassets/AppIcon.appiconset` é gerado, com a margem transparente do grid da Apple (arte em 824 de 1024 px). O target usa `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
- Para gerar de novo depois de mudar os SVGs, use o gerador do repo Windows: `../wallpaper4fun-windows/tools/IconKit/generate.sh "$PWD"`.
- O ícone da barra de menus é o SF Symbol `cup.and.heat.waves` (monocromático, como a Apple pede para a barra de menus).

## Como adicionar um shader

1. Em `Shaders.metal`, crie `[[stitchable]] half4 nome(float2 position, half4 color, float2 size, float time)`.
2. Em `ShaderSource.swift`, crie `static let nome = ShaderStyle(id: "nome", title: "Título")` (o `id` tem que ser igual ao nome da função) e inclua em `ShaderCatalog.all`.

O painel já lista todo o `ShaderCatalog.all`.

## Como adicionar um tipo de wallpaper

1. Crie um arquivo `NomeSource.swift` com um tipo que conforma a `WallpaperSource` (veja `ShaderSource` e `VideoSource`), com suas views.
2. Registre em `WallpaperSourceRegistry.standard`.
3. Se precisar guardar escolhas, adicione campos em `WallpaperSettings`.

O seletor de tipo do painel e as janelas do desktop já passam a mostrar o novo tipo.

## Regras de código

Estas regras valem para **todo** código novo e para qualquer código existente que for alterado.

### TDD sempre

1. **Vermelho**: escreva primeiro um teste que falha, descrevendo o comportamento desejado. Rode e confirme que ele falha pelo motivo certo.
2. **Verde**: escreva o mínimo de código para o teste passar.
3. **Refatorar**: limpe o código (nomes, duplicação, funções grandes) com os testes passando.

- Use **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`), não XCTest.
- Nenhum código de lógica entra sem teste. Correção de bug começa com um teste que reproduz o bug.
- Rode os testes depois de cada passo, com `xcodebuild … test` (mesmo comando do build, trocando `build` por `test`).
- Testes devem ser rápidos e isolados: nada de `UserDefaults.standard`, disco real ou rede. Use `UserDefaults(suiteName:)` próprio de cada teste, pastas temporárias e dublês (fakes).
- Um comportamento por teste, com nome que descreve o comportamento: `@Test("pausa quando as telas dormem")`.

### Código testável

- **Lógica fora das views.** Views SwiftUI e classes AppKit (`DesktopWindow`, `LoopingPlayerView`, `NSOpenPanel`) ficam finas: só montam a interface e repassam ações. Regras, cálculos e decisões vão para tipos testáveis.
- **Injete dependências** pelo `init` (`UserDefaults`, `FileManager`, pasta de vídeos, relógio, provedor de telas), com valores padrão para produção. Nunca acesse singletons direto dentro da lógica.
- Prefira **protocolos pequenos** nas fronteiras com o sistema (tela, arquivo, player) para poder trocar por fakes nos testes.

### Funções pequenas (Clean Code)

- **Uma função faz uma coisa só.** Se dá pra descrever com "e", divida.
- Mire em funções de **até ~15 linhas** e no máximo **um nível de indentação** de `if`/`for`. Passou disso, extraia funções com nomes descritivos.
- **Nomes revelam intenção**: `importVideo(from:)`, `rebuildWindows()`, não `handle()`, `doStuff()`, `data`. Identificadores em inglês; textos da interface e comentários em português.
- **Poucos parâmetros** (ideal até 2–3). Mais que isso, agrupe num tipo.
- Sem efeitos colaterais escondidos: uma função chamada `effectivePaused` não muda estado.
- Separe consulta de comando: funções que devolvem valor não alteram estado, e funções que alteram estado não devolvem valor (salvo `throws`).
- Comentários explicam o **porquê**, não o quê. Se precisa de comentário para explicar o quê, renomeie ou extraia uma função.
- Trate erros com `throws`/`Result` e mensagens claras; não engula erros com `try?` sem motivo.

### DRY

- **Não repita lógica.** Ao escrever a mesma coisa pela segunda vez, extraia uma função, tipo ou extensão compartilhada.
- Exemplos neste projeto: todas as configurações ficam em `WallpaperSettings` e são salvas num lugar só (`SettingsStore`); observers de notificação passam pela função `observe` em `DesktopWindows.swift`; `Playback` agrupa pausa e velocidade.
- Constantes (chaves, fps, nomes de pasta) ficam definidas em **um lugar**.
- DRY é sobre conhecimento, não sobre texto parecido: não junte duas coisas só porque o código se parece, se elas mudam por motivos diferentes.

### Open-Closed Principle (SOLID)

O código deve ser **aberto para extensão e fechado para modificação**: adicionar um comportamento novo é escrever código novo, não editar código que já funciona e já está testado.

- **Sem `switch`/`if` espalhados sobre "tipos".** Se adicionar uma variação obriga a editar vários `switch` em arquivos diferentes, troque por um **protocolo** com uma implementação por variação.
- **Um ponto de registro.** Variações novas entram por um único lugar (uma lista de registro ou um catálogo de dados), nunca editando as views ou as regras que as usam.
- **Dependa de abstrações.** A lógica conhece protocolos (`WallpaperDisplay`, `WallpaperSource`), não as classes concretas, e recebe as implementações por injeção.
- **Dados em vez de código** quando a variação é só configuração. Exemplo: um shader novo é uma entrada no `ShaderCatalog`, não um `case` novo com `switch` de título.
- **Prove a extensão com teste.** Ao criar um ponto de extensão, escreva um teste que registra uma implementação falsa e mostra que ela funciona sem mudar nada do que existe.
- Não crie abstração antes da hora. Comece concreto; extraia o protocolo quando surgir a segunda variação ou quando o teste precisar de um dublê.

Pontos de extensão deste projeto:

| Para adicionar… | Faça | Não mexa em |
|---|---|---|
| Um tipo de wallpaper (ex.: página web) | Crie um tipo que conforma a `WallpaperSource`, num arquivo próprio, e registre em `WallpaperSourceRegistry.standard`. | `WallpaperContent`, `ContentView`, `WallpaperManager` |
| Um shader | Escreva a função em `Shaders.metal` e adicione uma entrada em `ShaderCatalog.all`. | `ShaderSource`, views do painel |
| Outra forma de mostrar o wallpaper | Implemente `WallpaperDisplay`. | `WallpaperManager` |

### Antes de terminar uma tarefa

- Todos os testes passam e o build está sem warnings novos.
- Nenhuma função nova fora das regras acima.
- Código duplicado que você encontrou no caminho foi removido ou anotado.

## Convenções

- Swift 5 com `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` e approachable concurrency: tudo é MainActor por padrão. Closures `@Sendable` (ex.: `visualEffect`) só podem chamar código `nonisolated`. Observers do `NotificationCenter` usam `queue: .main` + `MainActor.assumeIsolated`.
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` está ligado: importe `AppKit` explicitamente em arquivos que usam `NSApp`, `NSWindow` etc.
- App em sandbox com `ENABLE_USER_SELECTED_FILES = readonly`.
- Textos da interface e comentários em português.
