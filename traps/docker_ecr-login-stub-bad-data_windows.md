# Docker（Windows）— ECR への docker login が "The stub received bad data." で失敗する（資格情報マネージャーに保存できない）

## 症状
- `aws ecr get-login-password | docker login --username AWS --password-stdin <アカウント>.dkr.ecr.<リージョン>.amazonaws.com` が次で失敗する
  ```
  Error saving credentials: error storing credentials - err: exit status 1, out: `The stub received bad data.`
  ```
- `set -e` のデプロイスクリプトは、build/push の前のここで止まる（ECR には何も push されない）

## 原因
- Docker Desktop の設定（`~/.docker/config.json`）が `"credsStore": "desktop"` で、資格情報を Windows の資格情報マネージャーに置こうとして失敗する。ECR のトークンが大きく、資格情報マネージャーの上限を超えるため（推測）
- **`auths` が空の設定を `DOCKER_CONFIG` で渡しても直らない。** docker CLI は、設定に資格情報の記述（`credsStore`・`credHelpers`・`auths` のどれか）が 1 つも無いと、既定の保存先を自分で探して使う。Windows では `docker-credential-wincred` が見つかるので、同じ資格情報マネージャーになる（`{"auths":{}}` では同じエラー、ダミーを 1 つ入れると成功、を確かめた。docker/cli の `config.Load` → `ContainsAuth()` が偽なら `DetectDefaultStore`、はコードの読みで推測）

## 対処
資格情報を設定ファイルに置く一時の設定を作り、その作業のときだけ使う。一時の設定には context が無いので、Docker Desktop のエンジンを `DOCKER_HOST` で直接指す。
```bash
DC=/c/Users/<user>/<作業用の場所>/docker-config
mkdir -p "$DC"
printf '{"auths":{"placeholder.invalid":{}}}\n' >"$DC/config.json"   # ダミーを 1 つ入れる（空だと wincred に戻る）
export DOCKER_CONFIG='C:/Users/<user>/<作業用の場所>/docker-config'
export DOCKER_HOST='npipe:////./pipe/dockerDesktopLinuxEngine'
aws ecr get-login-password --region <リージョン> | docker login --username AWS --password-stdin <レジストリ>
# build / push
docker logout <レジストリ>   # トークンは設定ファイルに base64 で残るので消す
```
- 普段の設定に戻すのは `unset DOCKER_CONFIG DOCKER_HOST`
- 一時の設定ではビルダーが `default`（docker ドライバ）になる。普段の docker-container のビルダー（`docker buildx ls` の別ビルダー）とはキャッシュが別
- Lambda 向けは `--platform linux/amd64 --provenance=false --sbom=false --output "type=image,name=<repo>:<tag>,oci-mediatypes=false,push=true"` で、push したマニフェストが `application/vnd.docker.distribution.manifest.v2+json`（単体）になった。確かめ方: `aws ecr batch-get-image --repository-name <repo> --image-ids imageTag=<tag> --query 'images[0].imageManifestMediaType' --output text`

## 観測
- 2026-11-05、Windows 11・Docker Desktop（server 28.3.0）。pj_rat で API の Lambda のイメージを先方の ECR へ push するとき
