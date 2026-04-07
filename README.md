# Xcode AI Proxy

解决 Xcode 中无法直接添加智谱 GLM、Kimi、DeepSeek、通义千问和 Ollama 模型的问题。

## 解决什么问题？

当你在 Xcode 中尝试添加智谱、Kimi、DeepSeek、通义千问或 Ollama AI 提供商时，会遇到：

- ❌ "Provider is not valid"
- ❌ "Models could not be fetched with the provided account details"

这个代理服务让你可以在 Xcode 中正常使用智谱 GLM-4.6、Kimi、DeepSeek、通义千问和 Ollama 模型。

## 使用方法

⚠️⚠️⚠️ 确保你已安装 Python 3.12 + ⚠️⚠️⚠️

### 配置 API 密钥

复制 `.env.example` 为 `.env`，填入你的 API 密钥：

```bash
# 智谱AI API 密钥 (从 https://open.bigmodel.cn/ 获取)
ZHIPU_API_KEY=你的智谱API密钥

# Kimi API 密钥 (从 https://platform.moonshot.cn/ 获取)
KIMI_API_KEY=你的Kimi API密钥

# DeepSeek API 密钥 (从 https://platform.deepseek.com/ 获取)
DEEPSEEK_API_KEY=你的DeepSeek API密钥

# 通义千问 API 密钥 (从 https://bailian.console.aliyun.com/ 或阿里云百炼获取)
DASHSCOPE_API_KEY=你的通义千问API密钥

# Ollama 可选：显式设置后才启用，启动时会从该地址拉取模型列表
# 示例: http://localhost:11434 或 http://192.168.1.70:11434
# OLLAMA_BASE_URL=http://localhost:11434

# Ollama Cloud 可选：与本地独立，需设置 API Key（https://ollama.com/settings/keys）
# OLLAMA_CLOUD_API_KEY=你的云端API密钥
# 拉取失败时可配置兜底: OLLAMA_CLOUD_MODELS=llama3,qwen3
```

### 启动服务

项目已经提供 `start.sh` 启动脚本，会自动完成依赖安装、虚拟环境配置并启动服务。

```bash
chmod +x start.sh   # 首次使用时赋予执行权限
./start.sh
```

服务启动在 `http://localhost:8899`（若 `.env` 中修改了 `PORT`，以后文各客户端说明中的实际端口为准）。

完成上述步骤后，按你所用的工具查看对应章节。

## 配置 Xcode

本代理在 Xcode 中按 **非 OpenAI 根路径** 填写（与 Cursor / OpenCode / Codex 的 `/v1` 写法不同）。

#### 在 Internet Hosted 中添加 AI 提供商

- **Base URL**: `http://localhost:8899`
- **API Key**: `any-string-works`（任意字符串）

#### 在 Locally Hosted 中添加端口

- **端口**: `8899`（与 `.env` 中 `PORT` 一致）

配置完成后，即可在 Xcode 中使用本代理暴露的智谱、Kimi、DeepSeek、通义千问与 Ollama 等模型。

## 配置 Cursor

本代理对 Cursor 提供 **OpenAI Chat Completions 兼容**接口（`GET /v1/models`、`POST /v1/chat/completions` 等），按「自定义 OpenAI 兼容端点」填写即可。

**与 OpenCode、Codex 相同的通用规则**

- **Base URL**：填到 **`/v1` 为止**，不要拼 `/chat/completions`。默认示例：`http://127.0.0.1:8899/v1`（端口随 `.env` 中 `PORT` 调整）。
- **API Key**：客户端可填 **任意占位字符串**；真实密钥在服务端 `.env`。
- **模型名**：须与代理暴露的 id 一致，可查 `GET http://127.0.0.1:8899/v1/models` 或下文「支持的模型」。

**重要限制**：本服务 **未实现** OpenAI **Responses API**。若 Cursor 在部分场景改用 Responses 形态请求会失败，需改用仅走 Chat Completions 的模式或相关客户端选项。

**操作步骤**

1. 打开 **Settings → Models**。
2. 在 **OpenAI API Key** 中填入任意占位 key，并开启 **Override OpenAI Base URL**（或同类选项）。
3. **Base URL** 填：`http://127.0.0.1:8899/v1`（按实际主机与端口调整）。
4. 在模型列表中选择或 **手动添加** 自定义模型名（如 `deepseek-chat`、`glm-4.6`），须与 `/v1/models` 返回的 `id` 一致。

**说明**：**Agent** 等模式若走 Responses API，可与本代理不兼容，可先试 **Ask**。连接异常时可尝试 **Settings → Network → HTTP Compatibility Mode → HTTP/1.1**。内联 **Tab 补全** 通常仍走 Cursor 自带通道。

## 配置 OpenCode

OpenAI 兼容参数（Base URL 到 `/v1`、占位 API Key、模型 id）与上文 **「配置 Cursor」** 中的通用规则一致。

