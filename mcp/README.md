# mcp

Claude Code に繋ぐ MCP サーバを、brew list と同じ感覚で宣言的に管理します。

新しいマシンで `install.sh` を流せば、繋ぐべきサーバが揃った状態になります。

## ファイル

| ファイル | 役割 |
| --- | --- |
| `servers.json` | 繋ぐサーバの宣言。**ここが正** |
| `install.sh` | 宣言どおりに配線する。冪等 |
| `doctor.sh` | 宣言と実態のズレを報告する。読み取りのみ |

```bash
bash mcp/install.sh
```

```bash
bash mcp/doctor.sh
```

## 2 種類ある

MCP には性質の違う 2 種類があり、**片方しか repo で管理できません**。

**① stdio / http (`user`, `project`)**
実体は「コマンド + 引数 + env」または URL だけ。完全に宣言できるので `install.sh` が自動配線します。

**Notion はこちら。** claude.ai コネクタではなく、公式のリモート MCP (`https://mcp.notion.com/mcp`)
を Claude Code に直接つないでいます。配線は `install.sh` がやり、OAuth だけ初回に手で通します
(下の「OAuth が要る http サーバ」)。

**② claude.ai コネクタ (`connectors`)**
claude.ai アカウントに付くコネクタ。**実体は OAuth トークン**なので設定からは復元できません。
`install.sh` は接続済みかを確認してチェックリストを出すだけです。切れていたら対話セッションで:

```bash
claude mcp login '<name>'
```

## OAuth が要る http サーバ

`notion` のように、ヘッダに秘密を書かず OAuth で認証する http サーバは宣言できます。
トークンは Claude Code が持つので repo にも `~/.claude.json` にも秘密が載りません。
`install.sh` で配線したあと、対話セッションで一度だけ認証します:

```bash
claude      # 起動して /mcp → notion → Authenticate
```

### ssh 越しに認証する

承認後、ブラウザは**その機械の** `http://localhost:<port>/callback?code=...` へ戻ります。
ssh 先の機械 (Mac mini など) で認証すると、手元のブラウザからは届かずエラーページになります。
**そのエラーページの URL を丸ごとコピーし、ssh 先で叩けば通ります** (2026-11-27 に mini で実測):

```bash
curl 'http://localhost:<port>/callback?code=...&state=...'
```

手元が Mac なら `ssh -L <port>:localhost:<port> <host>` で転送してから承認しても同じです。

## 秘密の扱い

**このディレクトリに秘密の実値を書かないでください。**

Keychain のサービス名を `secrets` に書き、`args` の中で実行時に解決します。`chatwork` がその形です。

```bash
security add-generic-password -a "$USER" -s CHATWORK_API_TOKEN -w
```

`install.sh` は追加前に Keychain を確認し、無ければ登録コマンドを表示して飛ばします。

### http ヘッダに秘密が要るサーバは、ここでは扱いません

`--header "Authorization: Bearer ..."` 形式のサーバは、`claude mcp add` した時点で
**トークンが `~/.claude.json` に平文で焼き付きます**。実行時解決ができないので、
宣言に載せても秘密を repo か平文設定のどちらかに置くことになります。

そのため意図的に対象外にしています。該当するものは手で追加し、トークンは定期的に回してください。

## doctor が検知できないこと

`claude mcp list` が `✔ Connected` でも、セッションに `mcp__*` ツールが 1 つも降りてこないこと
があります。設定は正しく健全性チェックも通るので、**シェルからは判定できません**。
セッションの内側からしか見えない症状なので、`doctor.sh` の対象外です。

読み取りだけで良ければ、ログイン済み Chrome 経由で代替できます。
