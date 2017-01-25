docker ps -a | awk '{print $1}' | tail -n +2 | xargs docker stop
docker ps -a | awk '{print $1}' | tail -n +2 | xargs docker rm

