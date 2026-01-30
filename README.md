# Xcode AI Proxy

解决 Xcode 中无法直接添加智谱 GLM、Kimi、DeepSeek、通义千问和 Ollama 模型的问题。

## 解决什么问题？

当你在 Xcode 中尝试添加智谱、Kimi、DeepSeek、通义千问或 Ollama AI 提供商时，会遇到：

- ❌ "Provider is not valid"
- ❌ "Models could not be fetched with the provided account details"

这个代理服务让你可以在 Xcode 中正常使用智谱 GLM-4.6、Kimi、DeepSeek、通义千问和 Ollama 模型。

## 使用方法

⚠️⚠️⚠️ 确保你已安装 Python 3.12 + ⚠️⚠️⚠️

#### 1. 配置 API 密钥

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
```

#### 2. 启动服务

项目已经提供 `start.sh` 启动脚本，会自动完成依赖安装、虚拟环境配置并启动服务。

```bash
chmod +x start.sh   # 首次使用时赋予执行权限
./start.sh
```

服务启动在 `http://localhost:8899`

### 3. 配置 Xcode

#### 3.1 在 Internet Hosted 中添加 AI 提供商：

- **Base URL**: `http://localhost:8899`
- **API Key**: `any-string-works` (任意字符串)

#### 3.2 在 Locally Hosted 中添加 端口：

- **端口**: `8899`

现在可以在 Xcode 中正常使用智谱 GLM-4.6、Kimi、DeepSeek、通义千问和 Ollama 模型了！

## 支持的模型

- `glm-4.6` - 智谱 AI GLM-4.6
- `kimi-k2-0905-preview` - Kimi K2
- `deepseek-reasoner` - DeepSeek Reasoner (思维模式)
- `deepseek-chat` - DeepSeek Chat (对话模式)
- `qwen-plus` - 通义千问 Plus
- `qwen-turbo` - 通义千问 Turbo
- **Ollama**：若设置了 `OLLAMA_BASE_URL`，代理启动时会从 Ollama 拉取模型列表，暴露的模型名与本地 `ollama list` 一致（如 `llama3:8b-instruct-fp16`、`qwen3` 等）

## 常见问题

**Q: 服务启动失败？**
A: 检查是否正确设置了 API 密钥，确保 8899 端口未被占用

**Q: 启用了 Ollama 但模型列表里没有本地模型？**
A: 确认已显式设置 `OLLAMA_BASE_URL`（如 `http://localhost:11434`），且该地址可访问、Ollama 服务已运行；启动时代理会请求 `/api/tags` 拉取模型列表，失败则跳过 Ollama

**Q: Xcode 还是连不上？**
A: 确认服务正在运行，Base URL 填写正确：`http://localhost:8899`或端口填写正确：`8899`

**Q: Python 版本需要什么依赖？**
A: 需要 Python 3.10+，依赖已列在 pyproject.toml 中,需要 python 包管理工具 uv

## 致谢：

- [Xcode AI Proxy](https://github.com/fengjinyi98/xcode-ai-proxy)
- [Kimi](https://www.kimi.com/)
- [DeepSeek](https://www.deepseek.com/)
- [ZhipuAI](https://bigmodel.cn/)
