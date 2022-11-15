FROM gitpod/workspace-base

### Versions ###
# https://dl.k8s.io/release/stable.txt
ARG KUBECTL_VERSION=v1.22.4
# https://github.com/helm/helm/releases
# ARG HELM3_VERSION=v3.7.1
# https://github.com/derailed/k9s/releases
ARG K9S_VERSION=v0.25.3

### Python ###
LABEL dazzle/layer=lang-python
LABEL dazzle/test=tests/lang-python.yaml
USER gitpod
RUN sudo install-packages python3-pip

ENV PATH=$HOME/.pyenv/bin:$HOME/.pyenv/shims:$PATH
RUN curl -fsSL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && { echo; \
        echo 'eval "$(pyenv init -)"'; \
        echo 'eval "$(pyenv virtualenv-init -)"'; } >> /home/gitpod/.bashrc.d/60-python \
    && pyenv update \
    && pyenv install 3.8.12 \
    && pyenv global 3.8.12 \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir --upgrade \
        setuptools wheel virtualenv pipenv pylint rope flake8 \
        mypy autopep8 pep8 pylama pydocstyle bandit notebook \
        twine \
    && sudo rm -rf /tmp/*
ENV PIP_USER=no
ENV PIPENV_VENV_IN_PROJECT=true
ENV PYTHONUSERBASE=/workspace/.pip-modules
ENV PATH=$PYTHONUSERBASE/bin:$PATH

### Docker ###
LABEL dazzle/layer=tool-docker
LABEL dazzle/test=tests/tool-docker.yaml
USER root
ENV TRIGGER_REBUILD=3
# https://docs.docker.com/engine/install/ubuntu/
RUN curl -o /var/lib/apt/dazzle-marks/docker.gpg -fsSL https://download.docker.com/linux/ubuntu/gpg \
    && apt-key add /var/lib/apt/dazzle-marks/docker.gpg \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && install-packages docker-ce docker-ce-cli containerd.io

RUN curl -o /usr/bin/slirp4netns -fsSL https://github.com/rootless-containers/slirp4netns/releases/download/v1.1.12/slirp4netns-$(uname -m) \
    && chmod +x /usr/bin/slirp4netns

RUN curl -o /usr/local/bin/docker-compose -fsSL https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose

# https://github.com/wagoodman/dive
RUN curl -o /tmp/dive.deb -fsSL https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.deb \
    && apt install /tmp/dive.deb \
    && rm /tmp/dive.deb

### Kubectl ###
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    sudo mv ./kubectl /usr/local/bin/kubectl
    

### Helm ###
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

### kubectx / kubens ###
RUN curl https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o /usr/local/bin/kubectx \
    && curl https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o /usr/local/bin/kubens \
    && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

### kube-ps1 ###
RUN curl https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh -o /usr/local/bin/kube-ps1.sh \
    && echo "source /usr/local/bin/kube-ps1.sh" >> /home/gitpod/.bashrc \
    && echo "export PS1='[\u@\h \W \$(kube_ps1)] \$ '" >> /home/gitpod/.bashrc

### Krew ###
RUN set -x; cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew && \
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> /home/gitpod/.bashrc

### Krew main plugins ###
RUN export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" && \
    kubectl krew install neat && \
    kubectl krew install access-matrix && \
    kubectl krew install cert-manager && \
    kubectl krew install ca-cert && \
    kubectl krew install get-all && \
    kubectl krew install ingress-nginx

### Aliases ###
RUN curl https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases -o /home/gitpod/.aliases \
    && echo "source /home/gitpod/.aliases" >> /home/gitpod/.bashrc

# share env see https://github.com/gitpod-io/workspace-images/issues/472
RUN echo "PATH="${PATH}"" | sudo tee /etc/environment

USER gitpod

### Default kubeconfig location
RUN mkdir /home/gitpod/.kube && touch /home/gitpod/.kube/config
