FROM mcr.microsoft.com/windows/servercore:ltsc2022

ARG RUNNER_VERSION="2.337.0"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Set working directory
WORKDIR /actions-runner

COPY install-choco.ps1 .
RUN .\install-choco.ps1; Remove-Item .\install-choco.ps1 -Force

# Git is pinned so a rebuild installs exactly this version. 2.56.1 fixes the Git security
# advisory of 2026-11-10; bump it on the next Git security release.
RUN choco install -y git --version=2.56.1

# PowerShell is pinned to the last version the BC pipelines ran on. The unpinned rebuild of
# 2026-11-11 installed 7.6.10, after which Expand-Archive failed in 'shell: powershell' steps
# (Cannot find an overload for "ExtractToDirectory" and the argument count: "3"), because
# Windows PowerShell loads PowerShell 7's Archive module there. Test a BC compile before bumping.
RUN choco install -y powershell-core --version=7.6.5

# Install dependencies with Chocolatey
RUN choco install -y \
    gh \
    python \
    docker-cli \
    7zip \
    dotnet-10.0-runtime \
    dotnet-10.0-aspnetruntime

# Separate layer so this runs in a fresh process that picks up the machine PATH the
# .NET installer wrote. Fails the build here rather than at BC compile time, where
# alc.dll is launched via a bare 'dotnet' command if the AL VSIX ships no alc.exe
RUN dotnet --list-runtimes

# Fails the build if the Git on the PATH is not the pinned version
RUN $v = git --version; Write-Host $v; if ($v -notmatch '2\.56\.1') { throw \"Expected Git 2.56.1, got: $v\" }

# Add MSBuild to the path
RUN [Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\", \"Machine\")

COPY install-runner.ps1 .
RUN .\install-runner.ps1; Remove-Item .\install-runner.ps1 -Force

COPY entrypoint.ps1 .

ENTRYPOINT ["pwsh.exe", ".\\entrypoint.ps1"]
