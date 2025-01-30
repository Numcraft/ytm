FROM ubuntu:24.04

RUN apt-get update && apt-get install -y openjdk-17-jre-headless curl jq python3 python3-bs4 python3-requests gnupg

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
		apt-get update && \
		apt-get install -y gh

CMD ["/bin/bash"]