在 OpenCode 配置（如 `opencode.json`）中为 OpenAI 类提供商设置 `baseURL`，例如：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "openai": {
      "options": {
        "baseURL": "http://127.0.0.1:8899/v1",
        "useCompletionUrls": true
      }
    }
  }
}
```

`useCompletionUrls` 有助于在仅支持 **Chat Completions** 的代理上使用工具调用等能力；选项名若因版本而异，以 [OpenCode Providers 文档](https://opencode.ai/docs/providers/) 为准。

## 配置 OpenAI Codex CLI

OpenAI 兼容参数同样与 **「配置 Cursor」** 中的通用规则一致。

在用户或项目配置 `~/.codex/config.toml`、`.codex/config.toml` 中将 OpenAI API 根指向本代理，例如：

```toml
openai_base_url = "http://127.0.0.1:8899/v1"
```

也可通过 **`[model_providers.xxx]`** 的 **`base_url`** 指向同一地址，并配置 **`env_key`**（如 `OPENAI_API_KEY`），环境中填入 **占位密钥** 即可。字段名以你安装的 Codex 版本文档为准。

若存在 **`wire_api = "responses"`**（或等价项）而上游仅支持 Chat Completions，可能报错，需改为 Chat Completions 线路，详见 [Codex 高级配置](https://developers.openai.com/codex/config-advanced/)。可用 `curl http://127.0.0.1:8899/v1/models` 自检代理是否可达。

## 支持的模型

- `glm-4.6` - 智谱 AI GLM-4.6
- `kimi-k2-0905-preview` - Kimi K2
- `deepseek-reasoner` - DeepSeek Reasoner (思维模式)
- `deepseek-chat` - DeepSeek Chat (对话模式)
- `qwen-plus` - 通义千问 Plus
- `qwen-turbo` - 通义千问 Turbo
- **Ollama（本地）**：若设置了 `OLLAMA_BASE_URL`，代理启动时会从 Ollama 拉取模型列表，暴露的模型名与本地 `ollama list` 一致（如 `llama3:8b-instruct-fp16`、`qwen3` 等）
- **Ollama Cloud（云端）**：若设置了 `OLLAMA_CLOUD_API_KEY`，代理会请求云端 `/api/tags` 拉取模型列表，暴露的模型 id 带前缀 `ollama-cloud:`（如 `ollama-cloud:llama3`），与本地模型区分；拉取失败时可配置 `OLLAMA_CLOUD_MODELS`（逗号分隔）作为兜底列表

## 常见问题

**Q: 服务启动失败？**
A: 检查是否正确设置了 API 密钥，确保 8899 端口未被占用

**Q: 启用了 Ollama 但模型列表里没有本地模型？**
A: 确认已显式设置 `OLLAMA_BASE_URL`（如 `http://localhost:11434`），且该地址可访问、Ollama 服务已运行；启动时代理会请求 `/api/tags` 拉取模型列表，失败则跳过 Ollama

**Q: 如何区分本地 Ollama 与 Ollama Cloud 模型？**
A: 本地模型 id 与 `ollama list` 一致（如 `llama3:8b-instruct-fp16`）；云端模型 id 带前缀 `ollama-cloud:`（如 `ollama-cloud:llama3`）。云端需配置 `OLLAMA_CLOUD_API_KEY`，与本地 `OLLAMA_BASE_URL` 相互独立。

**Q: Ollama Cloud 模型列表为空或拉取失败？**
A: 确认已设置 `OLLAMA_CLOUD_API_KEY`（从 https://ollama.com/settings/keys 获取）。若云端 `/api/tags` 不可用，可配置兜底列表：`OLLAMA_CLOUD_MODELS=llama3,qwen3`（逗号分隔）。

**Q: Xcode 还是连不上？**
A: 确认服务正在运行，Base URL 填写正确：`http://localhost:8899`或端口填写正确：`8899`

**Q: Python 版本需要什么依赖？**
A: 需要 Python 3.10+，依赖已列在 pyproject.toml 中,需要 python 包管理工具 uv

**Q: Cursor / OpenCode / Codex 连不上或 Agent 模式报错？**
A: 先确认 Base URL 为 `http://<主机>:<端口>/v1`、模型 id 与 `/v1/models` 一致。若客户端走 **Responses API** 而本代理仅支持 **Chat Completions**，会出现不兼容；请按上文 **「配置 Cursor」「配置 OpenCode」「配置 OpenAI Codex CLI」** 中的说明调整模式或 `wire_api` / `useCompletionUrls` 等配置。

## 致谢：

- [Xcode AI Proxy](https://github.com/fengjinyi98/xcode-ai-proxy)
- [Kimi](https://www.kimi.com/)
- [DeepSeek](https://www.deepseek.com/)
- [ZhipuAI](https://bigmodel.cn/)
