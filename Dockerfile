FROM mcr.microsoft.com/windows/servercore:ltsc2022

ARG RUNNER_VERSION="2.311.0"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# Set working directory
WORKDIR /actions-runner

COPY install-choco.ps1 .
RUN .\install-choco.ps1; Remove-Item .\install-choco.ps1 -Force

# Install dependencies with Chocolatey
RUN choco install -y \
    git \
    gh \
    powershell-core \
    python \
    docker-cli \
    7zip \
    dotnet-10.0-runtime \
    dotnet-10.0-aspnetruntime

# alc reads these when the AL compiler runs; keeps first-run telemetry and the
# .NET banner out of every build log
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1

# Add MSBuild to the path, and the .NET host alongside it - BcContainerHelper runs
# alc via a bare 'dotnet' command when the AL VSIX ships no alc.exe
RUN [Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin;C:\Program Files\dotnet\", \"Machine\")

COPY install-runner.ps1 .
RUN .\install-runner.ps1; Remove-Item .\install-runner.ps1 -Force

COPY entrypoint.ps1 .

ENTRYPOINT ["pwsh.exe", ".\\entrypoint.ps1"]
