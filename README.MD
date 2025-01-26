# net-tester

# Usage (local testing)

1. Clone repo
    ```
    git clone https://github.com/drewpypro/net-tester.git
    cd net-tester
    ```

2. Set temp shell
    ```
    env -i bash --norc -noprofile
    ```

3. Set docker PAT (using keepassxc-cli)
    ```
    export DOCKER_PAT=$(keepassxc-cli show -a password /path/to/your/Database.kdbx "docker_pat")
    echo "$DOCKER_PAT" | docker login --username bob --password-stdin
    ```

4. Build and run
    ```
    docker build -t net-tester .
    docker run -d -p 8443:8443 -p 9443:9443 \
    -e LE_EMAIL="bobplopson@example.com" \
    -e LE_HOST="net-test.example.com" \
    -e CLOUDFLARE_API_TOKEN="<cloudflare-api-token>" \
    --name net-tester net-tester
    ```

5. Test
    ```
    docker exec -it net-tester curl -kv -H "net-test.example.com" https://localhost:8443
    docker exec -it net-tester curl -kv -H "net-test.example.com" https://localhost:9443
    ```

6. Teardown & exit
    ```
    docker stop net-tester
    docker rm net-tester
    exit
    ```


# Repo Structure
- apache.conf: Apache configuration for the HTTPS site.
- Dockerfile: Docker build file.
- entrypoint.sh: Startup script for initializing services and Let's Encrypt.
- testsite.conf: NGINX configuration for the HTTPS site.
- supervisord.conf: Supervisor configuration to manage NGINX and Apache processes.
- .github/workflows/docker-build.yaml: GitHub Actions workflow for automated Docker image builds.

