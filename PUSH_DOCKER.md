# Push image to the Docker registry
docker build -t erikvargas/code-server .
docker login -u erikvargas
docker push erikvargas/code-server
