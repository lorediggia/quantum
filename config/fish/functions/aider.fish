function aider --wraps aider --description 'aider in a container'
    podman run -it --rm --net=host --userns=keep-id -v (pwd):/app:Z docker.io/paulgauthier/aider $argv
end
