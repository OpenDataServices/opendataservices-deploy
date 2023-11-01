# This installs Docker from it's own repositories on a Ubuntu machine
# https://docs.docker.com/engine/install/ubuntu/

docker-deps:
  pkg.installed:
    - pkgs:
      - ca-certificates
      - curl
      - gnupg
      - lsb-release

docker-key:
  cmd.run:
    - name: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    - creates: /usr/share/keyrings/docker-archive-keyring.gpg
    - requires:
        - pkg: docker-deps

docker-repo:
  cmd.run:
    - name: echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    - requires:
        - cmd: docker-key

docker-install:
  pkg.installed:
    - refresh: True
    - pkgs:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin
    - requires:
        - cmd: docker-repo

