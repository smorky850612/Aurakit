<div align="center">

[![Languages](https://img.shields.io/badge/languages-8-fcd34d?style=flat-square&labelColor=161b22)]()
[![IME Support](https://img.shields.io/badge/IME-Korean%20%26%20Japanese-a78bfa?style=flat-square&labelColor=161b22)]()

</div>

# Multilingual

> AuraKit speaks 8 languages natively. No input method switching required.

---

## Command Reference

### East Asian

| Action | 🇰🇷 Korean | 🇯🇵 Japanese | 🇨🇳 Chinese |
|--------|:----------:|:-----------:|:-----------:|
| Main | `/아우라` | `/オーラ` | `/奥拉` |
| Build | `/아우라빌드` | `/オーラビルド` | `/奥拉构建` |
| Fix | `/아우라수정` | `/オーラ修正` | `/奥拉修复` |
| Clean | `/아우라정리` | `/オーラ整理` | `/奥拉清理` |
| Deploy | `/아우라배포` | `/オーラデプロイ` | `/奥拉部署` |
| Review | `/아우라리뷰` | `/オーラレビュー` | `/奥拉审查` |
| Compact | `/아우라컴팩트` | `/オーラコンパクト` | `/奥拉压缩` |

### European

| Action | 🇪🇸 Spanish | 🇫🇷 French | 🇩🇪 German | 🇮🇹 Italian |
|--------|:-----------:|:---------:|:---------:|:-----------:|
| Main | `/aura-es` | `/aura-fr` | `/aura-de` | `/aura-it` |
| Build | `/aura-construir` | `/aura-construire` | `/aura-bauen` | `/aura-costruire` |
| Fix | `/aura-arreglar` | `/aura-corriger` | `/aura-beheben` | `/aura-correggere` |
| Clean | `/aura-limpiar` | `/aura-nettoyer` | `/aura-aufraeumen` | `/aura-pulire` |
| Deploy | `/aura-desplegar` | `/aura-deployer` | `/aura-deployen` | `/aura-distribuire` |
| Review | `/aura-revisar` | `/aura-reviser` | `/aura-pruefen` | `/aura-rivedere` |
| Compact | `/aura-compactar` | `/aura-compresser` | `/aura-komprimieren` | `/aura-compattare` |

---

## Examples by Language

<details open>
<summary><b>🇰🇷 Korean</b></summary>

```bash
/아우라빌드: JWT 인증 API
/아우라수정: 로그인 버튼이 모바일에서 작동 안 함
/아우라정리: utils 폴더 중복 코드 제거
/아우라배포: Vercel 프로덕션
/아우라리뷰: 보안 감사
/아우라컴팩트
```

</details>

<details>
<summary><b>🇯🇵 Japanese</b></summary>

```bash
/オーラビルド: JWT認証APIを実装
/オーラ修正: モバイルでログインボタンが動かない
/オーラ整理: utilsフォルダの重複コードを削除
/オーラデプロイ: Vercelプロダクション
/オーラレビュー: セキュリティ監査
/オーラコンパクト
```

</details>

<details>
<summary><b>🇨🇳 Chinese</b></summary>

```bash
/奥拉构建: JWT认证API
/奥拉修复: 移动端登录按钮无响应
/奥拉清理: 删除utils文件夹中的重复代码
/奥拉部署: Vercel生产环境
/奥拉审查: 安全审计
/奥拉压缩
```

</details>

<details>
<summary><b>🇪🇸 Spanish</b></summary>

```bash
/aura-construir: API de autenticación con JWT
/aura-arreglar: el botón de login no responde en móvil
/aura-limpiar: eliminar código duplicado en utils/
/aura-desplegar: a Vercel producción
/aura-revisar: auditoría de seguridad
/aura-compactar
```

</details>

<details>
<summary><b>🇫🇷 French</b></summary>

```bash
/aura-construire: API d'authentification avec JWT
/aura-corriger: le bouton login ne répond pas sur mobile
/aura-nettoyer: supprimer le code dupliqué dans utils/
/aura-deployer: sur Vercel production
/aura-reviser: audit de sécurité
/aura-compresser
```

</details>

<details>
<summary><b>🇩🇪 German</b></summary>

```bash
/aura-bauen: JWT Authentifizierungs-API
/aura-beheben: Login-Button funktioniert nicht auf Mobile
/aura-aufraeumen: doppelten Code in utils/ entfernen
/aura-deployen: auf Vercel Produktion
/aura-pruefen: Sicherheitsaudit
/aura-komprimieren
```

</details>

<details>
<summary><b>🇮🇹 Italian</b></summary>

```bash
/aura-costruire: API di autenticazione con JWT
/aura-correggere: il pulsante login non risponde su mobile
/aura-pulire: rimuovere codice duplicato in utils/
/aura-distribuire: su Vercel produzione
/aura-rivedere: audit di sicurezza
/aura-compattare
```

</details>

---

## IME Support

> [!TIP]
> Korean and Japanese input methods are handled by `korean-command.js`. When you type `/아우라빌드` in Korean IME mode, the hook reverse-transliterates the command automatically — you never need to press <kbd>Shift</kbd> or switch to English.

The hook intercepts the raw input before Claude Code processes it, maps the unicode characters back to the corresponding `/aura` command, and passes the translated command forward. The description after the colon remains in your language.
