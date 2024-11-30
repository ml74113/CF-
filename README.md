一键拉去脚本

wget https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/xlr.sh
chmod +x xlr.sh
./xlr.sh


添加定时任务 

echo "0 0 * * * cd /root && bash xlr.sh" | crontab -


这个脚本是一个自动化工具，用于从 Cloudflare 获取和更新 DNS 记录。它执行了以下主要任务：

    检查依赖命令是否存在并安装 ：例如 curl, jq, awk, 和 crontab。如果命令不存在，会自动尝试安装。

    下载 CloudflareSpeedTest 工具 ：如果本地没有安装 CloudflareSpeedtest，它会根据操作系统自动下载合适的版本。

    输入和保存配置 ：脚本会提示用户输入 Cloudflare 账户信息、域名及其子域名，并将这些配置保存到 config.conf 文件中。

    下载 Cloudflare IP 列表 ：从 Cloudflare 获取最新的 IPv4 地址列表，保存到 ip.txt 文件。

    运行测速 ：使用 CloudflareSpeedTest 工具测试多个 Cloudflare 节点的速度，并将结果保存到 result.csv。

    筛选最优 IP ：从测速结果中筛选出速度最快的 5 个 IP。

    获取 Zone ID ：通过 Cloudflare API 获取当前域名的 Zone ID。

    获取并更新 DNS 记录 ：使用 Cloudflare API 获取或创建 DNS 记录，并更新为测速得到的最快的 5 个 IP 地址。 

各个部分的详细解释：

    安装依赖工具 ：
        check_command 函数会检查命令是否已安装。如果没有，它会根据操作系统自动安装所需的包。
        支持的操作系统包括 Linux（Debian/RedHat），macOS，和 Windows（目前仅支持手动安装）。 

    配置输入和保存 ：
        read_configuration 函数会提示用户输入 Cloudflare 账户的邮箱、API 密钥，域名，以及五个子域名，并将其保存到配置文件中。 

    测速并筛选最快 IP ：
        CloudflareSpeedTest 工具会进行多次测速，并生成一个 CSV 文件，其中包含不同节点的测速结果。
        使用 awk 筛选出速度大于等于 10 Mbps 的 IP，并选出速度最快的前 5 个。 

    DNS 更新 ：
        脚本通过 Cloudflare API 获取现有的 DNS 记录，如果没有找到则创建新的记录。
        它会依次将测速得到的 IP 更新到指定的子域名上。 

注意事项：

    API 密钥和邮箱 ：需要提供有效的 Cloudflare 账户的邮箱和 API 密钥，确保有权限更新 DNS 记录。
    域名和子域名 ：需要事先在 Cloudflare 配置好域名，并能访问到该域名的 Zone ID。
    测速工具 ： CloudflareSpeedTest 工具是第三方的测速工具，脚本会自动下载对应操作系统版本。 

示例执行流程：

    运行脚本，脚本会提示你输入 Cloudflare 账户信息、API 密钥、域名、子域名。
    脚本会下载并运行 CloudflareSpeedTest，并获取最快的 5 个 IP。
    它会通过 Cloudflare API 获取你的域名的 Zone ID，然后依次更新指定的 5 个子域名的 DNS 记录。 

错误处理：

    如果某个步骤失败（例如下载 CloudflareSpeedTest 或更新 DNS 记录），脚本会输出错误信息并退出。
    如果无法获取到足够的测速 IP，脚本会提醒并退出。 

扩展功能：

    可以根据需要修改 CloudflareSpeedTest 的测速参数，例如调整测速节点数量、超时时间等。
    如果你有多个域名和多个子域名，可以将脚本进一步扩展以支持更多的输入和配置。 
